#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

PROVIDERS="$ROOT_DIR/policy/providers.json"
PROFILES="$ROOT_DIR/policy/profiles.json"

for required in "$PROVIDERS" "$PROFILES"; do
  if [[ ! -f "$required" ]]; then
    printf '%s: missing\n' "${required#"$ROOT_DIR/"}" >&2
    exit 1
  fi
done

assert_json "$PROVIDERS" 'keys' '["codex-lead","codex-worker","opencode-worker"]' \
  'policy defines only required provider capability classes'
assert_json "$PROVIDERS" '.["codex-lead"]' \
  '{"extends":"codex","label":"Codex Lead"}' \
  'Lead provider retains the complete Paseo catalog by omission'
assert_json "$PROVIDERS" '.["codex-worker"].paseoTools.enabled' 'false' \
  'Codex worker disables Paseo tools'
assert_json "$PROVIDERS" '.["opencode-worker"].paseoTools.enabled' 'false' \
  'OpenCode worker disables Paseo tools'

assert_json "$PROFILES" '.profiles | length' '5' \
  'policy defines exactly five V0.2 profiles'
assert_json "$PROFILES" '[.profiles[].name]' \
  '["Lead","Planning / Research","Implementation","Review","Specialist"]' \
  'profile names match V0.2 roles in stable order'
assert_json "$PROFILES" '[.profiles[].id]' \
  '["design-agent-lead-v02","design-agent-planning-research-v02","design-agent-implementation-v02","design-agent-review-v02","design-agent-specialist-v02"]' \
  'profile IDs are stable V0.2 identities'
assert_json "$PROFILES" '[.profiles[] | select(.name != "Lead") | .allowedProviders[]] | unique' \
  '["codex-worker","opencode-worker"]' \
  'non-Lead roles allow only restricted provider IDs'
assert_json "$PROFILES" '[.profiles[] | select(.name == "Integration")] | length' '0' \
  'Integration is not a permanent V0.2 profile'
assert_json "$PROFILES" '[.profiles[] | has("model") or has("thinkingOptionId")] | any' 'false' \
  'fresh policy does not hard-code user-owned model or thinking preferences'

if rg -ni 'api[_-]?key|access[_-]?token|refresh[_-]?token|password|session[_-]?cookie|private[_-]?key' \
  "$PROVIDERS" "$PROFILES" >/dev/null; then
  fail 'policy files contain no secret-bearing keys'
else
  TESTS_RUN=$((TESTS_RUN + 1))
  pass 'policy files contain no secret-bearing keys'
fi

finish_tests
