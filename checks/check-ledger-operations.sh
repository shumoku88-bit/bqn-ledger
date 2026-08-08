#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-operations.XXXXXX")
trap 'rm -rf "$work"' EXIT

# Retained CLI coordinates are request-shape shells only until Phase 6.
./tools/ledger-check "$fixture" bad/journal bad/plan.tsv bad/budget_alloc.tsv bad/cycle.tsv \
  issues.destination.tsv bad/daily_target_scope.tsv >"$work/check"
cmp "$work/check" "$fixture/ledger_check.destination.txt"
./tools/ledger-inspect "$fixture" bad/journal >"$work/inspect"
cmp "$work/inspect" "$fixture/ledger_inspect.destination.txt"

cp -R "$fixture" "$work/invalid"
printf 'bad\theader\n' >"$work/invalid/issues-invalid.tsv"
if ./tools/ledger-check "$work/invalid" bad/journal bad/plan.tsv bad/budget_alloc.tsv bad/cycle.tsv \
  issues-invalid.tsv bad/daily_target_scope.tsv >"$work/invalid.out" 2>&1; then
  echo 'FAIL: ledger-check accepted invalid Issues' >&2; exit 1
fi
grep -F 'issue_header_invalid' "$work/invalid.out" >/dev/null
! grep -F $'ledger_check\tstate\tok' "$work/invalid.out" >/dev/null

# A path-shaped Journal coordinate cannot redirect canonical Actual inspection.
./tools/ledger-inspect "$work/invalid" missing.journal >"$work/ignored-journal-coordinate"
cmp "$work/ignored-journal-coordinate" "$fixture/ledger_inspect.destination.txt"

if bqn src/application/report_selection_cli.bqn all human | grep -Eq '^(check|debug)$'; then
  echo 'FAIL: operational command leaked into report catalog' >&2; exit 1
fi
if rg -n 'src/sections|src_next|report_destination_cli' \
  src/application/ledger_check_cli.bqn src/application/ledger_inspect_cli.bqn tools/ledger-check tools/ledger-inspect >/dev/null; then
  echo 'FAIL: operational command imports report/runtime owner' >&2; exit 1
fi

echo 'check-ledger-operations: OK'
