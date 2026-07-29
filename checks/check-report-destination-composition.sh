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
cat "$fixture/envelope_backing.destination.human.txt" "$fixture/account_balances.destination.human.txt" \
  "$fixture/recent_journal.destination.human.txt" "$fixture/planned_payments.destination.human.txt" \
  "$fixture/cycle_accounts.destination.human.txt" "$fixture/cycle_comparison.destination.human.txt" \
  "$fixture/monthly_accounts.destination.human.txt" "$fixture/daily_target.application.human.txt" \
  "$fixture/issues.destination.human.txt" >"$tmp/all-human-expected"
./tools/report-destination "$fixture" all human report_all_human.destination.tsv >"$tmp/all-human"
cmp "$tmp/all-human" "$tmp/all-human-expected"
./tools/report-destination "$fixture" all compact report_all_compact.destination.tsv >"$tmp/all-compact"
: >"$tmp/all-compact-expected"
./tools/report-destination "$fixture" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 \
  actual.journal plan.tsv budget_alloc.tsv assets:cash >>"$tmp/all-compact-expected"
./tools/report-destination "$fixture" balances compact JPY 2026-01-12 actual.journal >>"$tmp/all-compact-expected"
./tools/report-destination "$fixture" recent compact 10 actual.journal >>"$tmp/all-compact-expected"
./tools/report-destination "$fixture" planned compact 2026-01-12 actual.journal plan.tsv cycle.tsv >>"$tmp/all-compact-expected"
./tools/report-destination "$fixture" daily-target compact JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >>"$tmp/all-compact-expected"
cmp "$tmp/all-compact" "$tmp/all-compact-expected"

mkdir "$tmp/actual-only" "$tmp/issues-only" "$tmp/cycle-only" "$tmp/planned-only" \
  "$tmp/income-cycle" "$tmp/envelope-only" "$tmp/daily-only"
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$tmp/actual-only/"
cp "$fixture/issues.destination.tsv" "$tmp/issues-only/"
./tools/report-destination "$tmp/actual-only" recent human 2 actual.journal >/dev/null
(
  cd "$tmp"
  "$root/tools/report-destination" actual-only recent human 2 actual.journal >/dev/null
)
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
if ./tools/report-destination "$tmp/issues-only" balances human JPY 2026-01-12 missing.journal >"$tmp/unreadable" 2>&1; then
  echo 'FAIL: missing required source succeeded' >&2; exit 1
fi
grep -F $'source_unreadable' "$tmp/unreadable" >/dev/null
if ./tools/report-destination "$tmp/not-present" all human >"$tmp/all" 2>&1; then
  echo 'FAIL: all without manifest succeeded' >&2; exit 1
fi
grep -F $'all_manifest_required' "$tmp/all" >/dev/null
{
  printf 'key\tsurface\targuments\n'
  tail -n +3 "$fixture/report_all_human.destination.tsv"
  sed -n '2p' "$fixture/report_all_human.destination.tsv"
} >"$tmp/bad-order.tsv"
if ./tools/report-destination "$tmp" all human bad-order.tsv >"$tmp/partial" 2>"$tmp/bad-order-error"; then
  echo 'FAIL: misordered all manifest succeeded' >&2; exit 1
fi
[[ ! -s $tmp/partial ]] || { echo 'FAIL: failed all request published partial output' >&2; exit 1; }
grep -F $'all_manifest_order_mismatch' "$tmp/bad-order-error" >/dev/null

echo 'check-report-destination-composition: OK'
