#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"

paseo_home="${PASEO_HOME:-$HOME/.paseo}"
json_output=false

usage() {
  printf 'Usage: bash verify.sh [--home PATH] [--json]\n' >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home) [[ $# -ge 2 ]] || usage; paseo_home="$2"; shift 2 ;;
    --json) json_output=true; shift ;;
    *) usage ;;
  esac
done

require_wsl_ubuntu

config_path="$paseo_home/config.json"
blockers=()
auth_required=()
config_status=valid
profiles_status=valid
skills_status=available
providers_status=available
daemon_status=available

if [[ ! -f "$config_path" ]]; then
  config_status=missing
  profiles_status='not tested'
  blockers+=('Paseo config is missing')
elif ! jq -e . "$config_path" >/dev/null 2>&1; then
  config_status=invalid
  profiles_status='not tested'
  blockers+=('Paseo config is not valid JSON')
elif ! config_policy_valid "$config_path"; then
  config_status='policy mismatch'
  profiles_status='policy mismatch'
  blockers+=('required provider/profile policy is not reconciled')
fi

skill_roots="${PASEO_WORKFLOW_SKILL_ROOTS:-$HOME/.agents/skills:$HOME/.codex/skills}"
for skill in paseo paseo-handoff paseo-committee paseo-advisor; do
  found=false
  IFS=: read -r -a roots <<<"$skill_roots"
  for root in "${roots[@]}"; do
    if [[ -f "$root/$skill/SKILL.md" ]]; then
      found=true
      break
    fi
  done
  if [[ "$found" != true ]]; then
    skills_status=missing
    blockers+=("native skill is missing: $skill")
  fi
done

status_json="$(paseo daemon status --json --home "$paseo_home" 2>/dev/null || printf '{}')"
local_daemon="$(jq -r '.localDaemon // "unknown"' <<<"$status_json" 2>/dev/null || printf unknown)"
configured_listen="$(jq -r '.configuredListen // "127.0.0.1:6767"' <<<"$status_json" 2>/dev/null || printf '127.0.0.1:6767')"

provider_json=''
if [[ "$local_daemon" == running || "$local_daemon" == ready ]]; then
  provider_json="$(paseo provider ls --json --home "$paseo_home" 2>/dev/null || true)"
elif curl -fsS "http://$configured_listen/api/health" >/dev/null 2>&1; then
  provider_json="$(paseo --host "$configured_listen" provider ls --json 2>/dev/null || true)"
else
  daemon_status=unreachable
  blockers+=("Paseo daemon is not reachable at $configured_listen")
fi

if [[ -n "$provider_json" ]]; then
  for provider in codex-lead codex-worker opencode-worker; do
    provider_state="$(jq -r --arg id "$provider" '
      if type == "array" then
        first(.[] | select((.provider // .id) == $id) | .status) // "missing"
      else
        first((.providers // [])[] | select((.provider // .id) == $id) | .status) // "missing"
      end
    ' <<<"$provider_json" 2>/dev/null || printf missing)"
    if [[ "$provider_state" != available ]]; then
      providers_status=unavailable
      auth_required+=("provider $provider is $provider_state")
    fi
  done
elif [[ "$daemon_status" == available ]]; then
  providers_status='not discoverable'
  blockers+=('Paseo provider discovery failed')
fi

paseo_version="$(paseo --version 2>/dev/null || printf unknown)"
bootstrap_status=READY
exit_status=0
if [[ ${#blockers[@]} -gt 0 ]]; then
  bootstrap_status=BLOCKED
  exit_status=1
elif [[ ${#auth_required[@]} -gt 0 ]]; then
  bootstrap_status=AUTH_REQUIRED
  exit_status=2
fi

blockers_json="$(printf '%s\n' "${blockers[@]:-}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
auth_json="$(printf '%s\n' "${auth_required[@]:-}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
result="$(jq -n \
  --arg paseoVersion "$paseo_version" \
  --arg bootstrapStatus "$bootstrap_status" \
  --arg config "$config_status" \
  --arg providers "$providers_status" \
  --arg profiles "$profiles_status" \
  --arg skills "$skills_status" \
  --arg daemon "$daemon_status" \
  --argjson blockers "$blockers_json" \
  --argjson authRequired "$auth_json" \
  '{
    paseoVersion: $paseoVersion,
    bootstrapStatus: $bootstrapStatus,
    checks: {
      platform: "WSL2 Ubuntu",
      config: $config,
      providers: $providers,
      profiles: $profiles,
      skills: $skills,
      daemon: $daemon
    },
    runtime: {
      profileDiscovery: "not tested",
      capabilityBoundary: "not tested"
    },
    blockers: $blockers,
    authRequired: $authRequired,
    observedMismatches: [
      "Paseo 0.9.1 public config schema omits daemon.agentProfiles although the runtime consumes it"
    ]
  }')"

if [[ "$json_output" == true ]]; then
  printf '%s\n' "$result"
else
  jq -r '"Bootstrap status: \(.bootstrapStatus)\nPaseo version: \(.paseoVersion)\nChecks: \(.checks | to_entries | map("\(.key)=\(.value)") | join(", "))", (.blockers[]? | "BLOCKED: \(.)"), (.authRequired[]? | "AUTH_REQUIRED: \(.)")' <<<"$result"
fi

exit "$exit_status"
