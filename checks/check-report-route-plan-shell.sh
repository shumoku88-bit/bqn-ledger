#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-route-plan-shell.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

if grep -Fq 'case "$key" in' tools/report; then
  echo 'FAIL: tools/report still owns the key-specific source-position case' >&2
  exit 1
fi
grep -F 'src/application/report_route_plan_cli.bqn' tools/report >/dev/null

./tools/report "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"

if ./tools/report "$fixture" balances human JPY 2026-01-12 >"$tmp/arity" 2>&1; then
  echo 'FAIL: invalid balances arity succeeded' >&2
  exit 1
else
  status=$?
fi
[[ $status -eq 2 ]] || { echo 'FAIL: invalid route arity did not preserve exit 2' >&2; exit 1; }
grep -F 'Usage:' "$tmp/arity" >/dev/null

if ./tools/report "$fixture" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal bad/plan.tsv budget_alloc.tsv assets:cash \
  >"$tmp/envelope-basename" 2>&1; then
  echo 'FAIL: unsafe envelope Plan basename succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tsource_basename_invalid\tPlan and Budget must be safe .tsv basenames' \
  "$tmp/envelope-basename" >/dev/null

if ./tools/report "$fixture" issues human bad/issues.tsv >"$tmp/issues-basename" 2>&1; then
  echo 'FAIL: unsafe Issue basename succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tsource_basename_invalid\tissues must be a safe .tsv basename' \
  "$tmp/issues-basename" >/dev/null

if ./tools/report "$tmp/not-present" recent human nope missing.journal >"$tmp/recent-precedence" 2>&1; then
  echo 'FAIL: invalid recent request with unreadable sources succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tsource_unreadable\trequired source is not readable: accounts.journal' \
  "$tmp/recent-precedence" >/dev/null
if grep -Fq $'limit_invalid' "$tmp/recent-precedence"; then
  echo 'FAIL: pure route validation changed the previous operational failure precedence' >&2
  exit 1
fi

if ./tools/report "$fixture" recent human nope actual.journal >"$tmp/recent-limit" 2>&1; then
  echo 'FAIL: invalid recent limit succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tlimit_invalid\tLIMIT must be decimal digits' "$tmp/recent-limit" >/dev/null

echo 'check-report-route-plan-shell: OK'
