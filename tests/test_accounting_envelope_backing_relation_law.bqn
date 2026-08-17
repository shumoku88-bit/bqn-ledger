#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
envelopes ← •Import "envelope_backing_test_adapter.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

lf ← @+10 ⋄ tab ← @+9 ⋄ quote ← @+34
JournalText ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Join ← {𝕊 fields: out ← ⊑fields ⋄ {𝕊 field:out∾↩tab∾field}¨1↓fields ⋄ out}

registry ← (registry_core.Build ⟨Join ⟨"JPY","0","¥"⟩⟩).registry
accountSource ← JournalText ⟨
  "account assets:cash","  type: Asset","  commodity: JPY","",
  "account expenses:food","  type: Expense","  commodity: JPY","",
  "account expenses:transport","  type: Expense","  commodity: JPY","",
  "account expenses:other","  type: Expense","  commodity: JPY"
⟩
actualRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account expenses:transport",lf,"    ; role: expense",lf,lf,
  "account expenses:other",lf,"    ; role: expense",lf
⟩
actual ← (snapshot.Build ⟨accountSource,actualRaw,registry⟩).facts

planRaw ← JournalText ⟨
  "2026-01-12 food","  ; plan-id: food-plan","  expenses:food  4 JPY","  assets:cash  -4 JPY","",
  "2026-01-13 transport","  ; plan-id: transport-plan","  expenses:transport  6 JPY","  assets:cash  -6 JPY","",
  "2026-01-14 other","  ; plan-id: other-plan","  expenses:other  9 JPY","  assets:cash  -9 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
policyRaw ← JournalText ⟨
  "[[backing-pools]]","id = "∾Q "cash","asset-accounts = ["∾(Q "assets:cash")∾"]","",
  "[[envelopes]]","id = "∾Q "food","label = "∾Q "Food","pacing = "∾Q "daily","backing-pool = "∾Q "cash","",
  "[[envelopes]]","id = "∾Q "transport","label = "∾Q "Transport","pacing = "∾Q "flex","backing-pool = "∾Q "cash"
⟩
policy ← envelopePolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

historyFixture ← •Import "envelope_history_test_fixture.bqn"
history ← historyFixture.Managed ⟨⟨"food","transport"⟩,⟨"expenses:food","expenses:transport"⟩,⟨"food","transport"⟩⟩
"ok" lib.AssertEq history.state
⟨"food","transport"⟩ lib.AssertEq history.registry.id
⟨"expenses:food","expenses:transport"⟩ lib.AssertEq history.expense_routing.expense_account_key
⟨"managed","managed"⟩ lib.AssertEq history.expense_routing.route
⟨"food","transport"⟩ lib.AssertEq history.expense_routing.target_id

entitlementRaw ← JournalText ⟨
  "2026-01-01 origin JPY",
  "2026-01-01 transfer unallocated -> food 20 JPY",
  "2026-01-01 transfer unallocated -> transport 10 JPY"
⟩
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

# An Expense Plan with no historical route remains merely unrouted. It does not
# become owned by an Envelope because a current policy happens to exist.
core ← •Import "../src/accounting/envelope_backing.bqn"
EmptyRetirements ← {𝕊: {plan_id⇐⟨⟩,retired_on⇐⟨⟩}}
result ← core.Build ⟨
  entitlement,policy,history,actual,plan,EmptyRetirements @,"JPY",
  dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"
⟩
"ok" lib.AssertEq result.state
⟨4,6⟩ lib.AssertEq result.envelopes.commitment
⟨"food","transport"⟩ lib.AssertEq result.envelopes.envelope_id
⟨"other-plan"⟩ lib.AssertEq result.commitment_observation.unrouted.plan_id
⟨"expenses:other"⟩ lib.AssertEq result.commitment_observation.unrouted.target_account_key

•Out "test_accounting_envelope_backing_relation_law: ok"
