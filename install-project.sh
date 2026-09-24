#!/usr/bin/env bash

set -uo pipefail

json_output=false
target=''

usage() {
  printf 'Usage: bash install-project.sh <repository> [--json]\n' >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_output=true; shift ;;
    -*) usage ;;
    *) [[ -z "$target" ]] || usage; target="$1"; shift ;;
  esac
done
[[ -n "$target" ]] || usage

status=PROJECT_RUNTIME_PENDING
exit_status=2
reason='No validated Paseo project runtime exists; inspect the reported manifests and review a minimal paseo.json before adding it.'
manifests_json='[]'
commands_json='[]'

emit() {
  local result
  result="$(jq -n \
    --arg status "$status" \
    --arg path "$target" \
    --arg reason "$reason" \
    --argjson manifests "$manifests_json" \
    --argjson commands "$commands_json" \
    '{
      status: $status,
      repository: $path,
      assessmentMode: "read-only",
      observedManifests: $manifests,
      observedCommands: $commands,
      reason: $reason,
      nextAction: (if $status == "PROJECT_RUNTIME_READY" then
        "Register or open the repository in Paseo and verify its configured scripts against the real workspace."
      elif $status == "PROJECT_RUNTIME_PENDING" then
        "Human-review the observed commands, then add the smallest documented paseo.json appropriate for this repository."
      else
        "Resolve the reported repository or configuration problem, then rerun this assessment."
      end)
    }')"
  if [[ "$json_output" == true ]]; then
    printf '%s\n' "$result"
  else
    jq -r '"\(.status): \(.reason)\nRepository: \(.repository)\nObserved manifests: \(.observedManifests | join(", "))\nObserved commands: \(.observedCommands | join(", "))\nNext action: \(.nextAction)"' <<<"$result"
  fi
  exit "$exit_status"
}

if [[ ! -d "$target" ]]; then
  status=BLOCKED
  exit_status=1
  reason='Target repository path does not exist or is not a directory.'
  emit
fi

target="$(cd "$target" && pwd -P)"
if [[ "$(git -C "$target" rev-parse --is-inside-work-tree 2>/dev/null || true)" != true ]]; then
  status=BLOCKED
  exit_status=1
  reason='Target directory is not a Git repository.'
  emit
fi

manifest_lines=()
for manifest in paseo.json package.json pnpm-workspace.yaml yarn.lock package-lock.json pyproject.toml Cargo.toml go.mod Makefile; do
  [[ -e "$target/$manifest" ]] && manifest_lines+=("$manifest")
done
if [[ ${#manifest_lines[@]} -gt 0 ]]; then
  manifests_json="$(printf '%s\n' "${manifest_lines[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
fi

if [[ -f "$target/paseo.json" ]]; then
  if ! jq -e '
    type == "object"
    and ((.worktree // {}) | type == "object")
    and ((.worktree.setup? // "") | (type == "string" or (type == "array" and all(.[]; type == "string"))))
    and ((.worktree.teardown? // "") | (type == "string" or (type == "array" and all(.[]; type == "string"))))
    and ((.scripts // {}) | type == "object")
    and ((.scripts // {}) | all(to_entries[];
      (.value | type == "object")
      and (.value.command | type == "string" and length > 0)
      and ((.value.type? // "script") | . == "script" or . == "service")
      and ((.value.port? // 1) | type == "number" and . >= 1 and . <= 65535)
    ))
  ' "$target/paseo.json" >/dev/null 2>&1; then
    status=BLOCKED
    exit_status=1
    reason='paseo.json is invalid for the documented Paseo 0.9.1 worktree/scripts shape.'
    emit
  fi
  commands_json="$(jq -c '[.scripts // {} | to_entries[] | .value.command]' "$target/paseo.json")"
  status=PROJECT_RUNTIME_READY
  exit_status=0
  reason='A structurally valid documented paseo.json is present; no project files were changed.'
  emit
fi

if [[ -f "$target/package.json" ]]; then
  if ! jq -e 'type == "object" and ((.scripts // {}) | type == "object")' "$target/package.json" >/dev/null 2>&1; then
    status=BLOCKED
    exit_status=1
    reason='package.json is invalid JSON or its scripts field is not an object.'
    emit
  fi
  commands_json="$(jq -c '[.scripts // {} | to_entries[] | .value | select(type == "string")]' "$target/package.json")"
  reason='Node scripts were observed, but no paseo.json exists; V1 does not guess setup, service, port, or lifecycle policy.'
elif [[ ${#manifest_lines[@]} -gt 0 ]]; then
  reason='Project manifests were observed, but V1 has no validated Paseo runtime for them and will not invent commands.'
else
  reason='No recognized runtime manifest or paseo.json was found; project runtime remains pending.'
fi

emit
