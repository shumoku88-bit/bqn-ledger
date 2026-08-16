#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
commitment ← •Import "../src/accounting/envelope_commitment.bqn"
lf ← @+10 ⋄ tab ← @+9
Raw ← {𝕊 lines:∾{𝕩∾⟨lf⟩}¨lines}
Join ← {𝕊 fields:out←⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}
registry ← (registryCore.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountSource ← Raw ⟨
  "account assets:cash","  type: Asset","  commodity: JPY","",
  "account assets:savings","  type: Asset","  commodity: JPY","",
  "account expenses:food","  type: Expense","  commodity: JPY","",
  "account expenses:transport","  type: Expense","  commodity: JPY","",
  "account expenses:other","  type: Expense","  commodity: JPY"
⟩
actualRaw ← Raw ⟨"commodity JPY","","account assets:cash","    ; role: asset","","account assets:savings","    ; role: asset","","account expenses:food","    ; role: expense","","account expenses:transport","    ; role: expense","","account expenses:other","    ; role: expense","","2026-01-10 * completed food","    ; event-id: completed-food-actual","    ; layer: actual","    ; plan-id: completed-food","    expenses:food 4 JPY","    assets:cash -4 JPY"⟩
actual ← (snapshot.Build ⟨accountSource,actualRaw,registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-09 completed food","  ; plan-id: completed-food","  expenses:food 4 JPY","  assets:cash -4 JPY","",
  "2026-01-20 open food","  ; plan-id: open-food","  expenses:food 5 JPY","  assets:cash -5 JPY","",
  "2026-01-20 open savings","  ; plan-id: open-save","  assets:savings 7 JPY","  assets:cash -7 JPY","",
  "2026-01-20 explicit unmanaged","  ; plan-id: open-transport","  expenses:transport 3 JPY","  assets:cash -3 JPY","",
  "2026-01-20 missing route","  ; plan-id: open-other","  expenses:other 2 JPY","  assets:cash -2 JPY"
⟩
planResult ← canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩ ⋄ plan ← planResult.facts ⋄ retirements ← planResult.retirements
baseHistory ← historyFixture.Initial ⟨⟨"food","goal"⟩,⟨⟩,⟨⟩,⟨⟩⟩
expenseHistory ← historyFixture.WithExpense ⟨baseHistory,⟨"initial","2026-01-12","initial"⟩,⟨"expenses:food","expenses:food","expenses:transport"⟩,⟨"managed","unmanaged","unmanaged"⟩,⟨"food","",""⟩⟩
history ← historyFixture.WithFulfillment ⟨expenseHistory,⟨"2026-01-01","2026-01-12"⟩,⟨"open-save","open-save"⟩,⟨"fulfills","not-target"⟩,⟨"goal",""⟩⟩
start ← dates.Ordinal "2026-01-01" ⋄ finish ← dates.Ordinal "2026-02-01" ⋄ jan11 ← dates.Ordinal "2026-01-11" ⋄ jan15 ← dates.Ordinal "2026-01-15"
before ← commitment.Build ⟨plan,retirements,actual,history,"JPY",start,finish,jan11⟩
"ok" lib.AssertEq before.state
⟨"food","goal"⟩ lib.AssertEq before.managed.envelope_id
⟨5,7⟩ lib.AssertEq before.managed.commitment
1 lib.AssertEq before.unmanaged.count
⟨"open-transport"⟩ lib.AssertEq before.unmanaged.plan_id
⟨3⟩ lib.AssertEq before.unmanaged.coefficient
1 lib.AssertEq before.unrouted.count
⟨"open-other"⟩ lib.AssertEq before.unrouted.plan_id
⟨2⟩ lib.AssertEq before.unrouted.coefficient
4 lib.AssertEq before.evidence.count
⟨"open-food","open-save","open-transport","open-other"⟩ lib.AssertEq before.evidence.plan_id
⟨"managed","fulfills","unmanaged","unrouted"⟩ lib.AssertEq before.evidence.route
"plan.journal" lib.AssertEq (⊑⊑before.managed.plan_contributors).source
# Open intent follows observation-day history.
after ← commitment.Build ⟨plan,retirements,actual,history,"JPY",start,finish,jan15⟩
"ok" lib.AssertEq after.state
⟨0,0⟩ lib.AssertEq after.managed.commitment
2 lib.AssertEq after.unmanaged.count
⟨"open-food","open-transport"⟩ lib.AssertEq after.unmanaged.plan_id
⟨5,3⟩ lib.AssertEq after.unmanaged.coefficient
1 lib.AssertEq after.unrouted.count
⟨"open-other"⟩ lib.AssertEq after.unrouted.plan_id
⟨"unmanaged","not-target","unmanaged","unrouted"⟩ lib.AssertEq after.evidence.route
0 lib.AssertEq +´"completed-food"⊸≡¨before.evidence.plan_id
0 lib.AssertEq +´"completed-food"⊸≡¨after.evidence.plan_id
•Out "test_accounting_envelope_commitment: ok"
