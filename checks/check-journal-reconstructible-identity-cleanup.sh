#!/usr/bin/env bash
# checks/check-journal-reconstructible-identity-cleanup.sh
# Verifies reconstructible Journal identity cleanup CLI, unit test, candidate, apply,
# atomic rename, input SHA verification, and failure paths.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

echo "=== 1. Unit test ==="
if bqn "$ROOT/tests/test_journal_reconstructible_identity_cleanup.bqn"; then
  pass "unit test"
else
  fail "unit test"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

SYNTH_JOURNAL="$TMP_DIR/actual.journal"
cat << 'EOF' > "$SYNTH_JOURNAL"
account assets:cash
  ; role: asset

account expenses:food
  ; role: expense

account income:salary
  ; role: income

commodity JPY

; Top comment

2026-01-01 * "Removable migration item"
  ; layer: actual
  ; event-id: legacy:synthetic-source:0
  ; note: test note
  assets:cash -1000 JPY
  expenses:food 1000 JPY

2026-01-02 * "Preserved migration with plan"
  ; layer: actual
  ; event-id: legacy:synthetic-source:1
  ; plan-id: plan-2026-001
  assets:cash -2000 JPY
  expenses:food 2000 JPY

2026-01-03 * "Preserved completion item"
  ; layer: actual
  ; event-id: completion-plan-2026-002-2026-01-03
  ; plan-id: plan-2026-002
  assets:cash -3000 JPY
  expenses:food 3000 JPY

2026-01-04 * "Preserved purchase item 1"
  ; layer: actual
  ; event-id: purchase-synthetic-item-001
  assets:cash -4000 JPY
  expenses:food 4000 JPY

2026-01-05 * "Preserved purchase item 2"
  ; layer: actual
  ; event-id: purchase-synthetic-item-002
  assets:cash -5000 JPY
  expenses:food 5000 JPY

2026-01-06 * "Identity free multi-posting 食費・スーパー買い物"
  ; layer: actual
  ; note: multi posting note
  assets:cash -6000 JPY
  expenses:food 5000 JPY
  expenses:food 1000 JPY
EOF

echo "=== 2. CLI inspect mode ==="
INSPECT_OUT="$("$ROOT/tools/journal-identity-cleanup" inspect "$SYNTH_JOURNAL")"
if echo "$INSPECT_OUT" | grep -q "total_transactions=6" && \
   echo "$INSPECT_OUT" | grep -q "explicit_event_id=5" && \
   echo "$INSPECT_OUT" | grep -q "identity_free=1" && \
   echo "$INSPECT_OUT" | grep -q "removable_count=1" && \
   echo "$INSPECT_OUT" | grep -q "preserved_functional=2" && \
   echo "$INSPECT_OUT" | grep -q "preserved_purchase=2"; then
  pass "cli inspect output fields"
else
  fail "cli inspect output fields"
fi

echo "=== 3. CLI candidate mode ==="
CAND_OUT="$TMP_DIR/candidate.journal"
ORIG_SHA="$(shasum -a 256 "$SYNTH_JOURNAL" | awk '{print $1}')"

if "$ROOT/tools/journal-identity-cleanup" candidate "$SYNTH_JOURNAL" "$CAND_OUT" 1 >/dev/null; then
  pass "candidate creation"
else
  fail "candidate creation"
fi

# Verify input file was not modified
POST_CAND_SHA="$(shasum -a 256 "$SYNTH_JOURNAL" | awk '{print $1}')"
if [ "$ORIG_SHA" = "$POST_CAND_SHA" ]; then
  pass "input file unmodified by candidate"
else
  fail "input file unmodified by candidate"
fi

# Verify candidate output inspect
CAND_INSPECT="$("$ROOT/tools/journal-identity-cleanup" inspect "$CAND_OUT")"
if echo "$CAND_INSPECT" | grep -q "explicit_event_id=4" && \
   echo "$CAND_INSPECT" | grep -q "identity_free=2" && \
   echo "$CAND_INSPECT" | grep -q "removable_count=0"; then
  pass "candidate inspect valid"
else
  fail "candidate inspect valid"
fi

echo "=== 4. Candidate failure: existing output ==="
if "$ROOT/tools/journal-identity-cleanup" candidate "$SYNTH_JOURNAL" "$CAND_OUT" 1 2>/dev/null; then
  fail "should reject existing output file"
else
  pass "reject existing output file"
fi

echo "=== 5. Candidate failure: removal count mismatch ==="
MISMATCH_OUT="$TMP_DIR/mismatch.journal"
if "$ROOT/tools/journal-identity-cleanup" candidate "$SYNTH_JOURNAL" "$MISMATCH_OUT" 5 2>/dev/null; then
  fail "should reject removal count mismatch"
else
  pass "reject removal count mismatch"
fi

echo "=== 6. Apply failure: input SHA mismatch ==="
if "$ROOT/tools/journal-identity-cleanup" apply "$SYNTH_JOURNAL" "bad_sha_000000000000000000000000000000000000000000000000000000000000" 1 2>/dev/null; then
  fail "should reject SHA mismatch"
else
  pass "reject SHA mismatch"
fi

echo "=== 7. Apply failure: removal count mismatch ==="
if "$ROOT/tools/journal-identity-cleanup" apply "$SYNTH_JOURNAL" "$ORIG_SHA" 99 2>/dev/null; then
  fail "should reject apply removal count mismatch"
else
  pass "reject apply removal count mismatch"
fi

echo "=== 8. Apply success path ==="
APPLY_TARGET="$TMP_DIR/apply_target.journal"
cp "$SYNTH_JOURNAL" "$APPLY_TARGET"
TARGET_SHA="$(shasum -a 256 "$APPLY_TARGET" | awk '{print $1}')"

if "$ROOT/tools/journal-identity-cleanup" apply "$APPLY_TARGET" "$TARGET_SHA" 1 >/dev/null; then
  pass "apply success"
else
  fail "apply success"
fi

NEW_TARGET_SHA="$(shasum -a 256 "$APPLY_TARGET" | awk '{print $1}')"
if [ "$TARGET_SHA" != "$NEW_TARGET_SHA" ]; then
  pass "applied file updated"
else
  fail "applied file updated"
fi

APPLY_INSPECT="$("$ROOT/tools/journal-identity-cleanup" inspect "$APPLY_TARGET")"
if echo "$APPLY_INSPECT" | grep -q "explicit_event_id=4" && \
   echo "$APPLY_INSPECT" | grep -q "identity_free=2" && \
   echo "$APPLY_INSPECT" | grep -q "removable_count=0"; then
  pass "applied file inspect valid"
else
  fail "applied file inspect valid"
fi

echo ""
echo "check-journal-reconstructible-identity-cleanup.sh: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
echo "OK"
