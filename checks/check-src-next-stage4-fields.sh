#!/usr/bin/env bash
set -euo pipefail

# src_next Stage 4 validation surface — field presence check.
# Old engine deleted; validates src_next output without cross-engine comparison.

fixture="${1:-fixtures/src-next-golden}"
if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi

src_out="$(mktemp)"
trap 'rm -f "$src_out"' EXIT

tools/report-next-summary "$fixture" > "$src_out" 2>/dev/null

src_value() {
  local key="$1"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$src_out"
}

as_of="$(src_value src_next_outlook_as_of)"
if [ -z "$as_of" ]; then
  echo "ERROR: src_next_outlook_as_of missing from $fixture" >&2
  exit 1
fi

fields=(
  src_next_outlook_as_of
  src_next_cycle_start
  src_next_cycle_end_exclusive
  src_next_outlook_days_left
  src_next_cycle_income_actual
  src_next_cycle_expense_actual
  src_next_cycle_net_actual
  src_next_cycle_plan_expense_remaining
  src_next_outlook_liq_total
  src_next_outlook_liq_daily
  src_next_outlook_liq_safe_daily
  src_next_actual_comparison_status
)

failures=0
for field in "${fields[@]}"; do
  val="$(src_value "$field")"
  if [ -z "$val" ]; then
    echo "FAIL: missing field: $field" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -eq 0 ]; then
  echo "OK: src_next Stage 4 field check passed for fixture: $fixture" >&2
  exit 0
else
  echo "FAILED: $failures src_next Stage 4 field(s) missing for fixture: $fixture" >&2
  exit 1
fi
