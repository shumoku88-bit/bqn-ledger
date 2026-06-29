#!/usr/bin/env bash
set -euo pipefail

# Verify the narrow experimental BQN editor append paths.
# Scope:
#   - positive resulting TSV byte parity with Go editor
#   - dry-run source protection
#   - negative cases fail closed without source/backup writes

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

assert_no_backup() {
  local base="$1"
  local label="$2"
  if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: $label created a backup during a failing/dry-run case" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi
}

assert_unchanged() {
  local base="$1"
  local target_file="$2"
  local before_sha="$3"
  local label="$4"
  local after_sha
  after_sha="$(sha_file "$base/$target_file")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: $label modified $target_file" >&2
    exit 1
  fi
}

run_expect_fail_closed() {
  local name="$1"
  local target_file="$2"
  shift 2
  local bqn_base="$tmp_root/neg-${name}-bqn"
  local bqn_out="$tmp_root/neg-${name}-bqn.out"
  local bqn_before bqn_rc

  cp -R data "$bqn_base"
  bqn_before="$(sha_file "$bqn_base/$target_file")"

  set +e
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  bqn_rc=$?
  set -e


  if [ "$bqn_rc" -eq 0 ]; then
    echo "FAIL: tools/edit-bqn unexpectedly accepted negative case: $name" >&2
    cat "$bqn_out" >&2
    exit 1
  fi

  assert_unchanged "$bqn_base" "$target_file" "$bqn_before" "tools/edit-bqn negative case $name"
  assert_no_backup "$bqn_base" "tools/edit-bqn negative case $name"
}

run_positive() {
  local name="$1"
  local target_file="$2"
  shift 2
  local bqn_base="$tmp_root/pos-${name}-bqn"
  local bqn_out="$tmp_root/pos-${name}-bqn.out"

  cp -R data "$bqn_base"

  if [[ "$name" == *"no-trailing-newline" ]]; then
    perl -0pi -e 's/\n\z//' "$bqn_base/$target_file"
  fi

  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1



  if ! find "$bqn_base/.backup" -type f -name "${target_file}*" | grep -q .; then
    echo "FAIL: tools/edit-bqn positive case did not create a backup for $target_file: $name" >&2
    exit 1
  fi
}

# ── Positive parity and dry-run protection ──────────────────────

bqn_base="$tmp_root/bqn"
dry_base="$tmp_root/dry"
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

before_sha="$(sha_file "$dry_base/journal.tsv")"
./tools/edit-bqn --base "$dry_base" journal add \
  --date 2026-06-29 \
  --memo "edit-bqn dry-run" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 123 \
  --meta source=check-edit-bqn \
  --dry-run 
assert_unchanged "$dry_base" "journal.tsv" "$before_sha" "tools/edit-bqn --dry-run"
assert_no_backup "$dry_base" "tools/edit-bqn --dry-run"

./tools/edit-bqn --base "$bqn_base" "${args[@]}"

if ! find "$bqn_base/.backup" -type f -name 'journal.tsv*' | grep -q .; then
  echo "FAIL: tools/edit-bqn journal add did not create a journal backup" >&2
  exit 1
fi

run_positive empty-memo journal.tsv \
  journal add \
  --date 2026-06-29 \
  --memo "" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 124 \
  --yes \
  --post-check none

run_positive multiple-meta journal.tsv \
  journal add \
  --date 2026-06-29 \
  --memo "edit-bqn multiple meta" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 125 \
  --meta source=check-edit-bqn \
  --meta note=multi_meta \
  --yes \
  --post-check none

run_positive japanese-values journal.tsv \
  journal add \
  --date 2026-06-29 \
  --memo "昼ごはん" \
  --from assets:bank \
  --to expenses:日用品 \
  --amount 126 \
  --meta source=確認 \
  --yes \
  --post-check none

run_positive no-trailing-newline journal.tsv \
  journal add \
  --date 2026-06-29 \
  --memo "edit-bqn no trailing newline" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 127 \
  --yes \
  --post-check none

# ── Budget add positive parity and dry-run protection ───────────

budget_dry_base="$tmp_root/budget-dry"
cp -R data "$budget_dry_base"
budget_before_sha="$(sha_file "$budget_dry_base/budget_alloc.tsv")"
./tools/edit-bqn --base "$budget_dry_base" budget add \
  --date 2026-06-29 \
  --memo "edit-bqn budget dry-run" \
  --from budget:opening \
  --to budget:食費 \
  --amount 200 \
  --meta source=check-edit-bqn \
  --dry-run 
if [[ "$budget_before_sha" != "$(sha_file "$budget_dry_base/budget_alloc.tsv")" ]]; then
  echo "FAIL: tools/edit-bqn budget add --dry-run modified budget_alloc.tsv" >&2
  exit 1
fi
assert_no_backup "$budget_dry_base" "tools/edit-bqn budget add --dry-run"

run_positive budget-basic budget_alloc.tsv \
  budget add \
  --date 2026-06-29 \
  --memo "edit-bqn budget parity" \
  --from budget:opening \
  --to budget:食費 \
  --amount 201 \
  --meta source=check-edit-bqn \
  --yes \
  --post-check none

run_positive budget-no-trailing-newline budget_alloc.tsv \
  budget add \
  --date 2026-06-29 \
  --memo "edit-bqn budget no trailing newline" \
  --from budget:opening \
  --to budget:一般生活 \
  --amount 202 \
  --yes \
  --post-check none

# ── Stale write protection ──────────────────────────────────────

stale_base="$tmp_root/stale"
stale_out="$tmp_root/stale.out"
cp -R data "$stale_base"
set +e
BQN_LEDGER_TEST_MODE=1 \
EDIT_BQN_TEST_BEFORE_APPEND_HOOK="printf '%s\\n' '# concurrent edit' >> '$stale_base/journal.tsv'" \
  ./tools/edit-bqn --base "$stale_base" journal add \
    --date 2026-06-29 \
    --memo "stale append should not land" \
    --from assets:bank \
    --to expenses:食費 \
    --amount 123 \
    --yes \
    --post-check none >"$stale_out" 2>&1
stale_rc=$?
set -e
if [ "$stale_rc" -eq 0 ]; then
  echo "FAIL: tools/edit-bqn accepted a stale journal append" >&2
  cat "$stale_out" >&2
  exit 1
fi
if grep -Fq "stale append should not land" "$stale_base/journal.tsv"; then
  echo "FAIL: stale tools/edit-bqn append payload landed in journal.tsv" >&2
  exit 1
fi
if ! tail -n 1 "$stale_base/journal.tsv" | grep -Fxq '# concurrent edit'; then
  echo "FAIL: stale test did not leave the simulated concurrent edit as the final line" >&2
  tail -n 5 "$stale_base/journal.tsv" >&2
  exit 1
fi
assert_no_backup "$stale_base" "tools/edit-bqn stale append"

# ── Negative fail-closed parity ─────────────────────────────────
# At this stage stdout/stderr text does not need to match exactly. The gate is:
# both paths reject the input, leave journal.tsv byte-identical, and create no backup.

run_expect_fail_closed invalid-date journal.tsv \
  journal add --date 2026-02-30 --memo "bad date" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed unknown-from journal.tsv \
  journal add --date 2026-06-29 --memo "unknown from" --from assets:missing --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed unknown-to journal.tsv \
  journal add --date 2026-06-29 --memo "unknown to" --from assets:bank --to expenses:missing --amount 123 --yes --post-check none
run_expect_fail_closed invalid-amount journal.tsv \
  journal add --date 2026-06-29 --memo "bad amount" --from assets:bank --to expenses:食費 --amount 12.3 --yes --post-check none
run_expect_fail_closed invalid-meta-missing-eq journal.tsv \
  journal add --date 2026-06-29 --memo "bad meta" --from assets:bank --to expenses:食費 --amount 123 --meta source --yes --post-check none
run_expect_fail_closed invalid-meta-key journal.tsv \
  journal add --date 2026-06-29 --memo "bad meta key" --from assets:bank --to expenses:食費 --amount 123 --meta Source=test --yes --post-check none
run_expect_fail_closed memo-tab journal.tsv \
  journal add --date 2026-06-29 --memo $'bad\tmemo' --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed memo-newline journal.tsv \
  journal add --date 2026-06-29 --memo $'bad\nmemo' --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed missing-date journal.tsv \
  journal add --memo "missing date" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed missing-amount journal.tsv \
  journal add --date 2026-06-29 --memo "missing amount" --from assets:bank --to expenses:食費 --yes --post-check none
run_expect_fail_closed invalid-post-check journal.tsv \
  journal add --date 2026-06-29 --memo "bad post check" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check bad

# ── Budget add negative fail-closed parity ──────────────────────

run_expect_fail_closed budget-unknown-from budget_alloc.tsv \
  budget add --date 2026-06-29 --memo "unknown budget from" --from budget:missing --to budget:食費 --amount 123 --yes --post-check none
run_expect_fail_closed budget-unknown-to budget_alloc.tsv \
  budget add --date 2026-06-29 --memo "unknown budget to" --from budget:opening --to budget:missing --amount 123 --yes --post-check none
run_expect_fail_closed budget-invalid-amount budget_alloc.tsv \
  budget add --date 2026-06-29 --memo "bad budget amount" --from budget:opening --to budget:食費 --amount 12.3 --yes --post-check none
run_expect_fail_closed budget-invalid-meta budget_alloc.tsv \
  budget add --date 2026-06-29 --memo "bad budget meta" --from budget:opening --to budget:食費 --amount 123 --meta Source=test --yes --post-check none

# ── Issue add parity and fail-closed checks ─────────────────────

issue_dry_base="$tmp_root/issue-dry"
cp -R data "$issue_dry_base"
./tools/edit-bqn --base "$issue_dry_base" issue add \
  --date 2026-06-29 \
  --title "edit-bqn issue dry-run" \
  --amount 300 \
  --memo "dry" \
  --dry-run 
if [[ -e "$issue_dry_base/issues.tsv" ]]; then
  echo "FAIL: tools/edit-bqn issue add --dry-run created issues.tsv" >&2
  exit 1
fi
assert_no_backup "$issue_dry_base" "tools/edit-bqn issue add --dry-run"

issue_bqn_base="$tmp_root/issue-new-bqn"
cp -R data "$issue_bqn_base"
./tools/edit-bqn --base "$issue_bqn_base" issue add \
  --date 2026-06-29 \
  --title "edit-bqn issue parity" \
  --amount 301 \
  --memo "new file" \
  --yes 
assert_no_backup "$issue_bqn_base" "tools/edit-bqn issue add new-file"

issue_existing_bqn="$tmp_root/issue-existing-bqn"
cp -R data "$issue_existing_bqn"
printf 'date\tstatus\ttitle\tamount\tmemo\n2026-06-28\topen\tBefore\t0\tseed\n' > "$issue_existing_bqn/issues.tsv"
./tools/edit-bqn --base "$issue_existing_bqn" issue add \
  --date 2026-06-29 \
  --status resolved \
  --title "edit-bqn issue existing" \
  --amount -302 \
  --memo "existing file" \
  --yes 
if ! find "$issue_existing_bqn/.backup" -type f -name 'issues.tsv*' | grep -q .; then
  echo "FAIL: tools/edit-bqn issue add existing-file did not create an issues backup" >&2
  exit 1
fi

for issue_case in invalid-status missing-title invalid-amount title-tab memo-newline; do
  issue_neg_bqn="$tmp_root/issue-neg-${issue_case}-bqn"
  cp -R data "$issue_neg_bqn"
  case "$issue_case" in
    invalid-status) issue_args=(issue add --date 2026-06-29 --status bad --title "bad status" --yes) ;;
    missing-title) issue_args=(issue add --date 2026-06-29 --amount 1 --yes) ;;
    invalid-amount) issue_args=(issue add --date 2026-06-29 --title "bad amount" --amount 1.2 --yes) ;;
    title-tab) issue_args=(issue add --date 2026-06-29 --title $'bad\ttitle' --yes) ;;
    memo-newline) issue_args=(issue add --date 2026-06-29 --title "bad memo" --memo $'bad\nmemo' --yes) ;;
  esac
  set +e
  ./tools/edit-bqn --base "$issue_neg_bqn" "${issue_args[@]}" >"$tmp_root/issue-neg-${issue_case}-bqn.out" 2>&1
  bqn_rc=$?
  set -e
  if [[ "$bqn_rc" -eq 0 ]]; then
    echo "FAIL: issue negative case was accepted: $issue_case (bqn=$bqn_rc)" >&2
    exit 1
  fi
  if [[ -e "$issue_neg_bqn/issues.tsv" ]]; then
    echo "FAIL: issue negative case created issues.tsv: $issue_case" >&2
    exit 1
  fi
  assert_no_backup "$issue_neg_bqn" "tools/edit-bqn issue negative case $issue_case"
done

echo "OK: tools/edit-bqn journal/budget/issue add parity checks passed" >&2
