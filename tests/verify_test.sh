#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

VERIFY="$ROOT_DIR/verify.sh"
if [[ ! -x "$VERIFY" ]]; then
  printf 'verify.sh: missing or not executable\n' >&2
  exit 1
fi

TEMP_ROOT="$(make_temp_home)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

prepare_home() {
  local root="$1"
  mkdir -p "$root/.paseo" "$root/state" "$root/skills"
  "$ROOT_DIR/bin/reconcile-config" --empty --output "$root/.paseo/config.json" \
    --codex-models "$ROOT_DIR/tests/fixtures/models/codex.json" \
    --opencode-models "$ROOT_DIR/tests/fixtures/models/opencode.json" >/dev/null
  local skill
  for skill in paseo paseo-handoff paseo-committee paseo-advisor; do
    mkdir -p "$root/skills/$skill"
    printf '# fixture\n' >"$root/skills/$skill/SKILL.md"
  done
}

run_verify() {
  local root="$1"
  shift
  PATH="$ROOT_DIR/tests/fixtures/fake-bin:$PATH" \
  HOME="$root" FAKE_ROOT="$ROOT_DIR" FAKE_STATE_DIR="$root/state" \
  PASEO_WORKFLOW_PROC_VERSION="$ROOT_DIR/tests/fixtures/platform/wsl/proc-version" \
  PASEO_WORKFLOW_OS_RELEASE="$ROOT_DIR/tests/fixtures/platform/wsl/os-release" \
  PASEO_WORKFLOW_SKILL_ROOTS="$root/skills" \
  "$VERIFY" --home "$root/.paseo" --json "$@"
}

ready="$TEMP_ROOT/ready"
prepare_home "$ready"
ready_json="$(FAKE_HEALTHY=1 run_verify "$ready")" || fail 'ready fixture verifies'
assert_eq '"READY"' "$(jq -c '.bootstrapStatus' <<<"$ready_json")" \
  'valid host structure reports READY'
assert_eq '"not tested"' "$(jq -c '.runtime.profileDiscovery' <<<"$ready_json")" \
  'static verification does not overclaim MCP profile discovery'
assert_eq '"not tested"' "$(jq -c '.runtime.capabilityBoundary' <<<"$ready_json")" \
  'static verification does not overclaim capability calls'

missing_skill="$TEMP_ROOT/missing-skill"
prepare_home "$missing_skill"
rm -rf "$missing_skill/skills/paseo-advisor"
set +e
missing_json="$(FAKE_HEALTHY=1 run_verify "$missing_skill" 2>/dev/null)"
missing_status=$?
set -e
assert_eq '1' "$missing_status" 'missing native skill is non-ready'
assert_eq '"BLOCKED"' "$(jq -c '.bootstrapStatus' <<<"$missing_json")" \
  'missing native skill reports BLOCKED'

auth="$TEMP_ROOT/auth"
prepare_home "$auth"
set +e
auth_json="$(FAKE_HEALTHY=1 FAKE_PROVIDER_STATUS=unavailable run_verify "$auth" 2>/dev/null)"
auth_status=$?
set -e
assert_eq '2' "$auth_status" 'unavailable provider uses AUTH_REQUIRED exit status'
assert_eq '"AUTH_REQUIRED"' "$(jq -c '.bootstrapStatus' <<<"$auth_json")" \
  'unavailable provider reports AUTH_REQUIRED'

wrong_profile="$TEMP_ROOT/wrong-profile"
prepare_home "$wrong_profile"
jq '(.daemon.agentProfiles[] | select(.id == "design-agent-review-v02") | .provider) = "codex"' \
  "$wrong_profile/.paseo/config.json" >"$wrong_profile/.paseo/config.next"
mv "$wrong_profile/.paseo/config.next" "$wrong_profile/.paseo/config.json"
set +e
wrong_json="$(FAKE_HEALTHY=1 run_verify "$wrong_profile" 2>/dev/null)"
wrong_status=$?
set -e
assert_eq '1' "$wrong_status" 'wrong profile capability class is non-ready'
assert_eq '"BLOCKED"' "$(jq -c '.bootstrapStatus' <<<"$wrong_json")" \
  'wrong profile capability class reports BLOCKED'

unreachable="$TEMP_ROOT/unreachable"
prepare_home "$unreachable"
set +e
unreachable_json="$(FAKE_HEALTHY=0 run_verify "$unreachable" 2>/dev/null)"
unreachable_status=$?
set -e
assert_eq '1' "$unreachable_status" 'unreachable daemon is non-ready'
assert_eq '"BLOCKED"' "$(jq -c '.bootstrapStatus' <<<"$unreachable_json")" \
  'unreachable daemon reports BLOCKED'

finish_tests
