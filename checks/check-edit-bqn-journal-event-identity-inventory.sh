#!/usr/bin/env bash
# checks/check-edit-bqn-journal-event-identity-inventory.sh
# Verifies Journal event identity inventory CLI and pure module.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Unit test ==="
bqn "$ROOT/tests/test_journal_event_identity_inventory.bqn"

echo "=== CLI summary format ==="
SUMMARY="$("$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format summary)"
echo "$SUMMARY" | grep -q "Journal Event Identity Inventory 002 Summary"
echo "$SUMMARY" | grep -q "total_transactions=9"
echo "$SUMMARY" | grep -q "explicit_event_id=9"
echo "$SUMMARY" | grep -q "family_prefixed_other=9"

echo "=== CLI tsv format ==="
TSV="$("$ROOT/tools/edit" --base "$ROOT/data" journal identity-inventory --format tsv)"
HEADER="$(echo "$TSV" | head -n 1)"
echo "$HEADER" | grep -q "ordinal"
echo "$HEADER" | grep -q "presence"
echo "$HEADER" | grep -q "lexical_family"
echo "$HEADER" | grep -q "disposition"
LINE_COUNT="$(echo "$TSV" | wc -l | tr -d ' ')"
test "$LINE_COUNT" -eq 10

echo "check-edit-bqn-journal-event-identity-inventory: PASS"
