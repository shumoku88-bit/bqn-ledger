#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
budgetSnapshot ← •Import "../src/ledger/budget_snapshot.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
registry ← (registry_core.Build ⟨"JPY\t0\t¥"⟩).registry
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
accounts ← ⟨
  "assets:cash\trole=asset\ttype=liquid\tcurrency=JPY",
  "expenses:food\trole=expense\tbudget=food\tcurrency=JPY",
  "expenses:groceries\trole=expense\tbudget=food\tcurrency=JPY",
  "expenses:transport\trole=expense\tbudget=transport\tcurrency=JPY",
  "budget:opening\trole=budget\tkind=opening\tcurrency=JPY",
  "budget:unassigned\trole=budget\tkind=unassigned\tcurrency=JPY",
  "budget:food\trole=budget\tkind=envelope\tbudget=food\tcurrency=JPY",
  "budget:transport\trole=budget\tkind=envelope\tbudget=transport\tcurrency=JPY"
⟩
raw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account expenses:groceries",lf,"    ; role: expense",lf,lf,
  "account expenses:transport",lf,"    ; role: expense",lf,lf,
  "account budget:opening",lf,"    ; role: budget",lf,lf,
  "account budget:unassigned",lf,"    ; role: budget",lf,lf,
  "account budget:food",lf,"    ; role: budget",lf,lf,
  "account budget:transport",lf,"    ; role: budget",lf,lf,
  "2026-01-03 * groceries",lf,"    ; event-id: grocery-spend",lf,"    ; layer: actual",lf,
  "    expenses:groceries 7 JPY",lf,"    assets:cash -7 JPY",lf,lf,
  "2026-01-04 * food",lf,"    ; event-id: food-spend",lf,"    ; layer: actual",lf,
  "    expenses:food 3 JPY",lf,"    assets:cash -3 JPY",lf,lf,
  "2026-01-05 * transport",lf,"    ; event-id: transport-spend",lf,"    ; layer: actual",lf,
  "    expenses:transport 5 JPY",lf,"    assets:cash -5 JPY",lf
⟩
actual ← (snapshot.Build ⟨accounts,raw,registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-12 food a",
  "  ; plan-id: food-plan-a",
  "  expenses:groceries  4 JPY",
  "  assets:cash  -4 JPY",
  "",
  "2026-01-13 transport",
  "  ; plan-id: transport-plan",
  "  expenses:transport  6 JPY",
  "  assets:cash  -6 JPY",
  "",
  "2026-01-14 food b",
  "  ; plan-id: food-plan-b",
  "  expenses:food  2 JPY",
  "  assets:cash  -2 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
budget ← (budgetSnapshot.Build ⟨
  ⟨
    "2026-01-01\tseed\tbudget:opening\tbudget:unassigned\t30\tcurrency=JPY",
    "2026-01-01\tfood\tbudget:unassigned\tbudget:food\t20\tcurrency=JPY",
    "2026-01-01\ttransport\tbudget:unassigned\tbudget:transport\t10\tcurrency=JPY"
  ⟩,
  actual.accounts,registry
⟩).facts
result ← envelopes.Build ⟨budget,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.envelopes.count
⟨"budget:food","budget:transport"⟩ lib.AssertEq result.envelopes.account_key
⟨"food","transport"⟩ lib.AssertEq result.envelopes.category
⟨20,10⟩ lib.AssertEq result.envelopes.entitlement
⟨10,5⟩ lib.AssertEq result.envelopes.actual_consumption
⟨0,0⟩ lib.AssertEq result.envelopes.actual_refunds
⟨10,5⟩ lib.AssertEq result.envelopes.ledger_remaining
⟨6,6⟩ lib.AssertEq result.envelopes.open_plan_reserve
⟨4,¯1⟩ lib.AssertEq result.envelopes.post_plan_headroom
foodConsumption ← 0⊑result.envelopes.consumption_contributors
⟨"food-spend:0","grocery-spend:0"⟩ lib.AssertEq {𝕩.posting_id}¨foodConsumption
foodPlans ← 0⊑result.envelopes.plan_contributors
⟨"plan.journal:plan_id:food-plan-a","plan.journal:plan_id:food-plan-b"⟩ lib.AssertEq {𝕩.transaction_id}¨foodPlans
•Out "test_accounting_envelope_backing_grouped_terms: ok"