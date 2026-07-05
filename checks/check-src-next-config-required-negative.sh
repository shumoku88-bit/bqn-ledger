#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# Characterize current Required accessor failure behavior for A4.
# Both missing and explicit-empty household group keys currently fail with
# exit 1 and the same CONFIG ERROR message.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); }
fail() { FAIL=$((FAIL + 1)); echo "FAIL: $*" >&2; }

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  if [ "$expected" = "$actual" ]; then
    pass
  else
    fail "$label: expected [$expected] got [$actual]"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" label="$3"
  if printf '%s\n' "$haystack" | grep -qF -- "$needle"; then
    pass
  else
    fail "$label: expected output to contain [$needle], got [$haystack]"
  fi
}

check_failure() {
  local base="$1" key="$2" state="$3" out code

  if out=$(bqn tests/config_required_probe.bqn "$base" "$key" 2>&1); then
    fail "$state $key should fail"
    return
  else
    code=$?
  fi

  assert_eq "1" "$code" "$state $key exit code"
  assert_contains "CONFIG ERROR: missing value for $key" "$out" "$state $key error message"
}

for key in HOUSEHOLD_GROUP_LIFE HOUSEHOLD_GROUP_RESERVE; do
  check_failure "fixtures/src-next-config-eligible-missing" "$key" "missing"
  check_failure "fixtures/src-next-config-eligible-empty" "$key" "explicit-empty"
done

echo "check-src-next-config-required-negative: $PASS passed, $FAIL failed" >&2
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi

echo "OK" >&2
