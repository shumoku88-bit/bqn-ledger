#!/usr/bin/env bash
set -euo pipefail

# Verify compact SrcNext Cycle Expense Breakdown format and internal total.
# Fixture-only by default; no private production amounts are baked in.

fixtures=("${@:-}")
if [ "$#" -eq 0 ]; then
  fixtures=(
    fixtures/src-next-golden
    fixtures/src-next-income-anchor-golden
    fixtures/src-next-expense-role-metadata
    fixtures/src-next-household-mapping-policy
    fixtures/src-next-empty-projection
    fixtures/src-next-missing-plan
  )
fi

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }
pass() { echo "PASS: $*"; }

for fixture in "${fixtures[@]}"; do
  if [ ! -d "$fixture" ]; then
    fail "fixture directory not found: $fixture"
    continue
  fi

  out="$(mktemp)"
  err="$(mktemp)"
  if ! tools/report-next-summary "$fixture" > "$out" 2> "$err"; then
    fail "$fixture: tools/report-next-summary failed"
    sed 's/^/  /' "$err" >&2
    rm -f "$out" "$err"
    continue
  fi

  if grep -qF -- '--- SrcNext Cycle Expense Breakdown ---' "$out"; then
    pass "$fixture: expense breakdown section found"
  else
    fail "$fixture: expense breakdown section missing"
  fi

  actual="$(awk -F': ' '$1 == "src_next_cycle_expense_actual" { print $2; exit }' "$out")"
  total="$(awk -F': ' '$1 == "src_next_cycle_expense_breakdown_total" { print $2; exit }' "$out")"
  if [[ ! "$actual" =~ ^(-|¯)?[0-9]+$ ]]; then
    fail "$fixture: src_next_cycle_expense_actual is not an integer: '$actual'"
  fi
  if [[ ! "$total" =~ ^(-|¯)?[0-9]+$ ]]; then
    fail "$fixture: src_next_cycle_expense_breakdown_total is not an integer: '$total'"
  fi
  if [ -n "$actual" ] && [ -n "$total" ] && [ "$actual" = "$total" ]; then
    pass "$fixture: breakdown total matches cycle expense actual ($total)"
  else
    fail "$fixture: breakdown total mismatch: total=$total actual=$actual"
  fi

  awk '
    /^src_next_cycle_expense_breakdown: / {
      rest=$0
      sub(/^src_next_cycle_expense_breakdown: /, "", rest)
      n=split(rest, parts, " ")
      if (n < 2) {
        printf("malformed breakdown line: %s\n", $0) > "/dev/stderr"
        bad=1
      } else if (parts[n] !~ /^(-|¯)?[0-9]+$/) {
        printf("breakdown amount is not integer: %s\n", $0) > "/dev/stderr"
        bad=1
      }
    }
    END { exit bad ? 1 : 0 }
  ' "$out" || fail "$fixture: malformed expense breakdown detail line"

  rm -f "$out" "$err"
done

if [ "$failures" -eq 0 ]; then
  echo "OK: all src_next expense breakdown checks passed" >&2
  exit 0
else
  echo "FAILED: $failures src_next expense breakdown check(s) failed" >&2
  exit 1
fi
