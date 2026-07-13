#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="fixtures/currency-m15-migration"

audit_out="$(bash tools/currency-setup audit "$fixture")"
grep -Fxq 'state=ok' <<<"$audit_out"
grep -Fxq 'default_key=DEFAULT_CURRENCY' <<<"$audit_out"
grep -Fxq 'default_state=ok' <<<"$audit_out"
grep -Fxq 'default_currency=JPY' <<<"$audit_out"
grep -Fxq 'default_provenance=ledger_config' <<<"$audit_out"
grep -Fxq 'migration_target=JPY' <<<"$audit_out"
grep -Fxq 'changed_count=5' <<<"$audit_out"
grep -Fxq 'error_count=0' <<<"$audit_out"
if grep -q '^FILE ' <<<"$audit_out"; then
  echo 'FAIL: audit mode emitted migration replacement preview' >&2
  exit 1
fi

dry_out="$(bash tools/currency-setup dry-run "$fixture")"
grep -Fxq 'changed_count=5' <<<"$dry_out"
grep -Fq $'FILE accounts.tsv ROW 1' <<<"$dry_out"
grep -Fq $'+assets:bank\trole=asset\ttype=liquid\tcurrency=JPY' <<<"$dry_out"
grep -Fq $'FILE journal.tsv ROW 1' <<<"$dry_out"
grep -Fq $'+2026-07-01\t\tassets:bank\texpenses:food\t1200\tparty=shop\tcurrency=JPY' <<<"$dry_out"
grep -Fq $'FILE plan.tsv ROW 0' <<<"$dry_out"
grep -Fq $'FILE budget_alloc.tsv ROW 0' <<<"$dry_out"

# Command is read-only: fixture digests must remain unchanged.
before="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
bash tools/currency-setup dry-run "$fixture" >/dev/null
after="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
if [[ "$before" != "$after" ]]; then
  echo 'FAIL: currency setup dry-run modified fixture data' >&2
  exit 1
fi

printf 'OK: M1.5 explicit default and read-only migration preview passed\n'
