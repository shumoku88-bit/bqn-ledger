# Test-only reference assembler for DAILY_CAPACITY_EVIDENCE_ASSEMBLER_CHARACTERIZATION_CONTRACT.md.
# It accepts public in-memory facts and explicit decisions only.

empty ← ⟨⟩

AnyEq ← {𝕊 value‿xs: ∨´ 0 ∾ ({value ≡ 𝕩}¨ xs) }
HasDuplicates ← {𝕊 xs:
  first ← xs ⊐ xs
  ∨´ 0 ∾ ((↕ ≠ xs) ≠ first)
}
Nonempty ← { 0 < ≠ 𝕩 }

Diagnostic ← {𝕊 severity‿stage‿code‿message‿refs:
  {
    severity ⇐ severity,
    stage ⇐ stage,
    code ⇐ code,
    message ⇐ message,
    evidence_refs ⇐ refs
  }
}

Build ← {𝕊 request:
  diagnostics ← empty
  Add ← {𝕊 severity‿stage‿code‿message‿refs:
    diagnostics ↩ diagnostics ∾ ⟨Diagnostic ⟨severity, stage, code, message, refs⟩⟩
  }

  observation ← request.observation_with_source
  horizon ← request.resolved_horizon_evidence
  proof ← request.arithmetic_domain_proof
  assetCandidates ← request.asset_candidates
  basisDecision ← request.asset_basis_decision
  assetDecisions ← request.per_asset_decisions
  assetPolicyRef ← request.asset_policy_ref
  obligationCandidates ← request.obligation_candidates
  settlements ← request.settlement_evidence
  obligationDecisions ← request.per_obligation_decisions
  obligationPolicy ← request.obligation_policy_ref
  reservations ← request.reservation_evidence

  # 1. Structure and stable candidate identities.
  assetIds ← {𝕩.asset_id}¨ assetCandidates
  obligationIds ← {𝕩.obligation_id}¨ obligationCandidates
  assetDecisionIds ← {𝕩.asset_id}¨ assetDecisions
  settlementIds ← {𝕩.obligation_id}¨ settlements
  obligationDecisionIds ← {𝕩.obligation_id}¨ obligationDecisions
  reservationIds ← {𝕩.obligation_id}¨ reservations

  emptyAssetIds ← (¬ Nonempty¨ assetIds) / assetIds
  emptyObligationIds ← (¬ Nonempty¨ obligationIds) / obligationIds
  {𝕊: Add ⟨"error", "structure", "duplicate_asset_candidate_id", "asset candidate identity invalid or duplicate", assetIds⟩ }⍟((0 < ≠ emptyAssetIds) ∨ HasDuplicates assetIds) @
  {𝕊: Add ⟨"error", "structure", "duplicate_obligation_candidate_id", "obligation candidate identity invalid or duplicate", obligationIds⟩ }⍟((0 < ≠ emptyObligationIds) ∨ HasDuplicates obligationIds) @

  # 2. Observation and horizon carriers. Date validity remains the calculator's contract.
  {𝕊: Add ⟨"unavailable", "temporal", "observation_source_missing", "observation source missing", empty⟩ }⍟(¬ Nonempty observation.source) @
  knownHorizon ← AnyEq ⟨horizon.state, ⟨"resolved", "unavailable", "error"⟩⟩
  {𝕊: Add ⟨"error", "temporal", "horizon_evidence_error", "horizon state invalid", ⟨horizon.source_ref⟩⟩ }⍟(¬ knownHorizon) @
  {𝕊: Add ⟨"unavailable", "temporal", "horizon_evidence_unavailable", "horizon evidence unavailable", ⟨horizon.source_ref⟩⟩ }⍟(horizon.state ≡ "unavailable") @
  {𝕊: Add ⟨"error", "temporal", "horizon_evidence_error", "horizon evidence rejected", ⟨horizon.source_ref⟩⟩ }⍟(horizon.state ≡ "error") @

  # 3. Arithmetic proof normalization.
  proofOk ← (proof.state ≡ "proven") ∧ (Nonempty proof.domain) ∧ (0 ≤ proof.amount_scale)
  {𝕊: Add ⟨"error", "currency", "arithmetic_domain_unproven", "arithmetic domain proof not proven", ⟨proof.basis⟩⟩ }⍟(¬ proofOk) @

  # 4. Asset basis and explicit decision joins.
  knownBasisState ← AnyEq ⟨basisDecision.state, ⟨"selected", "unavailable", "error"⟩⟩
  basisKindOk ← AnyEq ⟨basisDecision.basis_kind, ⟨"account_balance", "pool_remaining"⟩⟩
  {𝕊: Add ⟨"error", "asset_scope", "asset_basis_error", "asset basis state invalid", ⟨basisDecision.scope_id⟩⟩ }⍟(¬ knownBasisState) @
  {𝕊: Add ⟨"unavailable", "asset_scope", "asset_basis_unselected", "asset basis unselected", ⟨basisDecision.scope_id⟩⟩ }⍟(basisDecision.state ≡ "unavailable") @
  {𝕊: Add ⟨"error", "asset_scope", "asset_basis_error", "asset basis rejected", ⟨basisDecision.scope_id⟩⟩ }⍟(basisDecision.state ≡ "error") @
  {𝕊: Add ⟨"error", "asset_scope", "asset_basis_error", "asset basis kind invalid", ⟨basisDecision.scope_id⟩⟩ }⍟((basisDecision.state ≡ "selected") ∧ (¬ basisKindOk)) @
  {𝕊: Add ⟨"unavailable", "asset_scope", "asset_policy_ref_missing", "asset policy reference missing", empty⟩ }⍟(¬ Nonempty assetPolicyRef) @
  unknownAssetDecisionIds ← (¬ ({AnyEq ⟨𝕩, assetIds⟩}¨ assetDecisionIds)) / assetDecisionIds
  {𝕊: Add ⟨"error", "asset_scope", "unknown_asset_decision_id", "asset decision references unknown candidate", unknownAssetDecisionIds⟩ }⍟(0 < ≠ unknownAssetDecisionIds) @
  {𝕊: Add ⟨"error", "asset_scope", "duplicate_asset_decision_id", "duplicate asset decision identity", assetDecisionIds⟩ }⍟(HasDuplicates assetDecisionIds) @
  missingAssetDecisionIds ← (¬ ({AnyEq ⟨𝕩, assetDecisionIds⟩}¨ assetIds)) / assetIds
  {𝕊: Add ⟨"unavailable", "asset_scope", "asset_decision_missing", "asset decision missing", missingAssetDecisionIds⟩ }⍟(0 < ≠ missingAssetDecisionIds) @

  # 5. Settlement facts and explicit obligation decisions.
  {𝕊: Add ⟨"unavailable", "obligation_scope", "obligation_policy_ref_missing", "obligation policy reference missing", empty⟩ }⍟(¬ Nonempty obligationPolicy.policy_ref) @
  unknownSettlementIds ← (¬ ({AnyEq ⟨𝕩, obligationIds⟩}¨ settlementIds)) / settlementIds
  {𝕊: Add ⟨"error", "obligation_scope", "unknown_settlement_obligation_id", "settlement references unknown obligation", unknownSettlementIds⟩ }⍟(0 < ≠ unknownSettlementIds) @
  {𝕊: Add ⟨"error", "obligation_scope", "duplicate_settlement_evidence", "duplicate settlement evidence", settlementIds⟩ }⍟(HasDuplicates settlementIds) @
  missingSettlementIds ← (¬ ({AnyEq ⟨𝕩, settlementIds⟩}¨ obligationIds)) / obligationIds
  {𝕊: Add ⟨"unavailable", "obligation_scope", "settlement_evidence_missing", "settlement evidence missing", missingSettlementIds⟩ }⍟(0 < ≠ missingSettlementIds) @
  settlementStates ← {𝕩.settlement_state}¨ settlements
  badSettlementIds ← (¬ ({AnyEq ⟨𝕩, ⟨"open", "completed"⟩⟩}¨ settlementStates)) / settlementIds
  {𝕊: Add ⟨"error", "obligation_scope", "settlement_evidence_invalid", "settlement state invalid", badSettlementIds⟩ }⍟(0 < ≠ badSettlementIds) @
  unknownObligationDecisionIds ← (¬ ({AnyEq ⟨𝕩, obligationIds⟩}¨ obligationDecisionIds)) / obligationDecisionIds
  {𝕊: Add ⟨"error", "obligation_scope", "unknown_obligation_decision_id", "obligation decision references unknown candidate", unknownObligationDecisionIds⟩ }⍟(0 < ≠ unknownObligationDecisionIds) @
  {𝕊: Add ⟨"error", "obligation_scope", "duplicate_obligation_decision_id", "duplicate obligation decision identity", obligationDecisionIds⟩ }⍟(HasDuplicates obligationDecisionIds) @
  missingObligationDecisionIds ← (¬ ({AnyEq ⟨𝕩, obligationDecisionIds⟩}¨ obligationIds)) / obligationIds
  {𝕊: Add ⟨"unavailable", "obligation_scope", "obligation_decision_missing", "obligation decision missing", missingObligationDecisionIds⟩ }⍟(0 < ≠ missingObligationDecisionIds) @

  # 6. Reservation joins. An omitted reservation record is unavailable, not none.
  unknownReservationIds ← (¬ ({AnyEq ⟨𝕩, obligationIds⟩}¨ reservationIds)) / reservationIds
  {𝕊: Add ⟨"error", "reservation", "unknown_reservation_obligation_id", "reservation references unknown obligation", unknownReservationIds⟩ }⍟(0 < ≠ unknownReservationIds) @
  {𝕊: Add ⟨"error", "reservation", "duplicate_reservation_evidence", "duplicate reservation evidence", reservationIds⟩ }⍟(HasDuplicates reservationIds) @
  missingReservationIds ← (¬ ({AnyEq ⟨𝕩, reservationIds⟩}¨ obligationIds)) / obligationIds
  {𝕊: Add ⟨"unavailable", "reservation", "reservation_evidence_missing", "reservation evidence missing", missingReservationIds⟩ }⍟(0 < ≠ missingReservationIds) @
  reservationStates ← {𝕩.reservation_state}¨ reservations
  badReservationIds ← (¬ ({AnyEq ⟨𝕩, ⟨"none", "proven", "ambiguous"⟩⟩}¨ reservationStates)) / reservationIds
  {𝕊: Add ⟨"error", "reservation", "reservation_evidence_invalid", "reservation state invalid", badReservationIds⟩ }⍟(0 < ≠ badReservationIds) @
  ambiguousReservationIds ← (({"ambiguous" ≡ 𝕩}¨ reservationStates) ∧ ({AnyEq ⟨𝕩, obligationIds⟩}¨ reservationIds)) / reservationIds
  {𝕊: Add ⟨"unavailable", "reservation", "reservation_evidence_ambiguous", "reservation evidence ambiguous", ambiguousReservationIds⟩ }⍟(0 < ≠ ambiguousReservationIds) @
  positiveProven ← ({𝕩.reservation_state ≡ "proven"}¨ reservations) ∧ (({𝕩.excluded_from_asset_basis}¨ reservations) > 0)
  usedRefs ← positiveProven / ({𝕩.reservation_ref}¨ reservations)
  {𝕊: Add ⟨"error", "reservation", "duplicate_reservation_linkage", "duplicate reservation linkage", usedRefs⟩ }⍟(HasDuplicates usedRefs) @

  severities ← {𝕩.severity}¨ diagnostics
  hasError ← AnyEq ⟨"error", severities⟩
  hasUnavailable ← AnyEq ⟨"unavailable", severities⟩
  result ← { state ⇐ "error", input ⇐ empty, diagnostics ⇐ diagnostics }

  {𝕊:
    state ← "unavailable"
    {𝕊: state ↩ "error" }⍟hasError @
    result ↩ { state ⇐ state, input ⇐ empty, diagnostics ⇐ diagnostics }
  }⍟(hasError ∨ hasUnavailable) @

  {𝕊:
    AssetDecisionFor ← {𝕊 id:
      ⊑ (({id ≡ 𝕩.asset_id}¨ assetDecisions) / assetDecisions)
    }
    AssetRow ← {𝕊 candidate:
      assetDecision ← AssetDecisionFor (candidate.asset_id)
      {
        asset_id ⇐ candidate.asset_id,
        source_kind ⇐ candidate.source_kind,
        source_ref ⇐ candidate.source_ref,
        currency ⇐ candidate.currency,
        amount ⇐ candidate.amount,
        decision ⇐ assetDecision.decision,
        decision_basis ⇐ assetDecision.decision_basis
      }
    }
    SettlementFor ← {𝕊 id:
      ⊑ (({id ≡ 𝕩.obligation_id}¨ settlements) / settlements)
    }
    ObligationDecisionFor ← {𝕊 id:
      ⊑ (({id ≡ 𝕩.obligation_id}¨ obligationDecisions) / obligationDecisions)
    }
    ReservationFor ← {𝕊 id:
      ⊑ (({id ≡ 𝕩.obligation_id}¨ reservations) / reservations)
    }
    ObligationRow ← {𝕊 candidate:
      settlement ← SettlementFor (candidate.obligation_id)
      obligationDecision ← ObligationDecisionFor (candidate.obligation_id)
      reservation ← ReservationFor (candidate.obligation_id)
      {
        obligation_id ⇐ candidate.obligation_id,
        source_ref ⇐ candidate.source_ref,
        due_on ⇐ candidate.due_on,
        currency ⇐ candidate.currency,
        amount ⇐ candidate.amount,
        settlement_state ⇐ settlement.settlement_state,
        decision ⇐ obligationDecision.decision,
        decision_basis ⇐ obligationDecision.decision_basis,
        excluded_from_asset_basis ⇐ reservation.excluded_from_asset_basis,
        reservation_state ⇐ reservation.reservation_state,
        reservation_ref ⇐ reservation.reservation_ref
      }
    }
    result ↩ {
      state ⇐ "resolved",
      input ⇐ {
        observation ⇐ observation,
        horizon ⇐ horizon,
        arithmetic_domain ⇐ {
          state ⇐ "proven",
          currency ⇐ proof.domain,
          amount_scale ⇐ proof.amount_scale,
          basis ⇐ proof.basis,
          message ⇐ proof.message
        },
        asset_scope ⇐ {
          state ⇐ "resolved",
          scope_id ⇐ basisDecision.scope_id,
          basis_kind ⇐ basisDecision.basis_kind,
          policy_ref ⇐ assetPolicyRef,
          rows ⇐ AssetRow¨ assetCandidates
        },
        obligation_scope ⇐ {
          state ⇐ "resolved",
          scope_id ⇐ obligationPolicy.scope_id,
          policy_ref ⇐ obligationPolicy.policy_ref,
          rows ⇐ ObligationRow¨ obligationCandidates
        }
      },
      diagnostics ⇐ empty
    }
  }⍟((¬ hasError) ∧ (¬ hasUnavailable)) @

  result
}

{ AssembleDailyCapacityInputFromResolvedEvidence ⇐ Build }
