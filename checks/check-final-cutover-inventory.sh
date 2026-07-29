#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
out=$(mktemp "${TMPDIR:-/tmp}/bqn-ledger-cutover-inventory.XXXXXX")
trap 'rm -f "$out"' EXIT
./tools/characterization/final_cutover_inventory.py --assert-destination-clean >"$out"
for category in documentation_reference other_bqn_import other_test_import route_or_consumer runtime_reference src_next_check src_next_fixture src_next_module src_next_test; do
  grep -Eq "^${category}"$'\t''[1-9][0-9]*$' "$out"
done
if grep -q '^editor_import' "$out"; then
  echo 'FAIL: live editor still imports src_next' >&2; exit 1
fi
grep -Fx $'destination_src_next_import\t0' "$out" >/dev/null
grep -Fx $'cutover_state\tblocked' "$out" >/dev/null
plan=$(mktemp "${TMPDIR:-/tmp}/bqn-ledger-cutover-plan.XXXXXX")
trap 'rm -f "$out" "$plan"' EXIT
./tools/characterization/final_cutover_inventory.py --format tsv >"$plan"
sed -n '1p' "$plan" | grep -Fx $'category\taction\tpath' >/dev/null
if grep -q '^unclassified_' "$plan"; then
  echo 'FAIL: cutover inventory has unclassified references' >&2; exit 1
fi
if awk -F '\t' 'NR>1 && ($2 ~ /or/ || $2 == "classify") {bad=1} END {exit !bad}' "$plan"; then
  echo 'FAIL: cutover disposition is not exact' >&2; exit 1
fi
echo 'check-final-cutover-inventory: OK'
