# tests/test_journal_event_identity_inventory.bqn
# Unit test for Journal event identity inventory multi-axis classifier,
# reference index, privacy boundary, and reference independence.

lib ← •Import "test_lib.bqn"
inventory ← •Import "../src_edit/journal_identity_inventory.bqn"

# ─── 1. Lexical family tests ───
# Lexical family is a syntax observation; these tests verify shape classification only.
"LEGACY_ENTRY_24HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "entry-0123456789abcdef01234567")
"PREFIXED_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "tx-123456")
"PREFIXED_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "reverse-abcdef012345")
"PREFIXED_OTHER" lib.AssertEq (inventory.ClassifyLexicalFamily "plan-2026-07-15-wifi")
"OPAQUE_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "0123456789abcdef")
"TEXTUAL_OTHER" lib.AssertEq (inventory.ClassifyLexicalFamily "semantic_id_test")
"TEXTUAL_OTHER" lib.AssertEq (inventory.ClassifyLexicalFamily "daily_groceries_july")
"NONE" lib.AssertEq (inventory.ClassifyLexicalFamily "")
"OTHER" lib.AssertEq (inventory.ClassifyLexicalFamily "___")
"OPAQUE_HEX" lib.AssertEq (inventory.ClassifyLexicalFamily "12345")

# ─── 2. Privacy canary fixture ───
# Synthetic fixture with easily-searchable private canary values.
# These MUST NOT appear in summary or redacted TSV output.
canaryTxs ← ⟨
  {
    date⇐"2026-07-01", status_marker⇐"*", description⇐"PRIVATE_DESCRIPTION_CANARY_852", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"PRIVATE_EVENT_CANARY_741", plan_id⇐"PRIVATE_PLAN_CANARY_963", txn_id⇐"PRIVATE_TXN_CANARY_159",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩,
    metadata⇐⟨{key⇐"event-id", value⇐"PRIVATE_EVENT_CANARY_741", source_line⇐5}, {key⇐"plan-id", value⇐"PRIVATE_PLAN_CANARY_963", source_line⇐6}, {key⇐"txn-id", value⇐"PRIVATE_TXN_CANARY_159", source_line⇐7}⟩,
    source_start_line⇐4
  }
⟩

canaryInv ← inventory.BuildInventory canaryTxs
canaryS ← inventory.Summarize canaryInv
summaryText ← inventory.FormatSummary canaryS
tsvText ← inventory.FormatTsv canaryInv

# Privacy: canary values MUST NOT appear in summary output
# We verify the canary substrings are not found anywhere in the output text
HasSubstring ← {
  needle ← 𝕨 ⋄ haystack ← 𝕩
  nLen ← ≠ needle ⋄ hLen ← ≠ haystack
  (nLen > hLen) ◶ ⟨
    {𝕊: ∨´ 0 ∾ { needle ≡ nLen ↑ 𝕩 ↓ haystack }¨ ↕ (hLen - nLen) + 1},
    {𝕊: 0}
  ⟩ @
}

# Summary must not contain any private canary values
0 lib.AssertEq ("PRIVATE_EVENT_CANARY_741" HasSubstring summaryText)
0 lib.AssertEq ("PRIVATE_DESCRIPTION_CANARY_852" HasSubstring summaryText)
0 lib.AssertEq ("PRIVATE_PLAN_CANARY_963" HasSubstring summaryText)
0 lib.AssertEq ("PRIVATE_TXN_CANARY_159" HasSubstring summaryText)

# Redacted TSV must not contain any private canary values
0 lib.AssertEq ("PRIVATE_EVENT_CANARY_741" HasSubstring tsvText)
0 lib.AssertEq ("PRIVATE_DESCRIPTION_CANARY_852" HasSubstring tsvText)
0 lib.AssertEq ("PRIVATE_PLAN_CANARY_963" HasSubstring tsvText)
0 lib.AssertEq ("PRIVATE_TXN_CANARY_159" HasSubstring tsvText)

# ─── 3. Synthetic transaction inventory with comprehensive scenarios ───
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
  # 3. Durable tx-id (plan-linked) — TEXTUAL_OTHER family, with plan-id
  {
    date⇐"2026-07-03", status_marker⇐"*", description⇐"item3", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"daily_groceries_july", plan_id⇐"plan-2026-07-03-wifi", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"daily_groceries_july", source_line⇐10}, {key⇐"plan-id", value⇐"plan-2026-07-03-wifi", source_line⇐11}⟩, source_start_line⇐9
  },
  # 4. Durable TEXTUAL_OTHER (referenced by budget layer row)
  {
    date⇐"2026-07-04", status_marker⇐"*", description⇐"item4", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"rent_payment_july", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"rent_payment_july", source_line⇐15}⟩, source_start_line⇐14
  },
  # 5. Budget layer row referencing item4 via actual-event-id
  {
    date⇐"2026-07-04", status_marker⇐"*", description⇐"item5", layer_name⇐"budget",
    identity_kind⇐"durable", source_event_id⇐"budget_alloc_july", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"rent_payment_july", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"budget_alloc_july", source_line⇐20}, {key⇐"actual-event-id", value⇐"rent_payment_july", source_line⇐21}⟩, source_start_line⇐19
  },
  # 6. Reverse command ID
  {
    date⇐"2026-07-05", status_marker⇐"*", description⇐"[reverse]item4", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"reverse-9876543210fe", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"reverse-9876543210fe", source_line⇐25}⟩, source_start_line⇐24
  },
  # 7. TEXTUAL_OTHER with source-event-id incoming reference
  {
    date⇐"2026-07-06", status_marker⇐"*", description⇐"item7", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"subscription_monthly", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"subscription_monthly", source_line⇐30}⟩, source_start_line⇐29
  },
  # 8. Another row referencing item7 via source-event-id
  {
    date⇐"2026-07-06", status_marker⇐"*", description⇐"item8_ref", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"follow_up_sub", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"follow_up_sub", source_line⇐35}, {key⇐"source-event-id", value⇐"subscription_monthly", source_line⇐36}⟩, source_start_line⇐34
  },
  # 9. TEXTUAL_OTHER with both plan-id and txn-id (several links)
  {
    date⇐"2026-07-07", status_marker⇐"*", description⇐"item9_multi", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"multi_link_event", plan_id⇐"plan-2026-07-07-rent", txn_id⇐"txn-multi-001",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"multi_link_event", source_line⇐40}, {key⇐"plan-id", value⇐"plan-2026-07-07-rent", source_line⇐41}, {key⇐"txn-id", value⇐"txn-multi-001", source_line⇐42}, {key⇐"series", value⇐"monthly", source_line⇐43}⟩, source_start_line⇐39
  }
⟩

inv ← inventory.BuildInventory txs
rows ← inv.rows
9 lib.AssertEq (≠ rows)

# Row 1: Identity-free
r1 ← 0 ⊑ rows
"IDENTITY_FREE" lib.AssertEq (r1.presence)
"IDENTITY_FREE" lib.AssertEq (r1.disposition)
"not_applicable" lib.AssertEq (r1.provenance_confidence)

# Row 2: Legacy entry-id
r2 ← 1 ⊑ rows
"EXPLICIT_EVENT_ID" lib.AssertEq (r2.presence)
"LEGACY_ENTRY_24HEX" lib.AssertEq (r2.lexical_family)
"TSV_MIGRATION_CANDIDATE" lib.AssertEq (r2.provenance_class)
"inferred_from_prefix" lib.AssertEq (r2.provenance_confidence)
"NOT_RECONSTRUCTIBLE" lib.AssertEq (r2.reconstructibility)
"KEEP_NONRECONSTRUCTIBLE" lib.AssertEq (r2.disposition)

# Row 3: TEXTUAL_OTHER with plan-id — lexical family does not suppress functional-link detection
r3 ← 2 ⊑ rows
"TEXTUAL_OTHER" lib.AssertEq (r3.lexical_family)
1 lib.AssertEq (r3.has_plan_id)
1 lib.AssertEq (r3.has_functional_link)
"KEEP_FUNCTIONAL" lib.AssertEq (r3.disposition)
"PLAN_COMPLETION_CANDIDATE" lib.AssertEq (r3.provenance_class)
"inferred_from_plan_link" lib.AssertEq (r3.provenance_confidence)

# Row 4: TEXTUAL_OTHER referenced via actual-event-id — lexical family does not suppress reference detection
r4 ← 3 ⊑ rows
"TEXTUAL_OTHER" lib.AssertEq (r4.lexical_family)
1 lib.AssertEq (r4.incoming_reference_count)
"KEEP_REFERENCED" lib.AssertEq (r4.disposition)

# Row 5: Budget layer referencing item4
r5 ← 4 ⊑ rows
"TEXTUAL_OTHER" lib.AssertEq (r5.lexical_family)

# Row 6: Reverse command
r6 ← 5 ⊑ rows
"REVERSE_COMMAND_CANDIDATE" lib.AssertEq (r6.provenance_class)
"inferred_from_prefix" lib.AssertEq (r6.provenance_confidence)
"NOT_RECONSTRUCTIBLE" lib.AssertEq (r6.reconstructibility)

# Row 7: TEXTUAL_OTHER referenced via source-event-id — reference detection is independent of lexical family
r7 ← 6 ⊑ rows
"TEXTUAL_OTHER" lib.AssertEq (r7.lexical_family)
1 lib.AssertEq (r7.incoming_reference_count)
"KEEP_REFERENCED" lib.AssertEq (r7.disposition)

# Row 9: TEXTUAL_OTHER with several functional links (plan-id + txn-id + series)
r9 ← 8 ⊑ rows
"TEXTUAL_OTHER" lib.AssertEq (r9.lexical_family)
1 lib.AssertEq (r9.has_plan_id)
1 lib.AssertEq (r9.has_txn_id)
1 lib.AssertEq (r9.has_series)
1 lib.AssertEq (r9.has_functional_link)
"KEEP_FUNCTIONAL" lib.AssertEq (r9.disposition)

# ─── 4. Reference independence: incoming count is independent of lexical family ───
# Row 4 (TEXTUAL_OTHER) has exactly 1 incoming reference
# Row 7 (TEXTUAL_OTHER) has exactly 1 incoming reference via source-event-id
# This proves that TEXTUAL_OTHER family does not suppress reference detection
1 lib.AssertEq (r4.incoming_reference_count)
1 lib.AssertEq (r7.incoming_reference_count)
# Disposition is KEEP_REFERENCED regardless of lexical family
"KEEP_REFERENCED" lib.AssertEq (r4.disposition)
"KEEP_REFERENCED" lib.AssertEq (r7.disposition)

# ─── 5. Duplicate and dangling reference tests ───
# No duplicates in the main test fixture
0 lib.AssertEq (inv.duplicate_identity_definitions)
# No dangling references (all reference targets exist as durable event-ids)
0 lib.AssertEq (inv.dangling_references)
# No self-references
0 lib.AssertEq (inv.self_references)

# Test duplicate detection with synthetic duplicate fixture
dupTxs ← ⟨
  {
    date⇐"2026-07-01", status_marker⇐"*", description⇐"dup1", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"shared_id", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"shared_id", source_line⇐5}⟩, source_start_line⇐4
  },
  {
    date⇐"2026-07-02", status_marker⇐"*", description⇐"dup2", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"shared_id", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩, metadata⇐⟨{key⇐"event-id", value⇐"shared_id", source_line⇐10}⟩, source_start_line⇐9
  }
⟩
dupInv ← inventory.BuildInventory dupTxs
1 lib.AssertEq (dupInv.duplicate_identity_definitions)

# Test dangling reference detection
dangTxs ← ⟨
  {
    date⇐"2026-07-01", status_marker⇐"*", description⇐"dang1", layer_name⇐"actual",
    identity_kind⇐"durable", source_event_id⇐"real_id", plan_id⇐"", txn_id⇐"",
    allocation_id⇐"", actual_event_id⇐"", execution_envelope⇐"", postings⇐⟨⟩,
    metadata⇐⟨{key⇐"event-id", value⇐"real_id", source_line⇐5}, {key⇐"actual-event-id", value⇐"nonexistent_target", source_line⇐6}⟩, source_start_line⇐4
  }
⟩
dangInv ← inventory.BuildInventory dangTxs
1 lib.AssertEq (dangInv.dangling_references)

•Out "test_journal_event_identity_inventory: PASS"
