#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_FIXTURE="fixtures/generalization-calendar"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-income-cadence.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

mapfile -t runtime_matches < <(
  grep -RIl -E 'POLICY_INCOME_CADENCE|PolicyIncomeCadence' src_next | sort
)

if [ "${#runtime_matches[@]}" -ne 1 ] || [ "${runtime_matches[0]}" != "src_next/config.bqn" ]; then
  echo "FAIL: unexpected exact src_next income-cadence reference map" >&2
  printf '%s\n' "${runtime_matches[@]}" >&2
  exit 1
fi

make_state() {
  local state="$1"
  local dst="$TMP_ROOT/$state"

  cp -R -- "$BASE_FIXTURE" "$dst"
  awk -F '\t' -v OFS='\t' -v state="$state" '
    $1 == "POLICY_INCOME_CADENCE" { $2 = state; print; next }
    { print }
  ' "$BASE_FIXTURE/config.tsv" > "$dst/config.tsv"
}

for state in bimonthly monthly; do
  make_state "$state"
  NO_COLOR=1 bqn src_next/summary.bqn "$TMP_ROOT/$state" \
    > "$TMP_ROOT/$state.stdout" 2> "$TMP_ROOT/$state.stderr"
done

if ! cmp -s -- "$TMP_ROOT/monthly.stdout" "$TMP_ROOT/bimonthly.stdout"; then
  echo "DIFF: monthly vs bimonthly machine summary stdout" >&2
  diff -u -- "$TMP_ROOT/monthly.stdout" "$TMP_ROOT/bimonthly.stdout" >&2 || true
  exit 1
fi

if ! cmp -s -- "$TMP_ROOT/monthly.stderr" "$TMP_ROOT/bimonthly.stderr"; then
  echo "DIFF: monthly vs bimonthly machine summary stderr" >&2
  diff -u -- "$TMP_ROOT/monthly.stderr" "$TMP_ROOT/bimonthly.stderr" >&2 || true
  exit 1
fi

echo "income cadence observation: exact refs=config only; bimonthly/monthly summary identical" >&2
