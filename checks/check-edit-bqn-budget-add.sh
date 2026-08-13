#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
copy_fixture() {
  mkdir -p "$1"; cp -R "$fixture"/. "$1"/
  rm -f "$1/budget_alloc.tsv" "$1/accounts.tsv" "$1/config.tsv"
}
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
./tools/edit --base "$dry" budget add \
  --date 2026-01-02 --memo allocate-more-food \
  --from budget:unassigned --to budget:food --amount 10 --dry-run >"$tmp_root/dry.out"
assert_sha "$dry/budget.journal" "$budget_before" 'Budget Add dry-run canonical Budget'
assert_no_backup "$dry" 'Budget Add dry-run'
grep -F 'Target: '"$(cd -P "$dry" && pwd)"'/budget.journal' "$tmp_root/dry.out" >/dev/null
grep -F '    budget:unassigned    -10 JPY' "$tmp_root/dry.out" >/dev/null
grep -F '    budget:food    10 JPY' "$tmp_root/dry.out" >/dev/null

# Source-ordered metadata is a regular key/value collection after admission.
# Use values admitted by the canonical Journal metadata owner; this witness
# characterizes mapping/order, not a new permissive metadata contract.
./tools/edit --base "$dry" budget add \
  --date 2026-01-02 --memo metadata-map \
  --from budget:unassigned --to budget:food --amount 10 \
  --meta note=first --meta tax=business --dry-run >"$tmp_root/meta.out"
python3 - "$tmp_root/meta.out" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
first = text.find("    ; note: first")
second = text.find("    ; tax: business")
if first < 0 or second < 0 or first >= second:
    raise SystemExit("FAIL: Budget metadata order/rendering changed")
PY
if ./tools/edit --base "$dry" budget add \
  --date 2026-01-02 --memo bad-metadata \
  --from budget:unassigned --to budget:food --amount 10 \
  --meta 'note=one=two' --dry-run >"$tmp_root/meta-bad.out" 2>&1; then
  echo 'FAIL: Budget Add accepted metadata with more than one equals sign' >&2
  exit 1
fi
grep -F 'each --meta item must contain exactly one key=value pair' "$tmp_root/meta-bad.out" >/dev/null
assert_sha "$dry/budget.journal" "$budget_before" 'Budget metadata dry-run/failure'

# Apply appends only canonical budget.journal and creates one canonical backup.
apply="$tmp_root/apply"
copy_fixture "$apply"
./tools/edit --base "$apply" budget add \
  --date 2026-01-02 --memo allocate-more-food \
  --from budget:unassigned --to budget:food --amount 11 \
  --yes --post-check none >"$tmp_root/apply.out"
grep -Fx '2026-01-02 allocate-more-food' "$apply/budget.journal" >/dev/null
grep -F '    budget:unassigned    -11 JPY' "$apply/budget.journal" >/dev/null
grep -F '    budget:food    11 JPY' "$apply/budget.journal" >/dev/null
grep -F 'Mandatory Budget validation: OK' "$tmp_root/apply.out" >/dev/null
find "$apply/.backup" -type f -name 'budget.journal.*.bak' | grep -q .
bqn src_edit/budget_validate_cmd.bqn "$apply" >/dev/null
./tools/ledger-check "$apply" >/dev/null

# Budget migration retains registry-owned exact decimals; it does not introduce
# an integer-only shortcut.
exact="$tmp_root/exact-decimal"
copy_fixture "$exact"
cat >>"$exact/accounts.journal" <<'ACCOUNTS'

account budget:usd-pool
  type: Budget
  commodity: USD

account budget:usd-envelope
  type: Budget
  commodity: USD
ACCOUNTS
./tools/edit --base "$exact" budget add \
  --date 2026-01-02 --memo exact-usd \
  --from budget:usd-pool --to budget:usd-envelope --amount 12.34 --currency USD \
  --yes --post-check none >/dev/null
grep -F '    budget:usd-pool    -12.34 USD' "$exact/budget.journal" >/dev/null
grep -F '    budget:usd-envelope    12.34 USD' "$exact/budget.journal" >/dev/null
./tools/ledger-check "$exact" >/dev/null

expect_fail_closed() {
  local name="$1"; shift
  local base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$base"
  local canonical_before
  canonical_before="$(sha_file "$base/budget.journal")"
  if ./tools/edit --base "$base" budget add "$@" >"$out" 2>&1; then
    echo "FAIL: canonical Budget Add accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_sha "$base/budget.journal" "$canonical_before" "$name canonical Budget"
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

# The fixture is canonical-only: legacy Household TSVs are absent, not merely unchanged.
canonical_only="$tmp_root/canonical-only"
copy_fixture "$canonical_only"
./tools/edit-bqn --base "$canonical_only" budget add \
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
  src_edit/budget_add_cmd.bqn src_edit/budget_movement_candidate.bqn src_edit/budget_validate_cmd.bqn tools/budget-write >/dev/null; then
  echo 'FAIL: canonical Budget Add still depends on legacy Household routing' >&2
  exit 1
fi

echo 'check-edit-bqn-budget-add: OK'
