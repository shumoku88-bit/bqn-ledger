#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
fulfillment ← •Import "../src/accounting/envelope_fulfillment.bqn"
lf ← @+10 ⋄ tab ← @+9
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
Join ← {𝕊 fields:out←⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}
registry ← (registryCore.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountLines ← ⟨
  Join ⟨"assets:cash","role=asset","currency=JPY"⟩,
  Join ⟨"assets:savings","role=asset","currency=JPY"⟩,
  Join ⟨"assets:investment","role=asset","currency=JPY"⟩,
  Join ⟨"expenses:food","role=expense","currency=JPY"⟩
⟩
actualRaw ← Raw ⟨
  "commodity JPY","","account assets:cash","    ; role: asset","","account assets:savings","    ; role: asset","","account assets:investment","    ; role: asset","","account expenses:food","    ; role: expense","",
  "2026-01-10 * completed savings target","    ; event-id: save-actual","    ; layer: actual","    ; plan-id: save-1","    assets:savings 5 JPY","    assets:investment 7 JPY","    assets:cash -12 JPY","",
  "2026-01-10 * completed expense target","    ; event-id: food-actual","    ; layer: actual","    ; plan-id: food-1","    expenses:food 5 JPY","    assets:cash -5 JPY"
⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-10 savings target","  ; plan-id: save-1","  assets:savings 4 JPY","  assets:investment 6 JPY","  assets:cash -10 JPY","",
  "2026-01-10 expense target","  ; plan-id: food-1","  expenses:food 5 JPY","  assets:cash -5 JPY"
⟩
planResult ← canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩
plan ← planResult.facts ⋄ retirements ← planResult.retirements
baseHistory ← historyFixture.Initial ⟨⟨"goal"⟩,⟨"expenses:food"⟩,⟨"managed"⟩,⟨"goal"⟩⟩
history ← historyFixture.WithFulfillment ⟨baseHistory,⟨"2026-01-01","2026-01-12","2026-01-01"⟩,⟨"save-1","save-1","food-1"⟩,⟨"fulfills","not-target","fulfills"⟩,⟨"goal","","goal"⟩⟩
start ← dates.Ordinal "2026-01-01" ⋄ finish ← dates.Ordinal "2026-02-01" ⋄ jan11 ← dates.Ordinal "2026-01-11" ⋄ jan15 ← dates.Ordinal "2026-01-15"
before ← fulfillment.Build ⟨plan,retirements,actual,history,"JPY",start,finish,jan11⟩
"ok" lib.AssertEq before.state
⟨"goal"⟩ lib.AssertEq before.managed.envelope_id
⟨12⟩ lib.AssertEq before.managed.fulfillment
2 lib.AssertEq before.evidence.count
⟨"save-1","save-1"⟩ lib.AssertEq before.evidence.plan_id
⟨5,7⟩ lib.AssertEq before.evidence.actual_coefficient
⟨"assets:savings","assets:investment"⟩ lib.AssertEq before.evidence.target_account_key
"plan.journal" lib.AssertEq (⊑⊑before.managed.plan_contributors).source
"actual.journal" lib.AssertEq (⊑⊑before.managed.actual_contributors).source
# Completion-day route is frozen. The Jan 12 not-target decision cannot rewrite Jan 10.
after ← fulfillment.Build ⟨plan,retirements,actual,history,"JPY",start,finish,jan15⟩
"ok" lib.AssertEq after.state
⟨12⟩ lib.AssertEq after.managed.fulfillment
⟨"fulfills","fulfills"⟩ lib.AssertEq after.evidence.route
# Expense target is never Fulfillment even if its PlanId has a fulfills route.
2 lib.AssertEq after.evidence.count
unknownRoute ← historyFixture.WithFulfillment ⟨baseHistory,⟨"2026-01-01"⟩,⟨"missing-plan"⟩,⟨"fulfills"⟩,⟨"goal"⟩⟩
unknown ← fulfillment.Build ⟨plan,retirements,actual,unknownRoute,"JPY",start,finish,jan15⟩
"error" lib.AssertEq unknown.state
"fulfillment_route_plan_unknown" lib.AssertEq (⊑unknown.diagnostics).code
unknownActualRaw ← actualRaw∾Raw ⟨"","2026-01-11 * unknown completion","    ; event-id: ghost-actual","    ; layer: actual","    ; plan-id: ghost-plan","    assets:savings 3 JPY","    assets:cash -3 JPY"⟩
unknownActual ← (snapshot.Build ⟨accountLines,unknownActualRaw,registry⟩).facts
unknownCompletion ← fulfillment.Build ⟨plan,retirements,unknownActual,history,"JPY",start,finish,jan15⟩
"error" lib.AssertEq unknownCompletion.state
"completion_plan_unknown" lib.AssertEq (⊑unknownCompletion.diagnostics).code
•Out "test_accounting_envelope_fulfillment: ok"
