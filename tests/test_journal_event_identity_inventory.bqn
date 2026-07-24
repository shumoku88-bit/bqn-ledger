# tests/test_journal_event_identity_inventory.bqn
# Unit test for Journal event identity inventory multi-axis classifier and reference index.

lib ← •Import "test_lib.bqn"
inventory ← •Import "../src_edit/journal_identity_inventory.bqn"

# 1. Lexical family tests
"LEGACY_ENTRY_24HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "entry-0123456789abcdef01234567")
"PREFIXED_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "tx-123456")
"PREFIXED_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "reverse-abcdef012345")
"PREFIXED_OTHER" lib.AssertEq (inventory.ClassifyLexicalFamily "plan-2026-07-15-wifi")
"OPAQUE_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "0123456789abcdef")
"SEMANTIC_TEXT" lib.AssertEq (inventory.ClassifyLexicalFamily "semantic_id_test")
"NONE" lib.AssertEq (inventory.ClassifyLexicalFamily "")

# 2. Synthetic transaction inventory test
txs ← ⟨
  # 1. Identity-free
  {
    date⇐"2026-07-01", status_marker⇐"*", description⇐"item1", layer_name⇐"actual",
    identity_kind⇐"physical_fallback", source_event_id⇐"pos-1", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨⟩, source_start_line⇐1
  },
  # 2. Legacy entry-id (unreferenced)
  {
    date⇐"2026-07-02", status_marker⇐"*", description⇐"item2", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"entry-0123456789abcdef01234567", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"entry-0123456789abcdef01234567", source_line⇐5}⟩, source_start_line⇐4
  },
  # 3. Durable tx-id (plan-linked)
  {
    date⇐"2026-07-03", status_marker⇐"*", description⇐"item3", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"tx-abc123def456", plan_id⇐"plan-2026-07-03-wifi", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"tx-abc123def456", source_line⇐10}, {key⇐"plan-id", value⇐"plan-2026-07-03-wifi", source_line⇐11}⟩, source_start_line⇐9
  },
  # 4. Durable tx-id (referenced by budget layer row)
  {
    date⇐"2026-07-04", status_marker⇐"*", description⇐"item4", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"tx-target-event", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"tx-target-event", source_line⇐15}⟩, source_start_line⇐14
  },
  # 5. Budget layer row referencing item4
  {
    date⇐"2026-07-04", status_marker⇐"*", description⇐"item5", layer_name⇐"budget",
    identity_kind⇐"durable", source_event_id⇐"tx-budget-event", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"tx-target-event", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"tx-budget-event", source_line⇐20}, {key⇐"actual-event-id", value⇐"tx-target-event", source_line⇐21}⟩, source_start_line⇐19
  },
  # 6. Reverse command ID
  {
    date⇐"2026-07-05", status_marker⇐"*", description⇐"[reverse]item4", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"reverse-9876543210fe", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"reverse-9876543210fe", source_line⇐25}⟩, source_start_line⇐24
  }
⟩

rows ← inventory.BuildInventory txs
6 lib.AssertEq (≠ rows)

# Row 1: Identity-free
r1 ← 0 ⊑ rows
"IDENTITY_FREE" lib.AssertEq (r1.presence)
"IDENTITY_FREE" lib.AssertEq (r1.disposition)

# Row 2: Legacy entry-id
r2 ← 1 ⊑ rows
"EXPLICIT_EVENT_ID" lib.AssertEq (r2.presence)
"LEGACY_ENTRY_24HEX" lib.AssertEq (r2.lexical_family)
"TSV-to-Journal migration" lib.AssertEq (r2.provenance)
"NOT_RECONSTRUCTIBLE" lib.AssertEq (r2.reconstructibility)
"KEEP_NONRECONSTRUCTIBLE" lib.AssertEq (r2.disposition)

# Row 3: Plan-linked
r3 ← 2 ⊑ rows
1 lib.AssertEq (r3.has_plan_id)
"KEEP_FUNCTIONAL" lib.AssertEq (r3.disposition)

# Row 4: Referenced
r4 ← 3 ⊑ rows
1 lib.AssertEq (r4.incoming_reference_count)
"KEEP_REFERENCED" lib.AssertEq (r4.disposition)

# Row 6: Reverse command
r6 ← 5 ⊑ rows
"reverse command" lib.AssertEq (r6.provenance)
"NOT_RECONSTRUCTIBLE" lib.AssertEq (r6.reconstructibility)

•Out "test_journal_event_identity_inventory: PASS"
