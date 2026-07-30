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

mkdir -p "$tmp/empty/config" "$tmp/malformed/config"
: >"$tmp/empty/config/currencies.tsv"
printf 'JPY\t0\n' >"$tmp/malformed/config/currencies.tsv"

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
  cd "$tmp/malformed"
  bqn "$cli" "$fixture" balances human JPY 2026-01-12 >"$tmp/malformed.out" 2>&1
); then
  echo 'FAIL: malformed currency registry succeeded' >&2
  exit 1
fi
grep -Fx $'ERROR\tcurrency_registry_row_invalid\tcurrency registry rows require currency, max_fraction_digits, and symbol' \
  "$tmp/malformed.out" >/dev/null || {
    cat "$tmp/malformed.out" >&2
    exit 1
  }
if grep -Eq 'Field named "diagnostics" not found|usage_balances' "$tmp/malformed.out"; then
  echo 'FAIL: malformed registry did not fail through the registry result contract' >&2
  exit 1
fi

echo 'check-report-destination-registry-error: OK'
