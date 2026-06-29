#!/usr/bin/env bash
set -euo pipefail

# Verify read-only `tools/edit-bqn plan list` output compatibility.
# `--format tsv` is consumed by tools/add-ui.sh plan selection, so this is
# byte-parity checked against the current Go editor fallback.

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
  local go_out="$tmp_root/$name.go.out"
  local bqn_out="$tmp_root/$name.bqn.out"
  local before_sha after_sha

  cp -R "$fixture" "$base"
  before_sha="$(sha_file "$base/plan.tsv")"

  ./tools/edit --base "$base" plan list "$@" >"$go_out"
  ./tools/edit-bqn --base "$base" plan list "$@" >"$bqn_out"

  if ! cmp -s "$go_out" "$bqn_out"; then
    echo "FAIL: plan list output differs from Go editor: $name $*" >&2
    diff -u "$go_out" "$bqn_out" >&2 || true
    exit 1
  fi

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
}

assert_plan_list_parity plan-completion-tsv fixtures/plan-completion --format tsv
assert_plan_list_parity plan-completion-tsv-all fixtures/plan-completion --all --format tsv
assert_plan_list_parity plan-completion-text-default fixtures/plan-completion
assert_plan_list_parity plan-completion-text fixtures/plan-completion --format text
assert_plan_list_parity plan-completion-text-all fixtures/plan-completion --all --format text
assert_plan_list_parity data-tsv data --format tsv
assert_tsv_shape plan-completion fixtures/plan-completion

# Invalid CLI format should fail before touching source data or creating backups.
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

printf 'OK edit-bqn plan list parity\n'
