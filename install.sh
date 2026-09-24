#!/usr/bin/env bash

set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/config/bootstrap.env"

paseo_home="${PASEO_HOME:-$HOME/.paseo}"
dry_run=false

usage() {
  printf 'Usage: bash install.sh [--home PATH] [--dry-run]\n' >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --home) [[ $# -ge 2 ]] || usage; paseo_home="$2"; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    *) usage ;;
  esac
done

require_wsl_ubuntu

install_dependencies() {
  [[ "${PASEO_WORKFLOW_SKIP_DEPENDENCY_CHECK:-0}" == 1 ]] && return
  local missing=()
  local command_name
  for command_name in curl git jq node npm rg sha256sum; do
    command -v "$command_name" >/dev/null 2>&1 || missing+=("$command_name")
  done
  [[ ${#missing[@]} -eq 0 ]] && return
  log "Installing missing WSL dependencies: ${missing[*]}"
  local packages=(curl git jq nodejs npm ripgrep coreutils)
  if [[ "$(id -u)" -eq 0 ]]; then
    apt-get update
    apt-get install -y "${packages[@]}"
  elif command -v sudo >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y "${packages[@]}"
  else
    die "missing dependencies and sudo is unavailable: ${missing[*]}"
  fi
}

ensure_paseo() {
  local current=''
  set +e
  current="$(paseo --version 2>/dev/null)"
  local status=$?
  set -e
  if [[ $status -ne 0 || -z "$current" ]]; then
    log "Installing ${PASEO_PACKAGE}@${PASEO_VERSION}"
    npm install -g "${PASEO_PACKAGE}@${PASEO_VERSION}"
    current="$(paseo --version)"
  elif version_is_newer "$current" "$PASEO_VERSION"; then
    die "installed Paseo $current is newer than pinned $PASEO_VERSION; automatic downgrade is disabled"
  elif [[ "$current" != "$PASEO_VERSION" ]]; then
    log "Upgrading Paseo from $current to $PASEO_VERSION"
    npm install -g "${PASEO_PACKAGE}@${PASEO_VERSION}"
    current="$(paseo --version)"
  fi
  [[ "$current" == "$PASEO_VERSION" ]] || die "Paseo version check failed after install: $current"
}

native_skills_present() {
  local roots="${PASEO_WORKFLOW_SKILL_ROOTS:-$HOME/.agents/skills:$HOME/.codex/skills}"
  local skill root found
  for skill in paseo paseo-handoff paseo-committee paseo-advisor; do
    found=false
    IFS=: read -r -a skill_roots <<<"$roots"
    for root in "${skill_roots[@]}"; do
      if [[ -f "$root/$skill/SKILL.md" ]]; then
        found=true
        break
      fi
    done
    [[ "$found" == true ]] || return 1
  done
}

ensure_native_skills() {
  [[ "${PASEO_WORKFLOW_SKIP_SKILLS:-0}" == 1 ]] && return
  native_skills_present && return
  log 'Installing native Paseo orchestration skills'
  npx --yes skills add getpaseo/paseo
  native_skills_present || die 'native Paseo skill installation did not provide all required skills'
}

install_dependencies
ensure_paseo
ensure_native_skills

mkdir -p "$paseo_home"
config_path="$paseo_home/config.json"
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/paseo-bootstrap.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT
codex_models="$work_dir/codex-models.json"
opencode_models="$work_dir/opencode-models.json"
candidate="$work_dir/config.json"

paseo provider models codex --thinking --json --home "$paseo_home" >"$codex_models" \
  || die 'unable to discover Codex models; authenticate/install the provider and rerun'
paseo provider models opencode --thinking --json --home "$paseo_home" >"$opencode_models" \
  || die 'unable to discover OpenCode models; authenticate/install the provider and rerun'

reconcile_args=(--output "$candidate" --codex-models "$codex_models" --opencode-models "$opencode_models")
if [[ -f "$config_path" ]]; then
  reconcile_args+=(--input "$config_path")
else
  reconcile_args+=(--empty)
fi
summary="$($ROOT_DIR/bin/reconcile-config "${reconcile_args[@]}")" || exit $?
printf '%s\n' "$summary"

if [[ -f "$config_path" ]] && cmp -s "$config_path" "$candidate"; then
  printf 'READY: configuration already converged; no backup or write required\n'
  exit 0
fi

if [[ "$dry_run" == true ]]; then
  printf 'DRY_RUN: host configuration would change; no files were written\n'
  exit 0
fi

validation_home="$work_dir/validation-home"
mkdir -p "$validation_home"
cp "$candidate" "$validation_home/config.json"
chmod 0600 "$validation_home/config.json"
paseo daemon config set version 1 --home "$validation_home" >/dev/null \
  || die 'native Paseo candidate validation failed'

had_original=false
backup_path=''
if [[ -f "$config_path" ]]; then
  had_original=true
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_path="$paseo_home/config.json.backup-bootstrap-$timestamp"
  cp "$config_path" "$backup_path"
  chmod 0600 "$backup_path"
  printf 'backup=%s sha256=%s\n' "$backup_path" "$(sha256_file "$backup_path")"
fi

live_temp="$(mktemp "$paseo_home/.config.json.bootstrap.XXXXXX")"
cp "$candidate" "$live_temp"
chmod 0600 "$live_temp"
mv -f "$live_temp" "$config_path"

rollback() {
  warn 'apply verification failed; restoring previous configuration'
  if [[ "$had_original" == true ]]; then
    local restore_temp
    restore_temp="$(mktemp "$paseo_home/.config.json.restore.XXXXXX")"
    cp "$backup_path" "$restore_temp"
    chmod 0600 "$restore_temp"
    mv -f "$restore_temp" "$config_path"
  else
    rm -f "$config_path"
  fi
}

status_json="$(paseo daemon status --json --home "$paseo_home" 2>/dev/null || printf '{}')"
local_daemon="$(jq -r '.localDaemon // "unknown"' <<<"$status_json")"
configured_listen="$(jq -r '.configuredListen // "127.0.0.1:6767"' <<<"$status_json")"

apply_ok=true
if [[ "$local_daemon" == running || "$local_daemon" == ready ]]; then
  paseo reload --json --home "$paseo_home" >/dev/null || apply_ok=false
elif curl -fsS "http://$configured_listen/api/health" >/dev/null 2>&1; then
  paseo --host "$configured_listen" reload --json >/dev/null || apply_ok=false
else
  paseo daemon start --home "$paseo_home" >/dev/null || apply_ok=false
fi

if [[ "$apply_ok" != true ]] || ! config_policy_valid "$config_path"; then
  rollback
  if [[ "$local_daemon" == running || "$local_daemon" == ready ]]; then
    paseo reload --json --home "$paseo_home" >/dev/null 2>&1 || true
  elif curl -fsS "http://$configured_listen/api/health" >/dev/null 2>&1; then
    paseo --host "$configured_listen" reload --json >/dev/null 2>&1 || true
  fi
  die 'configuration was restored after reload or verification failure'
fi

printf 'READY: Paseo %s configuration reconciled and applied\n' "$PASEO_VERSION"
