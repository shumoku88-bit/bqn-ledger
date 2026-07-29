#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
out=$(mktemp "${TMPDIR:-/tmp}/bqn-ledger-cutover-inventory.XXXXXX")
trap 'rm -f "$out"' EXIT
./tools/characterization/final_cutover_inventory.py --assert-destination-clean >"$out"
for category in editor_import other_bqn_import other_test_import route_or_consumer src_next_check src_next_fixture src_next_module src_next_test; do
  grep -Eq "^${category}"$'\t''[1-9][0-9]*$' "$out"
done
grep -Fx $'destination_src_next_import\t0' "$out" >/dev/null
grep -Fx $'cutover_state\tblocked' "$out" >/dev/null
./tools/characterization/final_cutover_inventory.py --format tsv | sed -n '1p' \
  | grep -Fx $'category\taction\tpath' >/dev/null
echo 'check-final-cutover-inventory: OK'
