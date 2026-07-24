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
if echo "$SUMMARY" | grep -q "Journal Event Identity Inventory 002 Summary"; then
  pass "summary header"
else
  fail "summary header"
fi
if echo "$SUMMARY" | grep -q "total_transactions=9"; then
  pass "total=9"
else
  fail "total=9"
fi
if echo "$SUMMARY" | grep -q "explicit_event_id=9"; then
  pass "explicit=9"
else
  fail "explicit=9"
fi
if echo "$SUMMARY" | grep -q "family_prefixed_other=9"; then
  pass "family_prefixed_other=9"
else
  fail "family_prefixed_other=9"
fi
# Verify SEMANTIC_TEXT is no longer used (renamed to TEXTUAL_OTHER)
if echo "$SUMMARY" | grep -q "family_textual_other="; then
  pass "textual_other field present"
else
  fail "textual_other field present"
fi
if echo "$SUMMARY" | grep -q "family_semantic_text"; then fail "semantic_text still present"; else pass "semantic_text removed"; fi
# Verify provenance confidence section exists
if echo "$SUMMARY" | grep -q "confidence_not_verified="; then
  pass "provenance confidence present"
else
  fail "provenance confidence present"
fi
# Verify duplicate/dangling/self-reference tracking
if echo "$SUMMARY" | grep -q "duplicate_identity_definitions="; then
  pass "duplicate count present"
else
  fail "duplicate count present"
fi
if echo "$SUMMARY" | grep -q "dangling_references="; then
  pass "dangling count present"
else
  fail "dangling count present"
fi
if echo "$SUMMARY" | grep -q "self_references="; then
  pass "self-ref count present"
else
  fail "self-ref count present"
fi
# Sandbox has no duplicates, dangling refs, or self-refs
if echo "$SUMMARY" | grep -q "duplicate_identity_definitions=0"; then
  pass "duplicate=0"
else
  fail "duplicate=0"
fi
if echo "$SUMMARY" | grep -q "dangling_references=0"; then
  pass "dangling=0"
else
  fail "dangling=0"
fi
if echo "$SUMMARY" | grep -q "self_references=0"; then
  pass "self-ref=0"
else
  fail "self-ref=0"
fi

echo "=== Summary privacy canaries ==="
# Summary must not contain private event IDs from sandbox
for canary in "sandbox-event-0" "sandbox-event-1" "sandbox-event-2"; do
  if echo "$SUMMARY" | grep -qF "$canary"; then fail "summary contains canary: $canary"; else pass "summary clean: $canary"; fi
done

echo "=== CLI tsv format ==="
TSV="$("$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format tsv)"
HEADER="$(echo "$TSV" | head -n 1)"
if echo "$HEADER" | grep -q "ordinal"; then
  pass "tsv ordinal header"
else
  fail "tsv ordinal header"
fi
if echo "$HEADER" | grep -q "presence"; then
  pass "tsv presence header"
else
  fail "tsv presence header"
fi
if echo "$HEADER" | grep -q "lexical_family"; then
  pass "tsv lexical_family header"
else
  fail "tsv lexical_family header"
fi
if echo "$HEADER" | grep -q "disposition"; then
  pass "tsv disposition header"
else
  fail "tsv disposition header"
fi
if echo "$HEADER" | grep -q "provenance_class"; then
  pass "tsv provenance_class header"
else
  fail "tsv provenance_class header"
fi
if echo "$HEADER" | grep -q "provenance_confidence"; then
  pass "tsv provenance_confidence header"
else
  fail "tsv provenance_confidence header"
fi
LINE_COUNT="$(echo "$TSV" | wc -l | tr -d ' ')"
if test "$LINE_COUNT" -eq 10; then
  pass "tsv line count=10"
else
  fail "tsv line count=$LINE_COUNT (expected 10)"
fi

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
if test "$BEFORE_SHA" = "$AFTER_SHA"; then
  pass "source SHA unchanged"
else
  fail "source SHA changed"
fi

echo "=== no backup or candidate created ==="
BACKUP_DIR="$ROOT/data/.backup"
if [ -d "$BACKUP_DIR" ]; then
  BACKUP_COUNT="$(find "$BACKUP_DIR" -name '*.bak' -newer "$SOURCE_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  if test "$BACKUP_COUNT" -eq 0; then
    pass "no new backups"
  else
    fail "backups created: $BACKUP_COUNT"
  fi
else
  pass "no backup dir"
fi

echo ""
echo "check-edit-bqn-journal-event-identity-inventory: $PASS passed, $FAIL failed"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
echo "OK"
