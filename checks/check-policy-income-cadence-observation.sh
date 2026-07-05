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
    $1 == "POLICY_INCOME_CADENCE" {
      if (state == "missing") next
      if (state == "empty") { $2 = ""; print; next }
      $2 = state
      print
      next
    }
    { print }
  ' "$BASE_FIXTURE/config.tsv" > "$EXPERIMENT_BASE/config.tsv"
}

run_state() {
  local state="$1"
  local out="$TMP_ROOT/out-$state"
  mkdir -p -- "$out"
  write_state "$state"

  NO_COLOR=1 bqn src_next/summary.bqn "$EXPERIMENT_BASE" \
    > "$out/summary.stdout" 2> "$out/summary.stderr"

  local section
  for section in \
    cycle outlook planned daily-trend actual-comparison \
    snapshot issues ytd balances trial-balance; do
    NO_COLOR=1 bqn src_next/report.bqn "$EXPERIMENT_BASE" --no-color --section "$section" \
      > "$out/section-$section.stdout" 2> "$out/section-$section.stderr"
  done
}

for state in missing empty bimonthly monthly; do
  run_state "$state"
done

reference="$TMP_ROOT/out-monthly"
status=0

for state in missing empty bimonthly; do
  candidate="$TMP_ROOT/out-$state"
  while IFS= read -r ref_file; do
    rel="${ref_file#"$reference/"}"
    candidate_file="$candidate/$rel"

    if ! cmp -s -- "$ref_file" "$candidate_file"; then
      echo "DIFF: stable surface monthly vs $state at $rel" >&2
      diff -u -- "$ref_file" "$candidate_file" >&2 || true
      status=1
    fi
  done < <(find "$reference" -type f | sort)
done

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

echo "income cadence observation: exact refs=config only; stable 4-state outputs identical" >&2
