#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

INSTALL_PROJECT="$ROOT_DIR/install-project.sh"
if [[ ! -x "$INSTALL_PROJECT" ]]; then
  printf 'install-project.sh: missing or not executable\n' >&2
  exit 1
fi

TEMP_ROOT="$(make_temp_home)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

copy_fixture() {
  local name="$1"
  local target="$TEMP_ROOT/$name"
  mkdir -p "$target"
  cp -R "$ROOT_DIR/tests/fixtures/projects/$name/." "$target/"
  git -C "$target" init -q
  printf '%s\n' "$target"
}

tree_sha() {
  local target="$1"
  find "$target" -path "$target/.git" -prune -o -type f -print0 \
    | sort -z \
    | xargs -0 sha256sum \
    | sha256sum \
    | awk '{print $1}'
}

set +e
missing_json="$($INSTALL_PROJECT "$TEMP_ROOT/does-not-exist" --json 2>/dev/null)"
missing_status=$?
set -e
assert_eq '1' "$missing_status" 'missing target is blocked'
assert_eq '"BLOCKED"' "$(jq -c '.status' <<<"$missing_json")" 'missing target reports BLOCKED'

non_git="$TEMP_ROOT/non-git"
mkdir -p "$non_git"
set +e
non_git_json="$($INSTALL_PROJECT "$non_git" --json 2>/dev/null)"
non_git_status=$?
set -e
assert_eq '1' "$non_git_status" 'non-git target is blocked'
assert_eq '"BLOCKED"' "$(jq -c '.status' <<<"$non_git_json")" 'non-git target reports BLOCKED'

ready="$(copy_fixture node-existing-runtime)"
ready_before="$(tree_sha "$ready")"
ready_json="$($INSTALL_PROJECT "$ready" --json)" || fail 'documented paseo.json is ready'
assert_eq '"PROJECT_RUNTIME_READY"' "$(jq -c '.status' <<<"$ready_json")" 'valid paseo.json reports ready'
assert_eq '["npm test","npm run dev -- --port $PASEO_PORT"]' \
  "$(jq -c '.observedCommands' <<<"$ready_json")" 'ready assessment reports only configured commands'
assert_eq "$ready_before" "$(tree_sha "$ready")" 'ready assessment does not mutate target tree'

node_pending="$(copy_fixture node-no-runtime)"
node_before="$(tree_sha "$node_pending")"
set +e
node_json="$($INSTALL_PROJECT "$node_pending" --json)"
node_status=$?
set -e
assert_eq '2' "$node_status" 'Node project without paseo.json is pending'
assert_eq '"PROJECT_RUNTIME_PENDING"' "$(jq -c '.status' <<<"$node_json")" 'Node project reports pending'
assert_eq '["eslint .","vitest run"]' "$(jq -c '.observedCommands' <<<"$node_json")" \
  'pending assessment reports only literal package script bodies'
assert_eq "$node_before" "$(tree_sha "$node_pending")" 'pending assessment does not mutate target tree'

unknown="$(copy_fixture unknown)"
unknown_before="$(tree_sha "$unknown")"
set +e
unknown_json="$($INSTALL_PROJECT "$unknown" --json)"
unknown_status=$?
set -e
assert_eq '2' "$unknown_status" 'unknown manifest remains pending'
assert_eq '[]' "$(jq -c '.observedCommands' <<<"$unknown_json")" 'unknown manifest invents no commands'
assert_eq "$unknown_before" "$(tree_sha "$unknown")" 'unknown assessment does not mutate target tree'

no_manifest="$(copy_fixture missing-manifest)"
set +e
no_manifest_json="$($INSTALL_PROJECT "$no_manifest" --json)"
no_manifest_status=$?
set -e
assert_eq '2' "$no_manifest_status" 'repository without manifests remains pending'
assert_eq '[]' "$(jq -c '.observedCommands' <<<"$no_manifest_json")" 'repository without manifests invents no commands'

finish_tests
