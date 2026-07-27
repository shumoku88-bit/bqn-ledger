#!/usr/bin/env bash
set -euo pipefail

# Regression check: YTD section on unavailable-cycle fixture must not crash.
#
# Contract: when cycle.tsv has an unresolvable mode (e.g. "monthly"),
# cycle.bqn resolves start/end_exclusive to "unavailable".
# ytd_summary.Build must detect the sentinel and return an unavailable
# summary rather than passing "unavailable" to date arithmetic.
#
# Three execution paths are verified:
#   1. --section ytd (direct single-section render)
#   2. full human report (all sections)
#   3. --write-section-cache (cache population)
#
# The valid-cycle zero-actual case is also verified to confirm that numeric
# zeros (not "unavailable") are returned when the cycle is well-formed but
# the journal has no actual transactions.

export NO_COLOR=1

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

# ── fixtures ──────────────────────────────────────────────────────────────────
UNAVAIL_FIXTURE="fixtures/envelopes-disabled-policy"  # mode=monthly → unavailable
ZERO_FIXTURE="fixtures/empty-journal"                  # mode=fixed, 0 actual rows

if [ ! -d "$UNAVAIL_FIXTURE" ]; then
  echo "ERROR: fixture not found: $UNAVAIL_FIXTURE" >&2; exit 2
fi
if [ ! -d "$ZERO_FIXTURE" ]; then
  echo "ERROR: fixture not found: $ZERO_FIXTURE" >&2; exit 2
fi

# ── 1. --section ytd: no crash, exits 0, output contains "unavailable" ───────
section_out="$(mktemp)"
section_err="$(mktemp)"

if ! tools/report "$UNAVAIL_FIXTURE" --section ytd >"$section_out" 2>"$section_err"; then
  fail "unavailable-cycle: --section ytd exited non-zero"
  sed 's/^/  /' "$section_err" >&2
else
  if grep -qF "unavailable" "$section_out"; then
    pass "unavailable-cycle: --section ytd output contains 'unavailable'"
  else
    fail "unavailable-cycle: --section ytd output missing 'unavailable'"
    cat "$section_out" >&2
  fi
  # Must NOT contain a BQN error marker
  if grep -qE "Error:|out-of-bounds" "$section_err"; then
    fail "unavailable-cycle: --section ytd stderr contains BQN error"
    cat "$section_err" >&2
  else
    pass "unavailable-cycle: --section ytd stderr clean"
  fi
fi
rm -f "$section_out" "$section_err"

# ── 2. Full human report: no crash, exits 0 ───────────────────────────────────
full_out="$(mktemp)"
full_err="$(mktemp)"

if ! tools/report "$UNAVAIL_FIXTURE" >"$full_out" 2>"$full_err"; then
  fail "unavailable-cycle: full report exited non-zero"
  sed 's/^/  /' "$full_err" >&2
else
  pass "unavailable-cycle: full report exited 0"
fi
rm -f "$full_out" "$full_err"

# ── 3. --write-section-cache: exits 0, cache/ytd.txt exists and matches ───────
cache_dir="$(mktemp -d)"
cache_err="$(mktemp)"

if ! tools/report "$UNAVAIL_FIXTURE" --write-section-cache "$cache_dir" 2>"$cache_err"; then
  fail "unavailable-cycle: --write-section-cache exited non-zero"
  sed 's/^/  /' "$cache_err" >&2
else
  if [ -f "$cache_dir/ytd.txt" ]; then
    pass "unavailable-cycle: cache/ytd.txt created"

    # Byte-exact: cache content + "\n\n" == --section ytd stdout
    section_bytes="$(mktemp)"
    tools/report "$UNAVAIL_FIXTURE" --section ytd >"$section_bytes" 2>/dev/null
    expected_bytes="$(cat "$cache_dir/ytd.txt"; printf '\n\n')"
    actual_bytes="$(cat "$section_bytes")"
    if [ "$expected_bytes" = "$actual_bytes" ]; then
      pass "unavailable-cycle: cache/ytd.txt byte-exact match"
    else
      fail "unavailable-cycle: cache/ytd.txt byte-exact mismatch"
    fi
    rm -f "$section_bytes"
  else
    fail "unavailable-cycle: cache/ytd.txt not created"
  fi
fi
rm -rf "$cache_dir" "$cache_err"

# ── 4. Valid-cycle zero-actual: section ytd exits 0, no "unavailable" ─────────
zero_out="$(mktemp)"
zero_err="$(mktemp)"

if ! tools/report "$ZERO_FIXTURE" --section ytd >"$zero_out" 2>"$zero_err"; then
  fail "zero-actual: --section ytd exited non-zero"
  sed 's/^/  /' "$zero_err" >&2
else
  if grep -qF "unavailable" "$zero_out"; then
    fail "zero-actual: --section ytd output contains 'unavailable' (should be numeric zeros)"
    cat "$zero_out" >&2
  else
    pass "zero-actual: --section ytd output free of 'unavailable' sentinel"
  fi
fi
rm -f "$zero_out" "$zero_err"

# ── result ────────────────────────────────────────────────────────────────────
if [ "$failures" -eq 0 ]; then
  echo "OK: all ytd unavailable-cycle regression checks passed" >&2
  exit 0
else
  echo "FAILED: $failures ytd unavailable-cycle check(s) failed" >&2
  exit 1
fi
