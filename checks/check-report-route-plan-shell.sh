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

# Historical Plan/Budget/funding coordinates remain in argv until report.toml
# removes them, but none names physical companion I/O. Path-shaped values cannot
# redirect canonical Plan/Budget reads away from Household canonical sources.
./tools/report "$fixture" envelopes human JPY \
  2026-01-01 2026-02-01 2026-01-12 actual.journal bad/plan.tsv bad/budget.tsv bad/funding \
  >"$tmp/legacy-coordinates"
cmp "$tmp/legacy-coordinates" "$fixture/envelope_backing.destination.human.txt"

if ./tools/report "$fixture" issues human bad/issues.tsv >"$tmp/issues-basename" 2>&1; then
  echo 'FAIL: unsafe Issue basename succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tsource_basename_invalid\tissues must be a safe .tsv basename' \
  "$tmp/issues-basename" >/dev/null

# Canonical Actual routes reject a noncanonical source identity before filesystem
# readability or the independent LIMIT diagnostic can become relevant.
if ./tools/report "$tmp/not-present" recent human nope missing.journal >"$tmp/recent-precedence" 2>&1; then
  echo 'FAIL: invalid recent request with noncanonical source succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tactual_source_not_canonical\tActual-only report requires canonical actual.journal' \
  "$tmp/recent-precedence" >/dev/null
if grep -Fq $'limit_invalid' "$tmp/recent-precedence"; then
  echo 'FAIL: canonical source identity did not retain precedence over LIMIT validation' >&2
  exit 1
fi

if ./tools/report "$fixture" recent human nope actual.journal >"$tmp/recent-limit" 2>&1; then
  echo 'FAIL: invalid recent limit succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tlimit_invalid\tLIMIT must be decimal digits' "$tmp/recent-limit" >/dev/null

echo 'check-report-route-plan-shell: OK'
