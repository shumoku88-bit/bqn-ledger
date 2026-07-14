#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT_DIR"; unset LEDGER_DATA_DIR
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
make_base() {
  local b="$1"; mkdir "$b"
  printf '%s\n' \
    $'income:salary\trole=income\tcurrency=JPY' \
    $'income:refund\trole=income\tcurrency=JPY' \
    $'assets:bank\trole=asset\ttype=liquid\tcurrency=JPY' \
    $'expenses:misc\trole=expense\tspend_class=variable\tbudget=daily\tcurrency=JPY' \
    $'budget:daily\trole=budget\tkind=envelope\tenvelope_role=dynamic\tcurrency=JPY' \
    $'budget:opening\trole=budget\tkind=opening\tcurrency=JPY' \
    $'budget:unassigned\trole=budget\tkind=unassigned\tenvelope_role=unassigned\tcurrency=JPY' \
    $'budget:spent\trole=budget\tkind=spent\tcurrency=JPY' >"$b/accounts.tsv"
  : >"$b/journal.tsv"; : >"$b/budget_alloc.tsv"
  printf '%s\n' $'2026-06-15\tcycle\t2026-08-15' >"$b/cycle.tsv"
  cp config/default_config.tsv "$b/config.tsv"
  printf '%s\n' 'DEFAULT_CURRENCY=JPY' >>"$b/config.tsv"
}
base="$tmp/base"; make_base "$base"
tools/edit --base "$base" journal add --date 2026-07-14 --memo salary --from income:salary --to assets:bank --amount 1000 --meta income_budget=unassigned --yes --post-check none >/dev/null
grep -Fq $'txn_id=txn-2026-07-14-salary\tcurrency=JPY' "$base/journal.tsv"
grep -Fq $'budget:opening\tbudget:unassigned\t1000\ttxn_id=txn-2026-07-14-salary\tcurrency=JPY' "$base/budget_alloc.tsv"
[[ "$(wc -l <"$base/budget_alloc.tsv" | tr -d ' ')" == 1 ]]
tools/edit --base "$base" journal income-budget-sync --id txn-2026-07-14-salary --yes --post-check none | grep -Fq 'already applied'
[[ "$(wc -l <"$base/budget_alloc.tsv" | tr -d ' ')" == 1 ]]

# Same memo gets a stable collision suffix.
tools/edit --base "$base" journal add --date 2026-07-14 --memo salary --from income:salary --to assets:bank --amount 200 --meta income_budget=unassigned --yes --post-check none >/dev/null
grep -Fq 'txn_id=txn-2026-07-14-salary-02' "$base/journal.tsv"

# No explicit income-budget intent means no generated ID and no companion.
tools/edit --base "$base" journal add --date 2026-07-14 --memo refund --from income:refund --to assets:bank --amount 50 --yes --post-check none >/dev/null
! tail -n1 "$base/journal.tsv" | grep -Fq 'txn_id='

# A tagged but non-income row is rejected before either write.
bad="$tmp/bad"; make_base "$bad"
set +e
bad_out="$(tools/edit --base "$bad" journal add --date 2026-07-14 --memo bad --from assets:bank --to expenses:misc --amount 10 --meta income_budget=unassigned --yes --post-check none 2>&1)"; bad_rc=$?
set -e
[[ "$bad_rc" -ne 0 ]]; grep -Fq 'requires a from account with role=income' <<<"$bad_out"
[[ ! -s "$bad/journal.tsv" && ! -s "$bad/budget_alloc.tsv" ]]
set +e
amount_out="$(tools/edit --base "$bad" journal add --date 2026-07-14 --memo decimal --from income:salary --to assets:bank --amount 10.5 --meta income_budget=unassigned --yes --post-check none 2>&1)"; amount_rc=$?
set -e
[[ "$amount_rc" -ne 0 ]]; grep -Fq 'requires an integer budget amount' <<<"$amount_out"
[[ ! -s "$bad/journal.tsv" && ! -s "$bad/budget_alloc.tsv" ]]

# A stale budget failure remains retryable after the journal fact exists.
pending="$tmp/pending"; make_base "$pending"
printf '%s\n' $'2026-07-14\tsalary\tincome:salary\tassets:bank\t300\tincome_budget=unassigned\ttxn_id=txn-pending\tcurrency=JPY' >"$pending/journal.tsv"
mutate_income_budget() { printf '%s\n' '# concurrent writer' >>"$SYNC_TARGET"; }
export -f mutate_income_budget
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_APPEND_HOOK=mutate_income_budget SYNC_TARGET="$pending/budget_alloc.tsv" \
  tools/edit --base "$pending" journal income-budget-sync --id txn-pending --yes --post-check none >"$tmp/pending.out" 2>&1
pending_rc=$?
set -e
[[ "$pending_rc" -ne 0 ]]; ! grep -Fq 'txn_id=txn-pending' "$pending/budget_alloc.tsv"
tools/edit --base "$pending" journal income-budget-sync --id txn-pending --yes --post-check none >/dev/null
grep -Fq 'txn_id=txn-pending' "$pending/budget_alloc.tsv"

printf 'check-edit-bqn-income-budget-sync: OK\n'
