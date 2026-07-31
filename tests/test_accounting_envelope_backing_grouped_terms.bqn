#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
companion ← •Import "../src/ledger/companion_snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
registry ← (registry_core.Build ⟨"JPY	0	¥"⟩).registry
lf ← @+10
accounts ← ⟨
  "assets:cash	role=asset	type=liquid	currency=JPY",
  "expenses:food	role=expense	budget=food	currency=JPY",
  "expenses:groceries	role=expense	budget=food	currency=JPY",
  "expenses:transport	role=expense	budget=transport	currency=JPY",
  "budget:opening	role=budget	kind=opening	currency=JPY",
  "budget:unassigned	role=budget	kind=unassigned	currency=JPY",
  "budget:food	role=budget	kind=envelope	budget=food	currency=JPY",
  "budget:transport	role=budget	kind=envelope	budget=transport	currency=JPY"
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
companions ← companion.Build ⟨
  ⟨
    "2026-01-12	food a	assets:cash	expenses:groceries	4	currency=JPY	plan_id=food-plan-a",
    "2026-01-13	transport	assets:cash	expenses:transport	6	currency=JPY	plan_id=transport-plan",
    "2026-01-14	food b	assets:cash	expenses:food	2	currency=JPY	plan_id=food-plan-b"
  ⟩,
  ⟨
    "2026-01-01	seed	budget:opening	budget:unassigned	30	currency=JPY",
    "2026-01-01	food	budget:unassigned	budget:food	20	currency=JPY",
    "2026-01-01	transport	budget:unassigned	budget:transport	10	currency=JPY"
  ⟩,
  actual.accounts,registry
⟩
result ← envelopes.Build ⟨companions.budget,actual,companions.plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
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
⟨"plan.tsv:plan_id:food-plan-a","plan.tsv:plan_id:food-plan-b"⟩ lib.AssertEq {𝕩.transaction_id}¨foodPlans
•Out "test_accounting_envelope_backing_grouped_terms: ok"
