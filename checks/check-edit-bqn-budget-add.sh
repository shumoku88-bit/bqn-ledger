#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
copy_fixture() { mkdir -p "$1"; cp -R "$fixture"/. "$1"/; }
assert_sha() {
  local file="$1" expected="$2" label="$3"
  [[ "$(sha_file "$file")" == "$expected" ]] || { echo "FAIL: $label changed $file" >&2; exit 1; }
}
assert_no_backup() {
  local base="$1" label="$2"
  if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created backup" >&2
    exit 1
  fi
}

# Dry-run publishes nothing and uses the shared canonical Budget block shape.
dry="$tmp_root/dry"
copy_fixture "$dry"
budget_before="$(sha_file "$dry/budget.journal")"
legacy_before="$(sha_file "$dry/budget_alloc.tsv")"
./tools/edit --base "$dry" budget add \
  --date 2026-01-02 --memo allocate-more-food \
  --from budget:unassigned --to budget:food --amount 10 --dry-run >"$tmp_root/dry.out"
assert_sha "$dry/budget.journal" "$budget_before" 'Budget Add dry-run canonical Budget'
assert_sha "$dry/budget_alloc.tsv" "$legacy_before" 'Budget Add dry-run legacy Budget'
assert_no_backup "$dry" 'Budget Add dry-run'
grep -F 'Target: '"$dry"'/budget.journal' "$tmp_root/dry.out" >/dev/null
grep -F '    budget:unassigned    -10 JPY' "$tmp_root/dry.out" >/dev/null
grep -F '    budget:food    10 JPY' "$tmp_root/dry.out" >/dev/null

# Apply appends only canonical budget.journal and creates one canonical backup.
apply="$tmp_root/apply"
copy_fixture "$apply"
legacy_before="$(sha_file "$apply/budget_alloc.tsv")"
./tools/edit --base "$apply" budget add \
  --date 2026-01-02 --memo allocate-more-food \
  --from budget:unassigned --to budget:food --amount 11 \
  --yes --post-check none >"$tmp_root/apply.out"
assert_sha "$apply/budget_alloc.tsv" "$legacy_before" 'Budget Add apply legacy Budget'
grep -Fx '2026-01-02 allocate-more-food' "$apply/budget.journal" >/dev/null
grep -F '    budget:unassigned    -11 JPY' "$apply/budget.journal" >/dev/null
grep -F '    budget:food    11 JPY' "$apply/budget.journal" >/dev/null
grep -F 'Mandatory Budget validation: OK' "$tmp_root/apply.out" >/dev/null
find "$apply/.backup" -type f -name 'budget.journal.*.bak' | grep -q .
bqn src_edit/budget_validate_cmd.bqn "$apply" >/dev/null
./tools/ledger-check "$apply" >/dev/null

expect_fail_closed() {
  local name="$1"; shift
  local base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$base"
  local canonical_before legacy_before
  canonical_before="$(sha_file "$base/budget.journal")"
  legacy_before="$(sha_file "$base/budget_alloc.tsv")"
  if ./tools/edit --base "$base" budget add "$@" >"$out" 2>&1; then
    echo "FAIL: canonical Budget Add accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_sha "$base/budget.journal" "$canonical_before" "$name canonical Budget"
  assert_sha "$base/budget_alloc.tsv" "$legacy_before" "$name legacy Budget"
  assert_no_backup "$base" "$name"
}

expect_fail_closed unknown-from \
  --date 2026-01-02 --memo bad --from budget:missing --to budget:food --amount 10 --yes --post-check none
expect_fail_closed non-budget \
  --date 2026-01-02 --memo bad --from assets:cash --to budget:food --amount 10 --yes --post-check none
expect_fail_closed same-account \
  --date 2026-01-02 --memo bad --from budget:food --to budget:food --amount 10 --yes --post-check none
expect_fail_closed bad-date \
  --date not-a-date --memo bad --from budget:unassigned --to budget:food --amount 10 --yes --post-check none
expect_fail_closed bad-amount \
  --date 2026-01-02 --memo bad --from budget:unassigned --to budget:food --amount 12x --yes --post-check none
expect_fail_closed zero-amount \
  --date 2026-01-02 --memo bad --from budget:unassigned --to budget:food --amount 0 --yes --post-check none
expect_fail_closed negative-amount \
  --date 2026-01-02 --memo bad --from budget:unassigned --to budget:food --amount -10 --yes --post-check none

# Legacy Household TSVs do not participate in canonical Budget Add.
no_legacy="$tmp_root/no-legacy"
copy_fixture "$no_legacy"
rm -f "$no_legacy/budget_alloc.tsv" "$no_legacy/accounts.tsv" "$no_legacy/config.tsv"
./tools/edit --base "$no_legacy" budget add \
  --date 2026-01-02 --memo canonical-only \
  --from budget:unassigned --to budget:food --amount 12 --dry-run >/dev/null

# An already-invalid canonical Household is not a writable publication base.
invalid_household="$tmp_root/invalid-household"
copy_fixture "$invalid_household"
budget_before="$(sha_file "$invalid_household/budget.journal")"
printf '[query]\nunknown = "value"\n' >"$invalid_household/report.toml"
if ./tools/edit --base "$invalid_household" budget add \
  --date 2026-01-02 --memo invalid-household \
  --from budget:unassigned --to budget:food --amount 13 \
  --yes --post-check none >"$tmp_root/invalid-household.out" 2>&1; then
  echo 'FAIL: Budget Add published into an invalid canonical Household' >&2
  exit 1
fi
assert_sha "$invalid_household/budget.journal" "$budget_before" 'invalid Household Budget'
assert_no_backup "$invalid_household" 'invalid Household Budget'

# Mandatory post-publication failure restores exact original Budget bytes.
rollback="$tmp_root/rollback"
copy_fixture "$rollback"
budget_before="$(sha_file "$rollback/budget.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_BUDGET_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" budget add \
    --date 2026-01-02 --memo rollback \
    --from budget:unassigned --to budget:food --amount 14 \
    --yes --post-check none >"$tmp_root/rollback.out" 2>&1; then
  echo 'FAIL: forced Budget post-admission failure succeeded' >&2
  exit 1
fi
assert_sha "$rollback/budget.journal" "$budget_before" 'Budget rollback'
grep -F 'Rollback: restored original Budget bytes' "$tmp_root/rollback.out" >/dev/null

# AccountRegistry is part of the Budget candidate observation. A concurrent
# canonical Account change after preparation must fail before Budget publication.
race="$tmp_root/race"
copy_fixture "$race"
race_budget_before="$(sha_file "$race/budget.journal")"
HOOK_ACCOUNTS_PATH="$race/accounts.journal"
export HOOK_ACCOUNTS_PATH
mutate_accounts_before_budget_append() { printf '\n; concurrent Account change\n' >>"$HOOK_ACCOUNTS_PATH"; }
export -f mutate_accounts_before_budget_append
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_BUDGET_APPEND_HOOK=mutate_accounts_before_budget_append \
  ./tools/edit --base "$race" budget add \
    --date 2026-01-02 --memo raced \
    --from budget:unassigned --to budget:food --amount 15 \
    --yes --post-check none >"$tmp_root/race.out" 2>&1; then
  echo 'FAIL: Budget Add published from a stale Account observation' >&2
  exit 1
fi
assert_sha "$race/budget.journal" "$race_budget_before" 'Budget Account race fence'
assert_no_backup "$race" 'Budget Account race fence'
grep -F 'is stale; it changed during editing' "$tmp_root/race.out" >/dev/null

if rg -n 'budget_alloc\.tsv|accounts\.tsv|config\.tsv|DefaultBudgetAllocFile|DefaultAccountsFile|editor_accounts|system_defaults\.bqn' \
  src_edit/budget_add_cmd.bqn src_edit/budget_validate_cmd.bqn tools/budget-add >/dev/null; then
  echo 'FAIL: canonical Budget Add still depends on legacy Household routing' >&2
  exit 1
fi

echo 'check-edit-bqn-budget-add: OK'