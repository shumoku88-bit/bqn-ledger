#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-writer-ownership.XXXXXX")"
trap 'rm -rf "$work"' EXIT
sha_file() { shasum -a 256 "$1" | awk '{print $1}'; }

# Current first-file writers must use the exclusive publish primitive. A
# check-then-mv create can overwrite a concurrent first writer after its final
# existence check.
grep -Fq 'safe_create_exclusive_checked "$TARGET_PATH"' tools/lib/edit-bqn-issue.sh
grep -Fq 'safe_create_exclusive_checked "$target_path"' tools/lib/edit-bqn-travel.sh
if rg -n '\bsafe_create_checked\b' tools checks tests \
  --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >/dev/null; then
  echo 'FAIL: legacy non-exclusive first-file create still has a caller' >&2
  rg -n '\bsafe_create_checked\b' tools checks tests \
    --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >&2 || true
  exit 1
fi

# Old self-snapshotting append/rewrite helpers must not regain callers.
# Candidate writers capture their observation before BQN validation/preview and
# publish through the checked primitive using that same observation.
for legacy in safe_append safe_rewrite; do
  if rg -n "\\b${legacy}\\b" tools checks tests \
    --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >/dev/null; then
    echo "FAIL: legacy self-snapshotting writer still has a caller: $legacy" >&2
    rg -n "\\b${legacy}\\b" tools checks tests \
      --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >&2 || true
    exit 1
  fi
done

grep -Fq 'safe_append_checked' tools/lib/edit-bqn-common.sh
grep -Fq 'safe_replace_line_checked' tools/lib/edit-bqn-common.sh
grep -Fq 'safe_rewrite_checked' tools/lib/edit-bqn-common.sh

# Positive first Issue publication.
base="$work/first"
cp -R data "$base"
rm -f "$base/issues.tsv"
./tools/edit-bqn --base "$base" issue add \
  --date 2026-08-17 --title 'first issue' --amount 0 --memo 'first create' \
  --yes --post-check none >"$work/first.out"
[[ -f "$base/issues.tsv" ]]
head -n1 "$base/issues.tsv" | grep -Fx $'issue_id\tstatus\tdate\tdue\tclosed\tcategory\ttitle\tamount\tcurrency\tdetails' >/dev/null
grep -Fq $'first issue\t0\tJPY\tfirst create' "$base/issues.tsv"

# Race the first-file publication. The test hook creates the target after the
# candidate temp file is staged but before the exclusive link. The Issue writer
# must lose without replacing the concurrent bytes.
race_base="$work/race"
cp -R data "$race_base"
rm -f "$race_base/issues.tsv"
issue_first_create_race_hook() {
  printf 'concurrent-writer\n' >"$race_base/issues.tsv"
}
export race_base
export -f issue_first_create_race_hook
set +e
BQN_LEDGER_TEST_MODE=1 \
SAFE_WRITE_TEST_BEFORE_EXCLUSIVE_CREATE_HOOK=issue_first_create_race_hook \
./tools/edit-bqn --base "$race_base" issue add \
  --date 2026-08-17 --title 'losing issue' --amount 0 --memo 'must not publish' \
  --yes --post-check none >"$work/race.out" 2>"$work/race.err"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo 'FAIL: concurrent first Issue publication unexpectedly succeeded' >&2; exit 1; }
[[ "$(cat "$race_base/issues.tsv")" == 'concurrent-writer' ]] || {
  echo 'FAIL: losing Issue candidate replaced concurrent first-writer bytes' >&2
  cat "$race_base/issues.tsv" >&2
  exit 1
}
if [[ -d "$race_base/.backup" ]] && find "$race_base/.backup" -type f | grep -q .; then
  echo 'FAIL: failed first-file race created a backup' >&2
  exit 1
fi
grep -Fq 'concurrent first-write won' "$work/race.err"

# A first Issue publication whose mandatory/default validation fails is removed
# again, because there is no pre-existing file to restore.
create_fail="$work/create-fail"
cp -R data "$create_fail"
rm -f "$create_fail/issues.tsv"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 \
./tools/edit-bqn --base "$create_fail" issue add \
  --date 2026-08-17 --title 'invalid publication' --amount 0 --memo 'rollback create' \
  --yes --post-check lint >"$work/create-fail.out" 2>"$work/create-fail.err"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo 'FAIL: forced first Issue post-check failure unexpectedly succeeded' >&2; exit 1; }
[[ ! -e "$create_fail/issues.tsv" ]] || { echo 'FAIL: failed first Issue publication remained on disk' >&2; exit 1; }
grep -Fq 'Rollback: removed created Issue source' "$work/create-fail.err"

# Existing Issue append failure restores the exact observed bytes.
append_fail="$work/append-fail"
cp -R "$base" "$append_fail"
append_before="$(sha_file "$append_fail/issues.tsv")"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 \
./tools/edit-bqn --base "$append_fail" issue add \
  --date 2026-08-17 --title 'second issue' --amount 1 --memo 'rollback append' \
  --yes --post-check lint >"$work/append-fail.out" 2>"$work/append-fail.err"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo 'FAIL: forced Issue append post-check failure unexpectedly succeeded' >&2; exit 1; }
[[ "$(sha_file "$append_fail/issues.tsv")" == "$append_before" ]] || { echo 'FAIL: failed Issue append did not restore original bytes' >&2; exit 1; }
grep -Fq 'Rollback: restored original bytes' "$work/append-fail.err"

# Existing Issue replace/close failure also restores the exact observed bytes.
replace_fail="$work/replace-fail"
cp -R "$base" "$replace_fail"
replace_before="$(sha_file "$replace_fail/issues.tsv")"
set +e
BQN_LEDGER_TEST_MODE=1 EDIT_BQN_TEST_FORCE_POST_CHECK_FAIL=1 \
./tools/edit-bqn --base "$replace_fail" issue close \
  --index 1 --status resolved --decision 'rollback close' --closed-date 2026-08-17 \
  --yes --post-check lint >"$work/replace-fail.out" 2>"$work/replace-fail.err"
rc=$?
set -e
[[ $rc -ne 0 ]] || { echo 'FAIL: forced Issue replace post-check failure unexpectedly succeeded' >&2; exit 1; }
[[ "$(sha_file "$replace_fail/issues.tsv")" == "$replace_before" ]] || { echo 'FAIL: failed Issue replace did not restore original bytes' >&2; exit 1; }
grep -Fq 'Rollback: restored original bytes' "$work/replace-fail.err"

echo 'check-writer-effect-ownership: OK'
