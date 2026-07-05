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

awk -F '\t' -v OFS='\t' '
  $1 == "POLICY_INCOME_CADENCE" { $2 = "monthly"; print; next }
  { print }
' "$BASE_FIXTURE/config.tsv" > "$EXPERIMENT_BASE/config.tsv"

for run in first second; do
  NO_COLOR=1 bqn src_next/report.bqn "$EXPERIMENT_BASE" --no-color --section envelopes \
    > "$TMP_ROOT/$run.stdout" 2> "$TMP_ROOT/$run.stderr"
done

if ! cmp -s -- "$TMP_ROOT/first.stdout" "$TMP_ROOT/second.stdout"; then
  echo "DIFF: monthly envelopes repeatability stdout" >&2
  diff -u -- "$TMP_ROOT/first.stdout" "$TMP_ROOT/second.stdout" >&2 || true
  exit 1
fi

if ! cmp -s -- "$TMP_ROOT/first.stderr" "$TMP_ROOT/second.stderr"; then
  echo "DIFF: monthly envelopes repeatability stderr" >&2
  diff -u -- "$TMP_ROOT/first.stderr" "$TMP_ROOT/second.stderr" >&2 || true
  exit 1
fi

echo "income cadence observation control: monthly envelopes repeatable" >&2
