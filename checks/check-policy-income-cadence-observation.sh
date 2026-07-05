#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_FIXTURE="fixtures/generalization-calendar"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-income-cadence.XXXXXX")"
trap 'rm -rf -- "$TMP_ROOT"' EXIT

# Exact runtime-reference map. A behavioral consumer may still use renamed concepts,
# so this is evidence only, not a repository-wide absence proof.
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
    $1 == "POLICY_INCOME_CADENCE" {
      if (state == "missing") next
      if (state == "empty") { $2 = ""; print; next }
      $2 = state
      print
      next
    }
    { print }
  ' "$BASE_FIXTURE/config.tsv" > "$dst/config.tsv"
}

run_state() {
  local state="$1"
  local base="$TMP_ROOT/$state"
  local out="$TMP_ROOT/out-$state"
  mkdir -p -- "$out"

  NO_COLOR=1 bqn src_next/summary.bqn "$base" \
    > "$out/summary.stdout" 2> "$out/summary.stderr"

  NO_COLOR=1 bqn src_next/report.bqn "$base" --no-color \
    > "$out/report.stdout" 2> "$out/report.stderr"

  local section
  for section in cycle outlook planned daily-trend actual-comparison; do
    NO_COLOR=1 bqn src_next/report.bqn "$base" --no-color --section "$section" \
      > "$out/section-$section.stdout" 2> "$out/section-$section.stderr"
  done
}

for state in missing empty bimonthly monthly; do
  make_state "$state"
  run_state "$state"
done

status=0
reference="$TMP_ROOT/out-monthly"

for state in missing empty bimonthly; do
  candidate="$TMP_ROOT/out-$state"
  while IFS= read -r ref_file; do
    rel="${ref_file#"$reference/"}"
    candidate_file="$candidate/$rel"

    if ! cmp -s -- "$ref_file" "$candidate_file"; then
      echo "DIFF: monthly vs $state at $rel" >&2
      diff -u -- "$ref_file" "$candidate_file" >&2 || true
      status=1
    fi
  done < <(find "$reference" -type f | sort)
done

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

echo "income cadence observation: exact src_next refs=config only; 4-state outputs identical" >&2
