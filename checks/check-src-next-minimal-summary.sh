#!/usr/bin/env bash
set -euo pipefail

# check-src-next-minimal-summary.sh
# Semantic check for the src_next Minimal Report Summary section.
#
# Verifies field presence, format invariants, and numeric consistency
# WITHOUT baking in specific household amounts. This complements the
# exact golden diff in check-src-next-golden.sh.
#
# Stage 4 daily-trial comparison surface: the Minimal Report Summary is
# now mechanically checkable. Production remains bqn main.bqn.
#
# Usage:
#   bash checks/check-src-next-minimal-summary.sh [fixture-dir]

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

output="$(mktemp)"
trap 'rm -f "$output"' EXIT

bqn src_next/main.bqn "$fixture" > "$output"

# ── Helpers ──────────────────────────────────────────────────

# Extract the value of a single key:value line (first match).
extract() {
  local key="$1"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$output"
}

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $*" >&2
}

# ── 1. Section presence ──────────────────────────────────────

section_label="SrcNext Minimal Report Summary"
if grep -qF -- "$section_label" "$output"; then
  pass "Minimal Report Summary section found"
else
  fail "Minimal Report Summary section NOT found (label: $section_label)"
fi

# ── 2. Cycle range ──────────────────────────────────────────

cycle_range="$(extract src_next_cycle_range)"
if [ -n "$cycle_range" ]; then
  if [[ "$cycle_range" == *".."* ]]; then
    pass "src_next_cycle_range: $cycle_range"
  else
    fail "src_next_cycle_range missing '..' separator: '$cycle_range'"
  fi
else
  fail "src_next_cycle_range empty or missing"
fi

# ── 3. Valid projection rows count ──────────────────────────

valid_rows="$(extract src_next_valid_projection_rows)"
if [ -n "$valid_rows" ]; then
  if [[ "$valid_rows" =~ ^-?[0-9]+$ ]]; then
    pass "src_next_valid_projection_rows: $valid_rows"
  else
    fail "src_next_valid_projection_rows not an integer: '$valid_rows'"
  fi
else
  fail "src_next_valid_projection_rows empty or missing"
fi

# ── 4. Skipped projection rows count ────────────────────────

skipped_rows="$(extract src_next_skipped_projection_rows)"
if [ -n "$skipped_rows" ]; then
  if [[ "$skipped_rows" =~ ^-?[0-9]+$ ]]; then
    pass "src_next_skipped_projection_rows: $skipped_rows"
  else
    fail "src_next_skipped_projection_rows not an integer: '$skipped_rows'"
  fi
else
  fail "src_next_skipped_projection_rows empty or missing"
fi

# ── 5. Signed layer totals ──────────────────────────────────

for field in src_next_actual_total src_next_plan_total; do
  val="$(extract "$field")"
  if [ -n "$val" ]; then
    if [[ "$val" =~ ^-?[0-9]+$ ]]; then
      pass "$field: $val"
    else
      fail "$field not an integer: '$val'"
    fi
  else
    fail "$field empty or missing"
  fi
done

# ── 6. Debit-side expense totals ────────────────────────────

for field in src_next_actual_expense_total src_next_plan_expense_total; do
  val="$(extract "$field")"
  if [ -n "$val" ]; then
    if [[ "$val" =~ ^-?[0-9]+$ ]]; then
      pass "$field: $val"
    else
      fail "$field not an integer: '$val'"
    fi
  else
    fail "$field empty or missing"
  fi
done

# ── 7. Projection balance check ─────────────────────────────

if grep -qF 'projection_balance_by_source: ok' "$output"; then
  pass "projection_balance_by_source: ok"
else
  fail "projection_balance_by_source NOT ok (expected 'projection_balance_by_source: ok')"
fi

# ── 8. Cube numeric verification ────────────────────────────

for check_label in actual_total_match plan_total_match actual_per_account_totals_match; do
  status="$(extract "$check_label")"
  if [ "$status" = "ok" ]; then
    pass "${check_label}: ok"
  else
    if [ -n "$status" ]; then
      fail "${check_label}: expected 'ok', got '$status'"
    else
      fail "${check_label}: missing status line"
    fi
  fi
done

# ── 9. No production readiness claims ────────────────────────

# The Minimal Report Summary is a Stage 4 trial surface only.
# It must not claim production readiness or Stage 5 default switch.
if grep -qiE -- 'production.ready|production.default|default.switch|stage.5|production.replace|replaces.main' "$output"; then
  fail "output contains production readiness language (Stage 4 trial surface only)"
else
  pass "no production readiness claims"
fi

# ── 10. Account total fields have valid format ───────────────

# Each src_next_actual_account_total / src_next_plan_account_total line
# must have format: "label: <index> <account_key> <signed_integer>"
while IFS= read -r line; do
  # Expected: "src_next_actual_account_total: 4 expenses:food/JPY 80"
  rest="${line#src_next_actual_account_total: }"
  if [ "$rest" = "$line" ]; then continue; fi  # not this field
  if [[ "$rest" =~ ^[0-9]+\ .+\ ((-|$'\302\257')?[0-9]+)$ ]]; then
    :
  else
    fail "actual_account_total malformed: '$line'"
  fi
done < "$output"

while IFS= read -r line; do
  rest="${line#src_next_plan_account_total: }"
  if [ "$rest" = "$line" ]; then continue; fi
  if [[ "$rest" =~ ^[0-9]+\ .+\ ((-|$'\302\257')?[0-9]+)$ ]]; then
    :
  else
    fail "plan_account_total malformed: '$line'"
  fi
done < "$output"

# ── Report ──────────────────────────────────────────────────

if [ "$failures" -eq 0 ]; then
  echo "OK: all Minimal Report Summary checks passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures check(s) failed for fixture: $fixture" >&2
  exit 1
fi
