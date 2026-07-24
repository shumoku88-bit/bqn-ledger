#!/usr/bin/env bash
# checks/check-edit-bqn-journal-canonical-surface.sh
# End-to-end integration and safe-write checks for Journal Canonical Surface 001.

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$DIR/.." && pwd)"

source "$ROOT_DIR/tools/lib/safe-write.sh"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/bqn-ledger-canonical-check.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

setup_base() {
  local base="$1"
  mkdir -p "$base/data"
  cat <<'EOF' > "$base/accounts.tsv"
assets:cash	role=asset	type=asset	currency=JPY
expenses:food	role=expense	type=expense	currency=JPY
expenses:rent	role=expense	type=expense	currency=JPY
EOF
  cat <<'EOF' > "$base/cycle.tsv"
# year	month	start_day
2026	07	25
EOF
}

setup_fixture_a() {
  local base="$1"
  setup_base "$base"
  cat <<'EOF' > "$base/data/actual.journal"
commodity JPY

account assets:cash
    ; role: asset

account expenses:food
    ; role: expense

account expenses:rent
    ; role: expense

2026-07-24 * スーパー
    ; event-id: event-001
    ; layer: actual
    ; currency: JPY
    expenses:food 100 JPY
    assets:cash -100 JPY

2026-07-25 * 家賃
    ; event-id: event-002
    ; plan-id: plan-001
    ; tax: private
    ; biz: 0
    expenses:rent    64000 JPY
    assets:cash    -64000 JPY
EOF
}

setup_fixture_b() {
  local base="$1"
  setup_base "$base"
  cat <<'EOF' > "$base/data/actual.journal"
commodity JPY

account assets:cash
    ; role: asset

account expenses:food
    ; role: expense

2026-07-24 * スーパー
    ; event-id: event-001
    expenses:food    100 JPY
    assets:cash    -100 JPY
EOF
}

setup_fixture_c() {
  local base="$1"
  setup_base "$base"
  cat <<'EOF' > "$base/data/actual.journal"
commodity JPY

account assets:cash
    ; role: asset

2026-07-24 * Broken
    invalid_unsupported_line_here
EOF
}

echo "=== Test 1: Plan command on Fixture A ==="
BASE_A="$TMP_DIR/base_a"
setup_fixture_a "$BASE_A"

PLAN_TEXT="$("$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-plan --format text)"
echo "$PLAN_TEXT" | grep -q "Transactions: 2" || { echo "Test 1 failed: tx count"; exit 1; }
echo "$PLAN_TEXT" | grep -q "Single-space postings: 2" || { echo "Test 1 failed: single-space count"; exit 1; }
echo "$PLAN_TEXT" | grep -q "Layer:actual metadata: 1" || { echo "Test 1 failed: layer:actual count"; exit 1; }
echo "$PLAN_TEXT" | grep -q "Currency:JPY metadata: 1" || { echo "Test 1 failed: currency:jpy count"; exit 1; }

PLAN_TSV="$("$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-plan --format tsv)"
echo "$PLAN_TSV" | grep -q $'transactions\t2' || { echo "Test 1 failed TSV: tx count"; exit 1; }

# Privacy check: description, account names, and amount values must not leak to TSV output
if echo "$PLAN_TSV" | grep -qE "スーパー|expenses:food|100 JPY"; then
  echo "Test 1 failed: TSV plan leaked private data!"
  exit 1
fi
echo "Test 1 PASS"

echo "=== Test 2: Preview command on Fixture A ==="
PREVIEW_OUT="$TMP_DIR/preview_a.journal"
"$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-preview --output "$PREVIEW_OUT"

[[ -f "$PREVIEW_OUT" ]] || { echo "Test 2 failed: preview file not created"; exit 1; }
grep -q "; event-id: event-001" "$PREVIEW_OUT" || { echo "Test 2 failed: event-id removed"; exit 1; }
grep -q "; tax: private" "$PREVIEW_OUT" || { echo "Test 2 failed: tax metadata removed"; exit 1; }
grep -q "expenses:food    100 JPY" "$PREVIEW_OUT" || { echo "Test 2 failed: spacing not canonicalized"; exit 1; }
if grep -q "; layer: actual" "$PREVIEW_OUT"; then echo "Test 2 failed: layer:actual not removed"; exit 1; fi
if grep -q "; currency: JPY" "$PREVIEW_OUT"; then echo "Test 2 failed: currency:JPY not removed"; exit 1; fi
echo "Test 2 PASS"

echo "=== Test 3: Preview Output Equals Source Rejection (Fixture F) ==="
if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-preview --output "$BASE_A/data/actual.journal" 2>/dev/null; then
  echo "Test 3 failed: output equal to source was not rejected"
  exit 1
fi
echo "Test 3 PASS"

echo "=== Test 4: Apply Dry-run & Idempotency on Fixture B ==="
BASE_B="$TMP_DIR/base_b"
setup_fixture_b "$BASE_B"

APPLY_NOOP="$("$ROOT_DIR/tools/edit-bqn" --base "$BASE_B" journal canonical-surface-apply --dry-run)"
echo "$APPLY_NOOP" | grep -q "Journal is already canonical." || { echo "Test 4 failed: no-op message missing"; exit 1; }
[[ ! -d "$BASE_B/data/.backup" ]] || { echo "Test 4 failed: backup created for no-op"; exit 1; }
echo "Test 4 PASS"

echo "=== Test 5: Apply command with --apply on Fixture A ==="
BEFORE_SHA="$(_safe_write_sha256 "$BASE_A/data/actual.journal")"
"$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-apply --apply --yes
AFTER_SHA="$(_safe_write_sha256 "$BASE_A/data/actual.journal")"
[[ "$BEFORE_SHA" != "$AFTER_SHA" ]] || { echo "Test 5 failed: file was not modified"; exit 1; }
[[ -d "$BASE_A/data/.backup" ]] || { echo "Test 5 failed: backup not created"; exit 1; }

# Idempotency check on newly applied Journal
SECOND_APPLY="$("$ROOT_DIR/tools/edit-bqn" --base "$BASE_A" journal canonical-surface-apply --dry-run)"
echo "$SECOND_APPLY" | grep -q "Journal is already canonical." || { echo "Test 5 failed: idempotency check failed"; exit 1; }
echo "Test 5 PASS"

echo "=== Test 6: Unsupported Line (Fixture C Fail-closed) ==="
BASE_C="$TMP_DIR/base_c"
setup_fixture_c "$BASE_C"
if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_C" journal canonical-surface-preview --output "$TMP_DIR/c_out.journal" 2>/dev/null; then
  echo "Test 6 failed: unsupported line did not fail closed"
  exit 1
fi
[[ ! -f "$TMP_DIR/c_out.journal" ]] || { echo "Test 6 failed: candidate emitted on failure"; exit 1; }
echo "Test 6 PASS"

echo "=== Test 7: Stale Source Gate (Fixture D) ==="
BASE_D="$TMP_DIR/base_d"
setup_fixture_a "$BASE_D"

TARGET_D="$BASE_D/data/actual.journal"
SNAP_TOKEN="$(safe_snapshot_token "$TARGET_D")"
IFS=$'\t' read -r D_SIZE D_MTIME D_SHA <<< "$SNAP_TOKEN"

# Modify file after snapshot to simulate stale edit
sleep 1
echo " ; extra comment" >> "$TARGET_D"

if safe_rewrite_checked "$TARGET_D" "$PREVIEW_OUT" "$D_SIZE" "$D_MTIME" "$D_SHA" 2>/dev/null; then
  echo "Test 7 failed: stale source rewrite was not rejected"
  exit 1
fi
echo "Test 7 PASS"

echo "=== Test 8: Post-check Failure & Guarded Rollback (Fixture E) ==="
BASE_E="$TMP_DIR/base_e"
setup_fixture_a "$BASE_E"
TARGET_E="$BASE_E/data/actual.journal"
SNAP_E="$(_safe_write_sha256 "$TARGET_E")"

export BQN_LEDGER_TEST_MODE=1
export EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL=1

if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_E" journal canonical-surface-apply --apply --yes 2>/dev/null; then
  echo "Test 8 failed: forced post-check failure did not fail apply command"
  exit 1
fi

ROLLBACK_SHA="$(_safe_write_sha256 "$TARGET_E")"
[[ "$SNAP_E" == "$ROLLBACK_SHA" ]] || { echo "Test 8 failed: rollback did not restore original bytes"; exit 1; }

unset BQN_LEDGER_TEST_MODE
unset EDIT_BQN_TEST_FORCE_NATIVE_POST_CHECK_FAIL
echo "Test 8 PASS"

echo "=== Test 9: Option Combinations & Interactive Boundaries ==="
BASE_9="$TMP_DIR/base_9"
setup_fixture_a "$BASE_9"

# 9a: --yes without --apply must fail closed
if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_9" journal canonical-surface-apply --yes 2>/dev/null; then
  echo "Test 9a failed: --yes without --apply was not rejected"
  exit 1
fi

# 9b: --apply and --dry-run together must fail closed
if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_9" journal canonical-surface-apply --apply --dry-run 2>/dev/null; then
  echo "Test 9b failed: --apply --dry-run together was not rejected"
  exit 1
fi

# 9c: unknown option must fail closed
if "$ROOT_DIR/tools/edit-bqn" --base "$BASE_9" journal canonical-surface-apply --unknown 2>/dev/null; then
  echo "Test 9c failed: unknown option was not rejected"
  exit 1
fi

# 9d: --apply without --yes in non-interactive environment (EOF) must cancel without writing
SHA_9_BEFORE="$(_safe_write_sha256 "$BASE_9/data/actual.journal")"
APPLY_EOF_OUT="$("$ROOT_DIR/tools/edit-bqn" --base "$BASE_9" journal canonical-surface-apply --apply </dev/null)"
echo "$APPLY_EOF_OUT" | grep -q "Cancelled. No files were modified." || { echo "Test 9d failed: cancellation message missing"; exit 1; }
SHA_9_AFTER="$(_safe_write_sha256 "$BASE_9/data/actual.journal")"
[[ "$SHA_9_BEFORE" == "$SHA_9_AFTER" ]] || { echo "Test 9d failed: file was modified on non-interactive apply"; exit 1; }
echo "Test 9 PASS"

echo "ALL CANONICAL SURFACE CHECKS PASSED!"
