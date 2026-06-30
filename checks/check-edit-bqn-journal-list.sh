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

assert_journal_list_readonly data-tsv data --format tsv
assert_journal_list_readonly data-text data --format text
assert_journal_list_readonly empty-columns-tsv fixtures/src-next-broken-empty-columns --format tsv
assert_tsv_shape data data
assert_tsv_shape empty-columns fixtures/src-next-broken-empty-columns
assert_tsv_preserves_empty_memo

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
