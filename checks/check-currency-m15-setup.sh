#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fixture="fixtures/currency-m15-migration"

fail_output() {
  local label="$1" expected="$2" actual="$3"
  printf 'FAIL: %s\nexpected: %s\nactual output:\n%s\n' "$label" "$expected" "$actual" >&2
  exit 1
}

assert_line() {
  local expected="$1" actual="$2" label="$3"
  grep -Fxq -- "$expected" <<<"$actual" || fail_output "$label" "$expected" "$actual"
}

assert_contains() {
  local expected="$1" actual="$2" label="$3"
  grep -Fq -- "$expected" <<<"$actual" || fail_output "$label" "$expected" "$actual"
}

capture_setup() {
  local mode="$1" output status
  set +e
  output="$(bash tools/currency-setup "$mode" "$fixture" 2>&1)"
  status=$?
  set -e
  if [[ "$status" -ne 0 ]]; then
    fail_output "$mode command exit" 'status=0' "status=$status
$output"
  fi
  printf '%s' "$output"
}

audit_out="$(capture_setup audit)"
assert_line 'state=ok' "$audit_out" 'audit state'
assert_line 'default_key=DEFAULT_CURRENCY' "$audit_out" 'default key'
assert_line 'default_state=ok' "$audit_out" 'default state'
assert_line 'default_currency=JPY' "$audit_out" 'default currency'
assert_line 'default_provenance=ledger_config' "$audit_out" 'default provenance'
assert_line 'migration_target=JPY' "$audit_out" 'migration target'
assert_line 'changed_count=5' "$audit_out" 'audit changed count'
assert_line 'error_count=0' "$audit_out" 'audit error count'
if grep -q '^FILE ' <<<"$audit_out"; then
  echo 'FAIL: audit mode emitted migration replacement preview' >&2
  printf '%s\n' "$audit_out" >&2
  exit 1
fi

dry_out="$(capture_setup dry-run)"
assert_line 'changed_count=5' "$dry_out" 'dry-run changed count'
assert_contains 'FILE accounts.tsv ROW 1' "$dry_out" 'accounts preview row'
assert_contains $'+assets:bank\trole=asset\ttype=liquid\tcurrency=JPY' "$dry_out" 'accounts proposed line'
assert_contains 'FILE journal.tsv ROW 1' "$dry_out" 'journal preview row'
assert_contains $'+2026-07-01\t\tassets:bank\texpenses:food\t1200\tparty=shop\tcurrency=JPY' "$dry_out" 'journal proposed line'
assert_contains 'FILE plan.tsv ROW 0' "$dry_out" 'plan preview row'
assert_contains 'FILE budget_alloc.tsv ROW 0' "$dry_out" 'budget preview row'

# Command is read-only: fixture digests must remain unchanged.
before="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
capture_setup dry-run >/dev/null
after="$(find "$fixture" -type f -print0 | sort -z | xargs -0 sha256sum)"
if [[ "$before" != "$after" ]]; then
  echo 'FAIL: currency setup dry-run modified fixture data' >&2
  exit 1
fi

printf 'OK: M1.5 explicit default and read-only migration preview passed\n'
