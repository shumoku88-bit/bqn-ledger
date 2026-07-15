#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
assembler ← •Import "daily_capacity_evidence_assembler_reference.bqn"

Observation ← {𝕊:
  { date ⇐ "2026-07-01", source ⇐ "synthetic_test" }
}

Horizon ← {𝕊 state:
  {
    state ⇐ state,
    kind ⇐ "cycle",
    start ⇐ "2026-07-01",
    end_exclusive ⇐ "2026-07-11",
    source_ref ⇐ "synthetic:cycle"
  }
}

Proof ← {𝕊 state:
  {
    state ⇐ state,
    domain ⇐ "JPY",
    amount_scale ⇐ 0,
    basis ⇐ "synthetic:proof",
    message ⇐ ""
  }
}

AssetCandidate ← {𝕊 id‿amount:
  {
    asset_id ⇐ id,
    source_kind ⇐ "account_balance",
    source_ref ⇐ "synthetic:asset:" ∾ id,
    currency ⇐ "JPY",
    amount ⇐ amount
  }
}

AssetBasis ← {𝕊 state:
  { state ⇐ state, basis_kind ⇐ "account_balance", scope_id ⇐ "synthetic:assets" }
}

AssetDecision ← {𝕊 id‿decision:
  { asset_id ⇐ id, decision ⇐ decision, decision_basis ⇐ "owner:asset-policy" }
}

ObligationCandidate ← {𝕊 id‿amount:
  {
    obligation_id ⇐ id,
    source_ref ⇐ "synthetic:obligation:" ∾ id,
    due_on ⇐ "2026-07-05",
    currency ⇐ "JPY",
    amount ⇐ amount
  }
}

Settlement ← {𝕊 id‿state:
  { obligation_id ⇐ id, settlement_state ⇐ state, evidence_ref ⇐ "synthetic:settlement:" ∾ id }
}

ObligationDecision ← {𝕊 id‿decision:
  { obligation_id ⇐ id, decision ⇐ decision, decision_basis ⇐ "owner:obligation-policy" }
}

Reservation ← {𝕊 id‿state‿excluded‿ref:
  {
    obligation_id ⇐ id,
    reservation_state ⇐ state,
    excluded_from_asset_basis ⇐ excluded,
    reservation_ref ⇐ ref,
    evidence_ref ⇐ "synthetic:reservation:" ∾ id
  }
}

baseAssets ← ⟨AssetCandidate ⟨"checking", 10000⟩, AssetCandidate ⟨"emergency", 5000⟩⟩
baseAssetDecisions ← ⟨AssetDecision ⟨"checking", "include"⟩, AssetDecision ⟨"emergency", "exclude"⟩⟩
baseObligations ← ⟨ObligationCandidate ⟨"rent", 2000⟩, ObligationCandidate ⟨"optional", 700⟩⟩
baseSettlements ← ⟨Settlement ⟨"rent", "open"⟩, Settlement ⟨"optional", "open"⟩⟩
baseObligationDecisions ← ⟨ObligationDecision ⟨"rent", "include"⟩, ObligationDecision ⟨"optional", "exclude"⟩⟩
baseReservations ← ⟨Reservation ⟨"rent", "none", 0, ""⟩, Reservation ⟨"optional", "none", 0, ""⟩⟩

Request ← {𝕊 proof‿assetCandidates‿assetBasis‿assetDecisions‿obligationCandidates‿settlements‿obligationDecisions‿reservations:
  {
    observation_with_source ⇐ Observation @,
    resolved_horizon_evidence ⇐ Horizon "resolved",
    arithmetic_domain_proof ⇐ proof,
    asset_candidates ⇐ assetCandidates,
    asset_basis_decision ⇐ assetBasis,
    per_asset_decisions ⇐ assetDecisions,
    asset_policy_ref ⇐ "owner:asset-policy",
    obligation_candidates ⇐ obligationCandidates,
    settlement_evidence ⇐ settlements,
    per_obligation_decisions ⇐ obligationDecisions,
    obligation_policy_ref ⇐ { scope_id ⇐ "synthetic:obligations", policy_ref ⇐ "owner:obligation-policy" },
    reservation_evidence ⇐ reservations
  }
}

BaseRequest ← {𝕊:
  Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
}

Codes ← { {𝕩.code}¨ 𝕩.diagnostics }
CheckDiagnostic ← {𝕊 result‿state‿code:
  state lib.AssertEq result.state
  0 lib.AssertEq ≠ result.input
  1 lib.AssertEq ∨´ 0 ∾ (code⊸≡¨ Codes result)
}

# 1. Complete facts plus explicit decisions produce the contract-shaped input.
r1 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence BaseRequest @
"resolved" lib.AssertEq r1.state
0 lib.AssertEq ≠ r1.diagnostics
"JPY" lib.AssertEq r1.input.arithmetic_domain.currency
"include" lib.AssertEq (⊑ r1.input.asset_scope.rows).decision
"open" lib.AssertEq (⊑ r1.input.obligation_scope.rows).settlement_state
"none" lib.AssertEq (⊑ r1.input.obligation_scope.rows).reservation_state

# 2. An omitted asset decision is unavailable, never inferred from candidate facts.
r2 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", ⟨AssetDecision ⟨"checking", "include"⟩⟩, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r2, "unavailable", "asset_decision_missing"⟩

# 3. An omitted obligation decision is unavailable, never inferred from settlement facts.
r3 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, ⟨ObligationDecision ⟨"rent", "include"⟩⟩, baseReservations⟩
CheckDiagnostic ⟨r3, "unavailable", "obligation_decision_missing"⟩

# 4. A decision for no candidate is a structural error.
r4 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions ∾ ⟨AssetDecision ⟨"unknown", "include"⟩⟩, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r4, "error", "unknown_asset_decision_id"⟩

# 5. Duplicate decisions for one stable identity are an error.
r5 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions ∾ ⟨ObligationDecision ⟨"rent", "exclude"⟩⟩, baseReservations⟩
CheckDiagnostic ⟨r5, "error", "duplicate_obligation_decision_id"⟩

# 6. Basis absence is unavailable rather than a liquid-account fallback.
r6 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "unavailable", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r6, "unavailable", "asset_basis_unselected"⟩

# 7. A domain assertion must be proven before assembly.
r7 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "unsupported", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r7, "error", "arithmetic_domain_unproven"⟩

# 8. Ambiguous reservation evidence is unavailable and produces no input.
r8 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, ⟨Reservation ⟨"rent", "ambiguous", 0, ""⟩, Reservation ⟨"optional", "none", 0, ""⟩⟩⟩
CheckDiagnostic ⟨r8, "unavailable", "reservation_evidence_ambiguous"⟩

# 9. A reservation cannot point at an absent obligation.
r9 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, baseReservations ∾ ⟨Reservation ⟨"unknown", "proven", 10, "reservation:unknown"⟩⟩⟩
CheckDiagnostic ⟨r9, "error", "unknown_reservation_obligation_id"⟩

# 10. One positive reservation identity cannot link two obligations.
r10 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, ⟨Reservation ⟨"rent", "proven", 100, "reservation:same"⟩, Reservation ⟨"optional", "proven", 100, "reservation:same"⟩⟩⟩
CheckDiagnostic ⟨r10, "error", "duplicate_reservation_linkage"⟩

# 11. Candidate order, not decision/evidence order, is the deterministic output order.
r11 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", ⌽ baseAssets, AssetBasis "selected", ⌽ baseAssetDecisions, ⌽ baseObligations, ⌽ baseSettlements, ⌽ baseObligationDecisions, ⌽ baseReservations⟩
"resolved" lib.AssertEq r11.state
⟨"emergency", "checking"⟩ lib.AssertEq {𝕩.asset_id}¨ r11.input.asset_scope.rows
⟨"optional", "rent"⟩ lib.AssertEq {𝕩.obligation_id}¨ r11.input.obligation_scope.rows

# 12. Error precedence suppresses otherwise explanatory unavailable input.
r12 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "unavailable", baseAssetDecisions ∾ ⟨AssetDecision ⟨"unknown", "include"⟩⟩, baseObligations, baseSettlements, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r12, "error", "unknown_asset_decision_id"⟩

# 13. An invalid supplied settlement state is an error, never a normalized state.
r13 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, ⟨Settlement ⟨"rent", "unknown"⟩, Settlement ⟨"optional", "open"⟩⟩, baseObligationDecisions, baseReservations⟩
CheckDiagnostic ⟨r13, "error", "settlement_evidence_invalid"⟩

# 14. An invalid supplied reservation state is an error, never a normalized state.
r14 ← assembler.AssembleDailyCapacityInputFromResolvedEvidence Request ⟨Proof "proven", baseAssets, AssetBasis "selected", baseAssetDecisions, baseObligations, baseSettlements, baseObligationDecisions, ⟨Reservation ⟨"rent", "unknown", 0, ""⟩, Reservation ⟨"optional", "none", 0, ""⟩⟩⟩
CheckDiagnostic ⟨r14, "error", "reservation_evidence_invalid"⟩

•Out "test_daily_capacity_evidence_assembler_characterization.bqn: OK"
