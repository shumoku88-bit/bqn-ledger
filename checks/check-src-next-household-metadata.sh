#!/usr/bin/env bash
set -euo pipefail

# Verify SrcNext Household Metadata diagnostics format and basic consistency.

fixtures=("${@:-}")
if [ "$#" -eq 0 ]; then
  fixtures=(
    fixtures/src-next-golden
    fixtures/src-next-household-mapping-policy
    fixtures/src-next-empty-projection
    fixtures/src-next-out-of-cycle-journal
    fixtures/src-next-missing-plan
    fixtures/src-next-expense-role-metadata
    fixtures/src-next-income-anchor-golden
  )
fi

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

value() {
  local key="$1" file="$2"
  awk -F': ' -v key="$key" '$1 == key { print $2; exit }' "$file"
}

is_int() { [[ "$1" =~ ^(-|¯)?[0-9]+$ ]]; }

for fixture in "${fixtures[@]}"; do
  if [ ! -d "$fixture" ]; then
    fail "fixture directory not found: $fixture"
    continue
  fi

  out="$(mktemp)"
  tools/report-next-summary "$fixture" > "$out" 2>/dev/null

  if grep -qF -- '--- SrcNext Household Metadata ---' "$out"; then
    pass "$fixture: Household Metadata section found"
  else
    fail "$fixture: Household Metadata section missing"
    rm -f "$out"
    continue
  fi

  for field in \
    src_next_household_metadata_expense_accounts_total \
    src_next_household_metadata_missing_budget_count \
    src_next_household_metadata_missing_budget_group_count \
    src_next_household_metadata_missing_spend_class_count; do
    val="$(value "$field" "$out")"
    if [ -n "$val" ]; then
      pass "$fixture: $field present"
    else
      fail "$fixture: $field missing or empty"
    fi
  done

  # Value fields may legitimately be empty when no metadata exists
  for field in \
    src_next_household_metadata_budget_values \
    src_next_household_metadata_budget_group_values \
    src_next_household_metadata_spend_class_values \
    src_next_household_metadata_missing_budget_accounts \
    src_next_household_metadata_missing_budget_group_accounts \
    src_next_household_metadata_missing_spend_class_accounts; do
    if grep -qE "^${field}: " "$out"; then
      pass "$fixture: $field line present"
    else
      fail "$fixture: $field line missing"
    fi
  done

  # Count fields should be integers
  for field in \
    src_next_household_metadata_expense_accounts_total \
    src_next_household_metadata_missing_budget_count \
    src_next_household_metadata_missing_budget_group_count \
    src_next_household_metadata_missing_spend_class_count; do
    val="$(value "$field" "$out")"
    if is_int "$val"; then
      pass "$fixture: $field is integer ($val)"
    else
      fail "$fixture: $field not integer: '$val'"
    fi
  done

  # Consistency: missing counts ≤ expense total
  total="$(value src_next_household_metadata_expense_accounts_total "$out")"
  missing_b="$(value src_next_household_metadata_missing_budget_count "$out")"
  missing_bg="$(value src_next_household_metadata_missing_budget_group_count "$out")"
  missing_sc="$(value src_next_household_metadata_missing_spend_class_count "$out")"
  if [ "$missing_b" -le "$total" ] 2>/dev/null && \
     [ "$missing_bg" -le "$total" ] 2>/dev/null && \
     [ "$missing_sc" -le "$total" ] 2>/dev/null; then
    pass "$fixture: missing counts ≤ expense total"
  else
    fail "$fixture: missing count exceeds expense total"
  fi

  # Negative validation: prefix fallback count must be 0 for standard fixtures
  fallback_count="$(value src_next_household_metadata_prefix_fallback_total_count "$out")"
  if [ "$fallback_count" -eq 0 ] 2>/dev/null; then
    pass "$fixture: prefix fallback total count is 0"
  else
    fail "$fixture: prefix fallback total count is $fallback_count (expected 0)"
  fi

  # No remaining / envelope claims in the metadata section (extract just that section)
  meta_section="$(awk '/^--- SrcNext Household Metadata ---$/,/^$/' "$out" | head -20)"
  if echo "$meta_section" | grep -qF 'food_remaining' || \
     echo "$meta_section" | grep -qF 'daily_remaining' || \
     echo "$meta_section" | grep -qF 'flex_remaining' || \
     echo "$meta_section" | grep -qF 'reserve_remaining' || \
     echo "$meta_section" | grep -qF 'safe_remaining' || \
     echo "$meta_section" | grep -qF 'envelope_balance'; then
    fail "$fixture: household metadata section contains remaining/envelope claims (should not)"
  else
    pass "$fixture: no remaining/envelope claims in metadata section"
  fi

  rm -f "$out"
done

if [ "$failures" -eq 0 ]; then
  echo "OK: all src_next Household Metadata checks passed" >&2
  exit 0
else
  echo "FAILED: $failures Household Metadata check(s) failed" >&2
  exit 1
fi
