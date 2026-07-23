#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Readiness Check format and basic count consistency.

fixtures=("${@:-}")
if [ "$#" -eq 0 ]; then
  fixtures=(
    fixtures/src-next-golden
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

  if grep -qF -- '--- SrcNext Readiness Check ---' "$out"; then
    pass "$fixture: Readiness Check section found"
  else
    fail "$fixture: Readiness Check section missing"
  fi

  for field in \
    src_next_readiness_valid_projection_rows \
    src_next_readiness_skipped_projection_rows \
    src_next_readiness_skipped_status \
    src_next_readiness_skipped_day_before_start \
    src_next_readiness_skipped_day_after_end \
    src_next_readiness_skipped_account_key_index \
    src_next_readiness_skipped_layer_index \
    src_next_readiness_skipped_unknown \
    src_next_readiness_skipped_invalid \
    src_next_readiness_skipped_out_of_period \
    src_next_readiness_unknown_account_count \
    src_next_readiness_out_of_cycle_skipped_count; do
    val="$(value "$field" "$out")"
    if is_int "$val"; then
      pass "$fixture: $field is integer ($val)"
    else
      fail "$fixture: $field missing or not integer: '$val'"
    fi
  done

  min_valid="$(value src_next_valid_projection_rows "$out")"
  ready_valid="$(value src_next_readiness_valid_projection_rows "$out")"
  min_skipped="$(value src_next_skipped_projection_rows "$out")"
  ready_skipped="$(value src_next_readiness_skipped_projection_rows "$out")"
  if [ "$min_valid" = "$ready_valid" ]; then
    pass "$fixture: valid row count matches Minimal Report Summary ($ready_valid)"
  else
    fail "$fixture: valid row count mismatch: minimal=$min_valid readiness=$ready_valid"
  fi
  if [ "$min_skipped" = "$ready_skipped" ]; then
    pass "$fixture: skipped row count matches Minimal Report Summary ($ready_skipped)"
  else
    fail "$fixture: skipped row count mismatch: minimal=$min_skipped readiness=$ready_skipped"
  fi

  rm -f "$out"
done

if [ "$failures" -eq 0 ]; then
  echo "OK: all src_next Readiness Check checks passed" >&2
  exit 0
else
  echo "FAILED: $failures Readiness Check check(s) failed" >&2
  exit 1
fi
