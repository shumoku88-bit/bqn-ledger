#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
reference ← •Import "daily_capacity_contract_reference.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
outlook ← •Import "../src_next/outlook.bqn"

Observation ← {𝕊 value:
  { date ⇐ value, source ⇐ "synthetic_test" }
}

Horizon ← {𝕊 state‿start‿end:
  {
    state ⇐ state,
    kind ⇐ "cycle",
    start ⇐ start,
    end_exclusive ⇐ end,
    source_ref ⇐ "synthetic:cycle"
  }
}

Domain ← {𝕊 state:
  {
    state ⇐ state,
    currency ⇐ "JPY",
    amount_scale ⇐ 0,
    basis ⇐ "synthetic_single_currency",
    message ⇐ ""
  }
}

AssetRow ← {𝕊 id‿kind‿amount‿decision:
  {
    asset_id ⇐ id,
    source_kind ⇐ kind,
    source_ref ⇐ "synthetic:asset:" ∾ id,
    currency ⇐ "JPY",
    amount ⇐ amount,
    decision ⇐ decision,
    decision_basis ⇐ "owner:test"
  }
}

AssetScope ← {𝕊 state‿basis‿rows:
  {
    state ⇐ state,
    scope_id ⇐ "synthetic-assets",
    basis_kind ⇐ basis,
    policy_ref ⇐ "owner:test-assets",
    rows ⇐ rows
  }
}

ObligationRow ← {𝕊 id‿dueOn‿amount‿settlement‿decision‿excluded‿reservationState‿reservationRef:
  {
    obligation_id ⇐ id,
    source_ref ⇐ "synthetic:obligation:" ∾ id,
    due_on ⇐ dueOn,
    currency ⇐ "JPY",
    amount ⇐ amount,
    settlement_state ⇐ settlement,
    decision ⇐ decision,
    decision_basis ⇐ "owner:test",
    excluded_from_asset_basis ⇐ excluded,
    reservation_state ⇐ reservationState,
    reservation_ref ⇐ reservationRef
  }
}

ObligationScope ← {𝕊 state‿rows:
  {
    state ⇐ state,
    scope_id ⇐ "synthetic-obligations",
    policy_ref ⇐ "owner:test-obligations",
    rows ⇐ rows
  }
}

Input ← {𝕊 observation‿horizon‿domain‿assets‿obligations:
  {
    observation ⇐ observation,
    horizon ⇐ horizon,
    arithmetic_domain ⇐ domain,
    asset_scope ⇐ assets,
    obligation_scope ⇐ obligations
  }
}

CheckCalculation ← {𝕊 result‿state‿eligible‿gross‿excluded‿deduction‿balance‿days‿daily‿shortfall:
  state lib.AssertEq result.state
  0 lib.AssertEq ≠ result.diagnostics
  eligible lib.AssertEq result.calculation.eligible_assets
  gross lib.AssertEq result.calculation.gross_admitted_obligations
  excluded lib.AssertEq result.calculation.already_excluded_from_asset_basis
  deduction lib.AssertEq result.calculation.obligation_deduction
  balance lib.AssertEq result.calculation.capacity_balance
  days lib.AssertEq result.calculation.remaining_days
  daily lib.AssertEq result.calculation.daily_capacity
  shortfall lib.AssertEq result.calculation.daily_shortfall
}

CheckDiagnostic ← {𝕊 result‿state‿code:
  state lib.AssertEq result.state
  0 lib.AssertEq ≠ result.calculation
  codes ← {𝕩.code}¨ result.diagnostics
  1 lib.AssertEq ∨´ 0 ∾ (code⊸≡¨ codes)
}

obs ← Observation "2026-07-01"
horizon ← Horizon ⟨"resolved", "2026-07-01", "2026-07-11"⟩
domain ← Domain "proven"
noAssets ← AssetScope ⟨"resolved", "account_balance", ⟨⟩⟩
noObligations ← ObligationScope ⟨"resolved", ⟨⟩⟩

# 1. A resolved empty asset scope is valid and distinct from missing ownership.
r1 ← reference.Build Input ⟨obs, horizon, domain, noAssets, noObligations⟩
CheckCalculation ⟨r1, "ok", 0, 0, 0, 0, 0, 10, 0, 0⟩

# 2. Included and excluded liquid accounts respect owner admission.
assets2 ← AssetScope ⟨"resolved", "account_balance", ⟨
  AssetRow ⟨"checking", "account_balance", 10000, "include"⟩,
  AssetRow ⟨"emergency", "account_balance", 5000, "exclude"⟩
⟩⟩
r2 ← reference.Build Input ⟨obs, horizon, domain, assets2, noObligations⟩
CheckCalculation ⟨r2, "ok", 10000, 0, 0, 0, 10000, 10, 1000, 0⟩

# 3. Negative admitted balances remain visible and produce a deficit.
assets3 ← AssetScope ⟨"resolved", "account_balance", ⟨AssetRow ⟨"overdrawn", "account_balance", ¯1000, "include"⟩⟩⟩
r3 ← reference.Build Input ⟨obs, horizon, domain, assets3, noObligations⟩
CheckCalculation ⟨r3, "deficit", ¯1000, 0, 0, 0, ¯1000, 10, 0, 100⟩

# 4. Account-balance basis without envelopes deducts an admitted obligation once.
assets4 ← AssetScope ⟨"resolved", "account_balance", ⟨AssetRow ⟨"checking", "account_balance", 10000, "include"⟩⟩⟩
ob4 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"rent", "2026-07-05", 2000, "open", "include", 0, "none", ""⟩⟩⟩
r4 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob4⟩
CheckCalculation ⟨r4, "ok", 10000, 2000, 0, 2000, 8000, 10, 800, 0⟩

# 5. Pool-remaining basis works without adding its backing account balances.
assets5 ← AssetScope ⟨"resolved", "pool_remaining", ⟨AssetRow ⟨"daily-flex", "pool_remaining", 4000, "include"⟩⟩⟩
ob5 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"utility", "2026-07-07", 1000, "open", "include", 0, "none", ""⟩⟩⟩
r5 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob5⟩
CheckCalculation ⟨r5, "ok", 4000, 1000, 0, 1000, 3000, 10, 300, 0⟩

# 6. Account and pool claims cannot be mixed without a non-overlap proof.
assets6 ← AssetScope ⟨"resolved", "account_balance", ⟨
  AssetRow ⟨"checking", "account_balance", 10000, "include"⟩,
  AssetRow ⟨"daily", "pool_remaining", 3000, "include"⟩
⟩⟩
r6 ← reference.Build Input ⟨obs, horizon, domain, assets6, noObligations⟩
CheckDiagnostic ⟨r6, "error", "mixed_asset_basis"⟩

# 7. An open admitted obligation exposes its exact deduction amount.
r7 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob4⟩
2000 lib.AssertEq (⊑ r7.obligation_evidence).deduction_amount

# 8. A completed obligation excluded by policy contributes no deduction.
ob8 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"paid-rent", "2026-07-05", 2000, "completed", "exclude", 0, "none", ""⟩⟩⟩
r8 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob8⟩
CheckCalculation ⟨r8, "ok", 10000, 0, 0, 0, 10000, 10, 1000, 0⟩

# 9. An overdue open obligation remains admitted.
ob9 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"overdue", "2026-06-25", 3000, "open", "include", 0, "none", ""⟩⟩⟩
r9 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob9⟩
CheckCalculation ⟨r9, "ok", 10000, 3000, 0, 3000, 7000, 10, 700, 0⟩

# 10. An obligation exactly on C.end_exclusive is outside the half-open horizon.
ob10 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"next-cycle", "2026-07-11", 1000, "open", "include", 0, "none", ""⟩⟩⟩
r10 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob10⟩
CheckDiagnostic ⟨r10, "error", "obligation_outside_horizon"⟩

# 11. An optional purchase excluded by owner policy is not an obligation deduction.
ob11 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"optional-book", "2026-07-04", 2500, "open", "exclude", 0, "none", ""⟩⟩⟩
r11 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob11⟩
CheckCalculation ⟨r11, "ok", 10000, 0, 0, 0, 10000, 10, 1000, 0⟩

# 12. A liquid-to-non-liquid transfer can be explicitly excluded as non-obligation.
ob12 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"savings-transfer", "2026-07-04", 3000, "open", "exclude", 0, "none", ""⟩⟩⟩
r12 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob12⟩
CheckCalculation ⟨r12, "ok", 10000, 0, 0, 0, 10000, 10, 1000, 0⟩

# 13. A fully externalized obligation is not deducted again.
ob13 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"externalized", "2026-07-05", 1000, "open", "include", 1000, "proven", "reservation:externalized"⟩⟩⟩
r13 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob13⟩
CheckCalculation ⟨r13, "ok", 4000, 1000, 1000, 0, 4000, 10, 400, 0⟩

# 14. Partial externalization deducts only the remaining portion.
ob14 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"partial", "2026-07-05", 1000, "open", "include", 400, "proven", "reservation:partial"⟩⟩⟩
r14 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob14⟩
CheckCalculation ⟨r14, "ok", 4000, 1000, 400, 600, 3400, 10, 340, 0⟩

# 15. Positive externalized amount without inspectable provenance fails closed.
ob15 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"missing-proof", "2026-07-05", 1000, "open", "include", 500, "proven", ""⟩⟩⟩
r15 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob15⟩
CheckDiagnostic ⟨r15, "error", "reservation_provenance_missing"⟩

# 16. Ambiguous basis relationship is unavailable, not a guessed amount.
ob16 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"ambiguous", "2026-07-05", 1000, "open", "include", 0, "ambiguous", "reservation:ambiguous"⟩⟩⟩
r16 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob16⟩
CheckDiagnostic ⟨r16, "unavailable", "reservation_provenance_ambiguous"⟩

# 17. Duplicate obligation identity is rejected.
ob17 ← ObligationScope ⟨"resolved", ⟨
  ObligationRow ⟨"dup", "2026-07-05", 500, "open", "include", 0, "none", ""⟩,
  ObligationRow ⟨"dup", "2026-07-06", 600, "open", "include", 0, "none", ""⟩
⟩⟩
r17 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob17⟩
CheckDiagnostic ⟨r17, "error", "duplicate_obligation_id"⟩

# 18. One reservation allocation identity cannot be reused for two obligations.
ob18 ← ObligationScope ⟨"resolved", ⟨
  ObligationRow ⟨"a", "2026-07-05", 500, "open", "include", 500, "proven", "reservation:same"⟩,
  ObligationRow ⟨"b", "2026-07-06", 600, "open", "include", 600, "proven", "reservation:same"⟩
⟩⟩
r18 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob18⟩
CheckDiagnostic ⟨r18, "error", "duplicate_reservation_linkage"⟩

# 19. Positive daily capacity rounds down.
assets19 ← AssetScope ⟨"resolved", "account_balance", ⟨AssetRow ⟨"checking", "account_balance", 12001, "include"⟩⟩⟩
r19 ← reference.Build Input ⟨obs, horizon, domain, assets19, ob4⟩
CheckCalculation ⟨r19, "ok", 12001, 2000, 0, 2000, 10001, 10, 1000, 0⟩

# 20. Deficit shortfall rounds up.
assets20 ← AssetScope ⟨"resolved", "account_balance", ⟨AssetRow ⟨"checking", "account_balance", 999, "include"⟩⟩⟩
r20 ← reference.Build Input ⟨obs, horizon, domain, assets20, ob4⟩
CheckCalculation ⟨r20, "deficit", 999, 2000, 0, 2000, ¯1001, 10, 0, 101⟩

# 21. O == C is an exhausted unavailable horizon, never divide-by-zero.
exhaustedObs ← Observation "2026-07-11"
r21 ← reference.Build Input ⟨exhaustedObs, horizon, domain, assets4, noObligations⟩
CheckDiagnostic ⟨r21, "unavailable", "horizon_exhausted"⟩

# 22. Observation before the selected horizon is an error.
beforeObs ← Observation "2026-06-30"
r22 ← reference.Build Input ⟨beforeObs, horizon, domain, assets4, noObligations⟩
CheckDiagnostic ⟨r22, "error", "observation_before_horizon_start"⟩

# 23. Observation after the selected horizon is an error.
afterObs ← Observation "2026-07-12"
r23 ← reference.Build Input ⟨afterObs, horizon, domain, assets4, noObligations⟩
CheckDiagnostic ⟨r23, "error", "observation_after_horizon"⟩

# 24. Missing asset ownership is unavailable and differs from resolved-empty.
assets24 ← AssetScope ⟨"unavailable", "account_balance", ⟨⟩⟩
r24 ← reference.Build Input ⟨obs, horizon, domain, assets24, noObligations⟩
CheckDiagnostic ⟨r24, "unavailable", "asset_scope_unavailable"⟩

# 25. Missing obligation ownership is unavailable.
ob25 ← ObligationScope ⟨"unavailable", ⟨⟩⟩
r25 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob25⟩
CheckDiagnostic ⟨r25, "unavailable", "obligation_scope_unavailable"⟩

# 26. Rejected arithmetic domain prevents addition.
r26 ← reference.Build Input ⟨obs, horizon, Domain "rejected", assets4, noObligations⟩
CheckDiagnostic ⟨r26, "error", "arithmetic_domain_rejected"⟩

# 27. A completed obligation cannot be included.
ob27 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"paid-but-included", "2026-07-05", 1000, "completed", "include", 0, "none", ""⟩⟩⟩
r27 ← reference.Build Input ⟨obs, horizon, domain, assets4, ob27⟩
CheckDiagnostic ⟨r27, "error", "completed_obligation_included"⟩

# 28. Duplicate asset identity is rejected.
assets28 ← AssetScope ⟨"resolved", "account_balance", ⟨
  AssetRow ⟨"dup", "account_balance", 1000, "include"⟩,
  AssetRow ⟨"dup", "account_balance", 2000, "include"⟩
⟩⟩
r28 ← reference.Build Input ⟨obs, horizon, domain, assets28, noObligations⟩
CheckDiagnostic ⟨r28, "error", "duplicate_asset_id"⟩

# 29. Reservation exclusion cannot exceed its obligation.
ob29 ← ObligationScope ⟨"resolved", ⟨ObligationRow ⟨"too-much", "2026-07-05", 1000, "open", "include", 1200, "proven", "reservation:too-much"⟩⟩⟩
r29 ← reference.Build Input ⟨obs, horizon, domain, assets5, ob29⟩
CheckDiagnostic ⟨r29, "error", "reservation_amount_invalid"⟩

# 30. Invalid observation text fails before arithmetic.
r30 ← reference.Build Input ⟨Observation "2026-02-30", horizon, domain, assets4, noObligations⟩
CheckDiagnostic ⟨r30, "error", "observation_invalid"⟩

# 31. Current runtime compatibility remains separately characterized.
simpleCtx ← ctx_mod.BuildContext "fixtures/household-monthly-salary"
simpleVm ← outlook.BuildAt ⟨simpleCtx, "2026-05-20"⟩
"unavailable/policy" lib.AssertEq simpleVm.liq_safe_daily

conservativeCtx ← ctx_mod.BuildContext "fixtures/src-next-anchor-unmet"
conservativeVm ← outlook.Build conservativeCtx
5240 lib.AssertEq conservativeVm.liq_safe_daily

•Out "test_daily_capacity_contract_characterization.bqn: OK"