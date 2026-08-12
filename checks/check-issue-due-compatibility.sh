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
if ! grep -F '1 | line 2 | 2026-08-12 | Auction item | 1000 | buy before listing ends | due: 2026-08-15' "$list_out" >/dev/null; then
  echo "FAIL: due-aware list dropped a known due date" >&2
  cat "$list_out" >&2
  exit 1
fi
if ! grep -F '2 | line 3 | 2026-08-01 | Bookshelf |  | look when convenient | due: none' "$list_out" >/dev/null; then
  echo "FAIL: due-aware list dropped explicit no-due meaning" >&2
  cat "$list_out" >&2
  exit 1
fi

list_tsv="$tmp_root/list.tsv"
./tools/edit-bqn --base "$base" issue list --format tsv >"$list_tsv"
if [[ "$(awk -F '\t' 'NR == 1 {print $7}' "$list_tsv")" != '2026-08-15' ]] ||
   [[ "$(awk -F '\t' 'NR == 2 {print $7}' "$list_tsv")" != 'none' ]]; then
  echo "FAIL: Issue list TSV did not retain due as its appended seventh field" >&2
  cat "$list_tsv" >&2
  exit 1
fi

invalid="$tmp_root/invalid-due"
cp -R data "$invalid"
printf '%s\n' \
  $'issue_id\tstatus\tdate\tdue\tcategory\ttitle\tamount\tcurrency\tdetails' \
  $'issue:bad\topen\t2026-08-12\t2026-02-30\twant\tBad due\t\t\tinvalid' \
  >"$invalid/issues.tsv"
invalid_before="$(shasum -a 256 "$invalid/issues.tsv" | awk '{print $1}')"
if ./tools/edit-bqn --base "$invalid" issue list --format text >/dev/null 2>&1; then
  echo "FAIL: Issue list admitted an invalid Gregorian due date" >&2
  exit 1
fi
if ./tools/edit-bqn --base "$invalid" issue close --index 1 --status resolved --decision no --yes --post-check none >/dev/null 2>&1; then
  echo "FAIL: Issue close admitted an invalid Gregorian due date" >&2
  exit 1
fi
if [[ "$invalid_before" != "$(shasum -a 256 "$invalid/issues.tsv" | awk '{print $1}')" ]]; then
  echo "FAIL: rejected invalid due changed issues.tsv" >&2
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
