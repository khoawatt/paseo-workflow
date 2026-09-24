#!/usr/bin/env bash

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

die() {
  printf 'BLOCKED: %s\n' "$*" >&2
  exit 1
}

require_wsl_ubuntu() {
  local proc_version="${PASEO_WORKFLOW_PROC_VERSION:-/proc/version}"
  local os_release="${PASEO_WORKFLOW_OS_RELEASE:-/etc/os-release}"
  [[ -r "$proc_version" && -r "$os_release" ]] || die 'platform metadata is unavailable'
  rg -qi 'microsoft.*wsl|wsl.*microsoft' "$proc_version" || die 'V1 supports WSL2 only'
  # shellcheck disable=SC1090
  source "$os_release"
  [[ "${ID:-}" == ubuntu ]] || die 'V1 supports Ubuntu only'
}

version_is_newer() {
  local current="$1"
  local pinned="$2"
  [[ "$current" != "$pinned" && "$(printf '%s\n%s\n' "$pinned" "$current" | sort -V | tail -1)" == "$current" ]]
}

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

config_policy_valid() {
  local file="$1"
  jq -e '
    .daemon.mcp.enabled == true
    and .daemon.mcp.injectIntoAgents == true
    and .agents.providers["codex-lead"].extends == "codex"
    and (.agents.providers["codex-lead"] | has("paseoTools") | not)
    and .agents.providers["codex-worker"].paseoTools.enabled == false
    and .agents.providers["opencode-worker"].paseoTools.enabled == false
    and ([.daemon.agentProfiles[] | select(.id == "design-agent-lead-v02")] | length == 1)
    and ([.daemon.agentProfiles[] | select(.id == "design-agent-planning-research-v02") | .provider] | all(. == "codex-worker" or . == "opencode-worker"))
    and ([.daemon.agentProfiles[] | select(.id == "design-agent-review-v02") | .provider] | all(. == "codex-worker" or . == "opencode-worker"))
  ' "$file" >/dev/null
}
