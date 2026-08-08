#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
tab ← @+9
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Join ← {𝕊 fields:
  out ← ⊑fields
  {𝕊 field: out∾↩tab∾field}¨1↓fields
  out
}

planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
budgetRaw ← Raw ⟨
  "2026-01-01 seed",
  "  budget:opening     -100 JPY",
  "  budget:unassigned   100 JPY","",
  "2026-01-01 allocate-food",
  "  budget:unassigned  -60 JPY",
  "  budget:food         60 JPY"
⟩
budget ← (canonicalBudget.Build ⟨budgetRaw,actual.accounts,registry⟩).facts
policyRaw ← •FChars "../"∾base∾"budget.toml"
policy ← budgetPolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

result ← envelopes.Build ⟨budget,policy,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
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
⟨0⟩ lib.AssertEq result.funding_account_indices
"actual.journal" lib.AssertEq (⊑result.funding_contributors).source
"budget.journal" lib.AssertEq (⊑⊑result.envelopes.entitlement_contributors).source
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source

unknownDomain ← envelopes.Build ⟨budget,policy,actual,plan,"USD",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq unknownDomain.state
"domain_unknown" lib.AssertEq (⊑unknownDomain.diagnostics).code
invalidRange ← envelopes.Build ⟨budget,policy,actual,plan,"JPY",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-01",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq invalidRange.state
"statement_range_invalid" lib.AssertEq (⊑invalidRange.diagnostics).code

syntheticLines ← ⟨
  Join ⟨"assets:cash","role=asset","type=liquid","currency=JPY"⟩,
  Join ⟨"income:salary","role=income","currency=JPY"⟩,
  Join ⟨"expenses:food","role=expense","budget=food","currency=JPY"⟩,
  Join ⟨"budget:opening","role=budget","kind=opening","currency=JPY"⟩,
  Join ⟨"budget:unassigned","role=budget","kind=unassigned","currency=JPY"⟩,
  Join ⟨"budget:food","role=budget","kind=envelope","budget=food","currency=JPY"⟩
⟩
syntheticRaw ← ∾⟨
  "commodity JPY",lf,lf,"account assets:cash",lf,"    ; role: asset",lf,lf,
  "account income:salary",lf,"    ; role: income",lf,lf,"account expenses:food",lf,"    ; role: expense",lf,lf,
  "account budget:opening",lf,"    ; role: budget",lf,lf,"account budget:unassigned",lf,"    ; role: budget",lf,lf,
  "account budget:food",lf,"    ; role: budget",lf,lf,
  "2026-01-02 * income",lf,"    ; event-id: income",lf,"    ; layer: actual",lf,"    assets:cash 10 JPY",lf,"    income:salary -10 JPY",lf,lf,
  "2026-01-05 * spend",lf,"    ; event-id: spend",lf,"    ; layer: actual",lf,"    expenses:food 30 JPY",lf,"    assets:cash -30 JPY",lf,lf,
  "2026-01-08 * refund",lf,"    ; event-id: refund",lf,"    ; layer: actual",lf,"    assets:cash 5 JPY",lf,"    expenses:food -5 JPY",lf
⟩
syntheticActual ← (snapshot.Build ⟨syntheticLines,syntheticRaw,registry⟩).facts
syntheticPlan ← (canonicalPlan.Build ⟨Raw ⟨"2026-01-15 open-food","  ; plan-id: open-food","  expenses:food  4 JPY","  assets:cash  -4 JPY"⟩,syntheticActual.accounts,registry⟩).facts
syntheticBudget ← (canonicalBudget.Build ⟨Raw ⟨"2026-01-01 seed","  budget:opening     -20 JPY","  budget:unassigned   20 JPY","","2026-01-01 allocate","  budget:unassigned  -20 JPY","  budget:food         20 JPY"⟩,syntheticActual.accounts,registry⟩).facts
syntheticPolicy ← budgetPolicyAdmission.Admit ⟨policyRaw,syntheticActual.accounts⟩
"ok" lib.AssertEq syntheticPolicy.state
synthetic ← envelopes.Build ⟨syntheticBudget,syntheticPolicy,syntheticActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
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
emptyPlan ← envelopes.Build ⟨syntheticBudget,syntheticPolicy,syntheticActual,emptyPlanFacts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"ok" lib.AssertEq emptyPlan.state
⟨0⟩ lib.AssertEq emptyPlan.envelopes.open_plan_reserve

duplicateRaw ← syntheticRaw∾lf∾lf∾∾⟨
  "2026-01-09 * duplicate one",lf,"    ; event-id: duplicate-one",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,"    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf,lf,
  "2026-01-09 * duplicate two",lf,"    ; event-id: duplicate-two",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,"    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf
⟩
duplicateActual ← (snapshot.Build ⟨syntheticLines,duplicateRaw,registry⟩).facts
duplicateCompletion ← envelopes.Build ⟨syntheticBudget,syntheticPolicy,duplicateActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"error" lib.AssertEq duplicateCompletion.state
0 lib.AssertEq duplicateCompletion.envelopes.count
"plan_completion_conflict" lib.AssertEq (⊑duplicateCompletion.diagnostics).code

overflowLines ← ⟨
  Join ⟨"assets:ils","role=asset","currency=ILS"⟩,
  Join ⟨"expenses:ils","role=expense","budget=food","currency=ILS"⟩,
  Join ⟨"budget:unassigned-ils","role=budget","kind=unassigned","currency=ILS"⟩,
  Join ⟨"budget:food-ils","role=budget","kind=envelope","budget=food","currency=ILS"⟩
⟩
overflowRaw ← ∾⟨
  "commodity ILS",lf,lf,"account assets:ils",lf,"    ; role: asset",lf,lf,"account expenses:ils",lf,"    ; role: expense",lf,lf,
  "account budget:unassigned-ils",lf,"    ; role: budget",lf,lf,"account budget:food-ils",lf,"    ; role: budget",lf,lf,
  "2026-01-05 * fractional",lf,"    ; event-id: fractional",lf,"    ; layer: actual",lf,"    expenses:ils 0.1 ILS",lf,"    assets:ils -0.1 ILS",lf
⟩
overflowActual ← (snapshot.Build ⟨overflowLines,overflowRaw,registry⟩).facts
overflowBudget ← (canonicalBudget.Build ⟨Raw ⟨"2026-01-01 max","  budget:unassigned-ils  -999999999999999 ILS","  budget:food-ils         999999999999999 ILS"⟩,overflowActual.accounts,registry⟩).facts
overflowPolicyRaw ← Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "assets:ils")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),"expense-accounts = ["∾(Q "expenses:ils")∾"]"
⟩
overflowPolicy ← budgetPolicyAdmission.Admit ⟨overflowPolicyRaw,overflowActual.accounts⟩
"ok" lib.AssertEq overflowPolicy.state
overflowPlan ← (canonicalPlan.Build ⟨"",overflowActual.accounts,registry⟩).facts
overflow ← envelopes.Build ⟨overflowBudget,overflowPolicy,overflowActual,overflowPlan,"ILS",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"error" lib.AssertEq overflow.state
0 lib.AssertEq overflow.envelopes.count
"coefficient_sum_failed" lib.AssertEq (⊑overflow.diagnostics).code
•Out "test_accounting_envelope_backing: ok"
