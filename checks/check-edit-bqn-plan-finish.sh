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
assert_sha() {
  local file="$1" expected="$2" label="$3"
  [[ "$(sha_file "$file")" == "$expected" ]] || { echo "FAIL: $label changed $file" >&2; exit 1; }
}

# Dry-run observes canonical Plan + Actual only and publishes nothing.
dry="$tmp_root/dry"
copy_fixture "$dry"
plan_before="$(sha_file "$dry/plan.journal")"
actual_before="$(sha_file "$dry/actual.journal")"
legacy_before="$(sha_file "$dry/plan.tsv")"
./tools/edit --base "$dry" plan finish \
  --id plan-rent-daily-target --actual-date 2026-01-16 --actual-amount 180 --dry-run \
  >"$tmp_root/dry.out"
assert_sha "$dry/plan.journal" "$plan_before" 'Plan Finish dry-run Plan'
assert_sha "$dry/actual.journal" "$actual_before" 'Plan Finish dry-run Actual'
assert_sha "$dry/plan.tsv" "$legacy_before" 'Plan Finish dry-run legacy Plan'
assert_no_backup "$dry" 'Plan Finish dry-run'
grep -F 'Plan ID: plan-rent-daily-target' "$tmp_root/dry.out" >/dev/null
grep -F '; plan-id: plan-rent-daily-target' "$tmp_root/dry.out" >/dev/null

# Canonical completion changes Actual only, preserves Posting order/signs, and
# persists plan-id rather than the ephemeral transport event-id.
apply="$tmp_root/apply"
copy_fixture "$apply"
plan_before="$(sha_file "$apply/plan.journal")"
legacy_before="$(sha_file "$apply/plan.tsv")"
./tools/edit --base "$apply" plan finish \
  --id plan-rent-daily-target --actual-date 2026-01-16 --actual-amount 180 \
  --apply --yes --post-check none >"$tmp_root/apply.out"
assert_sha "$apply/plan.journal" "$plan_before" 'Plan Finish apply Plan'
assert_sha "$apply/plan.tsv" "$legacy_before" 'Plan Finish apply legacy Plan'
grep -F 'Mandatory Plan completion validation: OK' "$tmp_root/apply.out" >/dev/null
grep -Fx '2026-01-16 * rent' "$apply/actual.journal" >/dev/null
grep -F '    ; plan-id: plan-rent-daily-target' "$apply/actual.journal" >/dev/null
grep -F '    expenses:food    180 JPY' "$apply/actual.journal" >/dev/null
grep -F '    assets:cash    -180 JPY' "$apply/actual.journal" >/dev/null
! grep -F 'event-id: completion-plan-rent-daily-target-2026-01-16' "$apply/actual.journal" >/dev/null
find "$apply/.backup" -type f -name 'actual.journal.*.bak' | grep -q .
bqn src_edit/plan_finish_validate_cmd.bqn "$apply" plan-rent-daily-target 2026-01-16 >/dev/null
if ./tools/edit --base "$apply" plan finish \
  --id plan-rent-daily-target --actual-date 2026-01-17 --apply --yes --post-check none \
  >"$tmp_root/duplicate.out" 2>&1; then
  echo 'FAIL: already completed Plan was completed twice' >&2
  exit 1
fi

# No override preserves exact Plan Posting texts and order.
original="$tmp_root/original"
copy_fixture "$original"
./tools/edit --base "$original" plan finish \
  --id plan-income-next --actual-date 2026-02-02 --apply --yes --post-check none >/dev/null
grep -Fx '2026-02-02 * next-income' "$original/actual.journal" >/dev/null
grep -F '    income:salary    -1000 JPY' "$original/actual.journal" >/dev/null
grep -F '    assets:cash    1000 JPY' "$original/actual.journal" >/dev/null

# Multi-Posting Plan completion preserves all Postings when no amount override is supplied.
multi="$tmp_root/multi"
copy_fixture "$multi"
cat >>"$multi/plan.journal" <<'JOURNAL'

2026-03-01 split-plan
    ; plan-id: plan-split-finish
  assets:cash  -30 JPY
  expenses:food  20 JPY
  expenses:transport  10 JPY
JOURNAL
./tools/edit --base "$multi" plan finish \
  --id plan-split-finish --actual-date 2026-03-02 --apply --yes --post-check none >/dev/null
grep -Fx '2026-03-02 * split-plan' "$multi/actual.journal" >/dev/null
grep -F '    assets:cash    -30 JPY' "$multi/actual.journal" >/dev/null
grep -F '    expenses:food    20 JPY' "$multi/actual.journal" >/dev/null
grep -F '    expenses:transport    10 JPY' "$multi/actual.journal" >/dev/null

multi_override="$tmp_root/multi-override"
copy_fixture "$multi_override"
cat >>"$multi_override/plan.journal" <<'JOURNAL'

2026-03-01 split-plan
    ; plan-id: plan-split-finish
  assets:cash  -30 JPY
  expenses:food  20 JPY
  expenses:transport  10 JPY
JOURNAL
multi_actual_before="$(sha_file "$multi_override/actual.journal")"
if ./tools/edit --base "$multi_override" plan finish \
  --id plan-split-finish --actual-date 2026-03-02 --actual-amount 40 \
  --apply --yes --post-check none >"$tmp_root/multi-override.out" 2>&1; then
  echo 'FAIL: multi-Posting Plan accepted amount override' >&2
  exit 1
fi
assert_sha "$multi_override/actual.journal" "$multi_actual_before" 'multi-Posting override rejection'
assert_no_backup "$multi_override" 'multi-Posting override rejection'

expect_fail_closed() {
  local name="$1"; shift
  local base="$tmp_root/fail-$name" out="$tmp_root/fail-$name.out"
  copy_fixture "$base"
  local plan_before actual_before legacy_before
  plan_before="$(sha_file "$base/plan.journal")"
  actual_before="$(sha_file "$base/actual.journal")"
  legacy_before="$(sha_file "$base/plan.tsv")"
  if ./tools/edit --base "$base" plan finish "$@" >"$out" 2>&1; then
    echo "FAIL: canonical Plan Finish accepted negative case: $name" >&2
    cat "$out" >&2
    exit 1
  fi
  assert_sha "$base/plan.journal" "$plan_before" "$name Plan"
  assert_sha "$base/actual.journal" "$actual_before" "$name Actual"
  assert_sha "$base/plan.tsv" "$legacy_before" "$name legacy Plan"
  assert_no_backup "$base" "$name"
}

expect_fail_closed completed \
  --id plan-food-2026-01 --actual-date 2026-01-21 --apply --yes --post-check none
expect_fail_closed missing \
  --id plan-not-found --actual-date 2026-01-21 --apply --yes --post-check none
expect_fail_closed bad-index \
  --index 99 --actual-date 2026-01-21 --apply --yes --post-check none
expect_fail_closed bad-date \
  --id plan-rent-daily-target --actual-date not-a-date --apply --yes --post-check none
expect_fail_closed bad-amount \
  --id plan-rent-daily-target --actual-date 2026-01-21 --actual-amount 12x --apply --yes --post-check none
expect_fail_closed zero-amount \
  --id plan-rent-daily-target --actual-date 2026-01-21 --actual-amount 0 --apply --yes --post-check none
expect_fail_closed negative-amount \
  --id plan-rent-daily-target --actual-date 2026-01-21 --actual-amount -10 --apply --yes --post-check none

# Legacy Household TSVs are irrelevant to canonical completion.
no_legacy="$tmp_root/no-legacy"
copy_fixture "$no_legacy"
rm -f "$no_legacy/plan.tsv" "$no_legacy/accounts.tsv" "$no_legacy/config.tsv"
./tools/edit --base "$no_legacy" plan finish \
  --id plan-rent-daily-target --actual-date 2026-01-18 --actual-amount 181 --dry-run >/dev/null

# Old direct monolithic route cannot retain legacy Plan Finish authority.
legacy_route="$tmp_root/legacy-route"
copy_fixture "$legacy_route"
plan_before="$(sha_file "$legacy_route/plan.journal")"
actual_before="$(sha_file "$legacy_route/actual.journal")"
legacy_before="$(sha_file "$legacy_route/plan.tsv")"
if ./tools/edit-bqn --base "$legacy_route" plan finish \
  --id plan-rent-daily-target --actual-date 2026-01-18 --actual-amount 181 \
  --apply --yes --post-check none >"$tmp_root/legacy-route.out" 2>&1; then
  echo 'FAIL: legacy edit-bqn Plan Finish route remained writable' >&2
  exit 1
fi
assert_sha "$legacy_route/plan.journal" "$plan_before" 'legacy direct Plan source'
assert_sha "$legacy_route/actual.journal" "$actual_before" 'legacy direct Actual source'
assert_sha "$legacy_route/plan.tsv" "$legacy_before" 'legacy direct plan.tsv'
assert_no_backup "$legacy_route" 'legacy direct Plan Finish'

# Mandatory post-publication failure restores the exact original Actual bytes.
rollback="$tmp_root/rollback"
copy_fixture "$rollback"
plan_before="$(sha_file "$rollback/plan.journal")"
actual_before="$(sha_file "$rollback/actual.journal")"
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_PLAN_FINISH_POST_CHECK_FAIL=1 \
  ./tools/edit --base "$rollback" plan finish \
    --id plan-rent-daily-target --actual-date 2026-01-18 --actual-amount 182 \
    --apply --yes --post-check none >"$tmp_root/rollback.out" 2>&1; then
  echo 'FAIL: forced Plan Finish post-admission failure succeeded' >&2
  exit 1
fi
assert_sha "$rollback/plan.journal" "$plan_before" 'Plan Finish rollback Plan'
assert_sha "$rollback/actual.journal" "$actual_before" 'Plan Finish rollback Actual'
grep -F 'Rollback: restored original Actual bytes' "$tmp_root/rollback.out" >/dev/null

# If Plan changes after intent preparation, the fence rejects before Actual publication.
race="$tmp_root/race"
copy_fixture "$race"
race_actual_before="$(sha_file "$race/actual.journal")"
HOOK_PLAN_PATH="$race/plan.journal"
export HOOK_PLAN_PATH
mutate_plan_before_finish_append() { printf '\n; concurrent Plan change\n' >>"$HOOK_PLAN_PATH"; }
export -f mutate_plan_before_finish_append
if BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_BEFORE_PLAN_FINISH_APPEND_HOOK=mutate_plan_before_finish_append \
  ./tools/edit --base "$race" plan finish \
    --id plan-rent-daily-target --actual-date 2026-01-18 --actual-amount 183 \
    --apply --yes --post-check none >"$tmp_root/race.out" 2>&1; then
  echo 'FAIL: Plan Finish published from a stale Plan observation' >&2
  exit 1
fi
assert_sha "$race/actual.journal" "$race_actual_before" 'Plan race fence Actual'
assert_no_backup "$race" 'Plan race fence'
grep -F 'snapshot mismatch' "$tmp_root/race.out" >/dev/null

if rg -n 'plan\.tsv|accounts\.tsv|config\.tsv|DefaultPlanFile|DefaultAccountsFile|editor_accounts|system_defaults\.bqn' \
  src_edit/plan_finish_cmd.bqn src_edit/plan_finish_validate_cmd.bqn >/dev/null; then
  echo 'FAIL: canonical Plan Finish semantic owners still depend on legacy Household routing' >&2
  exit 1
fi

echo 'check-edit-bqn-plan-finish: OK'