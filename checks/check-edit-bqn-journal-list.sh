#!/usr/bin/env bash
set -euo pipefail

# Verify read-only `tools/edit-bqn journal list` output contract.
# `--format tsv` is consumed by tools/add-ui.sh reverse selection, so shell UI
# should parse this BQN/editor protocol instead of reading journal.tsv directly.

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

assert_journal_list_readonly() {
  local name="$1"
  local fixture="$2"
  shift 2
  local base="$tmp_root/$name"
  local out="$tmp_root/$name.out"
  local before_sha after_sha

  cp -R "$fixture" "$base"
  before_sha="$(sha_file "$base/journal.tsv")"

  ./tools/edit-bqn --base "$base" journal list "$@" >"$out"

  after_sha="$(sha_file "$base/journal.tsv")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: tools/edit-bqn journal list modified journal.tsv: $name $*" >&2
    exit 1
  fi

  if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: tools/edit-bqn journal list created a backup: $name $*" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi
}

assert_tsv_shape() {
  local name="$1"
  local fixture="$2"
  local base="$tmp_root/$name-shape"
  local out="$tmp_root/$name-shape.out"

  cp -R "$fixture" "$base"
  ./tools/edit-bqn --base "$base" journal list --format tsv >"$out"
  awk -F '\t' 'NF != 7 { print "bad field count on line " NR ": " $0 > "/dev/stderr"; exit 1 }' "$out"
}

assert_tsv_preserves_empty_memo() {
  local base="$tmp_root/empty-memo"
  local out="$tmp_root/empty-memo.out"

  cp -R fixtures/src-next-broken-empty-columns "$base"
  ./tools/edit-bqn --base "$base" journal list --format tsv >"$out"
  if ! awk -F '\t' '$1 == "2" && $3 == "" && $4 == "assets:bank" && $5 == "expenses:food" { found=1 } END { exit found ? 0 : 1 }' "$out"; then
    echo "FAIL: journal list did not preserve empty memo column" >&2
    cat "$out" >&2
    exit 1
  fi
}

assert_journal_list_native_readonly() {
  local base="$tmp_root/native-boundary"
  local out="$tmp_root/native-boundary.out"
  local before_sha after_sha

  cp -R fixtures/journal-ordinary-actual-fallback-boundary "$base"
  before_sha="$(sha_file "$base/actual.journal")"

  ./tools/edit-bqn --base "$base" journal list --format tsv >"$out"

  after_sha="$(sha_file "$base/actual.journal")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: tools/edit-bqn journal list modified actual.journal" >&2
    exit 1
  fi

  if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: tools/edit-bqn journal list created a backup" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi

  local row_count
  row_count="$(wc -l < "$out" | tr -d ' ')"
  if [ "$row_count" -ne 3 ]; then
    echo "FAIL: expected 3 rows, got $row_count" >&2
    cat "$out" >&2
    exit 1
  fi

  awk -F '\t' 'NF != 7 { print "bad field count on line " NR ": " $0 > "/dev/stderr"; exit 1 }' "$out"

  local row2
  row2="$(sed -n '2p' "$out")"
  local r2_num r2_date r2_memo r2_from r2_to r2_amt
  r2_num="$(echo "$row2" | awk -F '\t' '{print $1}')"
  r2_date="$(echo "$row2" | awk -F '\t' '{print $2}')"
  r2_memo="$(echo "$row2" | awk -F '\t' '{print $3}')"
  r2_from="$(echo "$row2" | awk -F '\t' '{print $4}')"
  r2_to="$(echo "$row2" | awk -F '\t' '{print $5}')"
  r2_amt="$(echo "$row2" | awk -F '\t' '{print $6}')"

  if [ "$r2_num" != "2" ] || [ "$r2_date" != "2026-07-23" ] || [ "$r2_memo" != "Ordinary purchase" ] || [ "$r2_from" != "assets:cash" ] || [ "$r2_to" != "expenses:food" ] || [ "$r2_amt" != "25" ]; then
    echo "FAIL: row 2 mismatch: got '$row2'" >&2
    exit 1
  fi

  if grep -q -E 'stage0-line-|completion-plan-household-001-20260724|opening-20260701-001' "$out"; then
    echo "FAIL: journal list output leaked identity implementation" >&2
    cat "$out" >&2
    exit 1
  fi
}

assert_journal_list_readonly data-tsv data --format tsv
assert_journal_list_readonly data-text data --format text
assert_journal_list_readonly empty-columns-tsv fixtures/src-next-broken-empty-columns --format tsv
assert_tsv_shape data data
assert_tsv_shape empty-columns fixtures/src-next-broken-empty-columns
assert_tsv_preserves_empty_memo
assert_journal_list_native_readonly

# Invalid CLI format should fail before touching source data or creating backups.
neg_base="$tmp_root/invalid-format"
cp -R data "$neg_base"
neg_before="$(sha_file "$neg_base/journal.tsv")"
set +e
./tools/edit-bqn --base "$neg_base" journal list --format json >"$tmp_root/invalid.out" 2>&1
neg_rc=$?
set -e
if [ "$neg_rc" -eq 0 ]; then
  echo "FAIL: invalid journal list format unexpectedly succeeded" >&2
  cat "$tmp_root/invalid.out" >&2
  exit 1
fi
neg_after="$(sha_file "$neg_base/journal.tsv")"
if [ "$neg_before" != "$neg_after" ]; then
  echo "FAIL: invalid journal list format modified journal.tsv" >&2
  exit 1
fi

printf 'OK edit-bqn journal list contract\n'
