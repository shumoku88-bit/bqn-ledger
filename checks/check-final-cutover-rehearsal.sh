#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
out=$(mktemp "${TMPDIR:-/tmp}/bqn-ledger-cutover-rehearsal.XXXXXX")
trap 'rm -f "$out"' EXIT
python3 tools/characterization/final_cutover_rehearsal.py >"$out"
grep -Fx $'unclassified_actions\t0' "$out" >/dev/null
grep -Fx $'surviving_old_bqn_imports\t0' "$out" >/dev/null
grep -Fx $'surviving_old_named_paths\t0' "$out" >/dev/null
grep -Fx $'rehearsal_state\tready_for_atomic_diff' "$out" >/dev/null
echo 'check-final-cutover-rehearsal: OK'
