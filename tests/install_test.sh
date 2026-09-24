#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

INSTALLER="$ROOT_DIR/install.sh"
if [[ ! -x "$INSTALLER" ]]; then
  printf 'install.sh: missing or not executable\n' >&2
  exit 1
fi

TEMP_ROOT="$(make_temp_home)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_install() {
  local home="$1"
  shift
  mkdir -p "$home" "$home/state"
  local skill
  for skill in paseo paseo-handoff paseo-committee paseo-advisor; do
    mkdir -p "$home/skills/$skill"
    printf '# fixture\n' >"$home/skills/$skill/SKILL.md"
  done
  PATH="$ROOT_DIR/tests/fixtures/fake-bin:$PATH" \
  HOME="$home" \
  FAKE_ROOT="$ROOT_DIR" \
  FAKE_STATE_DIR="$home/state" \
  PASEO_WORKFLOW_PROC_VERSION="$ROOT_DIR/tests/fixtures/platform/wsl/proc-version" \
  PASEO_WORKFLOW_OS_RELEASE="$ROOT_DIR/tests/fixtures/platform/wsl/os-release" \
  PASEO_WORKFLOW_SKIP_DEPENDENCY_CHECK=1 \
  PASEO_WORKFLOW_SKIP_SKILLS=1 \
  PASEO_WORKFLOW_SKILL_ROOTS="$home/skills" \
  "$INSTALLER" --home "$home/.paseo" "$@"
}

native_home="$TEMP_ROOT/native"
mkdir -p "$native_home/state"
set +e
PATH="$ROOT_DIR/tests/fixtures/fake-bin:$PATH" \
HOME="$native_home" FAKE_ROOT="$ROOT_DIR" FAKE_STATE_DIR="$native_home/state" \
PASEO_WORKFLOW_PROC_VERSION="$ROOT_DIR/tests/fixtures/platform/native/proc-version" \
PASEO_WORKFLOW_OS_RELEASE="$ROOT_DIR/tests/fixtures/platform/native/os-release" \
PASEO_WORKFLOW_SKIP_DEPENDENCY_CHECK=1 \
PASEO_WORKFLOW_SKIP_SKILLS=1 \
"$INSTALLER" --home "$native_home/.paseo" >"$native_home/output" 2>&1
native_status=$?
set -e
assert_eq '1' "$native_status" 'native Linux is rejected by the WSL-only bootstrap'

apply_home="$TEMP_ROOT/apply"
mkdir -p "$apply_home/.paseo"
cp "$ROOT_DIR/tests/fixtures/config/existing.json" "$apply_home/.paseo/config.json"
before_sha="$(sha256sum "$apply_home/.paseo/config.json" | awk '{print $1}')"
apply_output="$(FAKE_HEALTHY=1 run_install "$apply_home")" || fail 'changed host config applies'
after_sha="$(sha256sum "$apply_home/.paseo/config.json" | awk '{print $1}')"
assert_eq 'false' "$([[ "$before_sha" == "$after_sha" ]] && printf true || printf false)" \
  'changed config receives a new SHA'
assert_eq '1' "$(find "$apply_home/.paseo" -maxdepth 1 -name 'config.json.backup-bootstrap-*' | wc -l)" \
  'changed config creates one timestamped backup'
assert_json "$apply_home/.paseo/config.json" '.daemon.agentProfiles[] | select(.id == "design-agent-review-v02") | .provider' \
  '"codex-worker"' 'live profile is reconciled to a restricted provider'
if rg -q 'paseo --host 127.0.0.1:6767 reload' "$apply_home/state/calls.log"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'healthy external daemon receives explicit-host reload'
else
  fail 'healthy external daemon receives explicit-host reload'
fi
if rg -q 'provider ls' "$apply_home/state/calls.log"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'installer finishes with native provider verification'
else
  fail 'installer finishes with native provider verification'
fi

stable_sha="$(sha256sum "$apply_home/.paseo/config.json" | awk '{print $1}')"
run_install "$apply_home" >/dev/null || fail 'no-op rerun succeeds'
assert_eq "$stable_sha" "$(sha256sum "$apply_home/.paseo/config.json" | awk '{print $1}')" \
  'no-op rerun preserves config SHA'
assert_eq '1' "$(find "$apply_home/.paseo" -maxdepth 1 -name 'config.json.backup-bootstrap-*' | wc -l)" \
  'no-op rerun creates no additional backup'

start_home="$TEMP_ROOT/start"
FAKE_HEALTHY=0 run_install "$start_home" >/dev/null || fail 'stopped host bootstrap succeeds'
if rg -q 'paseo daemon start --home' "$start_home/state/calls.log"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'missing health endpoint starts the selected home'
else
  fail 'missing health endpoint starts the selected home'
fi

rollback_home="$TEMP_ROOT/rollback"
mkdir -p "$rollback_home/.paseo"
cp "$ROOT_DIR/tests/fixtures/config/existing.json" "$rollback_home/.paseo/config.json"
rollback_sha="$(sha256sum "$rollback_home/.paseo/config.json" | awk '{print $1}')"
set +e
FAKE_HEALTHY=1 FAKE_RELOAD_FAIL=1 run_install "$rollback_home" >/dev/null 2>&1
rollback_status=$?
set -e
assert_eq '1' "$rollback_status" 'reload failure returns BLOCKED/nonzero'
assert_eq "$rollback_sha" "$(sha256sum "$rollback_home/.paseo/config.json" | awk '{print $1}')" \
  'reload failure restores the exact original config'

missing_provider_home="$TEMP_ROOT/missing-provider"
set +e
FAKE_CODEX_DIAGNOSTIC_STATE=missing run_install "$missing_provider_home" \
  >"$missing_provider_home-output" 2>&1
missing_provider_status=$?
set -e
assert_eq '1' "$missing_provider_status" 'missing external provider runtime returns BLOCKED'
if rg -q 'Install the Codex CLI' "$missing_provider_home-output"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'missing provider reports exact user-owned install action'
else
  fail 'missing provider reports exact user-owned install action'
fi
if [[ -f "$missing_provider_home/state/calls.log" ]] \
  && rg -q 'npm install.*(@openai/codex|opencode)' "$missing_provider_home/state/calls.log"; then
  fail 'bootstrap never installs an external provider runtime'
else
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'bootstrap never installs an external provider runtime'
fi

auth_provider_home="$TEMP_ROOT/auth-provider"
set +e
FAKE_CODEX_DIAGNOSTIC_STATE=auth_required run_install "$auth_provider_home" \
  >"$auth_provider_home-output" 2>&1
auth_provider_status=$?
set -e
assert_eq '2' "$auth_provider_status" 'installed provider requiring login returns AUTH_REQUIRED'
if rg -q 'codex login' "$auth_provider_home-output"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'authentication status reports exact interactive next action'
else
  fail 'authentication status reports exact interactive next action'
fi

missing_home="$TEMP_ROOT/missing"
FAKE_PASEO_VERSION=missing run_install "$missing_home" >/dev/null || fail 'missing Paseo is installed at the pinned version'
if rg -q 'npm install -g @getpaseo/cli@0.9.1' "$missing_home/state/calls.log"; then
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'missing Paseo uses the pinned npm package'
else
  fail 'missing Paseo uses the pinned npm package'
fi

newer_home="$TEMP_ROOT/newer"
set +e
FAKE_PASEO_VERSION=0.10.0 run_install "$newer_home" >"$newer_home-output" 2>&1
newer_status=$?
set -e
assert_eq '1' "$newer_status" 'newer Paseo version requires an explicit policy decision'
if [[ -f "$newer_home/state/calls.log" ]] && rg -q '^npm ' "$newer_home/state/calls.log"; then
  fail 'newer Paseo is never downgraded automatically'
else
  TESTS_RUN=$((TESTS_RUN + 1)); pass 'newer Paseo is never downgraded automatically'
fi

finish_tests
