#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
observation ← •Import "../src/accounting/plan_observation.bqn"
lf ← @+10 ⋄ tab ← @+9
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
Join ← {𝕊 fields:out←⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}
registry ← (registryCore.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountLines ← ⟨Join ⟨"assets:cash","role=asset","currency=JPY"⟩,Join ⟨"assets:savings","role=asset","currency=JPY"⟩,Join ⟨"expenses:food","role=expense","currency=JPY"⟩,Join ⟨"expenses:books","role=expense","currency=JPY"⟩⟩
actualRaw ← Raw ⟨"commodity JPY","","account assets:cash","    ; role: asset","","account assets:savings","    ; role: asset","","account expenses:food","    ; role: expense","","account expenses:books","    ; role: expense","","2026-01-10 * explicit completion with unrelated shape","    ; event-id: complete-actual","    ; layer: actual","    ; plan-id: completed-plan","    assets:savings 5 JPY","    assets:cash -5 JPY","","2026-01-20 * future completion","    ; event-id: future-actual","    ; layer: actual","    ; plan-id: future-plan","    assets:savings 2 JPY","    assets:cash -2 JPY"⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
planRaw ← Raw ⟨"2026-01-20 old multi posting","  ; plan-id: old-plan","  ; superseded-on: 2026-01-12","  ; superseded-by: new-plan","  expenses:food 3 JPY","  expenses:books 2 JPY","  assets:cash -5 JPY","","2026-01-20 replacement","  ; plan-id: new-plan","  expenses:food 4 JPY","  assets:cash -4 JPY","","2026-01-08 completed multi posting","  ; plan-id: completed-plan","  expenses:food 3 JPY","  expenses:books 2 JPY","  assets:cash -5 JPY","","2026-01-20 future completion plan","  ; plan-id: future-plan","  assets:savings 2 JPY","  assets:cash -2 JPY"⟩
planResult ← canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩
"ok" lib.AssertEq planResult.state
plan ← planResult.facts ⋄ retirements ← planResult.retirements
1 lib.AssertEq retirements.count
⟨"old-plan"⟩ lib.AssertEq retirements.plan_id
⟨"2026-01-12"⟩ lib.AssertEq retirements.retired_on
jan11 ← dates.Ordinal "2026-01-11" ⋄ jan15 ← dates.Ordinal "2026-01-15" ⋄ jan21 ← dates.Ordinal "2026-01-21"
before ← observation.Build ⟨plan,retirements,actual,jan11⟩
"ok" lib.AssertEq before.state
⟨0,1,3⟩ lib.AssertEq before.open_transaction_indices
⟨⟩ lib.AssertEq before.retired_plan_ids
⟨"completed-plan"⟩ lib.AssertEq before.completed.plan_id
afterRetirement ← observation.Build ⟨plan,retirements,actual,jan15⟩
"ok" lib.AssertEq afterRetirement.state
⟨"old-plan"⟩ lib.AssertEq afterRetirement.retired_plan_ids
⟨1,3⟩ lib.AssertEq afterRetirement.open_transaction_indices
⟨"completed-plan"⟩ lib.AssertEq afterRetirement.completed.plan_id
afterFuture ← observation.Build ⟨plan,retirements,actual,jan21⟩
"ok" lib.AssertEq afterFuture.state
⟨1⟩ lib.AssertEq afterFuture.open_transaction_indices
⟨"completed-plan","future-plan"⟩ lib.AssertEq afterFuture.completed.plan_id
# Lifecycle relation is explicit identity, not posting resemblance.
0 lib.AssertEq ≠before.diagnostics
unknownRaw ← actualRaw∾Raw ⟨"","2026-01-09 * unknown relation","    ; event-id: unknown-actual","    ; layer: actual","    ; plan-id: missing-plan","    assets:savings 1 JPY","    assets:cash -1 JPY"⟩
unknownActual ← (snapshot.Build ⟨accountLines,unknownRaw,registry⟩).facts
unknown ← observation.Build ⟨plan,retirements,unknownActual,jan15⟩
"error" lib.AssertEq unknown.state
"completion_plan_unknown" lib.AssertEq (⊑unknown.diagnostics).code
duplicateRaw ← actualRaw∾Raw ⟨"","2026-01-30 * second completion","    ; event-id: duplicate-actual","    ; layer: actual","    ; plan-id: completed-plan","    assets:savings 5 JPY","    assets:cash -5 JPY"⟩
duplicateActual ← (snapshot.Build ⟨accountLines,duplicateRaw,registry⟩).facts
duplicate ← observation.Build ⟨plan,retirements,duplicateActual,jan11⟩
"error" lib.AssertEq duplicate.state
"plan_completion_multiple_actuals" lib.AssertEq (⊑duplicate.diagnostics).code
•Out "test_accounting_plan_observation: ok"
