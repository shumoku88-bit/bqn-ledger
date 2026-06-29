#!/usr/bin/env bash
set -euo pipefail
export NO_COLOR=1

# Verify BQN-backed `journal reverse` append path.
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
  # Add some rows to reverse
  echo -e "2026-06-25\tReversable Memo\tassets:bank\texpenses:食費\t1000" >> "$base/journal.tsv"
  # Duplicate memo to test conflict
  echo -e "2026-06-25\tDuplicate Memo\tassets:bank\texpenses:食費\t2000" >> "$base/journal.tsv"
  echo -e "2026-06-26\tDuplicate Memo\tassets:bank\texpenses:日用品\t3000" >> "$base/journal.tsv"
  # Row with same from/to
  echo -e "2026-06-27\tInvalid Self Transfer\tassets:bank\tassets:bank\t5000" >> "$base/journal.tsv"
}

run_positive_parity() {
  local name="$1"
  shift
  local bqn_base="$tmp_root/pos-$name-bqn"
  local bqn_out="$tmp_root/pos-$name-bqn.out"

  prepare_fixtures "$bqn_base"


  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1


  if ! find "$bqn_base/.backup" -type f -name 'journal.tsv*' | grep -q .; then
    echo "FAIL: tools/edit-bqn journal reverse did not create a journal backup: $name" >&2
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

  # Go editor doesn't support --yes or --post-check for journal reverse
  # We must pipe "y" to confirm the reverse operation.

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
./tools/edit-bqn --base "$dry_base" journal reverse \
  --index 10 \
  --date 2026-06-26 \
  --dry-run \
  --yes \
  --post-check none >/dev/null
assert_unchanged "$dry_base" "$dry_before" "tools/edit-bqn journal reverse dry-run"
assert_no_backup "$dry_base" "tools/edit-bqn journal reverse dry-run"

# Positive cases.
run_positive_parity reverse-by-index-date \
  journal reverse \
  --index 10 \
  --date 2026-06-26 \
  --yes \
  --post-check none

run_positive_parity reverse-by-id-date \
  journal reverse \
  --id "Reversable Memo" \
  --date 2026-06-26 \
  --yes \
  --post-check none

run_positive_parity reverse-by-index-default-date \
  journal reverse \
  --index 10 \
  --yes \
  --post-check none

# Negative cases.
run_expect_fail_closed invalid-index \
  journal reverse \
  --index 99 \
  --date 2026-06-26 \
  --yes \
  --post-check none

run_expect_fail_closed memo-not-found \
  journal reverse \
  --id "Nonexistent Memo" \
  --date 2026-06-26 \
  --yes \
  --post-check none

run_expect_fail_closed duplicate-memo \
  journal reverse \
  --id "Duplicate Memo" \
  --date 2026-06-26 \
  --yes \
  --post-check none

run_expect_fail_closed same-from-to \
  journal reverse \
  --index 13 \
  --date 2026-06-26 \
  --yes \
  --post-check none

echo "check-edit-bqn-journal-reverse: OK"
