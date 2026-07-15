# Test-only reference evaluator for DAILY_CAPACITY_MINIMAL_INPUT_RESULT_CONTRACT.md.
# This module is characterization evidence, not src_next runtime.

date ← •Import "../src_next/date.bqn"

Sum ← { +´ 0 ∾ 𝕩 }
AnyEq ← {𝕊 value‿xs: ∨´ 0 ∾ ({value ≡ 𝕩}¨ xs) }
HasDuplicates ← {𝕊 xs:
  first ← xs ⊐ xs
  ∨´ 0 ∾ ((↕ ≠ xs) ≠ first)
}

Diagnostic ← {𝕊 severity‿stage‿code‿message‿refs:
  {
    severity ⇐ severity,
    stage ⇐ stage,
    code ⇐ code,
    message ⇐ message,
    evidence_refs ⇐ refs
  }
}

NormalizeObligation ← {𝕊 row:
  {
    obligation_id ⇐ row.obligation_id,
    source_ref ⇐ row.source_ref,
    due_on ⇐ row.due_on,
    currency ⇐ row.currency,
    amount ⇐ row.amount,
    settlement_state ⇐ row.settlement_state,
    decision ⇐ row.decision,
    decision_basis ⇐ row.decision_basis,
    excluded_from_asset_basis ⇐ row.excluded_from_asset_basis,
    reservation_state ⇐ row.reservation_state,
    reservation_ref ⇐ row.reservation_ref,
    deduction_amount ⇐ row.amount - row.excluded_from_asset_basis
  }
}

Build ← {𝕊 input:
  diagnostics ← ⟨⟩
  Add ← {𝕊 severity‿stage‿code‿message‿refs:
    diagnostics ↩ diagnostics ∾ ⟨Diagnostic ⟨severity, stage, code, message, refs⟩⟩
  }

  observation ← input.observation
  horizon ← input.horizon
  domain ← input.arithmetic_domain
  assetScope ← input.asset_scope
  obligationScope ← input.obligation_scope

  # 1. Observation.
  observationOk ← date.IsValidDateText observation.date
  {𝕊: Add ⟨"error", "temporal", "observation_invalid", "observation date invalid", ⟨observation.date⟩⟩ }⍟(¬ observationOk) @

  # 2. Horizon and observation position.
  horizonReady ← 0
  horizonDatesReady ← 0
  knownHorizonState ← horizon.state ∊ ⟨"resolved", "unavailable", "error"⟩
  {𝕊: Add ⟨"error", "temporal", "horizon_invalid", "horizon state invalid", ⟨horizon.source_ref⟩⟩ }⍟(¬ knownHorizonState) @
  {𝕊: Add ⟨"unavailable", "temporal", "horizon_unavailable", "horizon unavailable", ⟨horizon.source_ref⟩⟩ }⍟(horizon.state ≡ "unavailable") @
  {𝕊: Add ⟨"error", "temporal", "horizon_invalid", "horizon evidence invalid", ⟨horizon.source_ref⟩⟩ }⍟(horizon.state ≡ "error") @
  {𝕊:
    kindOk ← horizon.kind ≡ "cycle"
    startOk ← date.IsValidDateText horizon.start
    endOk ← date.IsValidDateText horizon.end_exclusive
    orderOk ← 0
    {𝕊: orderOk ↩ (date.Ordinal horizon.start) < date.Ordinal horizon.end_exclusive }⍟(startOk ∧ endOk) @
    horizonDatesReady ↩ kindOk ∧ startOk ∧ endOk ∧ orderOk
    {𝕊: Add ⟨"error", "temporal", "horizon_invalid", "cycle horizon invalid", ⟨horizon.source_ref⟩⟩ }⍟(¬ horizonDatesReady) @
    {𝕊:
      o ← date.Ordinal observation.date
      s ← date.Ordinal horizon.start
      e ← date.Ordinal horizon.end_exclusive
      {𝕊: Add ⟨"error", "temporal", "observation_before_horizon_start", "observation before horizon start", ⟨observation.date, horizon.source_ref⟩⟩ }⍟(o < s) @
      {𝕊: Add ⟨"unavailable", "temporal", "horizon_exhausted", "horizon exhausted", ⟨observation.date, horizon.source_ref⟩⟩ }⍟(o = e) @
      {𝕊: Add ⟨"error", "temporal", "observation_after_horizon", "observation after horizon", ⟨observation.date, horizon.source_ref⟩⟩ }⍟(o > e) @
      horizonReady ↩ (s ≤ o) ∧ (o < e)
    }⍟(observationOk ∧ horizonDatesReady) @
  }⍟(horizon.state ≡ "resolved") @

  # 3. Arithmetic domain.
  domainReady ← (domain.state ≡ "proven") ∧ (0 < ≠ domain.currency) ∧ (0 ≤ domain.amount_scale)
  {𝕊: Add ⟨"error", "currency", "arithmetic_domain_rejected", "arithmetic domain rejected", ⟨domain.basis⟩⟩ }⍟(¬ domainReady) @

  # 4. Asset scope.
  assetReady ← 0
  knownAssetState ← assetScope.state ∊ ⟨"resolved", "unavailable", "error"⟩
  {𝕊: Add ⟨"error", "asset_scope", "asset_scope_error", "asset scope state invalid", ⟨assetScope.scope_id⟩⟩ }⍟(¬ knownAssetState) @
  {𝕊: Add ⟨"unavailable", "asset_scope", "asset_scope_unavailable", "asset scope unavailable", ⟨assetScope.scope_id⟩⟩ }⍟(assetScope.state ≡ "unavailable") @
  {𝕊: Add ⟨"error", "asset_scope", "asset_scope_error", "asset scope rejected", ⟨assetScope.scope_id⟩⟩ }⍟(assetScope.state ≡ "error") @
  {𝕊:
    rows ← assetScope.rows
    ids ← {𝕩.asset_id}¨ rows
    sourceKinds ← {𝕩.source_kind}¨ rows
    decisions ← {𝕩.decision}¨ rows
    refs ← {𝕩.source_ref}¨ rows
    currencies ← {𝕩.currency}¨ rows
    basisOk ← assetScope.basis_kind ∊ ⟨"account_balance", "pool_remaining"⟩
    duplicateIds ← HasDuplicates ids
    sameBasis ← {assetScope.basis_kind ≡ 𝕩}¨ sourceKinds
    mixedBasis ← ∨´ 0 ∾ (¬ sameBasis)
    decisionOk ← {𝕩 ∊ ⟨"include", "exclude"⟩}¨ decisions
    refOk ← {0 < ≠ 𝕩}¨ refs
    currencyOk ← {domain.currency ≡ 𝕩}¨ currencies
    invalidRows ← ¬ (decisionOk ∧ refOk ∧ currencyOk)
    hasInvalidRows ← ∨´ 0 ∾ invalidRows
    {𝕊: Add ⟨"error", "asset_scope", "asset_scope_error", "asset basis kind invalid", ⟨assetScope.scope_id⟩⟩ }⍟(¬ basisOk) @
    {𝕊: Add ⟨"error", "asset_scope", "duplicate_asset_id", "duplicate asset identity", ids⟩ }⍟duplicateIds @
    {𝕊: Add ⟨"error", "asset_scope", "mixed_asset_basis", "mixed asset basis", refs⟩ }⍟mixedBasis @
    {𝕊: Add ⟨"error", "asset_scope", "asset_row_invalid", "asset row invalid", invalidRows / ids⟩ }⍟hasInvalidRows @
    assetReady ↩ basisOk ∧ (¬ duplicateIds) ∧ (¬ mixedBasis) ∧ (¬ hasInvalidRows)
  }⍟(assetScope.state ≡ "resolved") @

  # 5. Obligation scope and horizon admission.
  obligationReady ← 0
  knownObligationState ← obligationScope.state ∊ ⟨"resolved", "unavailable", "error"⟩
  {𝕊: Add ⟨"error", "obligation_scope", "obligation_scope_error", "obligation scope state invalid", ⟨obligationScope.scope_id⟩⟩ }⍟(¬ knownObligationState) @
  {𝕊: Add ⟨"unavailable", "obligation_scope", "obligation_scope_unavailable", "obligation scope unavailable", ⟨obligationScope.scope_id⟩⟩ }⍟(obligationScope.state ≡ "unavailable") @
  {𝕊: Add ⟨"error", "obligation_scope", "obligation_scope_error", "obligation scope rejected", ⟨obligationScope.scope_id⟩⟩ }⍟(obligationScope.state ≡ "error") @
  {𝕊:
    rows ← obligationScope.rows
    ids ← {𝕩.obligation_id}¨ rows
    refs ← {𝕩.source_ref}¨ rows
    dueOns ← {𝕩.due_on}¨ rows
    currencies ← {𝕩.currency}¨ rows
    amounts ← {𝕩.amount}¨ rows
    settlements ← {𝕩.settlement_state}¨ rows
    decisions ← {𝕩.decision}¨ rows
    reservationStates ← {𝕩.reservation_state}¨ rows
    duplicateIds ← HasDuplicates ids
    refOk ← {0 < ≠ 𝕩}¨ refs
    dueOk ← date.IsValidDateText¨ dueOns
    currencyOk ← {domain.currency ≡ 𝕩}¨ currencies
    amountOk ← {0 ≤ 𝕩}¨ amounts
    settlementOk ← {𝕩 ∊ ⟨"open", "completed"⟩}¨ settlements
    decisionOk ← {𝕩 ∊ ⟨"include", "exclude"⟩}¨ decisions
    reservationStateOk ← {𝕩 ∊ ⟨"none", "proven", "ambiguous"⟩}¨ reservationStates
    invalidRows ← ¬ (refOk ∧ dueOk ∧ currencyOk ∧ amountOk ∧ settlementOk ∧ decisionOk ∧ reservationStateOk)
    included ← {"include" ≡ 𝕩}¨ decisions
    completedIncluded ← included ∧ ({"completed" ≡ 𝕩}¨ settlements)
    outside ← (≠ rows) ⥊ 0
    {𝕊:
      endOrdinal ← date.Ordinal horizon.end_exclusive
      outside ↩ included ∧ dueOk ∧ ({endOrdinal ≤ date.Ordinal 𝕩}¨ dueOns)
    }⍟horizonDatesReady @
    hasInvalidRows ← ∨´ 0 ∾ invalidRows
    hasCompletedIncluded ← ∨´ 0 ∾ completedIncluded
    hasOutside ← ∨´ 0 ∾ outside
    {𝕊: Add ⟨"error", "obligation_scope", "duplicate_obligation_id", "duplicate obligation identity", ids⟩ }⍟duplicateIds @
    {𝕊: Add ⟨"error", "obligation_scope", "obligation_row_invalid", "obligation row invalid", invalidRows / ids⟩ }⍟hasInvalidRows @
    {𝕊: Add ⟨"error", "obligation_scope", "completed_obligation_included", "completed obligation included", completedIncluded / ids⟩ }⍟hasCompletedIncluded @
    {𝕊: Add ⟨"error", "obligation_scope", "obligation_outside_horizon", "obligation outside horizon", outside / ids⟩ }⍟hasOutside @
    obligationReady ↩ (¬ duplicateIds) ∧ (¬ hasInvalidRows) ∧ (¬ hasCompletedIncluded) ∧ (¬ hasOutside)
  }⍟(obligationScope.state ≡ "resolved") @

  # 6. Reservation provenance.
  {𝕊:
    rows ← obligationScope.rows
    ids ← {𝕩.obligation_id}¨ rows
    amounts ← {𝕩.amount}¨ rows
    excluded ← {𝕩.excluded_from_asset_basis}¨ rows
    states ← {𝕩.reservation_state}¨ rows
    refs ← {𝕩.reservation_ref}¨ rows
    decisions ← {𝕩.decision}¨ rows
    included ← {"include" ≡ 𝕩}¨ decisions
    isAmbiguous ← {"ambiguous" ≡ 𝕩}¨ states
    isProven ← {"proven" ≡ 𝕩}¨ states
    isNone ← {"none" ≡ 𝕩}¨ states
    emptyRef ← {0 = ≠ 𝕩}¨ refs
    nonemptyRef ← {0 < ≠ 𝕩}¨ refs
    invalidAmount ← (excluded < 0) ∨ (excluded > amounts)
    ambiguous ← included ∧ isAmbiguous
    missing ← included ∧ (excluded > 0) ∧ ((¬ isProven) ∨ emptyRef) ∧ (¬ isAmbiguous)
    provenZero ← included ∧ isProven ∧ (excluded = 0)
    noneMismatch ← included ∧ isNone ∧ ((excluded ≠ 0) ∨ nonemptyRef)
    positiveProven ← included ∧ (excluded > 0) ∧ isProven ∧ nonemptyRef
    usedRefs ← positiveProven / refs
    duplicateReservation ← HasDuplicates usedRefs
    hasInvalidAmount ← ∨´ 0 ∾ invalidAmount
    hasAmbiguous ← ∨´ 0 ∾ ambiguous
    hasMissing ← ∨´ 0 ∾ missing
    hasProvenZero ← ∨´ 0 ∾ provenZero
    hasNoneMismatch ← ∨´ 0 ∾ noneMismatch
    {𝕊: Add ⟨"error", "reservation", "reservation_amount_invalid", "reservation amount invalid", invalidAmount / ids⟩ }⍟hasInvalidAmount @
    {𝕊: Add ⟨"unavailable", "reservation", "reservation_provenance_ambiguous", "reservation provenance ambiguous", ambiguous / ids⟩ }⍟hasAmbiguous @
    {𝕊: Add ⟨"error", "reservation", "reservation_provenance_missing", "reservation provenance missing", missing / ids⟩ }⍟hasMissing @
    {𝕊: Add ⟨"error", "reservation", "reservation_amount_invalid", "proven reservation has zero amount", provenZero / ids⟩ }⍟hasProvenZero @
    {𝕊: Add ⟨"error", "reservation", "reservation_amount_invalid", "none reservation carries evidence", noneMismatch / ids⟩ }⍟hasNoneMismatch @
    {𝕊: Add ⟨"error", "reservation", "duplicate_reservation_linkage", "duplicate reservation linkage", usedRefs⟩ }⍟duplicateReservation @
  }⍟(obligationScope.state ≡ "resolved") @

  severities ← {𝕩.severity}¨ diagnostics
  hasError ← AnyEq ⟨"error", severities⟩
  hasUnavailable ← AnyEq ⟨"unavailable", severities⟩

  normalizedObligations ← NormalizeObligation¨ obligationScope.rows
  result ← {
    state ⇐ "error",
    observation ⇐ observation,
    horizon ⇐ horizon,
    arithmetic_domain ⇐ domain,
    asset_evidence ⇐ assetScope.rows,
    obligation_evidence ⇐ normalizedObligations,
    calculation ⇐ ⟨⟩,
    diagnostics ⇐ diagnostics
  }

  {𝕊:
    state ← "unavailable"
    {𝕊: state ↩ "error" }⍟hasError @
    result ↩ {
      state ⇐ state,
      observation ⇐ observation,
      horizon ⇐ horizon,
      arithmetic_domain ⇐ domain,
      asset_evidence ⇐ assetScope.rows,
      obligation_evidence ⇐ normalizedObligations,
      calculation ⇐ ⟨⟩,
      diagnostics ⇐ diagnostics
    }
  }⍟(hasError ∨ hasUnavailable) @

  {𝕊:
    assetIncluded ← {"include" ≡ 𝕩}¨ ({𝕩.decision}¨ assetScope.rows)
    eligibleAssets ← Sum assetIncluded / ({𝕩.amount}¨ assetScope.rows)
    obligationIncluded ← {"include" ≡ 𝕩}¨ ({𝕩.decision}¨ obligationScope.rows)
    admittedAmounts ← obligationIncluded / ({𝕩.amount}¨ obligationScope.rows)
    admittedExcluded ← obligationIncluded / ({𝕩.excluded_from_asset_basis}¨ obligationScope.rows)
    grossObligations ← Sum admittedAmounts
    alreadyExcluded ← Sum admittedExcluded
    deduction ← grossObligations - alreadyExcluded
    balance ← eligibleAssets - deduction
    remaining ← date.DaysBetween ⟨observation.date, horizon.end_exclusive⟩
    state ← "ok"
    dailyCapacity ← ⌊ balance ÷ remaining
    dailyShortfall ← 0
    {𝕊:
      state ↩ "deficit"
      dailyCapacity ↩ 0
      dailyShortfall ↩ ⌈ (- balance) ÷ remaining
    }⍟(balance < 0) @
    result ↩ {
      state ⇐ state,
      observation ⇐ observation,
      horizon ⇐ horizon,
      arithmetic_domain ⇐ domain,
      asset_evidence ⇐ assetScope.rows,
      obligation_evidence ⇐ normalizedObligations,
      calculation ⇐ {
        eligible_assets ⇐ eligibleAssets,
        gross_admitted_obligations ⇐ grossObligations,
        already_excluded_from_asset_basis ⇐ alreadyExcluded,
        obligation_deduction ⇐ deduction,
        capacity_balance ⇐ balance,
        remaining_days ⇐ remaining,
        daily_capacity ⇐ dailyCapacity,
        daily_shortfall ⇐ dailyShortfall
      },
      diagnostics ⇐ ⟨⟩
    }
  }⍟((¬ hasError) ∧ (¬ hasUnavailable) ∧ horizonReady ∧ domainReady ∧ assetReady ∧ obligationReady) @

  result
}

{
  Build ⇐ Build
}