#!/usr/bin/env bash
set -euo pipefail

# Verify read-only `tools/edit-bqn plan list` output compatibility.
# `--format tsv` is consumed by tools/add-ui.sh plan selection, so this check
# keeps the BQN editor output contract stable.

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

assert_plan_list_parity() {
  local name="$1"
  local fixture="$2"
  shift 2
  local base="$tmp_root/$name"
  local bqn_out="$tmp_root/$name.bqn.out"
  local before_sha after_sha

  cp -R "$fixture" "$base"
  before_sha="$(sha_file "$base/plan.tsv")"

  ./tools/edit-bqn --base "$base" plan list "$@" >"$bqn_out"


  after_sha="$(sha_file "$base/plan.tsv")"
  if [ "$before_sha" != "$after_sha" ]; then
    echo "FAIL: tools/edit-bqn plan list modified plan.tsv: $name $*" >&2
    exit 1
  fi

  if [ -e "$base/.backup" ] && find "$base/.backup" -type f | grep -q .; then
    echo "FAIL: tools/edit-bqn plan list created a backup: $name $*" >&2
    find "$base/.backup" -type f >&2 || true
    exit 1
  fi
}

assert_tsv_shape() {
  local name="$1"
  local fixture="$2"
  local base="$tmp_root/$name-shape"
  local out="$tmp_root/$name-shape.out"

  cp -R "$fixture" "$base"
  ./tools/edit-bqn --base "$base" plan list --format tsv >"$out"
  awk -F '\t' 'NF != 9 { print "bad field count on line " NR ": " $0 > "/dev/stderr"; exit 1 }' "$out"
  awk -F '\t' '$8 != "" && $8 != "MISSING-ID" && $8 != "INVALID-ID" && $8 != "CLOSED" { print "bad status on line " NR ": " $8 > "/dev/stderr"; exit 1 }' "$out"
}

assert_plan_contract() {
  local base="$tmp_root/plan-contract"
  local out="$tmp_root/plan-contract.out"
  local all_out="$tmp_root/plan-contract-all.out"

  cp -R fixtures/plan-completion "$base"
  ./tools/edit-bqn --base "$base" plan list --format tsv >"$out"
  ./tools/edit-bqn --base "$base" plan list --all --format tsv >"$all_out"

  if ! awk -F '\t' '$1 == "1" && $2 == "plan-2026-01-10-phone" && $3 == "2026-01-10" && $8 == "" { found=1 } END { exit found ? 0 : 1 }' "$out"; then
    echo "FAIL: default plan list missing expected open plan row" >&2
    exit 1
  fi

  if grep -q $'\tCLOSED\t' "$out"; then
    echo "FAIL: default plan list emitted CLOSED row" >&2
    exit 1
  fi

  if ! awk -F '\t' '$2 == "" && $8 == "MISSING-ID" { found=1 } END { exit found ? 0 : 1 }' "$out"; then
    echo "FAIL: default plan list missing MISSING-ID status row" >&2
    exit 1
  fi

  if ! awk -F '\t' '$2 == "plan-2026-01-15-rent" && $8 == "CLOSED" { found=1 } END { exit found ? 0 : 1 }' "$all_out"; then
    echo "FAIL: plan list --all missing CLOSED status row" >&2
    exit 1
  fi
}

assert_plan_list_parity plan-completion-tsv fixtures/plan-completion --format tsv
assert_plan_list_parity plan-completion-tsv-all fixtures/plan-completion --all --format tsv
assert_plan_list_parity plan-completion-text-default fixtures/plan-completion
assert_plan_list_parity plan-completion-text fixtures/plan-completion --format text
assert_plan_list_parity plan-completion-text-all fixtures/plan-completion --all --format text
assert_plan_list_parity plan-completion-overdue fixtures/plan-completion --format tsv --temporal overdue --as-of 2026-01-24
assert_plan_list_parity plan-completion-upcoming fixtures/plan-completion --format tsv --temporal upcoming --as-of 2026-01-24
assert_plan_list_parity data-tsv data --format tsv
assert_tsv_shape plan-completion fixtures/plan-completion
assert_plan_contract

temporal_base="$tmp_root/temporal-contract"
cp -R fixtures/plan-completion "$temporal_base"
./tools/edit-bqn --base "$temporal_base" plan list --format tsv --temporal overdue --as-of 2026-01-24 >"$tmp_root/overdue.out"
./tools/edit-bqn --base "$temporal_base" plan list --format tsv --temporal upcoming --as-of 2026-01-24 >"$tmp_root/upcoming.out"
[[ $(wc -l <"$tmp_root/overdue.out" | tr -d ' ') -eq 1 ]]
awk -F '\t' '$3 != "2026-01-10" {exit 1}' "$tmp_root/overdue.out"
[[ $(wc -l <"$tmp_root/upcoming.out" | tr -d ' ') -eq 2 ]]
awk -F '\t' '$3 < "2026-01-24" {exit 1}' "$tmp_root/upcoming.out"

# Invalid CLI format/filter combinations should fail before touching source data or creating backups.
neg_base="$tmp_root/invalid-format"
cp -R fixtures/plan-completion "$neg_base"
neg_before="$(sha_file "$neg_base/plan.tsv")"
set +e
./tools/edit-bqn --base "$neg_base" plan list --format json >"$tmp_root/invalid.out" 2>&1
neg_rc=$?
set -e
if [ "$neg_rc" -eq 0 ]; then
  echo "FAIL: invalid plan list format unexpectedly succeeded" >&2
  cat "$tmp_root/invalid.out" >&2
  exit 1
fi
neg_after="$(sha_file "$neg_base/plan.tsv")"
if [ "$neg_before" != "$neg_after" ]; then
  echo "FAIL: invalid plan list format modified plan.tsv" >&2
  exit 1
fi

for bad_args in \
  '--temporal overdue' \
  '--temporal invalid --as-of 2026-01-24' \
  '--temporal upcoming --as-of invalid' \
  '--all --temporal overdue --as-of 2026-01-24'; do
  set +e
  # shellcheck disable=SC2086
  ./tools/edit-bqn --base "$neg_base" plan list --format tsv $bad_args >"$tmp_root/invalid-filter.out" 2>&1
  neg_rc=$?
  set -e
  [[ "$neg_rc" -ne 0 ]] || { echo "FAIL: invalid plan temporal filter unexpectedly succeeded: $bad_args" >&2; exit 1; }
done
[[ "$neg_before" == "$(sha_file "$neg_base/plan.tsv")" ]]
if [ -e "$neg_base/.backup" ] && find "$neg_base/.backup" -type f | grep -q .; then
  echo "FAIL: invalid plan temporal filter created backup" >&2
  exit 1
fi

printf 'OK edit-bqn plan list parity\n'
