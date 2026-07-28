#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
daily ← •Import "../src/accounting/daily_target.bqn"

Ref ← {𝕊 id:{source⇐"synthetic",transaction_id⇐id,posting_id⇐id}}
Asset ← {𝕊 id‿coefficient‿scaleValue:
  {asset_id⇐id,currency⇐"JPY",coefficient⇐coefficient,scale⇐scaleValue,decision⇐"include",reference⇐Ref id,contributors⇐⟨Ref id⟩}
}
Obligation ← {𝕊 id‿due‿coefficient‿scaleValue‿excluded‿excludedScale‿reservationState‿reservationRef:
  {obligation_id⇐id,due_ordinal⇐dates.Ordinal due,currency⇐"JPY",coefficient⇐coefficient,scale⇐scaleValue,settlement_state⇐"open",decision⇐"include",excluded_coefficient⇐excluded,excluded_scale⇐excludedScale,reservation_state⇐reservationState,reservation_ref⇐reservationRef,reference⇐Ref id,contributors⇐⟨Ref id⟩}
}
MakeAssetScope ← {𝕊 rows:{state⇐"resolved",scope_id⇐"owner-assets",basis_kind⇐"account_balance",rows⇐rows}}
MakeObligationScope ← {𝕊 rows:{state⇐"resolved",scope_id⇐"owner-obligations",rows⇐rows}}
Build ← {𝕊 assetRows‿obligationRows:daily.Build ⟨"2026-01-10","2026-01-20","JPY",(MakeAssetScope assetRows),(MakeObligationScope obligationRows)⟩}

funded ← Build ⟨⟨Asset ⟨"cash",1000,0⟩⟩,⟨Obligation ⟨"rent","2026-01-15",200,0,0,0,"none",""⟩⟩⟩
"ok" lib.AssertEq funded.state
0 lib.AssertEq funded.scale
1000 lib.AssertEq funded.calculation.eligible_assets
200 lib.AssertEq funded.calculation.gross_obligations
200 lib.AssertEq funded.calculation.obligation_deduction
800 lib.AssertEq funded.calculation.capacity_balance
10 lib.AssertEq funded.calculation.remaining_days
80 lib.AssertEq funded.calculation.daily_target
0 lib.AssertEq funded.calculation.daily_shortfall
"synthetic" lib.AssertEq (⊑funded.asset_evidence).reference.source
"synthetic" lib.AssertEq (⊑funded.obligation_evidence).reference.source

reserved ← Build ⟨⟨Asset ⟨"cash",1000,0⟩⟩,⟨Obligation ⟨"rent","2026-01-15",200,0,50,0,"proven","reservation:rent"⟩⟩⟩
50 lib.AssertEq reserved.calculation.already_excluded
150 lib.AssertEq reserved.calculation.obligation_deduction
85 lib.AssertEq reserved.calculation.daily_target

deficit ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨Obligation ⟨"rent","2026-01-15",250,0,0,0,"none",""⟩⟩⟩
"deficit" lib.AssertEq deficit.state
¯150 lib.AssertEq deficit.calculation.capacity_balance
0 lib.AssertEq deficit.calculation.daily_target
15 lib.AssertEq deficit.calculation.daily_shortfall

emptyObligations ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨⟩⟩
"ok" lib.AssertEq emptyObligations.state
10 lib.AssertEq emptyObligations.calculation.daily_target
# Overdue open obligations remain included.
overdue ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨Obligation ⟨"late","2026-01-05",20,0,0,0,"none",""⟩⟩⟩
80 lib.AssertEq overdue.calculation.capacity_balance

unavailableAssets ← {state⇐"unavailable",scope_id⇐"missing-assets",basis_kind⇐"account_balance",rows⇐⟨⟩}
unavailable ← daily.Build ⟨"2026-01-10","2026-01-20","JPY",unavailableAssets,(MakeObligationScope ⟨⟩)⟩
"unavailable" lib.AssertEq unavailable.state
"asset_scope_unavailable" lib.AssertEq unavailable.reason
⟨⟩ lib.AssertEq unavailable.calculation.daily_target

outside ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨Obligation ⟨"later","2026-01-20",20,0,0,0,"none",""⟩⟩⟩
"error" lib.AssertEq outside.state
"obligation_outside_horizon" lib.AssertEq (⊑outside.diagnostics).code

duplicateReservation ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨Obligation ⟨"a","2026-01-15",20,0,5,0,"proven","same"⟩,Obligation ⟨"b","2026-01-16",20,0,5,0,"proven","same"⟩⟩⟩
"error" lib.AssertEq duplicateReservation.state
lib.Assert ∨´"duplicate_reservation_linkage"⊸≡¨{𝕩.code}¨duplicateReservation.diagnostics

overExcluded ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨Obligation ⟨"a","2026-01-15",20,0,25,0,"proven","reservation:a"⟩⟩⟩
"error" lib.AssertEq overExcluded.state
"reservation_amount_invalid" lib.AssertEq (⊑overExcluded.diagnostics).code
completedRow ← {
  obligation_id⇐"done",due_ordinal⇐dates.Ordinal "2026-01-15",currency⇐"JPY",
  coefficient⇐20,scale⇐0,settlement_state⇐"completed",decision⇐"include",
  excluded_coefficient⇐0,excluded_scale⇐0,reservation_state⇐"none",reservation_ref⇐"",
  reference⇐Ref "done",contributors⇐⟨Ref "done"⟩
}
completed ← Build ⟨⟨Asset ⟨"cash",100,0⟩⟩,⟨completedRow⟩⟩
"error" lib.AssertEq completed.state
"completed_obligation_included" lib.AssertEq (⊑completed.diagnostics).code

mixedScale ← Build ⟨⟨Asset ⟨"cash",123,1⟩⟩,⟨Obligation ⟨"small","2026-01-15",5,2,0,0,"none",""⟩⟩⟩
"ok" lib.AssertEq mixedScale.state
2 lib.AssertEq mixedScale.scale
1225 lib.AssertEq mixedScale.calculation.capacity_balance
122 lib.AssertEq mixedScale.calculation.daily_target

overflow ← Build ⟨⟨Asset ⟨"cash",9007199254740991,0⟩⟩,⟨Obligation ⟨"fraction","2026-01-15",1,1,0,0,"none",""⟩⟩⟩
"error" lib.AssertEq overflow.state
"coefficient_normalization_failed" lib.AssertEq (⊑overflow.diagnostics).code

invalidDate ← daily.Build ⟨"2026-01-40","2026-01-20","JPY",(MakeAssetScope ⟨⟩),(MakeObligationScope ⟨⟩)⟩
"error" lib.AssertEq invalidDate.state
"observation_invalid" lib.AssertEq (⊑invalidDate.diagnostics).code
•Out "test_accounting_daily_target: ok"
