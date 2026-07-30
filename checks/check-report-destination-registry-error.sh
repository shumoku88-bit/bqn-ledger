#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
fixture="$root/fixtures/ledger-facts-phase1-proof"
cli="$root/src/application/report_destination_cli.bqn"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-report-registry.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

if grep -Fq 'registryResult.diagnostics' "$cli"; then
  echo 'FAIL: report destination still assumes registry results expose diagnostics' >&2
  exit 1
fi
grep -F 'RegistryDiagnostic registryResult' "$cli" >/dev/null

mkdir -p "$tmp/empty/config" "$tmp/duplicate/config"
: >"$tmp/empty/config/currencies.tsv"
printf 'JPY\t0\tYEN\nJPY\t0\tYEN\n' >"$tmp/duplicate/config/currencies.tsv"

if (
  cd "$tmp/empty"
  bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/empty.out" 2>&1
); then
  echo 'FAIL: empty currency registry succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tcurrency_registry_empty\tcurrency registry is empty' "$tmp/empty.out" >/dev/null || {
  cat "$tmp/empty.out" >&2
  exit 1
}
if grep -Eq 'Field named "diagnostics" not found|usage_balances' "$tmp/empty.out"; then
  echo 'FAIL: empty registry did not fail through the registry result contract' >&2
  exit 1
fi

if (
  cd "$tmp/duplicate"
  bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/duplicate.out" 2>&1
); then
  echo 'FAIL: duplicate currency registry succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tcurrency_registry_currency_duplicate\tcurrency registry contains duplicate currency code' \
  "$tmp/duplicate.out" >/dev/null || {
    cat "$tmp/duplicate.out" >&2
    exit 1
  }
if grep -Eq 'Field named "diagnostics" not found|usage_balances' "$tmp/duplicate.out"; then
  echo 'FAIL: duplicate registry did not fail through the registry result contract' >&2
  exit 1
fi

echo 'check-report-destination-registry-error: OK'
