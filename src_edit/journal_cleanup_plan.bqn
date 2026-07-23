# journal_cleanup_plan.bqn
# Pure classification and plan-row builder for legacy Journal event-id cleanup.

IsLegacyEntryId ← {𝕊 text:
  (30 = ≠ text) ∧ ("entry-" ≡ 6 ↑ text) ∧ ∧´ 1 ∾ ((6 ↓ text) ∊ "0123456789abcdef")
}

Classify ← {𝕊 tx‿allTransactions:
  incomingCount ← +´ 0 ∾ {
    (𝕩.layer_name ≡ "budget") ∧ (tx.source_event_id ≡ 𝕩.actual_event_id)
  }¨ allTransactions

  classification ← ""
  reason ← ""
  Set ← {𝕊 category‿why: classification ↩ category ⋄ reason ↩ why}

  {𝕊: Set ⟨"IDENTITY_FREE", "no-explicit-event-id"⟩} ⍟ (tx.identity_kind ≡ "physical_fallback") @
  {𝕊: Set ⟨"NOT_LEGACY", "non-legacy-event-id"⟩} ⍟ ((0 = ≠ classification) ∧ (tx.identity_kind ≡ "durable") ∧ ¬ IsLegacyEntryId tx.source_event_id) @
  {𝕊: Set ⟨"REFERENCED", "actual-event-id-reference"⟩} ⍟ ((0 = ≠ classification) ∧ (0 < incomingCount)) @
  {𝕊: Set ⟨"PLAN_LINKED", "plan-id"⟩} ⍟ ((0 = ≠ classification) ∧ (0 < ≠ tx.plan_id)) @

  otherReason ← ""
  SetOther ← {𝕊 why: otherReason ↩ why}
  {𝕊: SetOther "non-actual-layer"} ⍟ ((0 = ≠ otherReason) ∧ tx.layer_name ≢ "actual") @
  {𝕊: SetOther "non-durable-identity"} ⍟ ((0 = ≠ otherReason) ∧ tx.identity_kind ≢ "durable") @
  {𝕊: SetOther "txn-id"} ⍟ ((0 = ≠ otherReason) ∧ 0 < ≠ tx.txn_id) @
  {𝕊: SetOther "allocation-id"} ⍟ ((0 = ≠ otherReason) ∧ 0 < ≠ tx.allocation_id) @
  {𝕊: SetOther "actual-event-id"} ⍟ ((0 = ≠ otherReason) ∧ 0 < ≠ tx.actual_event_id) @
  {𝕊: SetOther "execution-envelope"} ⍟ ((0 = ≠ otherReason) ∧ 0 < ≠ tx.execution_envelope) @

  {𝕊: Set ⟨"OTHER_LINKED", otherReason⟩} ⍟ ((0 = ≠ classification) ∧ 0 < ≠ otherReason) @
  {𝕊: Set ⟨"REMOVABLE", "unreferenced-ordinary"⟩} ⍟ (0 = ≠ classification) @

  {classification⇐classification, reason⇐reason, incoming_reference_count⇐incomingCount}
}

Build ← {𝕊 transactions:
  {𝕊 index:
    tx ← index ⊑ transactions
    classified ← Classify ⟨tx, transactions⟩
    eventId ← ""
    eventIdLine ← 0
    {𝕊:
      eventId ↩ tx.source_event_id
      matching ← ({𝕩.key ≡ "event-id"}¨ tx.metadata) / tx.metadata
      {𝕊: eventIdLine ↩ (⊑ matching).source_line}⍟(0 < ≠ matching) @
    }⍟(tx.identity_kind ≡ "durable") @
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
