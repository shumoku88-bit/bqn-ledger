#!/usr/bin/env bash
set -euo pipefail

# Verify the narrow experimental BQN editor path for journal add.
# Scope: resulting TSV byte parity with Go editor, plus dry-run source protection.

if [ -f "src_next/report.bqn" ]; then
  ROOT_DIR="$PWD"
else
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

go_base="$tmp_root/go"
bqn_base="$tmp_root/bqn"
dry_base="$tmp_root/dry"
cp -R data "$go_base"
cp -R data "$bqn_base"
cp -R data "$dry_base"

args=(
  journal add
  --date 2026-06-29
  --memo "edit-bqn parity"
  --from assets:bank
  --to expenses:食費
  --amount 123
  --meta source=check-edit-bqn
  --yes
  --post-check none
)

before_sha="$(shasum -a 256 "$dry_base/journal.tsv" | awk '{print $1}')"
./tools/edit-bqn --base "$dry_base" journal add \
  --date 2026-06-29 \
  --memo "edit-bqn dry-run" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 123 \
  --meta source=check-edit-bqn \
  --dry-run >/dev/null
after_sha="$(shasum -a 256 "$dry_base/journal.tsv" | awk '{print $1}')"
if [ "$before_sha" != "$after_sha" ]; then
  echo "FAIL: tools/edit-bqn --dry-run modified journal.tsv" >&2
  exit 1
fi
if [ -e "$dry_base/.backup" ]; then
  echo "FAIL: tools/edit-bqn --dry-run created backup directory" >&2
  exit 1
fi

./tools/edit --base "$go_base" "${args[@]}" >/dev/null
./tools/edit-bqn --base "$bqn_base" "${args[@]}" >/dev/null

if ! cmp -s "$go_base/journal.tsv" "$bqn_base/journal.tsv"; then
  echo "FAIL: tools/edit-bqn journal add result differs from Go editor" >&2
  diff -u "$go_base/journal.tsv" "$bqn_base/journal.tsv" >&2 || true
  exit 1
fi

if ! find "$bqn_base/.backup" -type f -name 'journal.tsv*' | grep -q .; then
  echo "FAIL: tools/edit-bqn journal add did not create a journal backup" >&2
  exit 1
fi

echo "OK: tools/edit-bqn journal add narrow parity check passed" >&2
