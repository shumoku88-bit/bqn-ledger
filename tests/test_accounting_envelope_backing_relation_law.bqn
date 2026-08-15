#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
completion ← •Import "../src/accounting/plan_completion_join.bqn"
envelopes ← •Import "envelope_backing_test_adapter.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10 ⋄ tab ← @+9 ⋄ quote ← @+34
JournalText ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Join ← {𝕊 fields: out ← ⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}

registry ← (registry_core.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountLines ← ⟨
  Join ⟨"assets:cash","role=asset","currency=JPY"⟩,
  Join ⟨"expenses:food","role=expense","currency=JPY"⟩,
  Join ⟨"expenses:transport","role=expense","currency=JPY"⟩,
  Join ⟨"expenses:other","role=expense","currency=JPY"⟩,
  Join ⟨"budget:opening","role=budget","kind=opening","currency=JPY"⟩,
  Join ⟨"budget:unassigned","role=budget","kind=unassigned","currency=JPY"⟩,
  Join ⟨"budget:food","role=budget","kind=envelope","budget=food","currency=JPY"⟩,
  Join ⟨"budget:transport","role=budget","kind=envelope","budget=transport","currency=JPY"⟩
⟩
actualRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account expenses:transport",lf,"    ; role: expense",lf,lf,
  "account expenses:other",lf,"    ; role: expense",lf,lf,
  "account budget:opening",lf,"    ; role: budget",lf,lf,
  "account budget:unassigned",lf,"    ; role: budget",lf,lf,
  "account budget:food",lf,"    ; role: budget",lf,lf,
  "account budget:transport",lf,"    ; role: budget",lf
⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts

planRaw ← JournalText ⟨
  "2026-01-12 food","  ; plan-id: food-plan","  expenses:food  4 JPY","  assets:cash  -4 JPY","",
  "2026-01-13 transport","  ; plan-id: transport-plan","  expenses:transport  6 JPY","  assets:cash  -6 JPY","",
  "2026-01-14 other","  ; plan-id: other-plan","  expenses:other  9 JPY","  assets:cash  -9 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
budgetRaw ← JournalText ⟨
  "2026-01-01 seed","  budget:opening     -30 JPY","  budget:unassigned   30 JPY","",
  "2026-01-01 food","  budget:unassigned  -20 JPY","  budget:food         20 JPY","",
  "2026-01-01 transport","  budget:unassigned  -10 JPY","  budget:transport    10 JPY"
⟩
budget ← (canonicalBudget.Build ⟨budgetRaw,actual.accounts,registry⟩).movements
policyRaw ← JournalText ⟨
  "[[backing-pools]]","id = "∾Q "cash","asset-accounts = ["∾(Q "assets:cash")∾"]","",
  "[[envelopes]]","id = "∾Q "food","label = "∾Q "Food","pacing = "∾Q "daily","backing-pool = "∾Q "cash","expense-accounts = ["∾(Q "expenses:food")∾"]","",
  "[[envelopes]]","id = "∾Q "transport","label = "∾Q "Transport","pacing = "∾Q "flex","backing-pool = "∾Q "cash","expense-accounts = ["∾(Q "expenses:transport")∾"]"
⟩
policy ← budgetPolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

# The admitted Expense relation is constructed from the Envelope axis itself.
# Therefore every generated Envelope id already has a valid category coordinate.
categories ← policy.envelopes.id
expenseKeys ← ∾policy.envelopes.expense_account_keys
expenseEnvelopeIds ← ∾{𝕊 i:(≠i⊑policy.envelopes.expense_account_keys)⥊⟨i⊑categories⟩}¨↕≠categories
expenseIndices ← actual.accounts.key⊐expenseKeys
expenseCoordinates ← categories⊐expenseEnvelopeIds
1 lib.AssertEq ∧´1∾expenseCoordinates<≠categories

# Plan completion publishes destination Account keys. Matching one against the
# resolved Expense relation implies current Expense role, selected domain, and
# a valid Envelope coordinate without a second independent lookup contract.
joined ← completion.Build ⟨plan,actual,plan.transactions.index,actual.transactions.index⟩
"ok" lib.AssertEq joined.state
planAccountRows ← actual.accounts.key⊐joined.rows.planned_to_account
assignmentRows ← expenseIndices⊐planAccountRows
assigned ← assignmentRows<≠expenseIndices
⟨1,1,0⟩ lib.AssertEq assigned
assignedPlanRows ← assigned/planAccountRows
⟨"expense","expense"⟩ lib.AssertEq assignedPlanRows⊏actual.accounts.role
⟨"JPY","JPY"⟩ lib.AssertEq assignedPlanRows⊏actual.accounts.currency
assignedEnvelopeIds ← (assigned/assignmentRows)⊏expenseEnvelopeIds
assignedCoordinates ← categories⊐assignedEnvelopeIds
1 lib.AssertEq ∧´1∾assignedCoordinates<≠categories
⟨"expenses:other"⟩ lib.AssertEq (¬assigned)/joined.rows.planned_to_account

# An unmatched open Plan remains merely ineligible for Envelope reserve. It is
# not an ownership error and contributes no amount to either Envelope.
household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food","transport"⟩,
    allocation_account_key⇐⟨"budget:food","budget:transport"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩
  },
  account_policy⇐{account_key⇐actual.accounts.key}
}
result ← envelopes.Build ⟨
  budget,policy,household,actual,plan,"JPY",
  dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"
⟩
"ok" lib.AssertEq result.state
⟨4,6⟩ lib.AssertEq result.envelopes.open_plan_reserve
⟨"food","transport"⟩ lib.AssertEq result.envelopes.category

•Out "test_accounting_envelope_backing_relation_law: ok"
