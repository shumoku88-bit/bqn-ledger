#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
fixture="$ROOT_DIR/fixtures/ledger-facts-phase1-proof"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }
copy_fixture() {
  local dest="$1"
  mkdir -p "$dest"
  cp -R "$fixture"/. "$dest"/
}
assert_no_backup() {
  local base="$1" label="$2"
  if [[ -d "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup" >&2
    exit 1
  fi
}
assert_plan_unchanged() {
  local base="$1" before="$2" label="$3"
  [[ "$(sha_file "$base/plan.journal")" == "$before" ]] || { echo "FAIL: $label modified plan.journal" >&2; exit 1; }
}
assert_legacy_plan_unchanged() {
  local base="$1" before="$2" label="$3"
  [[ "$(sha_file "$base/plan.tsv")" == "$before" ]] || { echo "FAIL: $label modified legacy plan.tsv" >&2; exit 1; }
}

# Dry-run publishes no bytes and does not consult legacy config for currency.
dry="$tmp_root/dry"
copy_fixture "$dry"
printf 'DEFAULT_CURRENCY=USD\n' >"$dry/config.tsv"
dry_before="$(sha_file "$dry/plan.journal")"
dry_legacy_before="$(sha_file "$dry/plan.tsv")"
./tools/edit --base "$dry" plan add \
  --date 2026-06-30 --memo 'canonical plan dry-run' \
  --from assets:cash --to expenses:food --amount 301 \
  --meta series=canonical-plan --dry-run >"$tmp_root/dry.out"
assert_plan_unchanged "$dry" "$dry_before" 'plan add dry-run'
assert_legacy_plan_unchanged "$dry" "$dry_legacy_before" 'plan add dry-run'
assert_no_backup "$dry" 'plan add dry-run'
grep -F 'plan.journal' "$tmp_root/dry.out" >/dev/null

# Generated ID, shared canonical block shape, backup, and mandatory admission.
base="$tmp_root/generated"
copy_fixture "$base"
legacy_before="$(sha_file "$base/plan.tsv")"
./tools/edit --base "$base" plan add \
  --date 2026-06-30 --memo 'canonical plan generated' \
  --from assets:cash --to expenses:food --amount 302 \
  --meta series=canonical-plan-generated --yes --post-check none >"$tmp_root/generated.out"
grep -F 'Mandatory Plan validation: OK' "$tmp_root/generated.out" >/dev/null
grep -Fx '2026-06-30 canonical plan generated' "$base/plan.journal" >/dev/null
grep -F '  ; plan-id: plan-2026-06-30-canonical-plan-generated' "$base/plan.journal" >/dev/null
grep -F '  ; series: canonical-plan-generated' "$base/plan.journal" >/dev/null
grep -F '  assets:cash  -302 JPY' "$base/plan.journal" >/dev/null
grep -F '  expenses:food  302 JPY' "$base/plan.journal" >/dev/null
find "$base/.backup" -type f -name 'plan.journal.*.bak' | grep -q .
assert_legacy_plan_unchanged "$base" "$legacy_before" 'canonical Plan append'
bqn src_edit/plan_validate_cmd.bqn "$base" >/dev/null

# Same generated identity receives the deterministic collision suffix.
./tools/edit --base "$base" plan add \
  --date 2026-06-30 --memo 'canonical plan generated' \
  --from assets:cash --to expenses:food --amount 303 \
  --meta series=canonical-plan-generated --yes --post-check none >/dev/null
grep -F '  ; plan-id: plan-2026-06-30-canonical-plan-generated-02' "$base/plan.journal" >/dev/null

# Explicit Plan identity and underscore-to-native metadata key normalization.
explicit="$tmp_root/explicit"
copy_fixture "$explicit"
./tools/edit --base "$explicit" plan add \
  --date 2026-07-01 --memo 'explicit plan' \
  --from assets:cash --to expenses:transport --amount 45 \
  --id plan-2026-07-01-explicit \
  --meta due_on=2026-07-02 --yes --post-check lint >/dev/null
grep -F '  ; plan-id: plan-2026-07-01-explicit' "$explicit/plan.journal" >/dev/null
grep -F '  ; due-on: 2026-07-02' "$explicit/plan.journal" >/dev/null

# Source with no final newline still receives one separated canonical block.
no_nl="$tmp_root/no-newline"
copy_fixture "$no_nl"
perl -0pi -e 's/\n\z//' "$no_nl/plan.journal"
./tools/edit --base "$no_nl" plan add \
  --date 2026-07-03 --memo 'no trailing newline' \
  --from assets:cash --to expenses:food --amount 46 \
  --id plan-2026-07-03-no-newline --yes --post-check none >/dev/null
bqn src_edit/plan_validate_cmd.bqn "$no_nl" >/dev/null

expect_fail_closed() {
  local name="$1"; shift
  local fail_base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$fail_base"
  local before legacy_before
  before="$(sha_file "$fail_base/plan.journal")"
  legacy_before="$(sha_file "$fail_base/plan.tsv")"
  if ./tools/edit --base "$fail_base" plan add "$@" >"$out" 2>&1; then
    echo "FAIL: plan add accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_plan_unchanged "$fail_base" "$before" "$name"
  assert_legacy_plan_unchanged "$fail_base" "$legacy_before" "$name"
  assert_no_backup "$fail_base" "$name"
}

expect_fail_closed empty-description \
  --date 2026-07-04 --memo '' --from assets:cash --to expenses:food --amount 47 --yes --post-check none
expect_fail_closed meta-plan-id \
  --date 2026-07-04 --memo bad --from assets:cash --to expenses:food --amount 47 \
  --meta plan_id=plan-2026-07-04-bad --yes --post-check none
expect_fail_closed invalid-explicit-id \
  --date 2026-07-04 --memo bad --from assets:cash --to expenses:food --amount 47 \
  --id not-a-plan-id --yes --post-check none
expect_fail_closed unknown-account \
  --date 2026-07-04 --memo bad --from assets:not-found --to expenses:food --amount 47 --yes --post-check none
expect_fail_closed mismatched-explicit-currency \
  --date 2026-07-04 --memo bad --from assets:cash --to expenses:food --amount 47 \
  --currency USD --yes --post-check none

# The old monolithic direct route cannot publish plan.tsv after the canonical cutover.
legacy_route="$tmp_root/legacy-route"
copy_fixture "$legacy_route"
legacy_plan_before="$(sha_file "$legacy_route/plan.tsv")"
canonical_before="$(sha_file "$legacy_route/plan.journal")"
if ./tools/edit-bqn --base "$legacy_route" plan add \
  --date 2026-07-05 --memo 'legacy route' --from assets:cash --to expenses:food --amount 48 \
  --yes --post-check none >"$tmp_root/legacy-route.out" 2>&1; then
  echo 'FAIL: legacy edit-bqn Plan Add route remained writable' >&2
  exit 1
fi
assert_plan_unchanged "$legacy_route" "$canonical_before" 'legacy edit-bqn route'
assert_legacy_plan_unchanged "$legacy_route" "$legacy_plan_before" 'legacy edit-bqn route'
assert_no_backup "$legacy_route" 'legacy edit-bqn route'

# Mandatory canonical post-admission failure restores the exact original bytes.
rollback="$tmp_root/rollback"
copy_fixture "$rollback"
rollback_before="$(sha_file "$rollback/plan.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_PLAN_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" plan add \
    --date 2026-07-06 --memo rollback --from assets:cash --to expenses:food --amount 49 \
    --id plan-2026-07-06-rollback --yes --post-check none >"$tmp_root/rollback.out" 2>&1; then
  echo 'FAIL: forced Plan post-admission failure succeeded' >&2
  exit 1
fi
assert_plan_unchanged "$rollback" "$rollback_before" 'Plan rollback'
grep -F 'Rollback: restored original bytes' "$tmp_root/rollback.out" >/dev/null

if rg -n 'plan\.tsv|config\.tsv|editor_accounts|DefaultPlanFile|DefaultAccountsFile' \
  src_edit/plan_add_cmd.bqn tools/plan-add >/dev/null; then
  echo 'FAIL: canonical Plan Add still depends on legacy Plan/Account/config source routing' >&2
  exit 1
fi

echo 'check-edit-bqn-plan-add: OK'