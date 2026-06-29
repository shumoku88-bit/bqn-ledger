#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# Verify BQN-backed `plan finish` append path.
# Scope:
#   - resulting journal.tsv byte parity with Go editor
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
  local go_base="$tmp_root/pos-$name-go"
  local bqn_base="$tmp_root/pos-$name-bqn"
  local go_out="$tmp_root/pos-$name-go.out"
  local bqn_out="$tmp_root/pos-$name-bqn.out"

  prepare_fixtures "$go_base"
  prepare_fixtures "$bqn_base"

  # Go editor doesn't support --yes or --post-check for plan finish
  # We must pipe "y" to confirm the append operation.
  local go_args=()
  for arg in "$@"; do
    if [[ "$arg" != "--yes" && "$arg" != "--post-check" && "$arg" != "none" && "$arg" != "lint" && "$arg" != "full" ]]; then
      go_args+=("$arg")
    fi
  done

  echo "y" | ./tools/edit --base "$go_base" "${go_args[@]}" >"$go_out" 2>&1
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1

  if ! cmp -s "$go_base/journal.tsv" "$bqn_base/journal.tsv"; then
    echo "FAIL: tools/edit-bqn plan finish result differs from Go editor: $name" >&2
    diff -u "$go_base/journal.tsv" "$bqn_base/journal.tsv" >&2 || true
    exit 1
  fi

  if ! find "$bqn_base/.backup" -type f -name 'journal.tsv*' | grep -q .; then
    echo "FAIL: tools/edit-bqn plan finish did not create a journal backup: $name" >&2
    exit 1
  fi
}

run_expect_fail_closed() {
  local name="$1"
  shift
  local go_base="$tmp_root/neg-$name-go"
  local bqn_base="$tmp_root/neg-$name-bqn"
  local go_out="$tmp_root/neg-$name-go.out"
  local bqn_out="$tmp_root/neg-$name-bqn.out"
  local go_before bqn_before go_rc bqn_rc

  prepare_fixtures "$go_base"
  prepare_fixtures "$bqn_base"
  go_before="$(sha_file "$go_base/journal.tsv")"
  bqn_before="$(sha_file "$bqn_base/journal.tsv")"

  # Go editor doesn't support --yes or --post-check for plan finish
  # We must pipe "y" to confirm the append operation.
  local go_args=()
  for arg in "$@"; do
    if [[ "$arg" != "--yes" && "$arg" != "--post-check" && "$arg" != "none" && "$arg" != "lint" && "$arg" != "full" ]]; then
      go_args+=("$arg")
    fi
  done

  set +e
  echo "y" | ./tools/edit --base "$go_base" "${go_args[@]}" >"$go_out" 2>&1
  go_rc=$?
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  bqn_rc=$?
  set -e

  if [ "$go_rc" -eq 0 ]; then
    echo "FAIL: Go editor unexpectedly accepted negative case: $name" >&2
    cat "$go_out" >&2
    exit 1
  fi
  if [ "$bqn_rc" -eq 0 ]; then
    echo "FAIL: tools/edit-bqn unexpectedly accepted negative case: $name" >&2
    cat "$bqn_out" >&2
    exit 1
  fi

  assert_unchanged "$go_base" "$go_before" "Go editor negative case $name"
  assert_unchanged "$bqn_base" "$bqn_before" "tools/edit-bqn negative case $name"
  assert_no_backup "$go_base" "Go editor negative case $name"
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

echo "check-edit-bqn-plan-finish: OK"
