#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

bqn tests/test_ledger_account_admission.bqn >/dev/null
bqn tests/test_ledger_journal_transaction_structure.bqn >/dev/null
bqn tests/test_ledger_issue_admission.bqn >/dev/null
bqn tests/test_ledger_facts.bqn >/dev/null
bqn tests/test_report_json_text.bqn >/dev/null
bqn tests/test_report_catalog_request.bqn >/dev/null
bqn tests/test_report_composition.bqn >/dev/null
bash checks/check-report-destination-composition.sh >/dev/null
bqn tests/test_ledger_companion_facts.bqn >/dev/null
bqn tests/test_ledger_config_cycle_admission.bqn >/dev/null
bqn tests/test_accounting_account_period.bqn >/dev/null
bqn tests/test_accounting_account_balance.bqn >/dev/null
bqn tests/test_accounting_cycle_resolution.bqn >/dev/null
bqn tests/test_accounting_cycle_account_period.bqn >/dev/null
bqn tests/test_accounting_cycle_comparison.bqn >/dev/null
bqn tests/test_accounting_plan_completion_join.bqn >/dev/null
bqn tests/test_accounting_envelope_backing.bqn >/dev/null
bqn tests/test_accounting_daily_target.bqn >/dev/null
bqn tests/test_accounting_recent_transactions.bqn >/dev/null
bqn tests/test_accounting_date_category_flow.bqn >/dev/null
bqn tests/test_accounting_month_category_flow.bqn >/dev/null
bqn tests/test_accounting_month_account_movement.bqn >/dev/null
bqn tests/test_accounting_sparse_group.bqn >/dev/null
bqn tests/test_accounting_matrix_result.bqn >/dev/null
bqn tests/test_accounting_sparse_pivot.bqn >/dev/null
bqn tests/test_section_trial_balance.bqn >/dev/null
bqn tests/test_section_daily_flow.bqn >/dev/null
bqn tests/test_section_account_balances.bqn >/dev/null
bqn tests/test_section_planned_payments.bqn >/dev/null
bqn tests/test_section_recent_journal.bqn >/dev/null
bqn tests/test_section_cycle_accounts.bqn >/dev/null
bqn tests/test_section_cycle_comparison.bqn >/dev/null
bqn tests/test_section_envelope_backing.bqn >/dev/null
bqn tests/test_section_daily_target.bqn >/dev/null
bqn tests/test_section_issues.bqn >/dev/null
bqn tests/test_section_monthly_accounts.bqn >/dev/null

if rg -n '•Import ".*(src_next|src_edit|context\.bqn|report\.bqn|journal_profile)' src/ledger src/accounting src/sections src/report; then
  echo "FAIL: destination ledger facts import an old runtime/shape" >&2
  exit 1
fi

if rg -n '•FChars|•SH|ReadLines|ReadRaw|BuildContext|BuildAll' src/ledger src/accounting src/sections src/report; then
  echo "FAIL: destination ledger fact core performs I/O or builds a broad context" >&2
  exit 1
fi

echo "check-ledger-facts: OK"
