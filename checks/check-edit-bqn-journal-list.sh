#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }

assert_readonly() {
  local name="$1" fixture="$2" format="$3"
  local base="$tmp_root/$name" out="$tmp_root/$name.out"
  cp -R "$fixture" "$base"
  local rel before after
  rel="$(bqn src_edit/actual_journal_file_cmd.bqn "$base")"
  before="$(sha_file "$base/$rel")"
  ./tools/edit-bqn --base "$base" journal list --format "$format" >"$out"
  after="$(sha_file "$base/$rel")"
  [[ "$before" == "$after" ]]
  [[ ! -d "$base/.backup" ]] || ! find "$base/.backup" -type f | grep -q .
  [[ "$format" != tsv ]] || awk -F '\t' 'NF != 7 {exit 1}' "$out"
}

assert_readonly sandbox-tsv data tsv
assert_readonly sandbox-text data text

base="$tmp_root/native-boundary"
out="$tmp_root/native-boundary.out"
cp -R fixtures/journal-ordinary-actual-fallback-boundary "$base"
before="$(sha_file "$base/actual.journal")"
./tools/edit-bqn --base "$base" journal list --format tsv >"$out"
[[ "$before" == "$(sha_file "$base/actual.journal")" ]]
[[ "$(wc -l <"$out" | tr -d ' ')" -eq 3 ]]
awk -F '\t' 'NF != 7 {exit 1}' "$out"
awk -F '\t' '$1==2 && $2=="2026-07-23" && $3=="Ordinary purchase" && $4=="assets:cash" && $5=="expenses:food" && $6==25 {ok=1} END{exit !ok}' "$out"
! grep -q -E 'stage0-line-|completion-plan-household-001-20260724|opening-20260701-001' "$out"

neg="$tmp_root/invalid-format"; cp -R data "$neg"
before="$(sha_file "$neg/actual.journal")"
if ./tools/edit-bqn --base "$neg" journal list --format json >"$tmp_root/invalid.out" 2>&1; then
  echo 'FAIL: invalid Journal list format unexpectedly succeeded' >&2; exit 1
fi
[[ "$before" == "$(sha_file "$neg/actual.journal")" ]]
printf 'OK edit-bqn native Journal list contract\n'
