#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"
base="fixtures/ledger-facts-phase1-proof"

# Canonical Join/section and current Planned outputs share this strict public evidence.
bqn tests/test_accounting_plan_completion_join.bqn >/dev/null
bqn tests/test_section_planned_payments.bqn >/dev/null
bqn tests/test_section_account_balances.bqn >/dev/null
bqn tests/test_section_recent_journal.bqn >/dev/null
bqn tests/test_section_cycle_accounts.bqn >/dev/null
bqn tests/test_section_cycle_comparison.bqn >/dev/null
bqn tests/test_section_envelope_backing.bqn >/dev/null
bqn tests/test_section_daily_target.bqn >/dev/null
bqn tests/test_section_issues.bqn >/dev/null
bqn tests/test_report_catalog_request.bqn >/dev/null
bqn tests/test_section_monthly_accounts.bqn >/dev/null

audit=$(python3 tools/characterization/report_source_readiness_audit.py "$base")
grep -Fq $'\texplicit\t8\t0\t0\t1\t0\t0\t2\t0\tdirect' <<<"$audit"

trial=$(tools/report "$base" --section trial-balance --no-color)
destination_trial=$(cat "$base/trial_balance.destination.human.txt")
[[ "$trial" == "$destination_trial" ]]
grep -Eq '^assets:cash/JPY +\| +0 +\| +1000 +\| +-35 +\| +965 ' <<<"$trial"
grep -Eq '^income:salary/JPY +\| +0 +\| +0 +\| +-1000 +\| +-1000 ' <<<"$trial"
grep -Eq '^expenses:food/JPY +\| +0 +\| +30 +\| +0 +\| +30 ' <<<"$trial"
grep -Eq '^expenses:transport/JPY +\| +0 +\| +5 +\| +0 +\| +5 ' <<<"$trial"
grep -Eq '^Total +\| +0 +\| +1035 +\| +-1035 +\| +0 ' <<<"$trial"
grep -Fq 'Zero-sum check (debit=credit): OK' <<<"$trial"

recent=$(tools/report "$base" --section recent --no-color)
grep -Fq 'expenses:food,expenses:transport | split purchase' <<<"$recent"
[[ $(grep -Ec '^2026-01-(02|10|12) ' <<<"$recent") -eq 3 ]]

daily=$(tools/report "$base" --section daily-flow --no-color)
destination_daily=$(cat "$base/daily_flow.destination.human.txt")
[[ "${daily//¯/-}" == "$destination_daily" ]]
grep -Fq 'date       |     income |       food |      other |        net' <<<"$daily"
grep -Fq $'2026-01-12 |          0 |        ¯10 |         ¯5 |        ¯15' <<<"$daily"

balances=$(tools/report "$base" --section balances --no-color)
grep -Fq 'Currency view: JPY (ledger default)' <<<"$balances"
grep -Eq '^assets:cash/JPY +\| +965$' <<<"$balances"

planned_human=$(tools/report "$base" --section planned --no-color)
destination_planned_human=$(cat "$base/planned_payments.destination.human.txt")
[[ "$planned_human" == "$destination_planned_human" ]]

planned=$(tools/report "$base" --section planned --format json --no-color)
destination_planned_json=$(cat "$base/planned_payments.destination.json")
[[ "$planned" == "$destination_planned_json" ]]
python3 -c '
import json, sys
value = json.load(sys.stdin)
assert value["open_items"] == []
assert value["open_total"] == 0
assert value["completed_items"] == [{
    "date": "2026-01-20",
    "category": "food",
    "memo": "food-plan",
    "amount": 25,
    "actual_amount": 20,
    "status": "completed",
    "plan_id": "plan-food-2026-01",
}]
' <<<"$planned"

sections=$(tools/report "$base" --list-sections --no-color)
[[ $(wc -l <<<"$sections" | tr -d ' ') -eq 15 ]]
grep -q $'^trial-balance\t== Trial Balance (actual layer) ==$' <<<"$sections"
grep -q $'^daily-flow\t== Daily Flow ==$' <<<"$sections"

echo "check-ledger-facts-phase1-proof-fixture: OK"
