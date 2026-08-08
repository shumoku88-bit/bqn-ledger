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

run_report balances balances json JPY 2026-01-15
run_report balance-sheet balance-sheet human JPY 2026-01-15
run_report profit-and-loss profit-and-loss human JPY 2026-01-01 2026-02-01
run_report recent recent compact 2026-01-15 3
run_report monthly-accounts monthly-accounts human JPY 2026-01 2026-02

set +e
rejected="$(tools/report "$base" balances json JPY 2026-01-15 actual.journal 2>&1)"
rc=$?
set -e
[[ $rc -ne 0 ]]
grep -Fq $'ERROR\tusage_balances\t' <<<"$rejected"

echo "check-canonical-actual-reports: OK"
