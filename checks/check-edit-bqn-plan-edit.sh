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
assert_unchanged() {
  local file="$1" before="$2" label="$3"
  [[ "$(sha_file "$file")" == "$before" ]] || { echo "FAIL: $label modified $file" >&2; exit 1; }
}

# Date-only edit must preserve every non-date byte in the target source.
date_base="$tmp_root/date"
copy_fixture "$date_base"
legacy_before="$(sha_file "$date_base/plan.tsv")"
cp "$date_base/plan.journal" "$tmp_root/date.expected"
perl -0pi -e 's/^2026-01-15 rent$/2026-01-18 rent/m' "$tmp_root/date.expected"
./tools/edit --base "$date_base" plan edit \
  --id plan-rent-daily-target --date 2026-01-18 --yes --post-check none >"$tmp_root/date.out"
cmp "$date_base/plan.journal" "$tmp_root/date.expected"
assert_unchanged "$date_base/plan.tsv" "$legacy_before" 'date-only canonical Plan edit'
grep -F 'Mandatory Plan validation: OK' "$tmp_root/date.out" >/dev/null
find "$date_base/.backup" -type f -name 'plan.journal.*.bak' | grep -q .

# Amount-only edit preserves metadata/comment lines and Posting order/signs.
amount_base="$tmp_root/amount"
copy_fixture "$amount_base"
cp "$amount_base/plan.journal" "$tmp_root/amount.expected"
perl -0pi -e 's/^  expenses:food  200 JPY$/    expenses:food    333 JPY/m; s/^  assets:cash  -200 JPY$/    assets:cash    -333 JPY/m' "$tmp_root/amount.expected"
./tools/edit --base "$amount_base" plan edit \
  --id plan-rent-daily-target --amount 333 --yes --post-check none >/dev/null
cmp "$amount_base/plan.journal" "$tmp_root/amount.expected"
grep -F '  ; daily-target-id: rent' "$amount_base/plan.journal" >/dev/null
grep -F '  ; reservation-id: reservation:rent' "$amount_base/plan.journal" >/dev/null

# Date + amount edit changes only the admitted header and two Posting source lines.
both_base="$tmp_root/both"
copy_fixture "$both_base"
cp "$both_base/plan.journal" "$tmp_root/both.expected"
perl -0pi -e 's/^2026-01-15 rent$/2026-01-19 rent/m; s/^  expenses:food  200 JPY$/    expenses:food    444 JPY/m; s/^  assets:cash  -200 JPY$/    assets:cash    -444 JPY/m' "$tmp_root/both.expected"
./tools/edit --base "$both_base" plan edit \
  --id plan-rent-daily-target --date 2026-01-19 --amount 444 --yes --post-check none >/dev/null
cmp "$both_base/plan.journal" "$tmp_root/both.expected"

# Index selection is over open canonical Plans in source order; completed food-plan is skipped.
index_base="$tmp_root/index"
copy_fixture "$index_base"
./tools/edit --base "$index_base" plan edit --index 2 --date 2026-02-03 --yes --post-check none >/dev/null
grep -Fx '2026-02-03 next-income' "$index_base/plan.journal" >/dev/null

# Multi-Posting Plan permits date edit but not amount edit.
multi_base="$tmp_root/multi"
copy_fixture "$multi_base"
cat >>"$multi_base/plan.journal" <<'JOURNAL'

2026-03-01 split-plan
    ; plan-id: plan-split-edit
  assets:cash  -30 JPY
  expenses:food  20 JPY
  expenses:transport  10 JPY
JOURNAL
./tools/edit --base "$multi_base" plan edit --id plan-split-edit --date 2026-03-02 --yes --post-check none >/dev/null
grep -Fx '2026-03-02 split-plan' "$multi_base/plan.journal" >/dev/null
multi_before="$(sha_file "$multi_base/plan.journal")"
if ./tools/edit --base "$multi_base" plan edit --id plan-split-edit --amount 40 --yes --post-check none >"$tmp_root/multi-amount.out" 2>&1; then
  echo 'FAIL: multi-Posting Plan accepted amount edit' >&2
  exit 1
fi
assert_unchanged "$multi_base/plan.journal" "$multi_before" 'multi-Posting amount rejection'

expect_fail_closed() {
  local name="$1"; shift
  local base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$base"
  local before legacy_before
  before="$(sha_file "$base/plan.journal")"
  legacy_before="$(sha_file "$base/plan.tsv")"
  if ./tools/edit --base "$base" plan edit "$@" >"$out" 2>&1; then
    echo "FAIL: canonical Plan Edit accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_unchanged "$base/plan.journal" "$before" "$name"
  assert_unchanged "$base/plan.tsv" "$legacy_before" "$name legacy Plan"
  assert_no_backup "$base" "$name"
}

expect_fail_closed closed-plan \
  --id plan-food-2026-01 --date 2026-01-22 --yes --post-check none
expect_fail_closed closed-plan-all \
  --all --id plan-food-2026-01 --date 2026-01-22 --yes --post-check none
expect_fail_closed missing-id \
  --id plan-not-found --date 2026-01-22 --yes --post-check none
expect_fail_closed invalid-index \
  --index 99 --date 2026-01-22 --yes --post-check none
expect_fail_closed no-change \
  --id plan-rent-daily-target --date 2026-01-15 --amount 200 --yes --post-check none
expect_fail_closed invalid-date \
  --id plan-rent-daily-target --date not-a-date --yes --post-check none
expect_fail_closed invalid-amount \
  --id plan-rent-daily-target --amount 12x --yes --post-check none
expect_fail_closed nonpositive-amount \
  --id plan-rent-daily-target --amount -10 --yes --post-check none

# Dry-run has no publication or backup.
dry_base="$tmp_root/dry"
copy_fixture "$dry_base"
dry_before="$(sha_file "$dry_base/plan.journal")"
./tools/edit --base "$dry_base" plan edit --id plan-rent-daily-target --date 2026-01-21 --dry-run --yes --post-check none >/dev/null
assert_unchanged "$dry_base/plan.journal" "$dry_before" 'Plan Edit dry-run'
assert_no_backup "$dry_base" 'Plan Edit dry-run'

# Old monolithic direct route cannot mutate plan.tsv after canonical cutover.
legacy_route="$tmp_root/legacy-route"
copy_fixture "$legacy_route"
legacy_before="$(sha_file "$legacy_route/plan.tsv")"
canonical_before="$(sha_file "$legacy_route/plan.journal")"
if ./tools/edit-bqn --base "$legacy_route" plan edit --id plan-rent-daily-target --date 2026-01-23 --yes --post-check none >"$tmp_root/legacy-route.out" 2>&1; then
  echo 'FAIL: legacy edit-bqn Plan Edit route remained writable' >&2
  exit 1
fi
assert_unchanged "$legacy_route/plan.tsv" "$legacy_before" 'legacy Plan Edit route'
assert_unchanged "$legacy_route/plan.journal" "$canonical_before" 'legacy Plan Edit canonical source'
assert_no_backup "$legacy_route" 'legacy Plan Edit route'

# Mandatory canonical post-admission failure restores exact original bytes.
rollback="$tmp_root/rollback"
copy_fixture "$rollback"
rollback_before="$(sha_file "$rollback/plan.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_PLAN_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" plan edit --id plan-rent-daily-target --date 2026-01-24 --yes --post-check none >"$tmp_root/rollback.out" 2>&1; then
  echo 'FAIL: forced Plan Edit post-admission failure succeeded' >&2
  exit 1
fi
assert_unchanged "$rollback/plan.journal" "$rollback_before" 'Plan Edit rollback'
grep -F 'Rollback: restored original bytes' "$tmp_root/rollback.out" >/dev/null

if rg -n 'plan\.tsv|accounts\.tsv|config\.tsv|DefaultPlanFile|DefaultAccountsFile|editor_accounts' \
  src_edit/plan_edit_cmd.bqn tools/plan-edit >/dev/null; then
  echo 'FAIL: canonical Plan Edit still depends on legacy source routing' >&2
  exit 1
fi

echo 'check-edit-bqn-plan-edit: OK'