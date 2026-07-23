#!/usr/bin/env bash
set -euo pipefail

fixture="${1:-fixtures/src-next-golden}"
update=0
if [ "$fixture" = "--update" ]; then
  update=1
  fixture="${2:-fixtures/src-next-golden}"
fi

expected="$fixture/expected/src_next_summary.txt"
actual_raw="$(mktemp)"
actual_summary="$(mktemp)"
trap 'rm -f "$actual_raw" "$actual_summary"' EXIT

bqn src_next/main.bqn "$fixture" > "$actual_raw"

grep -E '^(mode:|start:|end_exclusive:|day_count:|accounts:|"source_file"|"actual.journal"|"plan.tsv"|projection_balance_by_source:|shape:|valid projection rows:|skipped projection rows:|  day_index|  actual:|  plan:|  budget:|  forecast:|  [0-9]+  |  status:|src_next_cycle_range:|src_next_valid_projection_rows:|src_next_skipped_projection_rows:|src_next_actual_total:|src_next_plan_total:|src_next_actual_expense_total:|src_next_plan_expense_total:|src_next_actual_account_total:|src_next_plan_account_total:|src_next_household_policy_|src_next_household_metadata_|valid_actual_delta_total:|cube_actual_total:|actual_total_match:|valid_plan_delta_total:|cube_plan_total:|plan_total_match:|actual_per_account_totals_match:)' "$actual_raw" > "$actual_summary"

if [ "$update" -eq 1 ]; then
  cp "$actual_summary" "$expected"
  echo "Updated $expected"
  exit 0
fi

diff -u "$expected" "$actual_summary"
