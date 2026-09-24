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
  local providers_policy="$2"
  local profiles_policy="$3"
  jq -e --slurpfile provider_policy "$providers_policy" \
    --slurpfile profile_policy "$profiles_policy" '
    ($provider_policy[0]) as $required_providers
    | ($profile_policy[0].profiles) as $required_profiles
    | . as $config
    | (
      $required_providers
      | to_entries
      | all(.[]; . as $provider
        |
          ($provider.value | to_entries)
          | all(.[]; . as $field
            |
              $config.agents.providers[$provider.key][$field.key] == $field.value))
    ) as $providers_match
    | (
      $required_profiles
      | all(.[]; . as $required
        |
          [$config.daemon.agentProfiles[]?
           | select(.id == $required.id)] as $matches
          | ($matches | length) == 1
          and $matches[0].name == $required.name
          and $matches[0].notes == $required.notes
          and ($required.allowedProviders | index($matches[0].provider) != null))
    ) as $profiles_match
    |
    .daemon.mcp.enabled == true
    and .daemon.mcp.injectIntoAgents == true
    and $providers_match
    and (.agents.providers["codex-lead"] | has("paseoTools") | not)
    and $profiles_match
  ' "$file" >/dev/null
}

provider_diagnostic_state() {
  local diagnostic_json="$1"
  local diagnostic
  diagnostic="$(jq -r '.diagnostic // ""' <<<"$diagnostic_json" 2>/dev/null || true)"
  local normalized="${diagnostic,,}"

  if [[ -z "$diagnostic" ]]; then
    printf 'error\n'
  elif [[ "$normalized" =~ resolved[[:space:]]path:[[:space:]]*(not[[:space:]]found|missing) ]] \
    || [[ "$normalized" =~ status:[[:space:]]*(not[[:space:]]installed|missing) ]] \
    || [[ "$normalized" == *"command not found"* ]]; then
    printf 'missing\n'
  elif [[ "$normalized" == *"status: ready"* ]]; then
    printf 'ready\n'
  elif [[ "$normalized" == *"authentication required"* ]] \
    || [[ "$normalized" == *"not authenticated"* ]] \
    || [[ "$normalized" == *"login required"* ]] \
    || [[ "$normalized" == *"unauthorized"* ]] \
    || [[ "$normalized" == *"missing credential"* ]]; then
    printf 'auth_required\n'
  else
    printf 'error\n'
  fi
}

provider_install_action() {
  case "$1" in
    codex)
      printf 'Install the Codex CLI on the Paseo daemon host, run `codex login`, ensure `codex` is on the daemon PATH, then rerun the bootstrap.'
      ;;
    opencode)
      printf 'Install OpenCode on the Paseo daemon host, complete its provider authentication, ensure `opencode` is on the daemon PATH, then rerun the bootstrap.'
      ;;
  esac
}

provider_auth_action() {
  case "$1" in
    codex)
      printf 'Run `codex login` interactively on the Paseo daemon host, then rerun verification.'
      ;;
    opencode)
      printf 'Complete OpenCode provider authentication interactively on the Paseo daemon host, then rerun verification.'
      ;;
  esac
}
