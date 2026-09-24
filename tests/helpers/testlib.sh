#!/usr/bin/env bash

set -u

TESTS_RUN=0
TESTS_FAILED=0

fail() {
  printf 'not ok - %s\n' "$*" >&2
  TESTS_FAILED=$((TESTS_FAILED + 1))
  return 1
}

pass() {
  printf 'ok - %s\n' "$*"
}

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$actual" == "$expected" ]]; then
    pass "$message"
  else
    fail "$message (expected=$expected actual=$actual)"
  fi
}

assert_json() {
  local file="$1"
  local filter="$2"
  local expected="$3"
  local message="$4"
  local actual
  actual="$(jq -c "$filter" "$file")" || return 1
  assert_eq "$expected" "$actual" "$message"
}

make_temp_home() {
  mktemp -d "${TMPDIR:-/tmp}/paseo-workflow-test.XXXXXX"
}

finish_tests() {
  printf 'tests=%d failures=%d\n' "$TESTS_RUN" "$TESTS_FAILED"
  [[ "$TESTS_FAILED" -eq 0 ]]
}
