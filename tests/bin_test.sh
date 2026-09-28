#!/usr/bin/env bash

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/tests/helpers/testlib.sh"

TEMP_ROOT="$(make_temp_home)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

ln -s "$ROOT_DIR/src/cli.ts" "$TEMP_ROOT/paseo-workflow"
help_output="$("$TEMP_ROOT/paseo-workflow" --help)" || fail 'symlinked package bin runs'
if [[ "$help_output" == *'Usage: paseo-workflow <command> [options]'* ]]; then
  TESTS_RUN=$((TESTS_RUN + 1))
  pass 'symlinked package bin resolves the real TypeScript entrypoint'
else
  fail 'symlinked package bin resolves the real TypeScript entrypoint'
fi

finish_tests
