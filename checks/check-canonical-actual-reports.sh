#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
base=fixtures/canonical-household-v1

[[ -f $base/accounts.journal && -f $base/actual.journal ]]
[[ ! -e $base/accounts.tsv ]]

run_report() {
  local label=$1
  shift
  local output
  output="$(tools/report "$base" "$@")"
  [[ -n $output ]] || { echo "FAIL: $label produced empty output" >&2; exit 1; }
}

run_report balances balances json JPY 2026-01-15 actual.journal
run_report balance-sheet balance-sheet human JPY 2026-01-15 actual.journal
run_report profit-and-loss profit-and-loss human JPY 2026-01-01 2026-02-01 actual.journal
run_report recent recent compact 3 actual.journal
run_report monthly-accounts monthly-accounts human JPY 2026-01 2026-02 actual.journal
run_report daily-flow daily-flow human JPY 2026-01-01 2026-02-01 2026-01-15 actual.journal

set +e
rejected="$(tools/report "$base" balances json JPY 2026-01-15 legacy.journal 2>&1)"
rc=$?
set -e
[[ $rc -ne 0 ]]
grep -Fq $'ERROR\tactual_source_not_canonical\t' <<<"$rejected"

echo "check-canonical-actual-reports: OK"
