#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
budgetSnapshot ← •Import "../src/ledger/budget_snapshot.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
budget ← (budgetSnapshot.Build ⟨loader.ReadLines base∾"budget_alloc.tsv",actual.accounts,registry⟩).facts
result ← envelopes.Build ⟨budget,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨0⟩⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.envelopes.count
⟨60⟩ lib.AssertEq result.envelopes.entitlement
⟨30⟩ lib.AssertEq result.envelopes.actual_consumption
⟨0⟩ lib.AssertEq result.envelopes.actual_refunds
⟨30⟩ lib.AssertEq result.envelopes.ledger_remaining
⟨0⟩ lib.AssertEq result.envelopes.open_plan_reserve
⟨30⟩ lib.AssertEq result.envelopes.post_plan_headroom
965 lib.AssertEq result.totals.funding_balance
30 lib.AssertEq result.totals.backing_required
935 lib.AssertEq result.totals.backing_surplus
40 lib.AssertEq result.totals.ledger_unassigned
895 lib.AssertEq result.totals.reconciliation_delta
"backed" lib.AssertEq result.status
"actual.journal" lib.AssertEq (⊑result.funding_contributors).source
"budget_alloc.tsv" lib.AssertEq (⊑⊑result.envelopes.entitlement_contributors).source
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source
unavailable ← envelopes.Build ⟨budget,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨⟩⟩
"unavailable" lib.AssertEq unavailable.state
0 lib.AssertEq unavailable.envelopes.count
invalidFunding ← envelopes.Build ⟨budget,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨1⟩⟩
"error" lib.AssertEq invalidFunding.state
"funding_scope_invalid" lib.AssertEq (⊑invalidFunding.diagnostics).code
unknownDomain ← envelopes.Build ⟨budget,actual,plan,"USD",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨0⟩⟩
"error" lib.AssertEq unknownDomain.state
"domain_unknown" lib.AssertEq (⊑unknownDomain.diagnostics).code
invalidRange ← envelopes.Build ⟨budget,actual,plan,"JPY",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-01",dates.Ordinal "2026-01-12",⟨0⟩⟩
"error" lib.AssertEq invalidRange.state
"statement_range_invalid" lib.AssertEq (⊑invalidRange.diagnostics).code

# Open Plan, refund, overspent Envelope, and under-backed funding remain distinct.
syntheticLines ← ⟨
  "assets:cash\trole=asset\ttype=liquid\tcurrency=JPY",
  "income:salary\trole=income\tcurrency=JPY",
  "expenses:food\trole=expense\tbudget=food\tcurrency=JPY",
  "budget:opening\trole=budget\tkind=opening\tcurrency=JPY",
  "budget:unassigned\trole=budget\tkind=unassigned\tcurrency=JPY",
  "budget:food\trole=budget\tkind=envelope\tbudget=food\tcurrency=JPY"
⟩
syntheticRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account income:salary",lf,"    ; role: income",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account budget:opening",lf,"    ; role: budget",lf,lf,
  "account budget:unassigned",lf,"    ; role: budget",lf,lf,
  "account budget:food",lf,"    ; role: budget",lf,lf,
  "2026-01-02 * income",lf,"    ; event-id: income",lf,"    ; layer: actual",lf,
  "    assets:cash 10 JPY",lf,"    income:salary -10 JPY",lf,lf,
  "2026-01-05 * spend",lf,"    ; event-id: spend",lf,"    ; layer: actual",lf,
  "    expenses:food 30 JPY",lf,"    assets:cash -30 JPY",lf,lf,
  "2026-01-08 * refund",lf,"    ; event-id: refund",lf,"    ; layer: actual",lf,
  "    assets:cash 5 JPY",lf,"    expenses:food -5 JPY",lf
⟩
syntheticActual ← (snapshot.Build ⟨syntheticLines,syntheticRaw,registry⟩).facts
syntheticPlanRaw ← Raw ⟨
  "2026-01-15 open-food",
  "  ; plan-id: open-food",
  "  expenses:food  4 JPY",
  "  assets:cash  -4 JPY"
⟩
syntheticPlan ← (canonicalPlan.Build ⟨syntheticPlanRaw,syntheticActual.accounts,registry⟩).facts
syntheticBudgetLines ← ⟨
  "2026-01-01\tseed\tbudget:opening\tbudget:unassigned\t20\tcurrency=JPY",
  "2026-01-01\tallocate\tbudget:unassigned\tbudget:food\t20\tcurrency=JPY"
⟩
syntheticBudget ← (budgetSnapshot.Build ⟨syntheticBudgetLines,syntheticActual.accounts,registry⟩).facts
synthetic ← envelopes.Build ⟨syntheticBudget,syntheticActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
"ok" lib.AssertEq synthetic.state
⟨20⟩ lib.AssertEq synthetic.envelopes.entitlement
⟨30⟩ lib.AssertEq synthetic.envelopes.actual_consumption
⟨5⟩ lib.AssertEq synthetic.envelopes.actual_refunds
⟨¯5⟩ lib.AssertEq synthetic.envelopes.ledger_remaining
⟨4⟩ lib.AssertEq synthetic.envelopes.open_plan_reserve
⟨¯9⟩ lib.AssertEq synthetic.envelopes.post_plan_headroom
¯15 lib.AssertEq synthetic.totals.funding_balance
0 lib.AssertEq synthetic.totals.backing_required
¯15 lib.AssertEq synthetic.totals.backing_surplus
"under_backed" lib.AssertEq synthetic.status
"plan.journal" lib.AssertEq (⊑⊑synthetic.envelopes.plan_contributors).source
"actual.journal" lib.AssertEq (⊑⊑synthetic.envelopes.refund_contributors).source

emptyPlanFacts ← (canonicalPlan.Build ⟨"",syntheticActual.accounts,registry⟩).facts
emptyPlan ← envelopes.Build ⟨syntheticBudget,syntheticActual,emptyPlanFacts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
"ok" lib.AssertEq emptyPlan.state
⟨0⟩ lib.AssertEq emptyPlan.envelopes.open_plan_reserve

duplicateRaw ← syntheticRaw∾lf∾lf∾∾⟨
  "2026-01-09 * duplicate one",lf,"    ; event-id: duplicate-one",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,
  "    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf,lf,
  "2026-01-09 * duplicate two",lf,"    ; event-id: duplicate-two",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,
  "    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf
⟩
duplicateActual ← (snapshot.Build ⟨syntheticLines,duplicateRaw,registry⟩).facts
duplicateCompletion ← envelopes.Build ⟨syntheticBudget,duplicateActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
"error" lib.AssertEq duplicateCompletion.state
0 lib.AssertEq duplicateCompletion.envelopes.count
"plan_completion_conflict" lib.AssertEq (⊑duplicateCompletion.diagnostics).code

# Cross-source scale normalization overflow is fail-closed.
overflowLines ← ⟨
  "assets:ils\trole=asset\tcurrency=ILS",
  "expenses:ils\trole=expense\tbudget=food\tcurrency=ILS",
  "budget:unassigned-ils\trole=budget\tkind=unassigned\tcurrency=ILS",
  "budget:food-ils\trole=budget\tkind=envelope\tbudget=food\tcurrency=ILS"
⟩
overflowRaw ← ∾⟨
  "commodity ILS",lf,lf,"account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:ils",lf,"    ; role: expense",lf,lf,
  "account budget:unassigned-ils",lf,"    ; role: budget",lf,lf,
  "account budget:food-ils",lf,"    ; role: budget",lf,lf,
  "2026-01-05 * fractional",lf,"    ; event-id: fractional",lf,"    ; layer: actual",lf,
  "    expenses:ils 0.1 ILS",lf,"    assets:ils -0.1 ILS",lf
⟩
overflowActual ← (snapshot.Build ⟨overflowLines,overflowRaw,registry⟩).facts
overflowBudget ← (budgetSnapshot.Build ⟨
  ⟨"2026-01-01\tmax\tbudget:unassigned-ils\tbudget:food-ils\t999999999999999\tcurrency=ILS"⟩,
  overflowActual.accounts,registry
⟩).facts
overflowPlan ← (canonicalPlan.Build ⟨"",overflowActual.accounts,registry⟩).facts
overflow ← envelopes.Build ⟨overflowBudget,overflowActual,overflowPlan,"ILS",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10",⟨0⟩⟩
"error" lib.AssertEq overflow.state
0 lib.AssertEq overflow.envelopes.count
"coefficient_sum_failed" lib.AssertEq (⊑overflow.diagnostics).code
•Out "test_accounting_envelope_backing: ok"