#!/usr/bin/env bash
set -euo pipefail

# Smoke-test daily shell UI entry points.
# Read-only: protects selector, full report, and representative UI routes.

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

assert_stdin_nonempty_contains() {
  local name="$1" expected="$2" input="$3"
  shift 3
  local out err
  out="$(mktemp)"
  err="$(mktemp)"
  if printf '%s\n' "$input" | "$@" >"$out" 2>"$err"; then
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

assert_stdin_nonempty_contains \
  "main-ui default selector" \
  "1. 全体サマリ" \
  "snapshot" \
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

assert_nonempty_contains \
  "add-ui preflight" \
  "OK add-ui preflight passed" \
  tools/add-ui.sh --base data --check

if tools/main-ui.sh --help >/dev/null; then
  pass "main-ui help works"
else
  fail "main-ui help failed"
fi

bad_out="$(mktemp)"
bad_err="$(mktemp)"
if tools/main-ui.sh --base /definitely/missing/base report >"$bad_out" 2>"$bad_err"; then
  fail "main-ui missing base report unexpectedly succeeded"
else
  if [[ -s "$bad_err" ]]; then
    pass "main-ui missing base report reports visible error"
  else
    fail "main-ui missing base report failed silently"
  fi
fi
rm -f "$bad_out" "$bad_err"

bad_out="$(mktemp)"
bad_err="$(mktemp)"
if tools/add-ui.sh --base /definitely/missing/base --check >"$bad_out" 2>"$bad_err"; then
  fail "add-ui missing base unexpectedly succeeded"
else
  if [[ -s "$bad_err" ]]; then
    pass "add-ui missing base reports visible error"
  else
    fail "add-ui missing base failed silently"
  fi
fi
rm -f "$bad_out" "$bad_err"

# Verify --list-sections produces the expected keys (catches section drift)
list_sections_out="$(mktemp)"
if tools/report "$fixture" --list-sections --no-color >"$list_sections_out" 2>/dev/null; then
  required_keys=(snapshot ytd balances cycle trial-balance envelopes planned recent check outlook daily-trend actual-comparison debug)
  for rk in "${required_keys[@]}"; do
    if awk -F'\t' -v k="$rk" '$1 == k { found=1; exit } END { exit !found }' "$list_sections_out"; then
      pass "report --list-sections key: $rk"
    else
      fail "report --list-sections missing key: $rk"
    fi
  done

  declared_count=$(awk -F'\t' 'NF>=2 && $1!="" {n++} END {print n+0}' "$list_sections_out")
  if [[ "$declared_count" -ge 13 ]]; then
    pass "report --list-sections returns $declared_count sections"
  else
    fail "report --list-sections returned only $declared_count sections (expected >=13)"
  fi

  while IFS=$'\t' read -r key marker; do
    [[ -z "$key" ]] && continue
    if [[ -z "$marker" ]]; then
      fail "report --list-sections empty marker for key: $key"
    fi
  done < "$list_sections_out"
else
  fail "report --list-sections failed"
fi
rm -f "$list_sections_out"

if [[ "$failures" -eq 0 ]]; then
  echo "OK: UI smoke checks passed" >&2
  exit 0
else
  echo "FAILED: $failures UI smoke check(s) failed" >&2
  exit 1
fi
