#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

./tools/report-destination "$fixture" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv assets:cash >"$tmp/envelopes"
cmp "$tmp/envelopes" "$fixture/envelope_backing.destination.compact.txt"
./tools/report-destination "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"
./tools/report-destination "$fixture" recent compact 10 actual.journal >"$tmp/recent"
cmp "$tmp/recent" "$fixture/recent_journal.destination.compact.txt"
./tools/report-destination "$fixture" planned human 2026-01-12 actual.journal plan.tsv cycle.tsv >"$tmp/planned"
cmp "$tmp/planned" "$fixture/planned_payments.destination.human.txt"
./tools/report-destination "$fixture" cycle-accounts human JPY 2026-01-10 actual.journal cycle.tsv >"$tmp/cycle"
cmp "$tmp/cycle" "$fixture/cycle_accounts.destination.human.txt"
./tools/report-destination "$fixture" cycle-comparison human JPY 2026-01-10 2025-12-31 aligned_elapsed actual.journal cycle.tsv cycle_baseline.destination.tsv >"$tmp/comparison"
cmp "$tmp/comparison" "$fixture/cycle_comparison.destination.human.txt"
./tools/report-destination "$fixture" monthly-accounts human JPY 2026-01 2026-03 actual.journal >"$tmp/monthly"
cmp "$tmp/monthly" "$fixture/monthly_accounts.destination.human.txt"
./tools/report-destination "$fixture" daily-target human JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >"$tmp/daily-target"
cmp "$tmp/daily-target" "$fixture/daily_target.application.human.txt"
./tools/report-destination "$fixture" issues human issues.destination.tsv >"$tmp/issues"
cmp "$tmp/issues" "$fixture/issues.destination.human.txt"

mkdir "$tmp/actual-only" "$tmp/issues-only" "$tmp/cycle-only" "$tmp/planned-only" \
  "$tmp/income-cycle" "$tmp/envelope-only" "$tmp/daily-only"
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$tmp/actual-only/"
cp "$fixture/issues.destination.tsv" "$tmp/issues-only/"
./tools/report-destination "$tmp/actual-only" recent human 2 actual.journal >/dev/null
./tools/report-destination "$tmp/issues-only" issues human issues.destination.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/cycle.tsv" "$tmp/cycle-only/"
./tools/report-destination "$tmp/cycle-only" cycle-accounts human JPY 2026-01-10 actual.journal cycle.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" \
  "$fixture/daily_target_plan.destination.tsv" "$fixture/daily_target_scope.destination.tsv" "$tmp/daily-only/"
./tools/report-destination "$tmp/daily-only" daily-target human JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/plan.tsv" "$fixture/budget_alloc.tsv" "$tmp/envelope-only/"
./tools/report-destination "$tmp/envelope-only" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv assets:cash >/dev/null
if ./tools/report-destination "$tmp/envelope-only" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv expenses:food \
  >"$tmp/funding-role" 2>&1; then
  echo 'FAIL: non-asset funding Account succeeded' >&2; exit 1
fi
grep -F $'funding_account_role_invalid' "$tmp/funding-role" >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/plan.tsv" "$fixture/cycle.tsv" "$tmp/planned-only/"
./tools/report-destination "$tmp/planned-only" planned human 2026-01-12 actual.journal plan.tsv cycle.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$tmp/income-cycle/"
printf '%s\n' $'mode\tincomeAnchor' $'income_account\tincome:salary' $'offset\t0' >"$tmp/income-cycle/cycle.tsv"
printf '%s\n' $'2026-02-01\tnext-income\tincome:salary\tassets:cash\t1000\tcurrency=JPY\tplan_id=income-next' >"$tmp/income-cycle/plan.tsv"
./tools/report-destination "$tmp/income-cycle" cycle-accounts human JPY 2026-01-12 actual.journal cycle.tsv plan.tsv >/dev/null
if ./tools/report-destination "$tmp/income-cycle" cycle-accounts human JPY 2026-01-12 actual.journal cycle.tsv >"$tmp/plan-required" 2>&1; then
  echo 'FAIL: incomeAnchor succeeded without Plan' >&2; exit 1
fi
grep -F $'plan_required' "$tmp/plan-required" >/dev/null

if ./tools/report-destination "$tmp/not-present" snapshot human >"$tmp/unknown" 2>&1; then
  echo 'FAIL: unknown key succeeded' >&2; exit 1
fi
grep -F $'report_key_unknown' "$tmp/unknown" >/dev/null
if ./tools/report-destination "$tmp/not-present" issues json issues.destination.tsv >"$tmp/unsupported" 2>&1; then
  echo 'FAIL: unsupported surface succeeded' >&2; exit 1
fi
grep -F $'report_surface_unsupported' "$tmp/unsupported" >/dev/null

echo 'check-report-destination-composition: OK'
