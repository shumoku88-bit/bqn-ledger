#!/usr/bin/env bash
set -euo pipefail

# Verify the narrow experimental BQN editor path for journal add.
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
  local before_sha="$2"
  local label="$3"
  local after_sha
  after_sha="$(sha_file "$base/journal.tsv")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: $label modified journal.tsv" >&2
    exit 1
  fi
}

run_expect_fail_closed() {
  local name="$1"
  shift
  local go_base="$tmp_root/neg-${name}-go"
  local bqn_base="$tmp_root/neg-${name}-bqn"
  local go_out="$tmp_root/neg-${name}-go.out"
  local bqn_out="$tmp_root/neg-${name}-bqn.out"
  local go_before bqn_before go_rc bqn_rc

  cp -R data "$go_base"
  cp -R data "$bqn_base"
  go_before="$(sha_file "$go_base/journal.tsv")"
  bqn_before="$(sha_file "$bqn_base/journal.tsv")"

  set +e
  ./tools/edit --base "$go_base" "$@" >"$go_out" 2>&1
  go_rc=$?
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  bqn_rc=$?
  set -e

  if [ "$go_rc" -eq 0 ]; then
    echo "FAIL: Go editor unexpectedly accepted negative case: $name" >&2
    cat "$go_out" >&2
    exit 1
  fi
  if [ "$bqn_rc" -eq 0 ]; then
    echo "FAIL: tools/edit-bqn unexpectedly accepted negative case: $name" >&2
    cat "$bqn_out" >&2
    exit 1
  fi

  assert_unchanged "$go_base" "$go_before" "Go editor negative case $name"
  assert_unchanged "$bqn_base" "$bqn_before" "tools/edit-bqn negative case $name"
  assert_no_backup "$go_base" "Go editor negative case $name"
  assert_no_backup "$bqn_base" "tools/edit-bqn negative case $name"
}

# ── Positive parity and dry-run protection ──────────────────────

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

before_sha="$(sha_file "$dry_base/journal.tsv")"
./tools/edit-bqn --base "$dry_base" journal add \
  --date 2026-06-29 \
  --memo "edit-bqn dry-run" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 123 \
  --meta source=check-edit-bqn \
  --dry-run >/dev/null
assert_unchanged "$dry_base" "$before_sha" "tools/edit-bqn --dry-run"
assert_no_backup "$dry_base" "tools/edit-bqn --dry-run"

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

# ── Stale write protection ──────────────────────────────────────

stale_base="$tmp_root/stale"
stale_out="$tmp_root/stale.out"
cp -R data "$stale_base"
set +e
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

valid_prefix=(
  journal add
  --date 2026-06-29
  --memo "edit-bqn negative"
  --from assets:bank
  --to expenses:食費
  --amount 123
  --yes
  --post-check none
)

run_expect_fail_closed invalid-date \
  journal add --date 2026-02-30 --memo "bad date" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed unknown-from \
  journal add --date 2026-06-29 --memo "unknown from" --from assets:missing --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed unknown-to \
  journal add --date 2026-06-29 --memo "unknown to" --from assets:bank --to expenses:missing --amount 123 --yes --post-check none
run_expect_fail_closed invalid-amount \
  journal add --date 2026-06-29 --memo "bad amount" --from assets:bank --to expenses:食費 --amount 12.3 --yes --post-check none
run_expect_fail_closed invalid-meta-missing-eq \
  journal add --date 2026-06-29 --memo "bad meta" --from assets:bank --to expenses:食費 --amount 123 --meta source --yes --post-check none
run_expect_fail_closed invalid-meta-key \
  journal add --date 2026-06-29 --memo "bad meta key" --from assets:bank --to expenses:食費 --amount 123 --meta Source=test --yes --post-check none
run_expect_fail_closed memo-tab \
  journal add --date 2026-06-29 --memo $'bad\tmemo' --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed memo-newline \
  journal add --date 2026-06-29 --memo $'bad\nmemo' --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed missing-date \
  journal add --memo "missing date" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check none
run_expect_fail_closed missing-amount \
  journal add --date 2026-06-29 --memo "missing amount" --from assets:bank --to expenses:食費 --yes --post-check none
run_expect_fail_closed invalid-post-check \
  journal add --date 2026-06-29 --memo "bad post check" --from assets:bank --to expenses:食費 --amount 123 --yes --post-check bad

echo "OK: tools/edit-bqn journal add parity checks passed" >&2
