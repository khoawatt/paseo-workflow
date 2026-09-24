#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
failures=0

for test_file in "$ROOT_DIR"/tests/*_test.sh; do
  [[ -e "$test_file" ]] || continue
  printf '==> %s\n' "${test_file#"$ROOT_DIR/"}"
  if ! bash "$test_file"; then
    failures=$((failures + 1))
  fi
done

printf 'failures=%d\n' "$failures"
[[ "$failures" -eq 0 ]]
