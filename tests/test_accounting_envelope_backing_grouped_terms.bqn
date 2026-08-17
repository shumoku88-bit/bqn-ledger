#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "envelope_backing_test_adapter.bqn"
lf ← @+10 ⋄ tab ← @+9 ⋄ quote ← @+34
JournalText ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Join ← {𝕊 fields: out ← ⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}

registry ← (registry_core.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountSource ← JournalText ⟨
  "account assets:cash","  type: Asset","  commodity: JPY","",
  "account expenses:food","  type: Expense","  commodity: JPY","",
  "account expenses:groceries","  type: Expense","  commodity: JPY","",
  "account expenses:transport","  type: Expense","  commodity: JPY"
⟩
raw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account expenses:groceries",lf,"    ; role: expense",lf,lf,
  "account expenses:transport",lf,"    ; role: expense",lf,lf,
  "2026-01-03 * groceries",lf,"    ; event-id: grocery-spend",lf,"    ; layer: actual",lf,
  "    expenses:groceries 7 JPY",lf,"    assets:cash -7 JPY",lf,lf,
  "2026-01-04 * food",lf,"    ; event-id: food-spend",lf,"    ; layer: actual",lf,
  "    expenses:food 3 JPY",lf,"    assets:cash -3 JPY",lf,lf,
  "2026-01-05 * transport",lf,"    ; event-id: transport-spend",lf,"    ; layer: actual",lf,
  "    expenses:transport 5 JPY",lf,"    assets:cash -5 JPY",lf
⟩
actual ← (snapshot.Build ⟨accountSource,raw,registry⟩).facts
planRaw ← JournalText ⟨
  "2026-01-12 food a","  ; plan-id: food-plan-a","  expenses:groceries  4 JPY","  assets:cash  -4 JPY","",
  "2026-01-13 transport","  ; plan-id: transport-plan","  expenses:transport  6 JPY","  assets:cash  -6 JPY","",
  "2026-01-14 food b","  ; plan-id: food-plan-b","  expenses:food  2 JPY","  assets:cash  -2 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts

policyRaw ← JournalText ⟨
  "[[backing-pools]]","id = "∾Q "cash","asset-accounts = ["∾(Q "assets:cash")∾"]","",
  "[[envelopes]]","id = "∾Q "food","label = "∾Q "Food","pacing = "∾Q "daily","backing-pool = "∾Q "cash","",
  "[[envelopes]]","id = "∾Q "transport","label = "∾Q "Transport","pacing = "∾Q "flex","backing-pool = "∾Q "cash"
⟩
policy ← envelopePolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

history ← envelopes.HistoryFor actual
entitlementRaw ← JournalText ⟨
  "2026-01-01 origin JPY",
  "2026-01-01 transfer unallocated -> food 20 JPY",
  "2026-01-01 transfer unallocated -> transport 10 JPY"
⟩
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

result ← envelopes.Build ⟨entitlement,policy,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.envelopes.count
⟨"food","transport"⟩ lib.AssertEq result.envelopes.envelope_id
⟨20,10⟩ lib.AssertEq result.envelopes.entitlement
⟨10,5⟩ lib.AssertEq result.envelopes.actual_consumption
⟨0,0⟩ lib.AssertEq result.envelopes.actual_refunds
⟨10,5⟩ lib.AssertEq result.envelopes.ledger_remaining
⟨6,6⟩ lib.AssertEq result.envelopes.commitment
⟨4,¯1⟩ lib.AssertEq result.envelopes.post_plan_headroom
foodConsumption ← 0⊑result.envelopes.consumption_contributors
⟨"grocery-spend:0","food-spend:0"⟩ lib.AssertEq {𝕩.posting_id}¨foodConsumption
foodPlans ← 0⊑result.envelopes.plan_contributors
⟨"plan.journal:plan_id:food-plan-a","plan.journal:plan_id:food-plan-b"⟩ lib.AssertEq {𝕩.transaction_id}¨foodPlans
•Out "test_accounting_envelope_backing_grouped_terms: ok"
