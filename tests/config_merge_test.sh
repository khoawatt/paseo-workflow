#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

RECONCILER="$ROOT_DIR/bin/reconcile-config"
CODEX_MODELS="$ROOT_DIR/tests/fixtures/models/codex.json"
OPENCODE_MODELS="$ROOT_DIR/tests/fixtures/models/opencode.json"

if [[ ! -x "$RECONCILER" ]]; then
  printf 'bin/reconcile-config: missing or not executable\n' >&2
  exit 1
fi

TEMP_ROOT="$(make_temp_home)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

run_reconcile() {
  "$RECONCILER" "$@" \
    --codex-models "$CODEX_MODELS" \
    --opencode-models "$OPENCODE_MODELS"
}

fresh="$TEMP_ROOT/fresh.json"
fresh_summary="$(run_reconcile --empty --output "$fresh")" || fail 'fresh config reconciles'
assert_json "$fresh" '.daemon.mcp' '{"enabled":true,"injectIntoAgents":true}' \
  'fresh config enables native MCP injection'
assert_json "$fresh" '.agents.providers | keys' \
  '["codex-lead","codex-worker","opencode-worker"]' \
  'fresh config creates required capability classes'
assert_json "$fresh" '[.daemon.agentProfiles[].name]' \
  '["Lead","Planning / Research","Implementation","Review","Specialist"]' \
  'fresh config creates five profiles'
assert_json "$fresh" '[.daemon.agentProfiles[].provider]' \
  '["codex-lead","opencode-worker","codex-worker","opencode-worker","codex-worker"]' \
  'fresh profile routing follows V0.2 preferences and review diversity'
assert_json "$fresh" '[.daemon.agentProfiles[] | has("model") or has("thinkingOptionId")] | any' 'false' \
  'fresh profiles do not invent model or thinking preferences'
assert_eq '600' "$(stat -c '%a' "$fresh")" 'candidate config is mode 0600'

existing="$TEMP_ROOT/existing.json"
existing_summary="$(run_reconcile --input "$ROOT_DIR/tests/fixtures/config/existing.json" --output "$existing")" \
  || fail 'existing config reconciles'
assert_json "$existing" '.unknownRoot' '{"nested":[1,2,3]}' \
  'unknown root fields are preserved'
assert_json "$existing" '.daemon.unknownDaemon' '{"keep":true}' \
  'unknown daemon fields are preserved'
assert_json "$existing" '.daemon.mcp.unknownMcpField' '"keep-me"' \
  'unknown MCP fields are preserved'
assert_json "$existing" '.agents.providers["personal-provider"].command' '["personal-agent"]' \
  'unrelated providers are preserved'
assert_json "$existing" '[.daemon.agentProfiles[] | select(.id == "personal-profile")] | length' '1' \
  'unrelated profiles are preserved'
assert_json "$existing" '.agents.providers["codex-worker"].env.EXAMPLE_TOKEN' '"fixture-private-value"' \
  'credential-shaped provider fields are preserved'
assert_json "$existing" '.agents.providers["codex-lead"] | has("paseoTools")' 'false' \
  'Lead capability class removes a conflicting worker policy'
assert_json "$existing" '.daemon.agentProfiles[] | select(.id == "design-agent-planning-research-v02") | {provider,model,thinkingOptionId}' \
  '{"provider":"codex-worker","model":"gpt-5.6-sol","thinkingOptionId":"high"}' \
  'Planning migrates to a compatible restricted provider and preserves preferences'
assert_json "$existing" '.daemon.agentProfiles[] | select(.id == "design-agent-review-v02") | {provider,model,thinkingOptionId}' \
  '{"provider":"codex-worker","model":"gpt-5.6-sol","thinkingOptionId":"high"}' \
  'Review preserves preferences and diversifies from OpenCode Implementation'
assert_json "$existing" '.daemon.agentProfiles[] | select(.id == "design-agent-implementation-v02") | {provider,model,thinkingOptionId}' \
  '{"provider":"opencode-worker","model":"opencode/muse-spark-1.3-contributor-free","thinkingOptionId":"default"}' \
  'Implementation keeps its compatible OpenCode fallback and preferences'
assert_json "$existing" '.daemon.agentProfiles[] | select(.id == "design-agent-specialist-v02") | .featureValues' \
  '{"fast_mode":false}' 'profile feature preferences are preserved'

if [[ "$existing_summary" == *'fixture-private-value'* ]]; then
  fail 'sanitized summary never prints preserved private values'
else
  TESTS_RUN=$((TESTS_RUN + 1))
  pass 'sanitized summary never prints preserved private values'
fi

partial="$TEMP_ROOT/partial.json"
run_reconcile --input "$ROOT_DIR/tests/fixtures/config/partial.json" --output "$partial" >/dev/null \
  || fail 'partial installation reconciles'
assert_json "$partial" '.daemon.relay.enabled' 'false' \
  'partial installation preserves unrelated daemon settings'
assert_json "$partial" '.agents.providers["personal-provider"].label' '"Personal Provider"' \
  'partial installation preserves unrelated provider'

second="$TEMP_ROOT/second.json"
second_summary="$(run_reconcile --input "$existing" --output "$second")" || fail 'second reconciliation succeeds'
assert_eq "$(sha256sum "$existing" | awk '{print $1}')" \
  "$(sha256sum "$second" | awk '{print $1}')" \
  'second reconciliation is byte-identical'
if [[ "$second_summary" == *'changed=false'* ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  pass 'second reconciliation reports no semantic change'
else
  fail 'second reconciliation reports no semantic change'
fi

blocked="$TEMP_ROOT/blocked.json"
set +e
blocked_summary="$(run_reconcile --input "$ROOT_DIR/tests/fixtures/config/incompatible-model.json" --output "$blocked" 2>&1)"
blocked_status=$?
set -e
assert_eq '3' "$blocked_status" 'unavailable model exits with compatibility status 3'
assert_eq 'false' "$([[ -e "$blocked" ]] && printf true || printf false)" \
  'unavailable model does not write a candidate'
if [[ "$blocked_summary" == *'MODEL/PROVIDER GAP'* ]] && [[ "$blocked_summary" == *'design-agent-planning-research-v02'* ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  pass 'compatibility blocker identifies only the affected profile'
else
  fail 'compatibility blocker identifies only the affected profile'
fi

invalid="$TEMP_ROOT/invalid.json"
set +e
PASEO_WORKFLOW_PROFILES_POLICY="$ROOT_DIR/tests/fixtures/config/invalid-profiles-policy.json" \
  run_reconcile --empty --output "$invalid" >/dev/null 2>&1
invalid_status=$?
set -e
assert_eq '2' "$invalid_status" 'invalid policy exits with usage/config status 2'
assert_eq 'false' "$([[ -e "$invalid" ]] && printf true || printf false)" \
  'invalid policy does not write a candidate'

finish_tests
