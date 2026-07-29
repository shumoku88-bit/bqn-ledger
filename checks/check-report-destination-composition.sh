#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

./tools/report-destination "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"
./tools/report-destination "$fixture" recent compact 10 actual.journal >"$tmp/recent"
cmp "$tmp/recent" "$fixture/recent_journal.destination.compact.txt"
./tools/report-destination "$fixture" monthly-accounts human JPY 2026-01 2026-03 actual.journal >"$tmp/monthly"
cmp "$tmp/monthly" "$fixture/monthly_accounts.destination.human.txt"
./tools/report-destination "$fixture" issues human issues.destination.tsv >"$tmp/issues"
cmp "$tmp/issues" "$fixture/issues.destination.human.txt"

mkdir "$tmp/actual-only" "$tmp/issues-only"
cp "$fixture/accounts.tsv" "$fixture/actual.journal" "$tmp/actual-only/"
cp "$fixture/issues.destination.tsv" "$tmp/issues-only/"
./tools/report-destination "$tmp/actual-only" recent human 2 actual.journal >/dev/null
./tools/report-destination "$tmp/issues-only" issues human issues.destination.tsv >/dev/null

if ./tools/report-destination "$tmp/not-present" snapshot human >"$tmp/unknown" 2>&1; then
  echo 'FAIL: unknown key succeeded' >&2; exit 1
fi
grep -F $'report_key_unknown' "$tmp/unknown" >/dev/null
if ./tools/report-destination "$tmp/not-present" issues json issues.destination.tsv >"$tmp/unsupported" 2>&1; then
  echo 'FAIL: unsupported surface succeeded' >&2; exit 1
fi
grep -F $'report_surface_unsupported' "$tmp/unsupported" >/dev/null

echo 'check-report-destination-composition: OK'
