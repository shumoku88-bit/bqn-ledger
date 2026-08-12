#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

[[ ! -e src/application/editor_accounts.bqn ]] \
  || { echo 'FAIL: retired legacy editor Accounts seam returned' >&2; exit 1; }
grep -Fq 'accountSource ← •Import "../src/application/account_source_adapter.bqn"' src_edit/travel_exchange_add_cmd.bqn \
  || { echo 'FAIL: travel exchange editor must use canonical Account source adapter' >&2; exit 1; }
if rg -n 'accounts\.tsv|account_admission\.bqn|editor_accounts\.bqn' src_edit/travel_exchange_add_cmd.bqn >/dev/null; then
  echo 'FAIL: travel exchange editor regained legacy Account source ownership' >&2; exit 1
fi
if rg -n 'journal_currency_proof_carrier_stage2a' \
  src_edit/journal_block_add_cmd.bqn src_edit/journal_native_source_check.bqn >/dev/null; then
  echo 'FAIL: editor retained redundant old carrier after complete Journal admission' >&2; exit 1
fi

echo 'check-editor-account-ownership: OK'
