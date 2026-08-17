#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination.XXXXXX")"
trap 'status=$?; echo "::error file=checks/check-report-composition.sh,line=$LINENO::Report composition check failed" >&2; exit "$status"' ERR
trap 'rm -rf "$tmp"' EXIT

request_cli=src/application/report_request_cli.bqn
presentation_cli=src/application/report_presentation_cli.bqn
grep -Fq 'request ← •Import "../report/request.bqn"' "$request_cli"
if grep -Eq '•Import ".*(source_adapter|source_io|canonical_household_sources)' "$request_cli"; then
  echo 'FAIL: Report request CLI gained source ownership' >&2
  exit 1
fi
grep -Fq 'source ← •Import "report_policy_source_adapter.bqn"' "$presentation_cli"
if grep -Fq 'report_source_adapter.bqn' "$presentation_cli"; then
  echo 'FAIL: Report presentation CLI gained accounting evidence ownership' >&2
  exit 1
fi

./tools/report "$fixture" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/envelopes"
cmp "$tmp/envelopes" "$fixture/envelope_backing.destination.compact.txt"
./tools/report "$fixture" envelopes json JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/envelopes-json"
cmp "$tmp/envelopes-json" "$fixture/envelope_backing.destination.json"
./tools/report "$fixture" balances human JPY 2026-01-12 >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"
./tools/report "$fixture" balance-sheet human JPY 2026-01-12 >"$tmp/balance-sheet"
cmp "$tmp/balance-sheet" "$fixture/balance_sheet.destination.human.txt"
./tools/report "$fixture" profit-and-loss human JPY 2026-01-01 2026-02-01 >"$tmp/profit-and-loss"
cmp "$tmp/profit-and-loss" "$fixture/profit_and_loss.destination.human.txt"
./tools/report "$fixture" recent compact 2026-01-12 10 >"$tmp/recent"
cmp "$tmp/recent" "$fixture/recent_journal.destination.compact.txt"
./tools/report "$fixture" planned human 2026-01-12 >"$tmp/planned"
cmp "$tmp/planned" "$fixture/planned_payments.destination.human.txt"
./tools/report "$fixture" cycle-accounts human JPY 2026-01-10 >"$tmp/cycle"
cmp "$tmp/cycle" "$fixture/cycle_accounts.destination.human.txt"
./tools/report "$fixture" cycle-comparison human JPY 2026-01-10 2026-01-10 aligned_elapsed >"$tmp/comparison"
cmp "$tmp/comparison" "$fixture/cycle_comparison.destination.human.txt"
./tools/report "$fixture" monthly-accounts human JPY 2026-01 2026-03 >"$tmp/monthly"
cmp "$tmp/monthly" "$fixture/monthly_accounts.destination.human.txt"
./tools/report "$fixture" daily-flow human JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/daily-flow"
cmp "$tmp/daily-flow" "$fixture/daily_flow.destination.human.txt"
if rg -n 'Budget unassigned|budget:|ledger_unassigned|reconciliation_delta|"account": ""' \
  "$tmp/envelopes" "$tmp/envelopes-json" "$tmp/balances" "$tmp/daily-flow"; then
  echo 'FAIL: accounting report retained a Budget/Account projection axis' >&2
  exit 1
fi
grep -F '"stock_origin": {"present": true' "$tmp/envelopes-json" >/dev/null
grep -F '"memo": "phase-one clean epoch"' "$tmp/envelopes-json" >/dev/null
grep -F '"source_event_id": "entitlement.journal:line:1"' "$tmp/envelopes-json" >/dev/null
./tools/report "$fixture" daily-target human JPY 2026-01-12 2026-01-22 >"$tmp/daily-target"
cmp "$tmp/daily-target" "$fixture/daily_target.application.human.txt"
./tools/report "$fixture" issues human >"$tmp/issues"
cmp "$tmp/issues" "$fixture/issues.destination.human.txt"

: >"$tmp/compact-expected"
cat "$fixture/envelope_backing.destination.compact.txt" >>"$tmp/compact-expected"
./tools/report "$fixture" balances compact JPY 2026-01-12 >>"$tmp/compact-expected"
./tools/report "$fixture" recent compact 2026-01-12 10 >>"$tmp/compact-expected"
./tools/report "$fixture" planned compact 2026-01-12 >>"$tmp/compact-expected"
./tools/report "$fixture" daily-target compact JPY 2026-01-12 2026-01-22 >>"$tmp/compact-expected"

# Partial data roots may exercise individual owners, but human rendering still
# uses the canonical Report presentation policy.
mkdir "$tmp/actual-only" "$tmp/issues-only"
cp "$fixture/accounts.journal" "$fixture/actual.journal" "$fixture/report.toml" "$tmp/actual-only/"
cp "$fixture/issues.tsv" "$fixture/report.toml" "$tmp/issues-only/"
./tools/report "$tmp/actual-only" recent human 2026-01-12 2 >/dev/null
./tools/report "$tmp/actual-only" balance-sheet human JPY 2026-01-12 >/dev/null
./tools/report "$tmp/actual-only" profit-and-loss human JPY 2026-01-01 2026-02-01 >/dev/null
(
  cd "$tmp"
  "$root/tools/report" actual-only recent human 2026-01-12 2 >/dev/null
)
./tools/report "$tmp/issues-only" issues human >/dev/null

if ./tools/report "$tmp/not-present" snapshot human >"$tmp/unknown" 2>&1; then
  echo 'FAIL: unknown key succeeded' >&2; exit 1
fi
grep -F $'report_key_unknown' "$tmp/unknown" >/dev/null
if ./tools/report "$tmp/not-present" issues json >"$tmp/unsupported" 2>&1; then
  echo 'FAIL: unsupported surface succeeded' >&2; exit 1
fi
grep -F $'report_surface_unsupported' "$tmp/unsupported" >/dev/null

if ./tools/report "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/source-coordinate" 2>&1; then
  echo 'FAIL: physical source coordinate survived Report composition boundary' >&2; exit 1
fi
grep -F 'usage_balances' "$tmp/source-coordinate" >/dev/null
if ./tools/report "$fixture" balances human --manifest report_all_human.destination.tsv >"$tmp/manifest" 2>&1; then
  echo 'FAIL: retired request manifest survived Report composition boundary' >&2; exit 1
fi
grep -F 'report_manifest_retired' "$tmp/manifest" >/dev/null

echo 'check-report-composition: OK'
