#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-writer-ownership.XXXXXX")"
trap 'rm -rf "$work"' EXIT

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

# The old self-snapshotting append helper must not regain a caller. Candidate
# writers capture their observation before BQN validation/preview and publish
# through safe_append_checked using that same snapshot.
if rg -n '\bsafe_append\b' tools checks tests \
  --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >/dev/null; then
  echo 'FAIL: legacy self-snapshotting append still has a caller' >&2
  rg -n '\bsafe_append\b' tools checks tests \
    --glob '!tools/lib/safe-write.sh' --glob '!checks/check-writer-effect-ownership.sh' >&2 || true
  exit 1
fi

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

echo 'check-writer-effect-ownership: OK'
