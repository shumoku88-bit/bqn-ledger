#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture=fixtures/ledger-facts-phase1-proof
work=$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-manifest-routing.XXXXXX")
trap 'rm -rf "$work"' EXIT

./tools/report "$fixture" balances human JPY 2026-01-12 >"$work/balances"
cmp "$work/balances" "$fixture/account_balances.destination.human.txt"

if ./tools/report "$fixture" balances human --manifest report_all_human.destination.tsv >"$work/manifest" 2>&1; then
  echo 'FAIL: retired per-key Report manifest still influenced execution' >&2
  exit 1
fi
grep -F $'ERROR\treport_manifest_retired\t' "$work/manifest" >/dev/null

if ./tools/report "$fixture" all human report_all_human.destination.tsv >"$work/all" 2>&1; then
  echo 'FAIL: retired all-report manifest still influenced execution' >&2
  exit 1
fi
grep -F $'ERROR\treport_manifest_retired\t' "$work/all" >/dev/null

echo 'check-report-manifest-routing: OK'
