#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

./tools/report "$fixture" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv assets:cash >"$tmp/envelopes"
cmp "$tmp/envelopes" "$fixture/envelope_backing.destination.compact.txt"
./tools/report "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"
./tools/report "$fixture" balances human --manifest report_all_human.destination.tsv >"$tmp/balances-manifest"
cmp "$tmp/balances-manifest" "$tmp/balances"
./tools/report "$fixture" balance-sheet human JPY 2026-01-12 actual.journal >"$tmp/balance-sheet"
cmp "$tmp/balance-sheet" "$fixture/balance_sheet.destination.human.txt"
./tools/report "$fixture" profit-and-loss human JPY 2026-01-01 2026-02-01 actual.journal >"$tmp/profit-and-loss"
cmp "$tmp/profit-and-loss" "$fixture/profit_and_loss.destination.human.txt"
./tools/report "$fixture" recent compact 10 actual.journal >"$tmp/recent"
cmp "$tmp/recent" "$fixture/recent_journal.destination.compact.txt"
./tools/report "$fixture" planned human 2026-01-12 actual.journal plan.tsv cycle.tsv >"$tmp/planned"
cmp "$tmp/planned" "$fixture/planned_payments.destination.human.txt"
./tools/report "$fixture" cycle-accounts human JPY 2026-01-10 actual.journal cycle.tsv >"$tmp/cycle"
cmp "$tmp/cycle" "$fixture/cycle_accounts.destination.human.txt"
./tools/report "$fixture" cycle-comparison human JPY 2026-01-10 2025-12-31 aligned_elapsed actual.journal cycle.tsv cycle_baseline.destination.tsv >"$tmp/comparison"
cmp "$tmp/comparison" "$fixture/cycle_comparison.destination.human.txt"
./tools/report "$fixture" monthly-accounts human JPY 2026-01 2026-03 actual.journal >"$tmp/monthly"
cmp "$tmp/monthly" "$fixture/monthly_accounts.destination.human.txt"
./tools/report "$fixture" daily-flow human JPY 2026-01-01 2026-02-01 2026-01-12 actual.journal >"$tmp/daily-flow"
cmp "$tmp/daily-flow" "$fixture/daily_flow.destination.human.txt"
./tools/report "$fixture" daily-target human JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >"$tmp/daily-target"
cmp "$tmp/daily-target" "$fixture/daily_target.application.human.txt"
./tools/report "$fixture" issues human issues.destination.tsv >"$tmp/issues"
cmp "$tmp/issues" "$fixture/issues.destination.human.txt"
cat "$fixture/envelope_backing.destination.human.txt" "$fixture/account_balances.destination.human.txt" \
  "$fixture/balance_sheet.destination.human.txt" "$fixture/profit_and_loss.destination.human.txt" \
  "$fixture/recent_journal.destination.human.txt" "$fixture/planned_payments.destination.human.txt" \
  "$fixture/cycle_accounts.destination.human.txt" "$fixture/cycle_comparison.destination.human.txt" \
  "$fixture/monthly_accounts.destination.human.txt" "$fixture/daily_flow.destination.human.txt" \
  "$fixture/daily_target.application.human.txt" \
  "$fixture/issues.destination.human.txt" >"$tmp/all-human-expected"
./tools/report "$fixture" all human report_all_human.destination.tsv >"$tmp/all-human"
cmp "$tmp/all-human" "$tmp/all-human-expected"
./tools/report "$fixture" all compact report_all_compact.destination.tsv >"$tmp/all-compact"
: >"$tmp/all-compact-expected"
./tools/report "$fixture" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 \
  actual.journal plan.tsv budget_alloc.tsv assets:cash >>"$tmp/all-compact-expected"
./tools/report "$fixture" balances compact JPY 2026-01-12 actual.journal >>"$tmp/all-compact-expected"
./tools/report "$fixture" recent compact 10 actual.journal >>"$tmp/all-compact-expected"
./tools/report "$fixture" planned compact 2026-01-12 actual.journal plan.tsv cycle.tsv >>"$tmp/all-compact-expected"
./tools/report "$fixture" daily-target compact JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >>"$tmp/all-compact-expected"
cmp "$tmp/all-compact" "$tmp/all-compact-expected"

mkdir "$tmp/actual-only" "$tmp/issues-only" "$tmp/cycle-only" "$tmp/planned-only" \
  "$tmp/income-cycle" "$tmp/envelope-only" "$tmp/daily-only"
cp "$fixture/accounts.journal" "$fixture/actual.journal" "$tmp/actual-only/"
cp "$fixture/issues.destination.tsv" "$tmp/issues-only/"
./tools/report "$tmp/actual-only" recent human 2 actual.journal >/dev/null
./tools/report "$tmp/actual-only" balance-sheet human JPY 2026-01-12 actual.journal >/dev/null
./tools/report "$tmp/actual-only" profit-and-loss human JPY 2026-01-01 2026-02-01 actual.journal >/dev/null
(
  cd "$tmp"
  "$root/tools/report" actual-only recent human 2 actual.journal >/dev/null
)
./tools/report "$tmp/issues-only" issues human issues.destination.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/cycle.tsv" "$tmp/cycle-only/"
./tools/report "$tmp/cycle-only" cycle-accounts human JPY 2026-01-10 actual.journal cycle.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" \
  "$fixture/daily_target_plan.destination.tsv" "$fixture/daily_target_scope.destination.tsv" "$tmp/daily-only/"
./tools/report "$tmp/daily-only" daily-target human JPY 2026-01-12 2026-01-22 \
  actual.journal daily_target_plan.destination.tsv daily_target_scope.destination.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/plan.tsv" "$fixture/budget_alloc.tsv" "$tmp/envelope-only/"
./tools/report "$tmp/envelope-only" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv assets:cash >/dev/null
if ./tools/report "$tmp/envelope-only" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget_alloc.tsv expenses:food \
  >"$tmp/funding-role" 2>&1; then
  echo 'FAIL: non-asset funding Account succeeded' >&2; exit 1
fi
grep -F $'funding_account_role_invalid' "$tmp/funding-role" >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$fixture/plan.tsv" "$fixture/cycle.tsv" "$tmp/planned-only/"
./tools/report "$tmp/planned-only" planned human 2026-01-12 actual.journal plan.tsv cycle.tsv >/dev/null
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$tmp/income-cycle/"
printf '%s\n' $'mode\tincomeAnchor' $'income_account\tincome:salary' $'offset\t0' >"$tmp/income-cycle/cycle.tsv"
printf '%s\n' $'2026-02-01\tnext-income\tincome:salary\tassets:cash\t1000\tcurrency=JPY\tplan_id=income-next' >"$tmp/income-cycle/plan.tsv"
./tools/report "$tmp/income-cycle" cycle-accounts human JPY 2026-01-12 actual.journal cycle.tsv plan.tsv >/dev/null
if ./tools/report "$tmp/income-cycle" cycle-accounts human JPY 2026-01-12 actual.journal cycle.tsv >"$tmp/plan-required" 2>&1; then
  echo 'FAIL: incomeAnchor succeeded without Plan' >&2; exit 1
fi
grep -F $'plan_required' "$tmp/plan-required" >/dev/null

if ./tools/report "$tmp/not-present" snapshot human >"$tmp/unknown" 2>&1; then
  echo 'FAIL: unknown key succeeded' >&2; exit 1
fi
grep -F $'report_key_unknown' "$tmp/unknown" >/dev/null
if ./tools/report "$tmp/not-present" issues json issues.destination.tsv >"$tmp/unsupported" 2>&1; then
  echo 'FAIL: unsupported surface succeeded' >&2; exit 1
fi
grep -F $'report_surface_unsupported' "$tmp/unsupported" >/dev/null
if ./tools/report "$tmp/issues-only" balances human JPY 2026-01-12 missing.journal >"$tmp/unreadable" 2>&1; then
  echo 'FAIL: missing required source succeeded' >&2; exit 1
fi
grep -F $'actual_source_not_canonical' "$tmp/unreadable" >/dev/null
if ./tools/report "$tmp/not-present" all human >"$tmp/all" 2>&1; then
  echo 'FAIL: all without manifest succeeded' >&2; exit 1
fi
grep -F $'all_manifest_required' "$tmp/all" >/dev/null
{
  printf 'key\tsurface\targuments\n'
  tail -n +3 "$fixture/report_all_human.destination.tsv"
  sed -n '2p' "$fixture/report_all_human.destination.tsv"
} >"$tmp/bad-order.tsv"
if ./tools/report "$tmp" all human bad-order.tsv >"$tmp/partial" 2>"$tmp/bad-order-error"; then
  echo 'FAIL: misordered all manifest succeeded' >&2; exit 1
fi
[[ ! -s $tmp/partial ]] || { echo 'FAIL: failed all request published partial output' >&2; exit 1; }
grep -F $'all_manifest_order_mismatch' "$tmp/bad-order-error" >/dev/null
if ./tools/report "$fixture" balances compact --manifest report_all_human.destination.tsv \
  >"$tmp/manifest-surface" 2>&1; then
  echo 'FAIL: manifest surface mismatch succeeded' >&2; exit 1
fi
grep -F $'request_manifest_surface_mismatch' "$tmp/manifest-surface" >/dev/null
{
  printf 'key\tsurface\targuments\n'
  sed -n '3p' "$fixture/report_all_human.destination.tsv"
  sed -n '3p' "$fixture/report_all_human.destination.tsv"
} >"$tmp/duplicate.tsv"
if ./tools/report "$tmp" balances human --manifest duplicate.tsv >"$tmp/manifest-duplicate" 2>&1; then
  echo 'FAIL: duplicate selected manifest row succeeded' >&2; exit 1
fi
grep -F $'request_manifest_duplicate' "$tmp/manifest-duplicate" >/dev/null

echo 'check-report-composition: OK'
