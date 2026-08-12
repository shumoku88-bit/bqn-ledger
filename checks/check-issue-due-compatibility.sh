#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

base="$tmp_root/due-aware"
cp -R data "$base"
printf '%s\n' \
  $'issue_id\tstatus\tdate\tdue\tcategory\ttitle\tamount\tcurrency\tdetails' \
  $'issue:auction\topen\t2026-08-12\t2026-08-15\twant\tAuction item\t1000\tJPY\tbuy before listing ends' \
  $'issue:bookshelf\topen\t2026-08-01\tnone\twant\tBookshelf\t\t\tlook when convenient' \
  >"$base/issues.tsv"

bqn src_edit/issue_validate_cmd.bqn "$base" >/dev/null

list_out="$tmp_root/list.out"
./tools/edit-bqn --base "$base" issue list --format text >"$list_out"
if ! grep -F '1 | line 2 | 2026-08-12 | Auction item | 1000 | buy before listing ends' "$list_out" >/dev/null; then
  echo "FAIL: due-aware source was not listable" >&2
  cat "$list_out" >&2
  exit 1
fi

./tools/edit-bqn --base "$base" issue close \
  --index 1 --status resolved --decision 'auction ended' --yes --post-check none >/dev/null
if ! grep -F $'issue:auction\tresolved\t2026-08-12\t2026-08-15\twant\tAuction item\t1000\tJPY\tbuy before listing ends。Decision: auction ended' "$base/issues.tsv" >/dev/null; then
  echo "FAIL: closing a due-aware Issue did not preserve its due coordinate" >&2
  cat "$base/issues.tsv" >&2
  exit 1
fi

./tools/edit-bqn --base "$base" issue add \
  --date 2026-08-12 --title 'New matter' --amount 10 --memo 'compat' --yes --post-check none >/dev/null
if ! grep -F $'issue:2026-08-12:New matter\topen\t2026-08-12\tundetermined\tgeneral\tNew matter\t10\tJPY\tcompat' "$base/issues.tsv" >/dev/null; then
  echo "FAIL: adding to a due-aware source did not emit explicit undetermined due" >&2
  cat "$base/issues.tsv" >&2
  exit 1
fi

bqn src_edit/issue_validate_cmd.bqn "$base" >/dev/null

echo 'OK: Issue due compatibility checks passed' >&2
