#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_FIXTURE="fixtures/generalization-calendar"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-income-cadence.XXXXXX")"
EXPERIMENT_BASE="$TMP_ROOT/base"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

mapfile -t runtime_matches < <(
  grep -RIl -E 'POLICY_INCOME_CADENCE|PolicyIncomeCadence' src_next | sort
)

if [ "${#runtime_matches[@]}" -ne 1 ] || [ "${runtime_matches[0]}" != "src_next/config.bqn" ]; then
  echo "FAIL: unexpected exact src_next income-cadence reference map" >&2
  printf '%s\n' "${runtime_matches[@]}" >&2
  exit 1
fi

cp -R -- "$BASE_FIXTURE" "$EXPERIMENT_BASE"

write_state() {
  local state="$1"
  awk -F '\t' -v OFS='\t' -v state="$state" '
    $1 == "POLICY_INCOME_CADENCE" { $2 = state; print; next }
    { print }
  ' "$BASE_FIXTURE/config.tsv" > "$EXPERIMENT_BASE/config.tsv"
}

run_state() {
  local state="$1"
  local out="$TMP_ROOT/out-$state"
  mkdir -p -- "$out"
  write_state "$state"

  local section
  for section in envelopes check daily-flow; do
    NO_COLOR=1 bqn src_next/report.bqn "$EXPERIMENT_BASE" --no-color --section "$section" \
      > "$out/$section.stdout" 2> "$out/$section.stderr"
  done
}

for state in bimonthly monthly; do
  run_state "$state"
done

reference="$TMP_ROOT/out-monthly"
candidate="$TMP_ROOT/out-bimonthly"
status=0

while IFS= read -r ref_file; do
  rel="${ref_file#"$reference/"}"
  candidate_file="$candidate/$rel"

  if ! cmp -s -- "$ref_file" "$candidate_file"; then
    echo "DIFF: cadence section bisection B1 at $rel" >&2
    diff -u -- "$ref_file" "$candidate_file" >&2 || true
    status=1
  fi
done < <(find "$reference" -type f | sort)

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

echo "income cadence observation: section bisection B1 identical" >&2
