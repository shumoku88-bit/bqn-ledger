#!/usr/bin/env bash
set -euo pipefail

# Verify tools/lib/safe-write.sh exact single-line replacement primitive.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

# shellcheck source=tools/lib/safe-write.sh
source tools/lib/safe-write.sh

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

assert_has_backup() {
  local base="$1"
  local label="$2"
  if ! find "$base/.backup" -type f -name 'plan.tsv*' | grep -q .; then
    echo "FAIL: $label did not create a backup" >&2
    exit 1
  fi
}

make_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf '2026-01-01\tA\tassets:bank\texpenses:food\t100\tplan_id=plan-2026-01-01-a\n' > "$path"
  printf '2026-01-02\tB\tassets:bank\texpenses:food\t200\tplan_id=plan-2026-01-02-b\n' >> "$path"
  printf '2026-01-03\tC\tassets:bank\texpenses:food\t300\tplan_id=plan-2026-01-03-c\n' >> "$path"
}

# Positive: replace exactly line 2, preserve other rows.
pos_base="$tmp_root/positive"
pos_file="$pos_base/plan.tsv"
make_file "$pos_file"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$pos_file")"
old_row=$'2026-01-02\tB\tassets:bank\texpenses:food\t200\tplan_id=plan-2026-01-02-b'
new_row=$'2026-01-09\tB\tassets:bank\texpenses:food\t250\tplan_id=plan-2026-01-02-b'
safe_replace_line_checked "$pos_file" 2 "$old_row" "$new_row" "$size" "$mtime" "$sha" >/dev/null
expected="$tmp_root/expected-positive.tsv"
printf '2026-01-01\tA\tassets:bank\texpenses:food\t100\tplan_id=plan-2026-01-01-a\n' > "$expected"
printf '%s\n' "$new_row" >> "$expected"
printf '2026-01-03\tC\tassets:bank\texpenses:food\t300\tplan_id=plan-2026-01-03-c\n' >> "$expected"
if ! cmp -s "$expected" "$pos_file"; then
  echo "FAIL: positive replace content mismatch" >&2
  diff -u "$expected" "$pos_file" >&2 || true
  exit 1
fi
assert_has_backup "$pos_base" "positive replace"

# Preserve missing final newline when replacing the last line.
no_nl_base="$tmp_root/no-final-newline"
no_nl_file="$no_nl_base/plan.tsv"
mkdir -p "$no_nl_base"
printf 'first\nsecond' > "$no_nl_file"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$no_nl_file")"
safe_replace_line_checked "$no_nl_file" 2 'second' 'changed' "$size" "$mtime" "$sha" >/dev/null
if [ "$(printf '%s' "$(cat "$no_nl_file")")" != $'first\nchanged' ]; then
  echo "FAIL: no-final-newline content mismatch" >&2
  od -An -tx1 "$no_nl_file" >&2
  exit 1
fi
if [[ "$(tail -c 1 "$no_nl_file" | xxd -p)" == "0a" ]]; then
  echo "FAIL: no-final-newline case gained a trailing newline" >&2
  exit 1
fi

# Negative: stale snapshot before backup creates no backup and no change.
stale_base="$tmp_root/stale-before"
stale_file="$stale_base/plan.tsv"
make_file "$stale_file"
before_sha="$(sha_file "$stale_file")"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$stale_file")"
printf 'concurrent\n' >> "$stale_file"
set +e
safe_replace_line_checked "$stale_file" 2 "$old_row" "$new_row" "$size" "$mtime" "$sha" >/dev/null 2>"$tmp_root/stale-before.err"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "FAIL: stale-before unexpectedly succeeded" >&2
  exit 1
fi
assert_no_backup "$stale_base" "stale-before"
if [ "$(sha_file "$stale_file")" = "$before_sha" ]; then
  echo "FAIL: stale-before setup did not modify file" >&2
  exit 1
fi

# Negative: old row mismatch creates no backup and no change.
mismatch_base="$tmp_root/mismatch"
mismatch_file="$mismatch_base/plan.tsv"
make_file "$mismatch_file"
mismatch_before="$(sha_file "$mismatch_file")"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$mismatch_file")"
set +e
safe_replace_line_checked "$mismatch_file" 2 'wrong old row' "$new_row" "$size" "$mtime" "$sha" >/dev/null 2>"$tmp_root/mismatch.err"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "FAIL: mismatch unexpectedly succeeded" >&2
  exit 1
fi
if [ "$(sha_file "$mismatch_file")" != "$mismatch_before" ]; then
  echo "FAIL: mismatch modified file" >&2
  exit 1
fi
assert_no_backup "$mismatch_base" "mismatch"

# Negative: line out of range creates no backup and no change.
range_base="$tmp_root/range"
range_file="$range_base/plan.tsv"
make_file "$range_file"
range_before="$(sha_file "$range_file")"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$range_file")"
set +e
safe_replace_line_checked "$range_file" 9 "$old_row" "$new_row" "$size" "$mtime" "$sha" >/dev/null 2>"$tmp_root/range.err"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "FAIL: out-of-range unexpectedly succeeded" >&2
  exit 1
fi
if [ "$(sha_file "$range_file")" != "$range_before" ]; then
  echo "FAIL: out-of-range modified file" >&2
  exit 1
fi
assert_no_backup "$range_base" "out-of-range"

# Negative: concurrent edit after backup but before rename fails without writing
# candidate content. A backup may exist because the race occurs after backup.
race_base="$tmp_root/race-before-rename"
race_file="$race_base/plan.tsv"
make_file "$race_file"
IFS=$'\t' read -r size mtime sha <<< "$(safe_snapshot_token "$race_file")"
set +e
BQN_LEDGER_TEST_MODE=1 \
SAFE_WRITE_TEST_BEFORE_REPLACE_RENAME_HOOK="printf 'race\\n' >> '$race_file'" \
safe_replace_line_checked "$race_file" 2 "$old_row" "$new_row" "$size" "$mtime" "$sha" >/dev/null 2>"$tmp_root/race.err"
rc=$?
set -e
if [ "$rc" -eq 0 ]; then
  echo "FAIL: race-before-rename unexpectedly succeeded" >&2
  exit 1
fi
if grep -qF "$new_row" "$race_file"; then
  echo "FAIL: race-before-rename wrote candidate row" >&2
  exit 1
fi
if ! grep -q '^race$' "$race_file"; then
  echo "FAIL: race-before-rename setup did not append race marker" >&2
  exit 1
fi
assert_has_backup "$race_base" "race-before-rename"

printf 'OK: safe_replace_line_checked checks passed\n'
