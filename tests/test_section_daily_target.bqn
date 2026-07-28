#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
accounting ← •Import "../src/accounting/daily_target.bqn"
section ← •Import "../src/sections/daily_target.bqn"
Ref ← {𝕊 id:{source⇐"synthetic",transaction_id⇐id,posting_id⇐id}}
asset ← {asset_id⇐"cash",currency⇐"JPY",coefficient⇐1000,scale⇐0,decision⇐"include",reference⇐Ref "cash",contributors⇐⟨Ref "cash"⟩}
obligation ← {obligation_id⇐"rent",due_ordinal⇐dates.Ordinal "2026-01-15",currency⇐"JPY",coefficient⇐200,scale⇐0,settlement_state⇐"open",decision⇐"include",excluded_coefficient⇐50,excluded_scale⇐0,reservation_state⇐"proven",reservation_ref⇐"reservation:rent",reference⇐Ref "rent",contributors⇐⟨Ref "rent"⟩}
assetScope ← {state⇐"resolved",scope_id⇐"assets",basis_kind⇐"account_balance",rows⇐⟨asset⟩}
obligationScope ← {state⇐"resolved",scope_id⇐"obligations",rows⇐⟨obligation⟩}
accounted ← accounting.Build ⟨"2026-01-10","2026-01-20","JPY",assetScope,obligationScope⟩
result ← section.Build accounted
"ok" lib.AssertEq result.state
85 lib.AssertEq result.calculation.daily_target
(•FChars "../fixtures/ledger-facts-phase1-proof/daily_target.destination.human.txt") lib.AssertEq section.FormatHuman result
(•FChars "../fixtures/ledger-facts-phase1-proof/daily_target.destination.compact.txt") lib.AssertEq section.FormatCompact result

deficitAsset ← {asset_id⇐"cash",currency⇐"JPY",coefficient⇐100,scale⇐0,decision⇐"include",reference⇐Ref "cash",contributors⇐⟨Ref "cash"⟩}
deficitObligation ← {obligation_id⇐"rent",due_ordinal⇐dates.Ordinal "2026-01-15",currency⇐"JPY",coefficient⇐250,scale⇐0,settlement_state⇐"open",decision⇐"include",excluded_coefficient⇐0,excluded_scale⇐0,reservation_state⇐"none",reservation_ref⇐"",reference⇐Ref "rent",contributors⇐⟨Ref "rent"⟩}
deficitAccounted ← accounting.Build ⟨"2026-01-10","2026-01-20","JPY",{state⇐"resolved",scope_id⇐"assets",basis_kind⇐"account_balance",rows⇐⟨deficitAsset⟩},{state⇐"resolved",scope_id⇐"obligations",rows⇐⟨deficitObligation⟩}⟩
deficit ← section.Build deficitAccounted
"deficit" lib.AssertEq deficit.state
lib.Assert ∨´"Status: deficit"⍷section.FormatHuman deficit
lib.Assert ∨´"ledger_daily_target_shortfall: 15"⍷section.FormatCompact deficit
•Out "test_section_daily_target: ok"
