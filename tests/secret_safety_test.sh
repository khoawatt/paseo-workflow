#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

required_public_files=(
  README.md AGENTS.md SECURITY.md CONTRIBUTING.md
  docs/SETUP.md docs/CONFIGURATION.md docs/VALIDATION.md docs/TROUBLESHOOTING.md
  .github/workflows/test.yml
)
for path in "${required_public_files[@]}"; do
  if [[ -f "$ROOT_DIR/$path" ]]; then
    TESTS_RUN=$((TESTS_RUN + 1)); pass "public operations file exists: $path"
  else
    fail "public operations file exists: $path"
  fi
done

mapfile -t repository_files < <(git -C "$ROOT_DIR" ls-files --cached --others --exclude-standard)
path_findings=()
content_findings=()
runtime_findings=()

for relative in "${repository_files[@]}"; do
  [[ -f "$ROOT_DIR/$relative" ]] || continue
  if [[ "$relative" =~ (^|/)\.paseo/config\.json$ || "$relative" =~ config\.json\.backup- ]]; then
    path_findings+=("$relative")
  fi
  [[ "$relative" == tests/secret_safety_test.sh ]] && continue
  if rg -n -P --no-heading --color never \
    "(?i)-----BEGIN [A-Z0-9 ]*PRIVATE KEY-----|\\b(api[_-]?key|access[_-]?token|refresh[_-]?token|password|session[_-]?cookie|client[_-]?secret)\\s*[:=]\\s*[\"'][A-Za-z0-9+/_=.-]{16,}[\"']" \
    "$ROOT_DIR/$relative" >/dev/null 2>&1; then
    content_findings+=("$relative")
  fi
  if [[ "$relative" == records/* ]] && rg -n -P --no-heading --color never \
    '\b(agt|wks|ses)_[0-9a-f]{12,}\b|\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b' \
    "$ROOT_DIR/$relative" >/dev/null 2>&1; then
    runtime_findings+=("$relative")
  fi
done

assert_eq '0' "${#path_findings[@]}" 'repository contains no live Paseo config or backup path'
assert_eq '0' "${#content_findings[@]}" 'repository contains no credential or private-key material'
assert_eq '0' "${#runtime_findings[@]}" 'sanitized records contain no runtime IDs'

for ignored in .paseo/ 'config.json.backup-*' records/private/ .env '.env.*'; do
  if rg -Fxq "$ignored" "$ROOT_DIR/.gitignore"; then
    TESTS_RUN=$((TESTS_RUN + 1)); pass ".gitignore excludes $ignored"
  else
    fail ".gitignore excludes $ignored"
  fi
done

finish_tests
