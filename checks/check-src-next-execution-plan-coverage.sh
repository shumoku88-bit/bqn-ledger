#!/usr/bin/env bash
set -euo pipefail

fixture="${1:-fixtures/src-next-execution-plan-coverage}"
expected="$fixture/expected/src_next_summary.txt"

if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi
if [ ! -f "$expected" ]; then
  echo "ERROR: expected summary not found: $expected" >&2
  exit 2
fi

actual_raw="$(mktemp)"
actual_summary="$(mktemp)"
human_out="$(mktemp)"
trap 'rm -f "$actual_raw" "$actual_summary" "$human_out"' EXIT

tools/report-next-summary "$fixture" 2>/dev/null > "$actual_raw"
grep -E '^(--- SrcNext Envelope Computation ---|src_next_envelope_)' "$actual_raw" > "$actual_summary"
diff -u "$expected" "$actual_summary"

grep -q '^src_next_envelope_execution_planned_envelope: 固定費予定$' "$actual_summary"
grep -q '^src_next_envelope_execution_planned_remaining: 3330$' "$actual_summary"
grep -q '^src_next_envelope_execution_planned_open_total: 3330$' "$actual_summary"
grep -q '^src_next_envelope_execution_planned_delta: 0$' "$actual_summary"
grep -q '^src_next_envelope_execution_planned_status: OK$' "$actual_summary"
grep -q $'^src_next_envelope_execution_planned_row: 2026-01-05\tfixed\twifi\t3000\twifi$' "$actual_summary"
grep -q $'^src_next_envelope_execution_planned_row: 2026-01-06\tfixed\tpovo\t330\tpovo$' "$actual_summary"

tools/report "$fixture" --section envelopes --no-color > "$human_out"
grep -q '^\[Execution planned coverage\]$' "$human_out"
grep -q '^  envelope:                 固定費予定$' "$human_out"
grep -q '^  envelope remaining:       3330$' "$human_out"
grep -q '^  unfinished planned total: 3330$' "$human_out"
grep -q '^  envelope - planned:       0$' "$human_out"
grep -q '^  status: OK$' "$human_out"
grep -q '^    2026-01-05 fixed        wifi                     3000$' "$human_out"
grep -q '^    2026-01-06 fixed        povo                      330$' "$human_out"

echo "OK: src_next execution plan coverage fixture passed: $fixture" >&2
