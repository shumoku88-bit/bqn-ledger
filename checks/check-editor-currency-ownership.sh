#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

if rg -n 'registry_value|currency ← "JPY"|CurrencyFrom' \
  src/application/editor_currency.bqn >/dev/null; then
  echo 'FAIL: editor currency owner gained old runtime or source-currency fallback' >&2; exit 1
fi

# Commands that observe currency policy must do so through the application owner.
# Pure validate.bqn is intentionally absent: callers pass an already-admitted policy.
for file in \
  src_edit/account_add_cmd.bqn src_edit/budget_add_cmd.bqn \
  src_edit/journal_block_add_cmd.bqn src_edit/journal_native_source_check.bqn \
  src_edit/plan_add_cmd.bqn src_edit/plan_edit_cmd.bqn \
  src_edit/plan_finish_cmd.bqn; do
  grep -Fq 'src/application/editor_currency.bqn' "$file" \
    || { echo "FAIL: expected editor currency consumer not migrated: $file" >&2; exit 1; }
done

if grep -Fq 'src/application/editor_currency.bqn' src_edit/validate.bqn; then
  echo 'FAIL: pure validation regained editor currency observation' >&2; exit 1
fi

bqn tests/test_application_editor_currency.bqn >/dev/null

echo 'check-editor-currency-ownership: OK'
