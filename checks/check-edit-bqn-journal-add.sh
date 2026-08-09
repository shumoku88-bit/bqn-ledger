#!/usr/bin/env bash
set -euo pipefail

# Legacy Budget row qualification was removed with its writer authority. This
# retained check covers the unrelated Issue append surface still in edit-bqn.
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
tmp_root="$(mktemp -d)"; trap 'rm -rf "$tmp_root"' EXIT

assert_no_backup() {
  local base="$1" label="$2"
  if [[ -e "$base/.backup" ]] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup" >&2; exit 1
  fi
}

issue_dry_base="$tmp_root/issue-dry"; cp -R data "$issue_dry_base"
./tools/edit-bqn --base "$issue_dry_base" issue add \
  --date 2026-06-29 --title "edit-bqn issue dry-run" --amount 300 --memo dry --dry-run
[[ ! -e "$issue_dry_base/issues.tsv" ]]
assert_no_backup "$issue_dry_base" "tools/edit-bqn issue add --dry-run"

issue_bqn_base="$tmp_root/issue-new-bqn"; cp -R data "$issue_bqn_base"
./tools/edit-bqn --base "$issue_bqn_base" issue add \
  --date 2026-06-29 --title "edit-bqn issue parity" --amount 301 --memo "new file" --yes
assert_no_backup "$issue_bqn_base" "tools/edit-bqn issue add new-file"

issue_existing_bqn="$tmp_root/issue-existing-bqn"; cp -R data "$issue_existing_bqn"
printf 'issue_id\tstatus\tdate\tcategory\ttitle\tamount\tcurrency\tdetails\nissue:seed\topen\t2026-06-28\tgeneral\tBefore\t0\tJPY\tseed\n' >"$issue_existing_bqn/issues.tsv"
./tools/edit-bqn --base "$issue_existing_bqn" issue add \
  --date 2026-06-29 --status resolved --title "edit-bqn issue existing" --amount 302 --memo "existing file" --yes
find "$issue_existing_bqn/.backup" -type f -name 'issues.tsv*' | grep -q .

for issue_case in invalid-status missing-title invalid-amount title-tab memo-newline; do
  base="$tmp_root/issue-neg-$issue_case"; cp -R data "$base"
  case "$issue_case" in
    invalid-status) args=(issue add --date 2026-06-29 --status bad --title "bad status" --yes) ;;
    missing-title) args=(issue add --date 2026-06-29 --amount 1 --yes) ;;
    invalid-amount) args=(issue add --date 2026-06-29 --title "bad amount" --amount 1.2 --yes) ;;
    title-tab) args=(issue add --date 2026-06-29 --title $'bad\ttitle' --yes) ;;
    memo-newline) args=(issue add --date 2026-06-29 --title "bad memo" --memo $'bad\nmemo' --yes) ;;
  esac
  if ./tools/edit-bqn --base "$base" "${args[@]}" >"$tmp_root/$issue_case.out" 2>&1; then
    echo "FAIL: Issue negative case accepted: $issue_case" >&2; exit 1
  fi
  [[ ! -e "$base/issues.tsv" ]]
  assert_no_backup "$base" "Issue negative case $issue_case"
done

echo 'OK: tools/edit-bqn Issue add checks passed' >&2
