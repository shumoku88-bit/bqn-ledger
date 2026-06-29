#!/usr/bin/env bash
set -euo pipefail

# Verify BQN-backed `plan add` append path.
# Scope:
#   - resulting plan.tsv append creates expected TSV/backup effects
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
    echo "FAIL: $label created a backup" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi
}

assert_unchanged() {
  local base="$1"
  local before_sha="$2"
  local label="$3"
  local after_sha
  after_sha="$(sha_file "$base/plan.tsv")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: $label modified plan.tsv" >&2
    exit 1
  fi
}

run_positive_parity() {
  local name="$1"
  shift
  local bqn_base="$tmp_root/pos-$name-bqn"
  local bqn_out="$tmp_root/pos-$name-bqn.out"

  cp -R data "$bqn_base"

  if [[ "$name" == *"no-trailing-newline" ]]; then
    perl -0pi -e 's/\n\z//'  "$bqn_base/plan.tsv"
  fi

  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1


  if ! find "$bqn_base/.backup" -type f -name 'plan.tsv*' | grep -q .; then
    echo "FAIL: tools/edit-bqn plan add did not create a plan backup: $name" >&2
    exit 1
  fi
}

run_expect_fail_closed() {
  local name="$1"
  shift
  local bqn_base="$tmp_root/neg-$name-bqn"
  local bqn_out="$tmp_root/neg-$name-bqn.out"
  local bqn_before bqn_rc

  cp -R data "$bqn_base"
  bqn_before="$(sha_file "$bqn_base/plan.tsv")"

  set +e
  ./tools/edit-bqn --base "$bqn_base" "$@" >"$bqn_out" 2>&1
  bqn_rc=$?
  set -e

  if [ "$bqn_rc" -eq 0 ]; then
    echo "FAIL: tools/edit-bqn unexpectedly accepted negative case: $name" >&2
    cat "$bqn_out" >&2
    exit 1
  fi

  assert_unchanged "$bqn_base" "$bqn_before" "tools/edit-bqn negative case $name"
  assert_no_backup "$bqn_base" "tools/edit-bqn negative case $name"
}

# Dry-run protection.
dry_base="$tmp_root/dry"
cp -R data "$dry_base"
dry_before="$(sha_file "$dry_base/plan.tsv")"
./tools/edit-bqn --base "$dry_base" plan add \
  --date 2026-06-30 \
  --memo "edit-bqn plan dry-run" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 301 \
  --meta series=edit-bqn-plan \
  --dry-run >/dev/null
assert_unchanged "$dry_base" "$dry_before" "tools/edit-bqn plan add --dry-run"
assert_no_backup "$dry_base" "tools/edit-bqn plan add --dry-run"

run_positive_parity generated-id \
  plan add \
  --date 2026-06-30 \
  --memo "edit-bqn plan generated" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 302 \
  --meta series=edit-bqn-plan-generated \
  --yes \
  --post-check none

run_positive_parity explicit-id \
  plan add \
  --date 2026-06-30 \
  --memo "edit-bqn plan explicit" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 303 \
  --id plan-2026-06-30-edit-bqn-explicit \
  --yes \
  --post-check none

run_positive_parity generated-collision-suffix \
  plan add \
  --date 2026-01-10 \
  --memo "phone" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 304 \
  --meta series=phone \
  --yes \
  --post-check none

run_positive_parity empty-memo-generated-plan-slug \
  plan add \
  --date 2026-06-30 \
  --memo "" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 305 \
  --yes \
  --post-check none

run_positive_parity no-trailing-newline \
  plan add \
  --date 2026-06-30 \
  --memo "edit-bqn no trailing newline" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 306 \
  --meta series=edit-bqn-no-trailing \
  --yes \
  --post-check none

run_expect_fail_closed meta-plan-id \
  plan add \
  --date 2026-06-30 \
  --memo "bad plan_id meta" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 307 \
  --meta plan_id=plan-2026-06-30-bad \
  --yes \
  --post-check none

run_expect_fail_closed invalid-explicit-id \
  plan add \
  --date 2026-06-30 \
  --memo "invalid id" \
  --from assets:bank \
  --to expenses:食費 \
  --amount 308 \
  --id not-a-plan-id \
  --yes \
  --post-check none

run_expect_fail_closed unknown-account \
  plan add \
  --date 2026-06-30 \
  --memo "unknown account" \
  --from assets:not-found \
  --to expenses:食費 \
  --amount 309 \
  --yes \
  --post-check none

printf 'OK: tools/edit-bqn plan add parity checks passed\n'
