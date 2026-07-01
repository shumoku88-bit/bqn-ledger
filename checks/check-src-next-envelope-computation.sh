#!/usr/bin/env bash
set -euo pipefail

fixture="${1:-fixtures/src-next-envelope-computation}"
expected="$fixture/expected/src_next_summary.txt"

if [ ! -d "$fixture" ]; then
  echo "ERROR: fixture directory not found: $fixture" >&2
  exit 2
fi
if [ ! -f "$expected" ]; then
  echo "ERROR: expected envelope summary not found: $expected" >&2
  exit 2
fi

actual_raw="$(mktemp)"
actual_summary="$(mktemp)"
trap 'rm -f "$actual_raw" "$actual_summary"' EXIT

tools/report-next-summary "$fixture" 2>/dev/null > "$actual_raw"

grep -E '^(--- SrcNext Envelope Computation ---|src_next_envelope_)' "$actual_raw" > "$actual_summary"
diff -u "$expected" "$actual_summary"

# Semantic boundary checks for the Stage 4a prototype.
grep -q '^src_next_envelope_status: computed$' "$actual_summary"
grep -q '^src_next_envelope_allocated: 1000$' "$actual_summary"
grep -q '^src_next_envelope_actual_spent: 350$' "$actual_summary"
grep -q '^src_next_envelope_remaining: 650$' "$actual_summary"
grep -q '^src_next_envelope_unassigned_remaining: ¯1500$' "$actual_summary"
grep -q '^src_next_envelope_unassigned_status: OVER_ALLOCATED$' "$actual_summary"
grep -q '^src_next_envelope_unassigned_account_count: 1$' "$actual_summary"

# Planned spending must not be folded into remaining, and later-work fields must
# not appear under this prototype surface.
if grep -Eq 'safe_remaining|daily_amount|per-day allowance' "$actual_raw"; then
  echo "FAIL: envelope prototype output leaked later-work safe/daily_amount fields" >&2
  exit 1
fi

echo "OK: src_next envelope computation fixture passed: $fixture" >&2
