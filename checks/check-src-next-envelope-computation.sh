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
human_out="$(mktemp)"
trap 'rm -f "$actual_raw" "$actual_summary" "$human_out"' EXIT

tools/report-next-summary "$fixture" 2>/dev/null > "$actual_raw"

grep -E '^(--- SrcNext Envelope Computation ---|src_next_envelope_)' "$actual_raw" > "$actual_summary"
diff -u "$expected" "$actual_summary"

# Semantic boundary checks for the Stage 4a prototype are now delegated to expected/src_next_summary.txt.
if grep -q $'^src_next_envelope_active_remaining_source: 謎\t' "$actual_summary" || \
   grep -q $'^src_next_envelope_active_movement: .*\tbudget:謎\t' "$actual_summary"; then
  echo "FAIL: unknown envelope_role leaked into active envelope total/provenance" >&2
  exit 1
fi

# Planned spending must not be folded into remaining, and later-work fields must
# not appear under this prototype surface.
if grep -Eq 'safe_remaining|daily_amount|per-day allowance' "$actual_raw"; then
  echo "FAIL: envelope prototype output leaked later-work safe/daily_amount fields" >&2
  exit 1
fi

tools/report "$fixture" --section envelopes --no-color > "$human_out"
grep -q '^\[Dynamic envelopes\]$' "$human_out"
grep -q '^\[Execution envelopes\]$' "$human_out"
grep -q '^\[Unknown role envelopes\]$' "$human_out"
grep -q '^\[Unassigned\]$' "$human_out"
grep -q '^ life_pri| 食費           |      1000|    350|   650|   35|       87|SAFE        $' "$human_out"
grep -q '^ life_pri| 日用品         |       500|       80|       420|HELD        $' "$human_out"
grep -q '^ life_pri| 謎             |       300|      0|   300|unknown_role$' "$human_out"
grep -q '^NOTE: unknown envelope_role は active envelope total に含めず、pace / execution advice もしません。$' "$human_out"
grep -q '^\[Backing check\]$' "$human_out"
grep -q '^  封筒対象資金(暫定:type=liquid): 0$' "$human_out"
grep -q '^  active封筒残高合計:              1070$' "$human_out"
grep -q '^  現金裏付け未割当:                ¯1070$' "$human_out"
grep -q '^\[Budget ledger\]$' "$human_out"
grep -q '^  予算台帳未割当:                   ¯1800$' "$human_out"
grep -q '^\[Delta\]$' "$human_out"
grep -q '^  現金裏付け未割当 - 予算台帳未割当: 730$' "$human_out"
grep -q '^  status: OVER_ALLOCATED$' "$human_out"
grep -q '^\[Backing provenance\]$' "$human_out"
grep -q '^  funding_base sources:$' "$human_out"
grep -q '^  (none)$' "$human_out"
grep -q '^  active envelope remaining:$' "$human_out"
grep -q '^  食費                                650$' "$human_out"
grep -q '^  日用品                              420$' "$human_out"
grep -q '^  ledger unassigned source:$' "$human_out"
grep -q '^  budget:unassigned                 ¯1800$' "$human_out"
grep -q '^\[Budget movement provenance\]$' "$human_out"
grep -q '^  ledger unassigned movements:$' "$human_out"
grep -q '^  2026-01-01 #0 budget:unassigned  credit    ¯1000 alloc_food$' "$human_out"
grep -q '^  2026-01-01 #1 budget:unassigned  credit     ¯500 alloc_goods$' "$human_out"
grep -q '^  2026-01-01 #2 budget:unassigned  credit     ¯300 alloc_unknown$' "$human_out"
grep -q '^  active envelope movements:$' "$human_out"
grep -q '^  2026-01-01 #0 budget:食費        debit      1000 alloc_food$' "$human_out"
grep -q '^  2026-01-01 #1 budget:日用品      debit       500 alloc_goods$' "$human_out"

echo "OK: src_next envelope computation fixture passed: $fixture" >&2
