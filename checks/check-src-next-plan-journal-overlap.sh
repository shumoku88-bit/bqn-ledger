#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Plan Journal Overlap format and field presence.

fixtures=("${@:-}")
if [ "$#" -eq 0 ]; then
  fixtures=(
    fixtures/src-next-golden
    fixtures/src-next-plan-overlap
    fixtures/src-next-missing-plan
    fixtures/src-next-empty-projection
    fixtures/src-next-out-of-cycle-journal
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

  if grep -qF -- '--- SrcNext Plan Journal Overlap ---' "$out"; then
    pass "$fixture: Plan Journal Overlap section found"
  else
    fail "$fixture: Plan Journal Overlap section missing"
  fi

  for field in \
    src_next_plan_rows_checked \
    src_next_journal_rows_checked \
    src_next_plan_journal_strong_overlap_count \
    src_next_plan_journal_ambiguous_overlap_count \
    src_next_plan_journal_unmatched_plan_count; do
    val="$(value "$field" "$out")"
    if is_int "$val"; then
      pass "$fixture: $field is integer ($val)"
    else
      fail "$fixture: $field missing or not integer: '$val'"
    fi
  done

  # strong_overlap_count + unmatched_plan_count <= plan_rows_checked
  plan_checked="$(value src_next_plan_rows_checked "$out")"
  strong="$(value src_next_plan_journal_strong_overlap_count "$out")"
  ambiguous="$(value src_next_plan_journal_ambiguous_overlap_count "$out")"
  unmatched="$(value src_next_plan_journal_unmatched_plan_count "$out")"

  if (( strong + ambiguous + unmatched <= plan_checked )); then
    pass "$fixture: strong($strong) + ambiguous($ambiguous) + unmatched($unmatched) <= plan_rows_checked($plan_checked)"
  else
    fail "$fixture: strong($strong) + ambiguous($ambiguous) + unmatched($unmatched) > plan_rows_checked($plan_checked)"
  fi

  # If strong_overlap_count > 0, should have strong_overlap_key lines
  if (( strong > 0 )); then
    key_count=$(grep -c '^src_next_plan_journal_strong_overlap_key:' "$out" || true)
    if (( key_count == strong )); then
      pass "$fixture: strong_overlap_key count ($key_count) matches strong_overlap_count ($strong)"
    else
      fail "$fixture: strong_overlap_key count ($key_count) != strong_overlap_count ($strong)"
    fi
  fi

  rm -f "$out"
done

if [ "$failures" -eq 0 ]; then
  echo "OK: all src_next Plan Journal Overlap checks passed" >&2
  exit 0
else
  echo "FAILED: $failures Plan Journal Overlap check(s) failed" >&2
  exit 1
fi
