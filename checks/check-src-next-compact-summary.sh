#!/usr/bin/env bash
set -euo pipefail

# check-src-next-compact-summary.sh
# Verify that tools/report-next-summary produces a clean compact output:
# - Contains SrcNext Snapshot, Minimal Report Summary, TBDS, and compact report sections
# - Does NOT contain verbose diagnostic sections
# - tools/report-next (full) behavior is unchanged (smoke test)
#
# This is a validation surface for the next ledger engine candidate.
# Production remains bqn main.bqn until default switch.

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

output="$(mktemp)"
full_output="$(mktemp)"
trap 'rm -f "$output" "$full_output"' EXIT

failures=0

fail() {
  echo "FAIL: $*" >&2
  failures=$((failures + 1))
}

pass() {
  echo "PASS: $*" >&2
}

# ── 1. Compact output contains compact report sections ────────

tools/report-next-summary "$fixture" 2>/dev/null > "$output"

if grep -qF -- 'SrcNext Snapshot' "$output"; then
  pass "compact output contains SrcNext Snapshot"
else
  fail "compact output missing SrcNext Snapshot"
fi

if grep -qF -- 'SrcNext Minimal Report Summary' "$output"; then
  pass "compact output contains Minimal Report Summary"
else
  fail "compact output missing Minimal Report Summary"
fi

if grep -qF -- 'SrcNext TBDS' "$output"; then
  pass "compact output contains SrcNext TBDS"
else
  fail "compact output missing SrcNext TBDS"
fi

if grep -qF -- 'SrcNext Cycle Summary' "$output"; then
  pass "compact output contains SrcNext Cycle Summary"
else
  fail "compact output missing SrcNext Cycle Summary"
fi

if grep -qF -- 'SrcNext YTD Summary' "$output"; then
  pass "compact output contains SrcNext YTD Summary"
else
  fail "compact output missing SrcNext YTD Summary"
fi

if grep -qF -- 'SrcNext Cycle Expense Breakdown' "$output"; then
  pass "compact output contains SrcNext Cycle Expense Breakdown"
else
  fail "compact output missing SrcNext Cycle Expense Breakdown"
fi

if grep -qF -- 'SrcNext Recent Journal' "$output"; then
  pass "compact output contains SrcNext Recent Journal"
else
  fail "compact output missing SrcNext Recent Journal"
fi

if grep -qF -- 'SrcNext Planned Payments' "$output"; then
  pass "compact output contains SrcNext Planned Payments"
else
  fail "compact output missing SrcNext Planned Payments"
fi

if grep -qF -- 'SrcNext Balances' "$output"; then
  pass "compact output contains SrcNext Balances"
else
  fail "compact output missing SrcNext Balances"
fi

if grep -qF -- 'SrcNext Readiness Check' "$output"; then
  pass "compact output contains SrcNext Readiness Check"
else
  fail "compact output missing SrcNext Readiness Check"
fi

if grep -qF -- 'SrcNext Actual Comparison' "$output"; then
  pass "compact output contains SrcNext Actual Comparison"
else
  fail "compact output missing SrcNext Actual Comparison"
fi

if grep -qF -- 'SrcNext Household Metadata' "$output"; then
  pass "compact output contains SrcNext Household Metadata"
else
  fail "compact output missing SrcNext Household Metadata"
fi

if grep -qF -- 'SrcNext Plan Journal Overlap' "$output"; then
  pass "compact output contains SrcNext Plan Journal Overlap"
else
  fail "compact output missing SrcNext Plan Journal Overlap"
fi

if grep -qF -- 'SrcNext Envelope Computation' "$output"; then
  pass "compact output contains SrcNext Envelope Computation"
else
  fail "compact output missing SrcNext Envelope Computation"
fi

if grep -qF -- 'SrcNext Outlook' "$output"; then
  pass "compact output contains SrcNext Outlook"
else
  fail "compact output missing SrcNext Outlook"
fi

if grep -qF -- 'SrcNext Daily Trend' "$output"; then
  pass "compact output contains SrcNext Daily Trend"
else
  fail "compact output missing SrcNext Daily Trend"
fi

# ── 2. Compact output does NOT contain verbose sections ─────

for banned in 'AccountKey Table' 'Projection Row Structure' 'Sample Projection Rows' 'Cube Numeric Verification' 'safe_remaining' 'daily_amount'; do
  if grep -qF -- "$banned" "$output"; then
    fail "compact output contains banned section: '$banned'"
  else
    pass "compact output excludes: $banned"
  fi
done

# ── 3. Compact output contains expected snapshot and summary fields ──

for field in as_of cycle next_income remaining_days status; do
  if grep -q "^${field}:" "$output"; then
    pass "compact output contains snapshot field: $field"
  else
    fail "compact output missing snapshot field: $field"
  fi
done

for text in 'daily_remaining:   fallback/current-engine' 'food_remaining:    fallback/current-engine' \
            'flex_remaining:    fallback/current-engine' 'reserve_remaining: fallback/current-engine' \
            'snapshot_base: src_next/tbds' 'balances: src_next/tbds' \
            'net_worth: src_next/tbds' \
            'envelopes: fallback/current-engine' 'outlook_daily: fallback/current-engine'; do
  if grep -qF -- "$text" "$output"; then
    pass "compact output contains snapshot text: $text"
  else
    fail "compact output missing snapshot text: $text"
  fi
done

for field in src_next_cycle_range src_next_valid_projection_rows src_next_skipped_projection_rows \
             src_next_actual_total src_next_plan_total \
             src_next_actual_expense_total src_next_plan_expense_total \
             src_next_tbds_rows src_next_tbds_row \
             src_next_cycle_start src_next_cycle_end_exclusive src_next_cycle_day_count \
             src_next_cycle_income_actual src_next_cycle_expense_actual \
             src_next_cycle_net_actual src_next_cycle_plan_expense \
             src_next_cycle_plan_expense_remaining \
             src_next_ytd_range src_next_ytd_income_actual src_next_ytd_expense_actual src_next_ytd_net_actual \
             src_next_cycle_expense_breakdown_total src_next_cycle_expense_breakdown \
             src_next_recent_journal src_next_planned_payment src_next_balance \
             src_next_readiness_valid_projection_rows src_next_readiness_skipped_projection_rows \
             src_next_readiness_unknown_account_count src_next_readiness_out_of_cycle_skipped_count \
             src_next_readiness_skipped_invalid src_next_readiness_skipped_out_of_period \
             src_next_actual_comparison_status src_next_actual_comparison_reason \
             src_next_plan_rows_checked src_next_journal_rows_checked \
             src_next_plan_journal_strong_overlap_count \
             src_next_plan_journal_ambiguous_overlap_count \
             src_next_plan_journal_unmatched_plan_count \
             src_next_envelope_target_id src_next_envelope_label src_next_envelope_selector \
             src_next_envelope_allocated src_next_envelope_actual_spent \
             src_next_envelope_remaining src_next_envelope_status \
             src_next_envelope_unassigned_remaining src_next_envelope_unassigned_status \
             src_next_envelope_unassigned_account_count \
             src_next_envelope_funding_base src_next_envelope_allocated_total \
             src_next_envelope_cash_backed_unassigned src_next_envelope_ledger_cash_delta \
             src_next_envelope_backing_status \
             src_next_envelope_execution_planned_envelope \
             src_next_envelope_execution_planned_remaining \
             src_next_envelope_execution_planned_open_total \
             src_next_envelope_execution_planned_delta \
             src_next_envelope_execution_planned_status \
             src_next_household_metadata_expense_accounts_total \
             src_next_household_metadata_missing_budget_count \
             src_next_household_metadata_missing_budget_group_count \
             src_next_household_metadata_missing_spend_class_count \
             src_next_outlook_as_of src_next_outlook_days_left \
             src_next_outlook_liq_total src_next_outlook_liq_daily \
             src_next_outlook_liq_safe_daily \
             src_next_daily_trend; do
  if grep -q "^${field}:" "$output"; then
    pass "compact output contains field: $field"
  else
    fail "compact output missing field: $field"
  fi
done

# ── 4. Full diagnostic output is unchanged (smoke test) ─────

tools/report-next "$fixture" 2>/dev/null > "$full_output"

full_sections=('AccountKey Table' 'Projection Row Structure' 'Sample Projection Rows' 'SrcNext Minimal Report Summary' 'Cube Numeric Verification')
for section in "${full_sections[@]}"; do
  if grep -qF -- "$section" "$full_output"; then
    pass "full output contains: $section"
  else
    fail "full output missing expected section: $section"
  fi
done

# ── 5. Compact output remains a readable opt-in surface ─────

compact_lines=$(wc -l < "$output" | tr -d ' ')
if [ "$compact_lines" -gt 0 ]; then
  pass "compact output is non-empty ($compact_lines lines)"
else
  fail "compact output is empty"
fi

# ── Report ──────────────────────────────────────────────────

if [ "$failures" -eq 0 ]; then
  echo "OK: all compact summary checks passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures check(s) failed for fixture: $fixture" >&2
  exit 1
fi
