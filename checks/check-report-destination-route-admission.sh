#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture="$root/fixtures/ledger-facts-phase1-proof"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-destination-route.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
cli="$root/src/application/report_destination_cli.bqn"

grep -F 'route ← •Import "report_route.bqn"' "$cli" >/dev/null
grep -F 'route.Admit ⟨key,surface,coordinates⟩' "$cli" >/dev/null
if grep -Eq 'usage_(envelopes|balances|recent|planned|cycle_accounts|cycle_comparison|monthly_accounts|daily_flow|daily_target|issues)' "$cli"; then
  echo 'FAIL: destination CLI still owns individual raw route admission' >&2
  exit 1
fi
if grep -Fq 'IsDigits' "$cli"; then
  echo 'FAIL: destination CLI still owns recent LIMIT text admission' >&2
  exit 1
fi

bqn "$cli" "$fixture" balances human JPY 2026-01-12 actual.journal >"$tmp/balances"
cmp "$tmp/balances" "$fixture/account_balances.destination.human.txt"

if bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/arity" 2>&1; then
  echo 'FAIL: direct destination invalid arity succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tusage_balances\tbalances requires DOMAIN AS_OF JOURNAL_BASENAME' "$tmp/arity" >/dev/null

if bqn "$cli" "$fixture" recent human nope actual.journal >"$tmp/limit" 2>&1; then
  echo 'FAIL: direct destination invalid LIMIT succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tlimit_invalid\tLIMIT must be decimal digits' "$tmp/limit" >/dev/null

# Request and `all` admission remain before registry access.
if (
  cd "$tmp"
  bqn "$cli" "$fixture" unknown human >"$tmp/unknown" 2>&1
); then
  echo 'FAIL: unknown direct destination key succeeded without registry' >&2
  exit 1
fi
grep -Fx $'ERROR\treport_key_unknown\tunknown report key: unknown' "$tmp/unknown" >/dev/null

if (
  cd "$tmp"
  bqn "$cli" "$fixture" all human >"$tmp/all" 2>&1
); then
  echo 'FAIL: direct destination all succeeded without registry' >&2
  exit 1
fi
grep -Fx $'ERROR\tall_not_implemented\tparallel CLI currently requires one retained key' "$tmp/all" >/dev/null

# Individual route admission remains after registry access, preserving direct-CLI failure order.
if (
  cd "$tmp"
  bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/registry-first" 2>&1
); then
  echo 'FAIL: invalid direct route succeeded without registry' >&2
  exit 1
fi
grep -Fx $'ERROR\tcurrency_registry_empty\tcurrency registry is empty' "$tmp/registry-first" >/dev/null
if grep -Fq $'usage_balances' "$tmp/registry-first"; then
  echo 'FAIL: route admission moved before registry admission' >&2
  exit 1
fi

echo 'check-report-destination-route-admission: OK'
