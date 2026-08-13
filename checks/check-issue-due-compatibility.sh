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

closed_base="$tmp_root/closed-aware"
cp -R data "$closed_base"
printf '%s\n' \
  $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails' \
  $'issue:close-me\topen\t2026-08-12\t2026-08-15\tnone\twant\tClose me\t1000\tJPY\tdecision pending' \
  $'issue:old\tresolved\t2026-08-01\tnone\tundetermined\twant\tHistorical close\t\t\tlegacy close date unknown' \
  >"$closed_base/issues.tsv"

bqn src_edit/issue_validate_cmd.bqn "$closed_base" >/dev/null

closed_before="$(shasum -a 256 "$closed_base/issues.tsv" | awk '{print $1}')"
if ./tools/edit-bqn --base "$closed_base" issue close \
  --index 1 --status resolved --decision 'too early' --closed-date 2026-08-11 \
  --yes --post-check none >/dev/null 2>&1; then
  echo "FAIL: Issue close admitted a close date before the recorded date" >&2
  exit 1
fi
if [[ "$closed_before" != "$(shasum -a 256 "$closed_base/issues.tsv" | awk '{print $1}')" ]]; then
  echo "FAIL: rejected early close date changed issues.tsv" >&2
  exit 1
fi

./tools/edit-bqn --base "$closed_base" issue close \
  --index 1 --status resolved --decision 'closed deliberately' --closed-date 2026-08-13 \
  --yes --post-check none >/dev/null
if ! grep -F $'issue:close-me\tresolved\t2026-08-12\t2026-08-15\t2026-08-13\twant\tClose me\t1000\tJPY\tdecision pending。Decision: closed deliberately' "$closed_base/issues.tsv" >/dev/null; then
  echo "FAIL: closing a closed-aware Issue did not stamp the close date" >&2
  cat "$closed_base/issues.tsv" >&2
  exit 1
fi

./tools/edit-bqn --base "$closed_base" issue add \
  --date 2026-08-14 --title 'Still open' --amount 10 --memo 'lifecycle' --yes --post-check none >/dev/null
if ! grep -F $'issue:2026-08-14:Still open\topen\t2026-08-14\tundetermined\tnone\tgeneral\tStill open\t10\tJPY\tlifecycle' "$closed_base/issues.tsv" >/dev/null; then
  echo "FAIL: closed-aware append did not write closed=none for an open Issue" >&2
  cat "$closed_base/issues.tsv" >&2
  exit 1
fi

invalid_lifecycle="$tmp_root/invalid-lifecycle"
cp -R data "$invalid_lifecycle"
printf '%s\n' \
  $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails' \
  $'issue:bad-open\topen\t2026-08-12\tnone\tundetermined\twant\tBad open\t\t\tinvalid lifecycle' \
  >"$invalid_lifecycle/issues.tsv"
if bqn src_edit/issue_validate_cmd.bqn "$invalid_lifecycle" >/dev/null 2>&1; then
  echo "FAIL: admission accepted open Issue with closed=undetermined" >&2
  exit 1
fi
if ./tools/edit-bqn --base "$invalid_lifecycle" issue list --format text >/dev/null 2>&1; then
  echo "FAIL: list accepted open Issue with closed=undetermined" >&2
  exit 1
fi

bqn src_edit/issue_validate_cmd.bqn "$closed_base" >/dev/null

# Comments, backslash notes, and blank lines are physical source evidence, not
# semantic Issue rows. The admitted relation carries source_row so List and Close
# can preserve real physical coordinates without re-parsing Issue lifecycle.
source_rows="$tmp_root/source-rows"
cp -R data "$source_rows"
cat >"$source_rows/issues.tsv" <<'EOF'
# retained comment
issue_id	status	date	due	closed	category	title	amount	currency	details
\ retained source note
issue:commented	open	2026-08-10	none	none	general	Commented open	100	JPY	keep coordinates

issue:done	resolved	2026-08-01	none	2026-08-02	general	Already done			closed
EOF
bqn src_edit/issue_validate_cmd.bqn "$source_rows" >/dev/null
source_list="$(./tools/edit-bqn --base "$source_rows" issue list --format text)"
grep -F '1 | line 4 | 2026-08-10 | Commented open | 100 | keep coordinates | due: none' <<<"$source_list" >/dev/null || {
  echo 'FAIL: admitted Issue list lost physical source_row' >&2
  printf '%s\n' "$source_list" >&2
  exit 1
}
close_protocol="$(bqn src_edit/issue_close_cmd.bqn "$source_rows" 1 resolved 'coordinate witness' 2026-08-13)"
grep -Fq $'OK\tREPLACE\t4\tCommented open' <<<"$close_protocol" || {
  echo 'FAIL: admitted Issue close lost physical source_row' >&2
  printf '%s\n' "$close_protocol" >&2
  exit 1
}

echo 'OK: Issue due/closed lifecycle compatibility checks passed' >&2
