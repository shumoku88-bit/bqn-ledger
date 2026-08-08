#!/usr/bin/env bash
set -euo pipefail
trap 'status=$?; echo "FAIL: check-report-route-plan-shell line $LINENO" >&2; echo "::error file=checks/check-report-route-plan-shell.sh,line=$LINENO::route-plan shell check failed" >&2; exit "$status"' ERR

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-route-plan-shell.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

grep -F 'src/application/report_route_plan_cli.bqn' tools/report >/dev/null
if grep -Eq 'source_basename|actual_source|plan_source|cycle_source|daily_scope_source|funding_account' src/application/report_route.bqn; then
  echo 'FAIL: Report route still exposes physical source coordinates' >&2
  exit 1
fi

./tools/report "$fixture" balances human JPY 2026-01-12 >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"

if ./tools/report "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances-source" 2>&1; then
  echo 'FAIL: physical Actual source coordinate still succeeded' >&2
  exit 1
fi
grep -F 'usage_balances' "$tmp/balances-source" >/dev/null

./tools/report "$fixture" envelopes human JPY 2026-01-01 2026-02-01 2026-01-12 >"$tmp/envelopes"
cmp "$tmp/envelopes" "$fixture/envelope_backing.destination.human.txt"
if ./tools/report "$fixture" envelopes human JPY 2026-01-01 2026-02-01 2026-01-12 actual.journal plan.tsv budget.tsv funding >"$tmp/envelopes-source" 2>&1; then
  echo 'FAIL: legacy Envelope source coordinates still succeeded' >&2
  exit 1
fi
grep -F 'usage_envelopes' "$tmp/envelopes-source" >/dev/null

./tools/report "$fixture" planned human 2026-01-12 >"$tmp/planned"
cmp "$tmp/planned" "$fixture/planned_payments.destination.human.txt"
./tools/report "$fixture" cycle-accounts human JPY 2026-01-12 >"$tmp/cycle"
grep -F '== Current-cycle Accounts ==' "$tmp/cycle" >/dev/null
./tools/report "$fixture" daily-target human JPY 2026-01-12 2026-01-22 >"$tmp/daily-target"
grep -F '== Daily Target ==' "$tmp/daily-target" >/dev/null
./tools/report "$fixture" issues human >"$tmp/issues"
grep -F '== Issues ==' "$tmp/issues" >/dev/null

if ./tools/report "$fixture" issues human issues.tsv >"$tmp/issues-source" 2>&1; then
  echo 'FAIL: Issue source coordinate still succeeded' >&2
  exit 1
fi
grep -F 'usage_issues' "$tmp/issues-source" >/dev/null

if ./tools/report "$fixture" recent human 2026-01-12 nope >"$tmp/recent-limit" 2>&1; then
  echo 'FAIL: invalid recent limit succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tlimit_invalid\tLIMIT must be decimal digits' "$tmp/recent-limit" >/dev/null

if ./tools/report "$fixture" recent human 2026-01-12 3 actual.journal >"$tmp/recent-source" 2>&1; then
  echo 'FAIL: Recent physical source coordinate still succeeded' >&2
  exit 1
fi
grep -F 'usage_recent' "$tmp/recent-source" >/dev/null

echo 'check-report-route-plan-shell: OK'
