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
  Join ⟨"expenses:food","role=expense","currency=JPY"⟩
⟩
actualRaw ← Raw ⟨
  "commodity JPY","",
  "account assets:cash","    ; role: asset","",
  "account assets:savings","    ; role: asset","",
  "account expenses:food","    ; role: expense","",
  "2026-01-10 * completed savings target",
  "    ; event-id: save-actual",
  "    ; layer: actual",
  "    ; plan-id: save-1",
  "    assets:savings 12 JPY",
  "    assets:cash -12 JPY","",
  "2026-01-10 * completed expense target",
  "    ; event-id: food-actual",
  "    ; layer: actual",
  "    ; plan-id: food-1",
  "    expenses:food 5 JPY",
  "    assets:cash -5 JPY"
⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-10 savings target",
  "  ; plan-id: save-1",
  "  assets:savings 10 JPY",
  "  assets:cash -10 JPY","",
  "2026-01-10 expense target",
  "  ; plan-id: food-1",
  "  expenses:food 5 JPY",
  "  assets:cash -5 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
baseHistory ← historyFixture.Initial ⟨⟨"goal"⟩,⟨"expenses:food"⟩,⟨"managed"⟩,⟨"goal"⟩⟩
history ← historyFixture.WithFulfillment ⟨
  baseHistory,
  ⟨"2026-01-01","2026-01-12","2026-01-01"⟩,
  ⟨"save-1","save-1","food-1"⟩,
  ⟨"fulfills","not-target","fulfills"⟩,
  ⟨"goal","","goal"⟩
⟩
start ← dates.Ordinal "2026-01-01"
finish ← dates.Ordinal "2026-02-01"
jan11 ← dates.Ordinal "2026-01-11"
jan15 ← dates.Ordinal "2026-01-15"

beforeRouteChange ← fulfillment.Build ⟨plan,actual,history,"JPY",start,finish,jan11⟩
"ok" lib.AssertEq beforeRouteChange.state
1 lib.AssertEq beforeRouteChange.managed.count
⟨"goal"⟩ lib.AssertEq beforeRouteChange.managed.envelope_id
⟨12⟩ lib.AssertEq beforeRouteChange.managed.fulfillment
1 lib.AssertEq beforeRouteChange.evidence.count
⟨"save-1"⟩ lib.AssertEq beforeRouteChange.evidence.plan_id
⟨"fulfills"⟩ lib.AssertEq beforeRouteChange.evidence.route
⟨12⟩ lib.AssertEq beforeRouteChange.evidence.actual_coefficient
"plan.journal" lib.AssertEq (⊑⊑beforeRouteChange.managed.plan_contributors).source
"actual.journal" lib.AssertEq (⊑⊑beforeRouteChange.managed.actual_contributors).source

# Fulfillment freezes route meaning at completion Actual day. The later not-target
# decision must not rewrite the already-completed Jan 10 evidence.
afterRouteChange ← fulfillment.Build ⟨plan,actual,history,"JPY",start,finish,jan15⟩
"ok" lib.AssertEq afterRouteChange.state
⟨12⟩ lib.AssertEq afterRouteChange.managed.fulfillment
⟨"fulfills"⟩ lib.AssertEq afterRouteChange.evidence.route

# An Expense target never becomes Fulfillment merely because its PlanId has a
# fulfillment route. Expense use belongs to Expense routing / Consumption.
1 lib.AssertEq afterRouteChange.evidence.count

unknownRoute ← historyFixture.WithFulfillment ⟨
  baseHistory,⟨"2026-01-01"⟩,⟨"missing-plan"⟩,⟨"fulfills"⟩,⟨"goal"⟩
⟩
unknown ← fulfillment.Build ⟨plan,actual,unknownRoute,"JPY",start,finish,jan15⟩
"error" lib.AssertEq unknown.state
"fulfillment_route_plan_unknown" lib.AssertEq (⊑unknown.diagnostics).code

unknownActualRaw ← actualRaw∾Raw ⟨
  "","2026-01-11 * unknown completion",
  "    ; event-id: ghost-actual",
  "    ; layer: actual",
  "    ; plan-id: ghost-plan",
  "    assets:savings 3 JPY",
  "    assets:cash -3 JPY"
⟩
unknownActual ← (snapshot.Build ⟨accountLines,unknownActualRaw,registry⟩).facts
unknownCompletion ← fulfillment.Build ⟨plan,unknownActual,history,"JPY",start,finish,jan15⟩
"error" lib.AssertEq unknownCompletion.state
"completion_plan_unknown" lib.AssertEq (⊑unknownCompletion.diagnostics).code

•Out "test_accounting_envelope_fulfillment: ok"
