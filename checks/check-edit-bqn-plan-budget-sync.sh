#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"; unset LEDGER_DATA_DIR

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
base="$tmp/base"; mkdir "$base"
printf '%s\n' \
  $'assets:bank\trole=asset\ttype=liquid\tcurrency=JPY' \
  $'expenses:fixed\trole=expense\tspend_class=fixed\tcurrency=JPY' \
  $'expenses:variable\trole=expense\tspend_class=variable\tbudget=daily\tcurrency=JPY' \
  $'budget:fixed\trole=budget\tkind=envelope\tenvelope_role=execution\tcurrency=JPY' \
  $'budget:daily\trole=budget\tkind=envelope\tenvelope_role=dynamic\tcurrency=JPY' \
  $'budget:opening\trole=budget\tkind=opening\tcurrency=JPY' \
  $'budget:unassigned\trole=budget\tkind=unassigned\tenvelope_role=unassigned\tcurrency=JPY' \
  $'budget:spent\trole=budget\tkind=spent\tcurrency=JPY' >"$base/accounts.tsv"
printf '%s\n' \
  $'2026-07-20\tfixed bill\tassets:bank\texpenses:fixed\t1000\tplan_id=plan-2026-07-20-fixed\tcurrency=JPY' \
  $'2026-07-20\tvariable\tassets:bank\texpenses:variable\t200\tplan_id=plan-2026-07-20-variable\tcurrency=JPY' >"$base/plan.tsv"
cat >"$base/actual.journal" <<'JOURNAL'
commodity JPY

account assets:bank
    ; role: asset

account expenses:fixed
    ; role: expense

account expenses:variable
    ; role: expense

2026-07-14 * fixed bill
    ; plan-id: plan-2026-07-20-fixed
    assets:bank       -900 JPY
    expenses:fixed     900 JPY

2026-07-14 * variable
    ; plan-id: plan-2026-07-20-variable
    assets:bank          -200 JPY
    expenses:variable     200 JPY
JOURNAL
: >"$base/budget_alloc.tsv"; printf '%s\n' $'2026-06-15\tcycle\t2026-08-15' >"$base/cycle.tsv"
cp config/default_config.tsv "$base/config.tsv"
python3 - "$base/config.tsv" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); s=p.read_text()
s=s.replace('EXECUTION_PLANNED_PAYMENTS_ENVELOPE=', 'EXECUTION_PLANNED_PAYMENTS_ENVELOPE=fixed')
s=s.replace('BUDGET_ID_UNASSIGNED=none', 'BUDGET_ID_UNASSIGNED=budget:unassigned')
p.write_text(s)
PY

before="$(shasum -a 256 "$base/budget_alloc.tsv" | awk '{print $1}')"
out="$(tools/edit --base "$base" plan budget-sync --id plan-2026-07-20-fixed --dry-run)"
grep -Fq $'budget:fixed\tbudget:spent\t900\tplan_id=plan-2026-07-20-fixed\tcurrency=JPY' <<<"$out"
[[ "$before" == "$(shasum -a 256 "$base/budget_alloc.tsv" | awk '{print $1}')" ]]

legacy="$tmp/legacy"; cp -R "$base" "$legacy"
printf '%s\n' $'2026-07-14\tmanual sync\tbudget:fixed\tbudget:spent\t900\tcurrency=JPY' >>"$legacy/budget_alloc.tsv"
set +e
legacy_out="$(tools/edit --base "$legacy" plan budget-sync --id plan-2026-07-20-fixed --dry-run 2>&1)"; legacy_rc=$?
set -e
[[ "$legacy_rc" -ne 0 ]]; grep -Fq 'possible existing budget companion lacks plan_id' <<<"$legacy_out"

pending="$tmp/pending"; cp -R "$base" "$pending"
mutate_budget_sync_target() { printf '%s\n' '# concurrent writer' >>"$SYNC_TARGET"; }
export -f mutate_budget_sync_target
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_APPEND_HOOK=mutate_budget_sync_target SYNC_TARGET="$pending/budget_alloc.tsv" \
  tools/edit --base "$pending" plan budget-sync --id plan-2026-07-20-fixed --yes --post-check none >"$tmp/pending.out" 2>&1
pending_rc=$?
set -e
[[ "$pending_rc" -ne 0 ]]
! grep -Fq 'plan_id=plan-2026-07-20-fixed' "$pending/budget_alloc.tsv"
tools/edit --base "$pending" plan budget-sync --id plan-2026-07-20-fixed --yes --post-check none >/dev/null
grep -Fq 'plan_id=plan-2026-07-20-fixed' "$pending/budget_alloc.tsv"

tools/edit --base "$base" plan budget-sync --id plan-2026-07-20-fixed --yes --post-check none >/dev/null
[[ "$(wc -l <"$base/budget_alloc.tsv" | tr -d ' ')" == 1 ]]
tools/edit --base "$base" plan budget-sync --id plan-2026-07-20-fixed --yes --post-check none | grep -Fq 'already applied'
[[ "$(wc -l <"$base/budget_alloc.tsv" | tr -d ' ')" == 1 ]]

tools/edit --base "$base" plan budget-sync --id plan-2026-07-20-variable --yes --post-check none | grep -Fq 'not linked'
[[ "$(wc -l <"$base/budget_alloc.tsv" | tr -d ' ')" == 1 ]]

awk '/^2026-07-14 \* variable$/{copy=1} copy{print}' "$base/actual.journal" >>"$base/actual.journal"
set +e
err="$(tools/edit --base "$base" plan budget-sync --id plan-2026-07-20-variable --dry-run 2>&1)"; rc=$?
set -e
[[ "$rc" -ne 0 ]]; grep -Fq 'native Journal source rejected' <<<"$err"

printf 'check-edit-bqn-plan-budget-sync: OK\n'
