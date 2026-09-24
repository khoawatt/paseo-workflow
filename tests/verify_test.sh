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
auth_json="$(FAKE_HEALTHY=1 FAKE_PROVIDER_STATUS=unavailable \
  FAKE_DIAGNOSTIC_STATE=auth_required run_verify "$auth" 2>/dev/null)"
auth_status=$?
set -e
assert_eq '2' "$auth_status" 'unavailable provider uses AUTH_REQUIRED exit status'
assert_eq '"AUTH_REQUIRED"' "$(jq -c '.bootstrapStatus' <<<"$auth_json")" \
  'unavailable provider reports AUTH_REQUIRED'
assert_eq '"auth_required"' "$(jq -c '.checks.providerRuntimes.codex' <<<"$auth_json")" \
  'native diagnostic identifies authentication requirement'

missing_provider="$TEMP_ROOT/missing-provider"
prepare_home "$missing_provider"
set +e
missing_provider_json="$(FAKE_HEALTHY=1 FAKE_PROVIDER_STATUS=unavailable \
  FAKE_CODEX_DIAGNOSTIC_STATE=missing run_verify "$missing_provider" 2>/dev/null)"
missing_provider_status=$?
set -e
assert_eq '1' "$missing_provider_status" 'missing external provider runtime is blocked'
assert_eq '"BLOCKED"' "$(jq -c '.bootstrapStatus' <<<"$missing_provider_json")" \
  'missing external provider runtime is not misclassified as authentication'
assert_eq 'true' "$(jq -c '[.blockers[] | contains("Install the Codex CLI")] | any' <<<"$missing_provider_json")" \
  'missing runtime reports the exact external installation action'

runtime_error="$TEMP_ROOT/runtime-error"
prepare_home "$runtime_error"
set +e
runtime_error_json="$(FAKE_HEALTHY=1 FAKE_PROVIDER_STATUS=unavailable \
  FAKE_OPENCODE_DIAGNOSTIC_STATE=error run_verify "$runtime_error" 2>/dev/null)"
runtime_error_status=$?
set -e
assert_eq '1' "$runtime_error_status" 'installed but unhealthy runtime is blocked'
assert_eq 'true' "$(jq -c '[.blockers[] | contains("OPENCODE_COMPATIBILITY.md")] | any' <<<"$runtime_error_json")" \
  'OpenCode runtime error reports conditional compatibility next action'

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

wrong_provider_policy="$TEMP_ROOT/wrong-provider-policy"
prepare_home "$wrong_provider_policy"
jq '.agents.providers["codex-worker"].label = "User label"' \
  "$wrong_provider_policy/.paseo/config.json" >"$wrong_provider_policy/.paseo/config.next"
mv "$wrong_provider_policy/.paseo/config.next" "$wrong_provider_policy/.paseo/config.json"
set +e
wrong_provider_policy_json="$(FAKE_HEALTHY=1 run_verify "$wrong_provider_policy" 2>/dev/null)"
wrong_provider_policy_status=$?
set -e
assert_eq '1' "$wrong_provider_policy_status" 'repository-owned provider label mismatch is blocked'
assert_eq '"policy mismatch"' "$(jq -c '.checks.config' <<<"$wrong_provider_policy_json")" \
  'verification covers every repository-owned provider field'

wrong_profile_notes="$TEMP_ROOT/wrong-profile-notes"
prepare_home "$wrong_profile_notes"
jq '(.daemon.agentProfiles[] | select(.id == "design-agent-review-v02") | .notes) = "stale"' \
  "$wrong_profile_notes/.paseo/config.json" >"$wrong_profile_notes/.paseo/config.next"
mv "$wrong_profile_notes/.paseo/config.next" "$wrong_profile_notes/.paseo/config.json"
set +e
wrong_profile_notes_json="$(FAKE_HEALTHY=1 run_verify "$wrong_profile_notes" 2>/dev/null)"
wrong_profile_notes_status=$?
set -e
assert_eq '1' "$wrong_profile_notes_status" 'repository-owned profile notes mismatch is blocked'
assert_eq '"policy mismatch"' "$(jq -c '.checks.profiles' <<<"$wrong_profile_notes_json")" \
  'verification covers repository-owned profile name and notes policy'

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
