#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-operations.XXXXXX")
trap 'rm -rf "$work"' EXIT

./tools/ledger-check "$fixture" actual.journal plan.tsv budget_alloc.tsv cycle.tsv \
  issues.destination.tsv daily_target_scope.destination.tsv >"$work/check"
cmp "$work/check" "$fixture/ledger_check.destination.txt"
./tools/ledger-inspect "$fixture" actual.journal >"$work/inspect"
cmp "$work/inspect" "$fixture/ledger_inspect.destination.txt"

cp -R "$fixture" "$work/invalid"
printf 'bad\theader\n' >"$work/invalid/issues-invalid.tsv"
if ./tools/ledger-check "$work/invalid" actual.journal plan.tsv budget_alloc.tsv cycle.tsv \
  issues-invalid.tsv daily_target_scope.destination.tsv >"$work/invalid.out" 2>&1; then
  echo 'FAIL: ledger-check accepted invalid Issues' >&2; exit 1
fi
grep -F 'issue_header_invalid' "$work/invalid.out" >/dev/null
! grep -F $'ledger_check\tstate\tok' "$work/invalid.out" >/dev/null
if ./tools/ledger-inspect "$work/invalid" missing.journal >"$work/missing.out" 2>&1; then
  echo 'FAIL: ledger-inspect accepted missing Journal' >&2; exit 1
fi
grep -F 'source_unreadable' "$work/missing.out" >/dev/null

if bqn src/application/report_selection_cli.bqn all human | grep -Eq '^(check|debug)$'; then
  echo 'FAIL: operational command leaked into report catalog' >&2; exit 1
fi
if rg -n 'src/sections|src_next|report_destination_cli' \
  src/application/ledger_check_cli.bqn src/application/ledger_inspect_cli.bqn tools/ledger-check tools/ledger-inspect >/dev/null; then
  echo 'FAIL: operational command imports report/runtime owner' >&2; exit 1
fi

echo 'check-ledger-operations: OK'
