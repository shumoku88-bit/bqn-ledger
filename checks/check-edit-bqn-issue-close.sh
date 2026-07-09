#!/usr/bin/env bash
set -euo pipefail

# Verify BQN editor issue list/close paths:
# - list exports open issue candidates for UI
# - close preserves original title/memo and appends a Decision note
# - dry-run and negative cases do not modify issues.tsv

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }

make_base() {
  local base="$1"
  cp -R data "$base"
  cat >"$base/issues.tsv" <<'TSV'
date	status	title	amount	memo
2026-06-28	open	amazon-prime plan化	600	サブスクとして固定支出にするか検討
2026-06-29	resolved	old decision	0	already closed
TSV
}

make_numbering_base() {
  local base="$1"
  cp -R data "$base"
  cat >"$base/issues.tsv" <<'TSV'
date	status	title	amount	memo
2026-06-20	resolved	resolved-before-open	0	already closed
2026-06-21	open	open issue A	100	first open issue
2026-06-22	open	open issue B	200	second open issue
TSV
}

base="$tmp_root/base"
make_base "$base"

list_out="$tmp_root/list.out"
./tools/edit-bqn --base "$base" issue list --format tsv >"$list_out"
if [ "$(wc -l <"$list_out" | tr -d ' ')" != "1" ]; then
  echo "FAIL: issue list should export exactly one open issue" >&2
  cat "$list_out" >&2
  exit 1
fi
if ! grep -F $'1	2026-06-28	amazon-prime plan化	600	サブスクとして固定支出にするか検討' "$list_out" >/dev/null; then
  echo "FAIL: issue list TSV output did not contain expected open issue" >&2
  cat "$list_out" >&2
  exit 1
fi

numbering_base="$tmp_root/numbering"
make_numbering_base "$numbering_base"
numbering_before="$(sha_file "$numbering_base/issues.tsv")"
text_out="$tmp_root/numbering-text.out"
tsv_out="$tmp_root/numbering-tsv.out"
./tools/edit-bqn --base "$numbering_base" issue list --format text >"$text_out"
./tools/edit-bqn --base "$numbering_base" issue list --format tsv >"$tsv_out"
if ! grep -F '1 | line 3 | 2026-06-21 | open issue A | 100 | first open issue' "$text_out" >/dev/null; then
  echo "FAIL: text issue list should show open issue A with selector 1 and physical line only as secondary info" >&2
  cat "$text_out" >&2
  exit 1
fi
if ! grep -F '2 | line 4 | 2026-06-22 | open issue B | 200 | second open issue' "$text_out" >/dev/null; then
  echo "FAIL: text issue list should show open issue B with selector 2 and physical line only as secondary info" >&2
  cat "$text_out" >&2
  exit 1
fi
if grep -E '^(3|4) \|' "$text_out" >/dev/null; then
  echo "FAIL: text issue list exposes physical line number as the primary selector" >&2
  cat "$text_out" >&2
  exit 1
fi
if ! grep -F $'1	2026-06-21	open issue A	100	first open issue	1 | line 3 | 2026-06-21 | open issue A | 100 | first open issue' "$tsv_out" >/dev/null; then
  echo "FAIL: TSV issue list first field should be open issue ordinal 1" >&2
  cat "$tsv_out" >&2
  exit 1
fi
if ! grep -F $'2	2026-06-22	open issue B	200	second open issue	2 | line 4 | 2026-06-22 | open issue B | 200 | second open issue' "$tsv_out" >/dev/null; then
  echo "FAIL: TSV issue list first field should be open issue ordinal 2" >&2
  cat "$tsv_out" >&2
  exit 1
fi
if [ "$numbering_before" != "$(sha_file "$numbering_base/issues.tsv")" ]; then
  echo "FAIL: issue list numbering checks modified issues.tsv" >&2
  exit 1
fi

close_a_base="$tmp_root/close-a"
make_numbering_base "$close_a_base"
./tools/edit-bqn --base "$close_a_base" issue close --index 1 --status resolved --decision 'closed A' --yes --post-check none >/dev/null
if ! grep -F $'2026-06-21	resolved	open issue A	100	first open issue。Decision: closed A' "$close_a_base/issues.tsv" >/dev/null; then
  echo "FAIL: issue close --index 1 should close open issue A" >&2
  cat "$close_a_base/issues.tsv" >&2
  exit 1
fi
if ! grep -F $'2026-06-22	open	open issue B	200	second open issue' "$close_a_base/issues.tsv" >/dev/null; then
  echo "FAIL: issue close --index 1 should not close open issue B" >&2
  cat "$close_a_base/issues.tsv" >&2
  exit 1
fi

close_b_base="$tmp_root/close-b"
make_numbering_base "$close_b_base"
./tools/edit-bqn --base "$close_b_base" issue close --index 2 --status resolved --decision 'closed B' --yes --post-check none >/dev/null
if ! grep -F $'2026-06-22	resolved	open issue B	200	second open issue。Decision: closed B' "$close_b_base/issues.tsv" >/dev/null; then
  echo "FAIL: issue close --index 2 should close open issue B from the unchanged open issue candidate set" >&2
  cat "$close_b_base/issues.tsv" >&2
  exit 1
fi
if ! grep -F $'2026-06-21	open	open issue A	100	first open issue' "$close_b_base/issues.tsv" >/dev/null; then
  echo "FAIL: issue close --index 2 should not close open issue A" >&2
  cat "$close_b_base/issues.tsv" >&2
  exit 1
fi

before_sha="$(sha_file "$base/issues.tsv")"
./tools/edit-bqn --base "$base" issue close \
  --index 1 \
  --status resolved \
  --decision '2026-07-09 解約済み。固定支出/plan化しない。' \
  --dry-run >/dev/null
if [ "$before_sha" != "$(sha_file "$base/issues.tsv")" ]; then
  echo "FAIL: issue close --dry-run modified issues.tsv" >&2
  exit 1
fi
if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
  echo "FAIL: issue close --dry-run created backup" >&2
  exit 1
fi

./tools/edit-bqn --base "$base" issue close \
  --index 1 \
  --status resolved \
  --decision '2026-07-09 解約済み。固定支出/plan化しない。' \
  --yes \
  --post-check none >/dev/null

expected=$'2026-06-28	resolved	amazon-prime plan化	600	サブスクとして固定支出にするか検討。Decision: 2026-07-09 解約済み。固定支出/plan化しない。'
if ! grep -F "$expected" "$base/issues.tsv" >/dev/null; then
  echo "FAIL: closed issue row does not preserve original text plus Decision note" >&2
  cat "$base/issues.tsv" >&2
  exit 1
fi
if ! find "$base/.backup" -type f -name 'issues.tsv*' | grep -q .; then
  echo "FAIL: issue close did not create backup" >&2
  exit 1
fi

neg_base="$tmp_root/neg"
make_base "$neg_base"
neg_before="$(sha_file "$neg_base/issues.tsv")"
set +e
./tools/edit-bqn --base "$neg_base" issue close --index 1 --status open --decision nope >"$tmp_root/neg.out" 2>&1
neg_rc=$?
set -e
if [ "$neg_rc" -eq 0 ]; then
  echo "FAIL: issue close accepted invalid close status" >&2
  cat "$tmp_root/neg.out" >&2
  exit 1
fi
if [ "$neg_before" != "$(sha_file "$neg_base/issues.tsv")" ]; then
  echo "FAIL: issue close negative case modified issues.tsv" >&2
  exit 1
fi

memo_guard_base="$tmp_root/memo-guard"
make_base "$memo_guard_base"
memo_guard_before="$(sha_file "$memo_guard_base/issues.tsv")"
set +e
./tools/edit-bqn --base "$memo_guard_base" issue close --index 1 --status resolved --decision '2026-07-09 ' >"$tmp_root/memo-guard.out" 2>&1
memo_guard_rc=$?
set -e
if [ "$memo_guard_rc" -eq 0 ]; then
  echo "FAIL: issue close accepted date-only decision memo" >&2
  cat "$tmp_root/memo-guard.out" >&2
  exit 1
fi
if ! grep -F 'decision memo must include text after the date' "$tmp_root/memo-guard.out" >/dev/null; then
  echo "FAIL: issue close date-only guard did not explain the problem" >&2
  cat "$tmp_root/memo-guard.out" >&2
  exit 1
fi
if [ "$memo_guard_before" != "$(sha_file "$memo_guard_base/issues.tsv")" ]; then
  echo "FAIL: issue close date-only negative case modified issues.tsv" >&2
  exit 1
fi

echo "OK: edit-bqn issue list/close checks passed"
