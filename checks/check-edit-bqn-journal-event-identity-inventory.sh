#!/usr/bin/env bash
# checks/check-edit-bqn-journal-event-identity-inventory.sh
# Verifies Journal event identity inventory CLI, pure module, privacy boundary,
# and reference/duplicate/dangling handling.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1" >&2; }

echo "=== Unit test ==="
bqn "$ROOT/tests/test_journal_event_identity_inventory.bqn"
pass "unit test"

echo "=== CLI summary format ==="
SUMMARY="$("$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format summary)"
echo "$SUMMARY" | grep -q "Journal Event Identity Inventory 002 Summary" && pass "summary header" || fail "summary header"
echo "$SUMMARY" | grep -q "total_transactions=9" && pass "total=9" || fail "total=9"
echo "$SUMMARY" | grep -q "explicit_event_id=9" && pass "explicit=9" || fail "explicit=9"
echo "$SUMMARY" | grep -q "family_prefixed_other=9" && pass "family_prefixed_other=9" || fail "family_prefixed_other=9"
# Verify SEMANTIC_TEXT is no longer used (renamed to TEXTUAL_OTHER)
echo "$SUMMARY" | grep -q "family_textual_other=" && pass "textual_other field present" || fail "textual_other field present"
if echo "$SUMMARY" | grep -q "family_semantic_text"; then fail "semantic_text still present"; else pass "semantic_text removed"; fi
# Verify provenance confidence section exists
echo "$SUMMARY" | grep -q "confidence_not_verified=" && pass "provenance confidence present" || fail "provenance confidence present"
# Verify duplicate/dangling/self-reference tracking
echo "$SUMMARY" | grep -q "duplicate_identity_definitions=" && pass "duplicate count present" || fail "duplicate count present"
echo "$SUMMARY" | grep -q "dangling_references=" && pass "dangling count present" || fail "dangling count present"
echo "$SUMMARY" | grep -q "self_references=" && pass "self-ref count present" || fail "self-ref count present"
# Sandbox has no duplicates, dangling refs, or self-refs
echo "$SUMMARY" | grep -q "duplicate_identity_definitions=0" && pass "duplicate=0" || fail "duplicate=0"
echo "$SUMMARY" | grep -q "dangling_references=0" && pass "dangling=0" || fail "dangling=0"
echo "$SUMMARY" | grep -q "self_references=0" && pass "self-ref=0" || fail "self-ref=0"

echo "=== Summary privacy canaries ==="
# Summary must not contain private event IDs from sandbox
for canary in "sandbox-event-0" "sandbox-event-1" "sandbox-event-2"; do
  if echo "$SUMMARY" | grep -qF "$canary"; then fail "summary contains canary: $canary"; else pass "summary clean: $canary"; fi
done

echo "=== CLI tsv format ==="
TSV="$("$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format tsv)"
HEADER="$(echo "$TSV" | head -n 1)"
echo "$HEADER" | grep -q "ordinal" && pass "tsv ordinal header" || fail "tsv ordinal header"
echo "$HEADER" | grep -q "presence" && pass "tsv presence header" || fail "tsv presence header"
echo "$HEADER" | grep -q "lexical_family" && pass "tsv lexical_family header" || fail "tsv lexical_family header"
echo "$HEADER" | grep -q "disposition" && pass "tsv disposition header" || fail "tsv disposition header"
echo "$HEADER" | grep -q "provenance_class" && pass "tsv provenance_class header" || fail "tsv provenance_class header"
echo "$HEADER" | grep -q "provenance_confidence" && pass "tsv provenance_confidence header" || fail "tsv provenance_confidence header"
LINE_COUNT="$(echo "$TSV" | wc -l | tr -d ' ')"
test "$LINE_COUNT" -eq 10 && pass "tsv line count=10" || fail "tsv line count=$LINE_COUNT (expected 10)"

echo "=== TSV privacy canaries ==="
# Redacted TSV must not contain private event IDs, descriptions, account names, amounts
for canary in "sandbox-event-0" "sandbox-event-1" "sandbox-event-2" "sandbox-event-3"; do
  if echo "$TSV" | grep -qF "$canary"; then fail "tsv contains canary: $canary"; else pass "tsv clean: $canary"; fi
done

echo "=== private-tsv rejected ==="
if "$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format private-tsv 2>/dev/null; then
  fail "private-tsv should be rejected"
else
  pass "private-tsv rejected"
fi

echo "=== unknown format rejected ==="
if "$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format invalid 2>/dev/null; then
  fail "unknown format should be rejected"
else
  pass "unknown format rejected"
fi

echo "=== source SHA unchanged ==="
SOURCE_FILE="$ROOT/data/actual.journal"
BEFORE_SHA="$(shasum -a 256 "$SOURCE_FILE" | awk '{print $1}')"
"$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format summary >/dev/null
AFTER_SHA="$(shasum -a 256 "$SOURCE_FILE" | awk '{print $1}')"
test "$BEFORE_SHA" = "$AFTER_SHA" && pass "source SHA unchanged" || fail "source SHA changed"

echo "=== no backup or candidate created ==="
BACKUP_DIR="$ROOT/data/.backup"
if [ -d "$BACKUP_DIR" ]; then
  BACKUP_COUNT="$(find "$BACKUP_DIR" -name '*.bak' -newer "$SOURCE_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  test "$BACKUP_COUNT" -eq 0 && pass "no new backups" || fail "backups created: $BACKUP_COUNT"
else
  pass "no backup dir"
fi

echo ""
echo "check-edit-bqn-journal-event-identity-inventory: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
echo "OK"
