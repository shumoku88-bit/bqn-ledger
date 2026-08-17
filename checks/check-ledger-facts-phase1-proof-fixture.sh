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
bqn tests/test_section_daily_flow.bqn >/dev/null
bqn tests/test_section_issues.bqn >/dev/null
bqn tests/test_report_catalog_request.bqn >/dev/null
bqn tests/test_report_composition.bqn >/dev/null
bqn tests/test_section_monthly_accounts.bqn >/dev/null
bqn tests/test_section_trial_balance.bqn >/dev/null

# Retained report surfaces use semantic coordinates and stay byte-stable against
# the same golden witness the standalone section owners already protect.
./tools/report "$base" envelopes compact JPY 2026-01-01 2026-02-01 2026-01-12 \
  | cmp - "$base/envelope_backing.destination.compact.txt"
./tools/report "$base" balances human JPY 2026-01-12 \
  | cmp - "$base/account_balances.destination.human.txt"
./tools/report "$base" recent human 2026-01-12 10 \
  | cmp - "$base/recent_journal.destination.human.txt"
./tools/report "$base" daily-flow human JPY 2026-01-01 2026-02-01 2026-01-12 \
  | cmp - "$base/daily_flow.destination.human.txt"
./tools/report "$base" planned human 2026-01-12 \
  | cmp - "$base/planned_payments.destination.human.txt"

recent=$(./tools/report "$base" recent human 2026-01-12 10)
grep -Fq 'expenses:food,expenses:transport | split purchase' <<<"$recent"
[[ $(grep -Ec '^2026-01-(02|10|12) ' <<<"$recent") -eq 3 ]]

daily=$(./tools/report "$base" daily-flow human JPY 2026-01-01 2026-02-01 2026-01-12)
grep -Fq 'date       | assets:cash/JPY | income:salary/JPY | expenses:food/JPY | expenses:transport/JPY' <<<"$daily"
grep -Fq $'2026-01-12 |             -15 |                 0 |               -10 |                     -5' <<<"$daily"

balances=$(./tools/report "$base" balances human JPY 2026-01-12)
grep -Fq 'Currency: JPY' <<<"$balances"
grep -Eq '^assets:cash/JPY        \|          965$' <<<"$balances"

planned_json=$(./tools/report "$base" planned json 2026-01-12)
destination_planned_json=$(cat "$base/planned_payments.destination.json")
[[ "$planned_json" == "$destination_planned_json" ]]
python3 -c '
import json, sys
value = json.load(sys.stdin)
assert len(value["open_items"]) == 2
assert value["current_cycle_total"] == 200
assert value["due_through_cycle_total"] == 200
assert value["overdue_total"] == 0
assert value["future_cycles_total"] == 1000
' <<<"$planned_json"

# The retained catalog exposes twelve semantic report keys; retired report
# section aliases such as trial-balance are not selectable report coordinates.
sections=$(bqn src/application/report_selection_cli.bqn all human)
[[ $(wc -l <<<"$sections" | tr -d ' ') -eq 12 ]]
grep -qx 'envelopes' <<<"$sections"
grep -qx 'balances' <<<"$sections"
grep -qx 'recent' <<<"$sections"
grep -qx 'planned' <<<"$sections"
grep -qx 'daily-flow' <<<"$sections"
! grep -qx 'trial-balance' <<<"$sections"

echo "check-ledger-facts-phase1-proof-fixture: OK"
