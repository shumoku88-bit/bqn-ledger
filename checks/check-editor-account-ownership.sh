#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if rg -n '"JPY"|physical_fallback|RoleFrom|CurrencyFrom' src/application/editor_accounts.bqn >/dev/null; then
  echo 'FAIL: strict editor Accounts gained compatibility inference/runtime' >&2; exit 1
fi
if rg -n 'journal_currency_proof_carrier_stage2a' \
  src_edit/journal_block_add_cmd.bqn src_edit/journal_native_source_check.bqn >/dev/null; then
  echo 'FAIL: editor retained redundant old carrier after complete Journal admission' >&2; exit 1
fi
bqn tests/test_application_editor_accounts.bqn >/dev/null

echo 'check-editor-account-ownership: OK'
