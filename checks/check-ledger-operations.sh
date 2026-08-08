#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-operations.XXXXXX")
trap 'rm -rf "$work"' EXIT

Fail() {
  local label=$1
  echo "FAIL: $label" >&2
  echo "::error file=checks/check-ledger-operations.sh::$label" >&2
  exit 1
}
Compare() {
  local label=$1 actual=$2 expected=$3
  cmp "$actual" "$expected" || {
    diff -u "$expected" "$actual" >&2 || true
    Fail "$label"
  }
}

# Retained CLI coordinates are request-shape shells only until Phase 6.
./tools/ledger-check "$fixture" bad/journal bad/plan.tsv bad/budget_alloc.tsv bad/cycle.tsv \
  issues.destination.tsv bad/daily_target_scope.tsv >"$work/check" || Fail 'canonical ledger-check failed'
Compare 'canonical ledger-check output mismatch' "$work/check" "$fixture/ledger_check.destination.txt"
./tools/ledger-inspect "$fixture" bad/journal >"$work/inspect" || Fail 'canonical ledger-inspect failed'
Compare 'canonical ledger-inspect output mismatch' "$work/inspect" "$fixture/ledger_inspect.destination.txt"

cp -R "$fixture" "$work/invalid"
printf 'bad\theader\n' >"$work/invalid/issues-invalid.tsv"
if ./tools/ledger-check "$work/invalid" bad/journal bad/plan.tsv bad/budget_alloc.tsv bad/cycle.tsv \
  issues-invalid.tsv bad/daily_target_scope.tsv >"$work/invalid.out" 2>&1; then
  Fail 'ledger-check accepted invalid Issues'
fi
grep -F 'issue_header_invalid' "$work/invalid.out" >/dev/null || Fail 'invalid Issues diagnostic missing'
! grep -F $'ledger_check\tstate\tok' "$work/invalid.out" >/dev/null || Fail 'invalid Issues published ok state'

# A path-shaped Journal coordinate cannot redirect canonical Actual inspection.
./tools/ledger-inspect "$work/invalid" missing.journal >"$work/ignored-journal-coordinate" || Fail 'ignored Journal coordinate changed inspect success'
Compare 'ignored Journal coordinate redirected inspect output' "$work/ignored-journal-coordinate" "$fixture/ledger_inspect.destination.txt"

if bqn src/application/report_selection_cli.bqn all human | grep -Eq '^(check|debug)$'; then
  Fail 'operational command leaked into report catalog'
fi
if rg -n 'src/sections|src_next|report_destination_cli' \
  src/application/ledger_check_cli.bqn src/application/ledger_inspect_cli.bqn tools/ledger-check tools/ledger-inspect >/dev/null; then
  Fail 'operational command imports report/runtime owner'
fi

echo 'check-ledger-operations: OK'
