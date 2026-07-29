#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
parser ← •Import "../src/editor/journal_profile.bqn"
cleanup ← •Import "../src_edit/journal_cleanup_plan.bqn"

fixtureDir ← "fixtures/journal-legacy-entry-id-removal-boundary"
profile ← "historical_external_plan"

# Exact predicate is identical to the C4A characterization boundary.
lib.Assert cleanup.IsLegacyEntryId "entry-0123456789abcdef01234567"
lib.Assert cleanup.IsLegacyEntryId "entry-aaaaaaaaaaaaaaaaaaaaaaaa"
lib.Assert cleanup.IsLegacyEntryId "entry-bbbbbbbbbbbbbbbbbbbbbbbb"
lib.Assert ¬ cleanup.IsLegacyEntryId "entry-short"
lib.Assert ¬ cleanup.IsLegacyEntryId "entry-0123456789ABCDEF01234567"
lib.Assert ¬ cleanup.IsLegacyEntryId "opening-20260701-001"
lib.Assert ¬ cleanup.IsLegacyEntryId "budget-companion-household-001"
lib.Assert ¬ cleanup.IsLegacyEntryId "stage0-line-26"
lib.Assert ¬ cleanup.IsLegacyEntryId ""

before ← parser.ParseWithProfile ⟨loader.ReadRaw (fixtureDir ∾ "/before.journal"), profile⟩
"ok" lib.AssertEq before.state
rows ← cleanup.Build before.transactions
5 lib.AssertEq ≠ rows

Expected ← {
  index‿category‿reason‿eventId‿eventLine‿startLine‿refs‿planId ← 𝕩
  row ← index ⊑ rows
  (index + 1) lib.AssertEq row.number
  category lib.AssertEq row.classification
  reason lib.AssertEq row.reason
  eventId lib.AssertEq row.event_id
  eventLine lib.AssertEq row.event_id_line
  startLine lib.AssertEq row.source_start_line
  refs lib.AssertEq row.incoming_reference_count
  planId lib.AssertEq row.plan_id
}
Expected ⟨0, "NOT_LEGACY", "non-legacy-event-id", "opening-20260701-001", 22, 21, 0, ""⟩
Expected ⟨1, "REMOVABLE", "unreferenced-ordinary", "entry-0123456789abcdef01234567", 27, 26, 0, ""⟩
Expected ⟨2, "REFERENCED", "actual-event-id-reference", "entry-aaaaaaaaaaaaaaaaaaaaaaaa", 34, 33, 1, ""⟩
Expected ⟨3, "NOT_LEGACY", "non-legacy-event-id", "budget-companion-household-001", 39, 38, 0, ""⟩
Expected ⟨4, "PLAN_LINKED", "plan-id", "entry-bbbbbbbbbbbbbbbbbbbbbbbb", 46, 45, 0, "plan-legacy-household-001"⟩

Count ← {𝕊 category: +´ 0 ∾ {𝕩.classification ≡ category}¨ rows}
1 lib.AssertEq Count "REMOVABLE"
1 lib.AssertEq Count "REFERENCED"
1 lib.AssertEq Count "PLAN_LINKED"
0 lib.AssertEq Count "OTHER_LINKED"
0 lib.AssertEq Count "IDENTITY_FREE"
2 lib.AssertEq Count "NOT_LEGACY"

identityFree ← parser.ParseWithProfile ⟨loader.ReadRaw (fixtureDir ∾ "/after-unreferenced.journal"), profile⟩
"ok" lib.AssertEq identityFree.state
identityRows ← cleanup.Build identityFree.transactions
identityRow ← 1 ⊑ identityRows
"IDENTITY_FREE" lib.AssertEq identityRow.classification
"no-explicit-event-id" lib.AssertEq identityRow.reason
"" lib.AssertEq identityRow.event_id
0 lib.AssertEq identityRow.event_id_line
26 lib.AssertEq identityRow.source_start_line
0 lib.AssertEq identityRow.incoming_reference_count
lib.Assert ¬ "stage0-line-" ≡ 12 ↑ identityRow.event_id

legacyId ← "entry-cccccccccccccccccccccccc"
MakeTx ← {𝕊 kind‿layer‿planId‿txnId‿allocationId‿actualEventId‿executionEnvelope:
  {
    source_event_id⇐legacyId,
    identity_kind⇐kind,
    source_start_line⇐1,
    date⇐"2026-07-20",
    description⇐"synthetic",
    layer_name⇐layer,
    txn_id⇐txnId,
    plan_id⇐planId,
    allocation_id⇐allocationId,
    execution_envelope⇐executionEnvelope,
    actual_event_id⇐actualEventId,
    metadata⇐⟨{key⇐"event-id", value⇐legacyId, source_line⇐2}⟩
  }
}
ordinary ← MakeTx ⟨"durable", "actual", "", "", "", "", ""⟩
txnLinked ← MakeTx ⟨"durable", "actual", "", "txn-1", "", "", ""⟩
executionLinked ← MakeTx ⟨"durable", "actual", "", "", "", "", "daily"⟩
budgetLayer ← MakeTx ⟨"durable", "budget", "", "", "allocation-1", "", ""⟩

classified ← cleanup.Classify ⟨txnLinked, ⟨txnLinked⟩⟩
"OTHER_LINKED" lib.AssertEq classified.classification
"txn-id" lib.AssertEq classified.reason
classified ↩ cleanup.Classify ⟨executionLinked, ⟨executionLinked⟩⟩
"OTHER_LINKED" lib.AssertEq classified.classification
"execution-envelope" lib.AssertEq classified.reason
classified ↩ cleanup.Classify ⟨budgetLayer, ⟨budgetLayer⟩⟩
"OTHER_LINKED" lib.AssertEq classified.classification
"non-actual-layer" lib.AssertEq classified.reason

# Classification precedence.
referencingBudget ← MakeTx ⟨"durable", "budget", "", "", "", legacyId, ""⟩
referencedPlan ← MakeTx ⟨"durable", "actual", "plan-1", "", "", "", ""⟩
classified ↩ cleanup.Classify ⟨referencedPlan, ⟨referencedPlan, referencingBudget⟩⟩
"REFERENCED" lib.AssertEq classified.classification
"actual-event-id-reference" lib.AssertEq classified.reason

planAndTxn ← MakeTx ⟨"durable", "actual", "plan-1", "txn-1", "", "", ""⟩
classified ↩ cleanup.Classify ⟨planAndTxn, ⟨planAndTxn⟩⟩
"PLAN_LINKED" lib.AssertEq classified.classification
"plan-id" lib.AssertEq classified.reason

physical ← MakeTx ⟨"physical_fallback", "budget", "plan-1", "txn-1", "", legacyId, "daily"⟩
classified ↩ cleanup.Classify ⟨physical, ⟨physical⟩⟩
"IDENTITY_FREE" lib.AssertEq classified.classification
"no-explicit-event-id" lib.AssertEq classified.reason

•Out "test_journal_cleanup_plan.bqn: OK"
