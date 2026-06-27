#!/usr/bin/env bash
set -euo pipefail

# Smoke-test daily shell UI entry points.
# Read-only: protects the normal report path and representative UI routes.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

export NO_COLOR=1
fixture="${1:-fixtures/src-next-golden}"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

assert_nonempty_contains() {
  local name="$1" expected="$2"
  shift 2
  local out err
  out="$(mktemp)"
  err="$(mktemp)"
  if "$@" >"$out" 2>"$err"; then
    if [[ ! -s "$out" ]]; then
      fail "$name produced empty output"
    elif ! grep -qF -- "$expected" "$out"; then
      fail "$name output did not contain expected text: $expected"
    else
      pass "$name renders visible output"
    fi
  else
    fail "$name failed: $(head -1 "$err")"
  fi
  rm -f "$out" "$err"
}

if bash -n tools/main-ui.sh; then pass "main-ui syntax ok"; else fail "main-ui syntax error"; fi
if bash -n tools/add-ui.sh; then pass "add-ui syntax ok"; else fail "add-ui syntax error"; fi

assert_nonempty_contains \
  "main-ui default report" \
  "1. 全体サマリ" \
  tools/main-ui.sh --base "$fixture"

assert_nonempty_contains \
  "main-ui report command" \
  "== Readiness Check ==" \
  tools/main-ui.sh --base "$fixture" report

sections=(
  "snapshot|1. 全体サマリ"
  "envelopes|== Envelope & Budget =="
  "planned|== Planned Payments =="
  "check|== Readiness Check =="
  "trial-balance|== Trial Balance"
)

for item in "${sections[@]}"; do
  section="${item%%|*}"
  expected="${item#*|}"
  assert_nonempty_contains \
    "main-ui section: $section" \
    "$expected" \
    tools/main-ui.sh --base "$fixture" "$section"
done

if tools/add-ui.sh --help >/dev/null; then
  pass "add-ui help works"
else
  fail "add-ui help failed"
fi

if tools/main-ui.sh --help >/dev/null; then
  pass "main-ui help works"
else
  fail "main-ui help failed"
fi

bad_out="$(mktemp)"
bad_err="$(mktemp)"
if tools/main-ui.sh --base /definitely/missing/base >"$bad_out" 2>"$bad_err"; then
  fail "main-ui missing base unexpectedly succeeded"
else
  if [[ -s "$bad_err" ]]; then
    pass "main-ui missing base reports visible error"
  else
    fail "main-ui missing base failed silently"
  fi
fi
rm -f "$bad_out" "$bad_err"

if [[ "$failures" -eq 0 ]]; then
  echo "OK: UI smoke checks passed" >&2
  exit 0
else
  echo "FAILED: $failures UI smoke check(s) failed" >&2
  exit 1
fi
