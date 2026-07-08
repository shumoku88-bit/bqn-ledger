#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# Verify BQN-backed `plan finish` append path.
# Scope:
#   - resulting journal.tsv append creates expected TSV/backup effects
#   - actual amount override changes only the journal actual row, not plan.tsv
#   - dry-run source protection
#   - negative cases fail closed without source/backup writes

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

assert_no_backup() {
  local base="$1"
  local label="$2"
  if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi
}

assert_unchanged() {
  local base="$1"
  local before_sha="$2"
  local label="$3"
  local after_sha
  after_sha="$(sha_file "$base/journal.tsv")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: $label modified journal.tsv" >&2
    exit 1
  fi
}

prepare_fixtures() {
  local base="$1"
  cp -R data "$base"
  # Valid plan with plan_id
  echo -e "2026-08-15\tTest Plan\texpenses:食費\tassets:bank\t1000\tplan_id=plan-2026-08-15-test-finish" >> "$base/plan.tsv"
  # Valid plan to test conflict/closed
  echo -e "2026-08-15\tTest Plan Closed\texpenses:食費\tassets:bank\t2000\tplan_id=plan-2026-08-15-test-closed" >> "$base/plan.tsv"
  # Already finished plan in journal
  echo -e "2026-06-29\tTest Plan Closed\texpenses:食費\tassets:bank\t2000\tplan_id=plan-2026-08-15-test-closed" >> "$base/journal.tsv"
}

run_positive_parity() {
  local name="$1"
  shift
  local bqn_base="$tmp_root/pos-$name-bqn"
  local bqn_out="$tmp_root/pos-$name-bqn.out"

  prepare_fixtures "$bqn_base"

  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1

  if ! find "$bqn_base/.backup" -type f -name 'journal.tsv*' | grep -q .; then
    echo "FAIL: tools/edit-bqn plan finish did not create a journal backup: $name" >&2
    exit 1
  fi
}

run_actual_amount_override() {
  local bqn_base="$tmp_root/actual-amount-override"
  local bqn_out="$tmp_root/actual-amount-override.out"
  local plan_before plan_after last_amount

  prepare_fixtures "$bqn_base"
  plan_before="$(sha_file "$bqn_base/plan.tsv")"

  ./tools/edit-bqn --base "$bqn_base" plan finish \
    --id plan-2026-08-15-test-finish \
    --actual-date 2026-06-29 \
    --actual-amount 1750 \
    --apply \
    --yes \
    --post-check none >"$bqn_out" 2>&1

  last_amount="$(tail -n 1 "$bqn_base/journal.tsv" | cut -f5)"
  if [ "$last_amount" != "1750" ]; then
    echo "FAIL: actual amount override was not written to journal.tsv" >&2
    tail -n 1 "$bqn_base/journal.tsv" >&2
    exit 1
  fi

  plan_after="$(sha_file "$bqn_base/plan.tsv")"
  if [ "$plan_before" != "$plan_after" ]; then
    echo "FAIL: actual amount override modified plan.tsv" >&2
    exit 1
  fi
}

run_expect_fail_closed() {
  local name="$1"
  shift
  local bqn_base="$tmp_root/neg-$name-bqn"
  local bqn_out="$tmp_root/neg-$name-bqn.out"
  local bqn_before bqn_rc

  prepare_fixtures "$bqn_base"
  bqn_before="$(sha_file "$bqn_base/journal.tsv")"

  set +e
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  bqn_rc=$?
  set -e

  if [ "$bqn_rc" -eq 0 ]; then
    echo "FAIL: tools/edit-bqn unexpectedly accepted negative case: $name" >&2
    cat "$bqn_out" >&2
    exit 1
  fi

  assert_unchanged "$bqn_base" "$bqn_before" "tools/edit-bqn negative case $name"
  assert_no_backup "$bqn_base" "tools/edit-bqn negative case $name"
}

# Dry-run protection.
dry_base="$tmp_root/dry"
prepare_fixtures "$dry_base"
dry_before="$(sha_file "$dry_base/journal.tsv")"
./tools/edit-bqn --base "$dry_base" plan finish \
  --index 2 \
  --actual-date 2026-06-29 \
  --yes \
  --post-check none >/dev/null
assert_unchanged "$dry_base" "$dry_before" "tools/edit-bqn plan finish dry-run (no --apply)"
assert_no_backup "$dry_base" "tools/edit-bqn plan finish dry-run (no --apply)"

# Positive cases.
run_positive_parity finish-by-index \
  plan finish \
  --index 2 \
  --actual-date 2026-06-29 \
  --apply \
  --yes \
  --post-check none

run_positive_parity finish-by-id \
  plan finish \
  --id plan-2026-08-15-test-finish \
  --actual-date 2026-06-29 \
  --apply \
  --yes \
  --post-check none

run_actual_amount_override

# Negative cases.
run_expect_fail_closed closed-plan \
  plan finish \
  --id plan-2026-08-15-test-closed \
  --actual-date 2026-06-29 \
  --apply \
  --yes \
  --post-check none

run_expect_fail_closed missing-id \
  plan finish \
  --index 1 \
  --actual-date 2026-06-29 \
  --apply \
  --yes \
  --post-check none

run_expect_fail_closed future-date \
  plan finish \
  --index 2 \
  --actual-date 2026-08-15 \
  --apply \
  --yes \
  --post-check none

run_expect_fail_closed invalid-index \
  plan finish \
  --index 3 \
  --actual-date 2026-06-29 \
  --apply \
  --yes \
  --post-check none

run_expect_fail_closed invalid-actual-amount \
  plan finish \
  --id plan-2026-08-15-test-finish \
  --actual-date 2026-06-29 \
  --actual-amount not-a-number \
  --apply \
  --yes \
  --post-check none

echo "check-edit-bqn-plan-finish: OK"
