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
