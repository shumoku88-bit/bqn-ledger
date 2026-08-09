#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
copy_fixture() {
  mkdir -p "$1"; cp -R "$fixture"/. "$1"/
  rm -f "$1/accounts.tsv" "$1/budget_alloc.tsv" "$1/config.tsv"
  python3 - "$1/household.toml" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('allocation-account = "budget:food"', 'allocation-account = "budget:food"\nplan-destination-accounts = ["expenses:food"]')
p.write_text(s)
PY
}
assert_no_backup() {
  if [[ -d "$1/.backup" ]] && find "$1/.backup" -type f | grep -q .; then
    echo "FAIL: $2 created a backup" >&2; exit 1
  fi
}

# Canonical Plan/Actual/Household evidence derives one canonical movement; dry-run
# is read-only even though no legacy Budget, Account, or config TSV exists.
dry="$tmp/dry"; copy_fixture "$dry"
before="$(sha_file "$dry/budget.journal")"
tools/edit --base "$dry" plan budget-sync --id plan-food-2026-01 --dry-run >"$tmp/dry.out"
[[ "$(sha_file "$dry/budget.journal")" == "$before" ]]
assert_no_backup "$dry" dry-run
grep -F 'Plan Budget sync preview' "$tmp/dry.out" >/dev/null
grep -F '    ; plan-id: plan-food-2026-01' "$tmp/dry.out" >/dev/null
grep -F '    ; actual-event-id: proof-food-1' "$tmp/dry.out" >/dev/null
grep -F '    budget:food    -20 JPY' "$tmp/dry.out" >/dev/null
grep -F '    budget:spent    20 JPY' "$tmp/dry.out" >/dev/null

# Apply, mandatory narrow/Household validation, and exact idempotent retry all use
# the same Budget publication authority as Budget Add.
apply="$tmp/apply"; copy_fixture "$apply"
tools/edit --base "$apply" plan budget-sync --id plan-food-2026-01 --yes --post-check none >"$tmp/apply.out"
grep -Fx '2026-01-10 Plan completion Budget sync: plan-food-2026-01' "$apply/budget.journal" >/dev/null
grep -F 'Mandatory Budget validation: OK' "$tmp/apply.out" >/dev/null
bqn src_edit/budget_validate_cmd.bqn "$apply" >/dev/null
tools/ledger-check "$apply" >/dev/null
after="$(sha_file "$apply/budget.journal")"
tools/edit-bqn --base "$apply" plan budget-sync --id plan-food-2026-01 --yes --post-check none >"$tmp/retry.out"
grep -F 'Budget sync already applied' "$tmp/retry.out" >/dev/null
[[ "$(sha_file "$apply/budget.journal")" == "$after" ]]

# A Plan without an admitted Household destination coordinate is not linked. It
# requires valid completion evidence first, so append a synthetic canonical pair.
unlinked="$tmp/unlinked"; copy_fixture "$unlinked"
cat >>"$unlinked/plan.journal" <<'PLAN'

2026-01-22 transport-plan
  ; plan-id: plan-transport-2026-01
  expenses:transport  7 JPY
  assets:cash  -7 JPY
PLAN
cat >>"$unlinked/actual.journal" <<'ACTUAL'

2026-01-21 * completed transport plan
    ; event-id: proof-transport-1
    ; layer: actual
    ; plan-id: plan-transport-2026-01
    expenses:transport 7 JPY
    assets:cash -7 JPY
ACTUAL
before="$(sha_file "$unlinked/budget.journal")"
tools/edit --base "$unlinked" plan budget-sync --id plan-transport-2026-01 --yes --post-check none >"$tmp/unlinked.out"
grep -F 'Budget sync not linked' "$tmp/unlinked.out" >/dev/null
[[ "$(sha_file "$unlinked/budget.journal")" == "$before" ]]
assert_no_backup "$unlinked" not-linked

# A stale source observation fails before publication and leaves no backup.
stale="$tmp/stale"; copy_fixture "$stale"
before="$(sha_file "$stale/budget.journal")"
HOOK_ACCOUNTS_PATH="$stale/accounts.journal"; export HOOK_ACCOUNTS_PATH
mutate_budget_sync_observation() { printf '\n; concurrent Account change\n' >>"$HOOK_ACCOUNTS_PATH"; }
export -f mutate_budget_sync_observation
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_BUDGET_APPEND_HOOK=mutate_budget_sync_observation \
  tools/edit --base "$stale" plan budget-sync --id plan-food-2026-01 --yes --post-check none >"$tmp/stale.out" 2>&1; then
  echo 'FAIL: stale Plan Budget sync published' >&2; exit 1
fi
[[ "$(sha_file "$stale/budget.journal")" == "$before" ]]
assert_no_backup "$stale" stale

# Post-write failure restores exact original bytes; guarded rollback remains in
# the shared Budget authority rather than a Plan-owned writer.
rollback="$tmp/rollback"; copy_fixture "$rollback"
before="$(sha_file "$rollback/budget.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_BUDGET_POST_CHECK_FAIL=1 \
  tools/edit --base "$rollback" plan budget-sync --id plan-food-2026-01 --yes --post-check none >"$tmp/rollback.out" 2>&1; then
  echo 'FAIL: forced Plan Budget sync post-check failure succeeded' >&2; exit 1
fi
[[ "$(sha_file "$rollback/budget.journal")" == "$before" ]]
grep -F 'Rollback: restored original Budget bytes' "$tmp/rollback.out" >/dev/null

if rg -n 'budget_alloc\.tsv|accounts\.tsv|config\.tsv|DefaultBudgetAllocFile|editor_plan_budget_config|system_defaults\.bqn' \
  src_edit/plan_budget_sync_cmd.bqn src_edit/budget_movement_candidate.bqn tools/budget-write >/dev/null; then
  echo 'FAIL: canonical Budget sync retains a legacy Household dependency' >&2; exit 1
fi

printf 'check-edit-bqn-plan-budget-sync: OK\n'
