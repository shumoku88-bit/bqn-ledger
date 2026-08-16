# journal_cleanup_plan.bqn
# Pure classification and plan-row builder for legacy Journal event-id cleanup.

IsLegacyEntryId ← {𝕊 text:
  (30 = ≠ text) ∧ ("entry-" ≡ 6 ↑ text) ∧ ∧´ 1 ∾ ((6 ↓ text) ∊ "0123456789abcdef")
}

otherReasons ← ⟨"non-actual-layer","non-durable-identity","txn-id","allocation-id","actual-event-id","execution-envelope",""⟩
classificationNames ← ⟨"IDENTITY_FREE","NOT_LEGACY","REFERENCED","PLAN_LINKED","OTHER_LINKED","REMOVABLE"⟩

Classify ← {𝕊 tx‿allTransactions:
  incomingCount ← +´ 0 ∾ {
    (𝕩.layer_name ≡ "budget") ∧ (tx.source_event_id ≡ 𝕩.actual_event_id)
  }¨ allTransactions

  otherCases ← ⟨
    tx.layer_name ≢ "actual",
    tx.identity_kind ≢ "durable",
    0 < ≠ tx.txn_id,
    0 < ≠ tx.allocation_id,
    0 < ≠ tx.actual_event_id,
    0 < ≠ tx.execution_envelope,
    1
  ⟩
  otherIndex ← ⊑ otherCases / ↕≠otherCases
  otherReason ← otherIndex⊑otherReasons

  # Cleanup priority is one ordered classification axis. The final true case
  # makes it total; first-match selection preserves the established precedence.
  classificationCases ← ⟨
    tx.identity_kind ≡ "physical_fallback",
    (tx.identity_kind ≡ "durable") ∧ ¬ IsLegacyEntryId tx.source_event_id,
    0 < incomingCount,
    0 < ≠ tx.plan_id,
    0 < ≠ otherReason,
    1
  ⟩
  classificationIndex ← ⊑ classificationCases / ↕≠classificationCases
  classification ← classificationIndex⊑classificationNames
  reasons ← ⟨"no-explicit-event-id","non-legacy-event-id","actual-event-id-reference","plan-id",otherReason,"unreferenced-ordinary"⟩
  reason ← classificationIndex⊑reasons

  {classification⇐classification, reason⇐reason, incoming_reference_count⇐incomingCount}
}

Build ← {𝕊 transactions:
  {𝕊 index:
    tx ← index ⊑ transactions
    classified ← Classify ⟨tx, transactions⟩
    durable ← tx.identity_kind ≡ "durable"
    eventId ← durable⊑⟨"",tx.source_event_id⟩
    eventIdLine ← 0
    {𝕊:
      matching ← ({𝕩.key ≡ "event-id"}¨ tx.metadata) / tx.metadata
      {𝕊: eventIdLine ↩ (⊑ matching).source_line}⍟(0 < ≠ matching) @
    }⍟durable @
    {
      number⇐index + 1,
      classification⇐classified.classification,
      reason⇐classified.reason,
      date⇐tx.date,
      description⇐tx.description,
      event_id⇐eventId,
      event_id_line⇐eventIdLine,
      source_start_line⇐tx.source_start_line,
      incoming_reference_count⇐classified.incoming_reference_count,
      plan_id⇐tx.plan_id
    }
  }¨ ↕ ≠ transactions
}

{IsLegacyEntryId⇐IsLegacyEntryId, Classify⇐Classify, Build⇐Build}
