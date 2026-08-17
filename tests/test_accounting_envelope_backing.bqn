#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "envelope_backing_test_adapter.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
actual ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
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
history ← envelopes.HistoryFor actual

entitlementRaw ← Raw ⟨
  "2026-01-01 origin JPY",
  "2026-01-01 transfer unallocated -> food 60 JPY ; allocate-food"
⟩
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

policyRaw ← •FChars "../"∾base∾"envelope.toml"
policy ← envelopePolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

result ← envelopes.Build ⟨entitlement,policy,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.envelopes.count
⟨"food"⟩ lib.AssertEq result.envelopes.envelope_id
⟨60⟩ lib.AssertEq result.envelopes.entitlement
⟨30⟩ lib.AssertEq result.envelopes.actual_consumption
⟨0⟩ lib.AssertEq result.envelopes.actual_refunds
⟨30⟩ lib.AssertEq result.envelopes.ledger_remaining
⟨0⟩ lib.AssertEq result.envelopes.commitment
⟨30⟩ lib.AssertEq result.envelopes.post_plan_headroom
965 lib.AssertEq result.totals.funding_balance
30 lib.AssertEq result.totals.backing_required
935 lib.AssertEq result.totals.backing_surplus
"backed" lib.AssertEq result.status
⟨0⟩ lib.AssertEq result.funding_account_indices
"actual.journal" lib.AssertEq (⊑result.funding_contributors).source
"entitlement.journal" lib.AssertEq (⊑⊑result.envelopes.entitlement_contributors).source
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source
1 lib.AssertEq result.consumption_observation.unmanaged.count
0 lib.AssertEq result.consumption_observation.unrouted.count

# Envelope policy keeps Backing Account keys, not admission-time numeric coordinates.
# Reversing only the Account carrier used for policy admission leaves Backing-pool
# resolution unchanged.
reorderedAccounts ← {
  count⇐actual.accounts.count,index⇐actual.accounts.index,
  key⇐⌽actual.accounts.key,role⇐⌽actual.accounts.role
}
reorderedPolicy ← envelopePolicyAdmission.Admit ⟨policyRaw,reorderedAccounts⟩
"ok" lib.AssertEq reorderedPolicy.state
reordered ← envelopes.Build ⟨entitlement,reorderedPolicy,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
"ok" lib.AssertEq reordered.state
result.envelopes.actual_consumption lib.AssertEq reordered.envelopes.actual_consumption
result.envelopes.ledger_remaining lib.AssertEq reordered.envelopes.ledger_remaining
result.totals.funding_balance lib.AssertEq reordered.totals.funding_balance
result.totals.backing_surplus lib.AssertEq reordered.totals.backing_surplus
result.funding_account_indices lib.AssertEq reordered.funding_account_indices

unknownDomain ← envelopes.Build ⟨entitlement,policy,actual,plan,"USD",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq unknownDomain.state
"domain_unknown" lib.AssertEq (⊑unknownDomain.diagnostics).code
invalidRange ← envelopes.Build ⟨entitlement,policy,actual,plan,"JPY",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-01",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq invalidRange.state
"statement_range_invalid" lib.AssertEq (⊑invalidRange.diagnostics).code

syntheticAccountSource ← Raw ⟨
  "account assets:cash","  type: Asset","  commodity: JPY","",
  "account income:salary","  type: Income","  commodity: JPY","",
  "account expenses:food","  type: Expense","  commodity: JPY"
⟩
syntheticRaw ← ∾⟨
  "commodity JPY",lf,lf,"account assets:cash",lf,"    ; role: asset",lf,lf,
  "account income:salary",lf,"    ; role: income",lf,lf,"account expenses:food",lf,"    ; role: expense",lf,lf,
  "2026-01-02 * income",lf,"    ; event-id: income",lf,"    ; layer: actual",lf,"    assets:cash 10 JPY",lf,"    income:salary -10 JPY",lf,lf,
  "2026-01-05 * spend",lf,"    ; event-id: spend",lf,"    ; layer: actual",lf,"    expenses:food 30 JPY",lf,"    assets:cash -30 JPY",lf,lf,
  "2026-01-08 * refund",lf,"    ; event-id: refund",lf,"    ; layer: actual",lf,"    assets:cash 5 JPY",lf,"    expenses:food -5 JPY",lf
⟩
syntheticActual ← (snapshot.Build ⟨syntheticAccountSource,syntheticRaw,registry⟩).facts
syntheticPlan ← (canonicalPlan.Build ⟨Raw ⟨"2026-01-15 open-food","  ; plan-id: open-food","  expenses:food  4 JPY","  assets:cash  -4 JPY"⟩,syntheticActual.accounts,registry⟩).facts
syntheticHistory ← envelopes.HistoryFor syntheticActual
syntheticEntitlement ← entitlementAdmission.Admit ⟨Raw ⟨"2026-01-01 origin JPY","2026-01-01 transfer unallocated -> food 20 JPY ; allocate"⟩,syntheticHistory,registry⟩
syntheticPolicy ← envelopePolicyAdmission.Admit ⟨policyRaw,syntheticActual.accounts⟩
"ok" lib.AssertEq syntheticPolicy.state
synthetic ← envelopes.Build ⟨syntheticEntitlement,syntheticPolicy,syntheticActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"ok" lib.AssertEq synthetic.state
⟨20⟩ lib.AssertEq synthetic.envelopes.entitlement
⟨30⟩ lib.AssertEq synthetic.envelopes.actual_consumption
⟨5⟩ lib.AssertEq synthetic.envelopes.actual_refunds
⟨¯5⟩ lib.AssertEq synthetic.envelopes.ledger_remaining
⟨4⟩ lib.AssertEq synthetic.envelopes.commitment
⟨¯9⟩ lib.AssertEq synthetic.envelopes.post_plan_headroom
¯15 lib.AssertEq synthetic.totals.funding_balance
0 lib.AssertEq synthetic.totals.backing_required
¯15 lib.AssertEq synthetic.totals.backing_surplus
"under_backed" lib.AssertEq synthetic.status
"plan.journal" lib.AssertEq (⊑⊑synthetic.envelopes.plan_contributors).source
"actual.journal" lib.AssertEq (⊑⊑synthetic.envelopes.refund_contributors).source
0 lib.AssertEq synthetic.consumption_observation.unrouted.count
0 lib.AssertEq synthetic.consumption_observation.unmanaged.count

emptyPlanFacts ← (canonicalPlan.Build ⟨"",syntheticActual.accounts,registry⟩).facts
emptyPlan ← envelopes.Build ⟨syntheticEntitlement,syntheticPolicy,syntheticActual,emptyPlanFacts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"ok" lib.AssertEq emptyPlan.state
⟨0⟩ lib.AssertEq emptyPlan.envelopes.commitment

duplicateRaw ← syntheticRaw∾lf∾lf∾∾⟨
  "2026-01-09 * duplicate one",lf,"    ; event-id: duplicate-one",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,"    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf,lf,
  "2026-01-09 * duplicate two",lf,"    ; event-id: duplicate-two",lf,"    ; layer: actual",lf,"    ; currency: JPY",lf,"    ; plan-id: open-food",lf,"    expenses:food 4 JPY",lf,"    assets:cash -4 JPY",lf
⟩
duplicateActual ← (snapshot.Build ⟨syntheticAccountSource,duplicateRaw,registry⟩).facts
duplicateCompletion ← envelopes.Build ⟨syntheticEntitlement,syntheticPolicy,duplicateActual,syntheticPlan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"error" lib.AssertEq duplicateCompletion.state
0 lib.AssertEq duplicateCompletion.envelopes.count
"plan_completion_multiple_actuals" lib.AssertEq (⊑duplicateCompletion.diagnostics).code

overflowAccountSource ← Raw ⟨
  "account assets:ils","  type: Asset","  commodity: ILS","",
  "account income:ils","  type: Income","  commodity: ILS","",
  "account expenses:ils","  type: Expense","  commodity: ILS"
⟩
overflowRaw ← ∾⟨
  "commodity ILS",lf,lf,"account assets:ils",lf,"    ; role: asset",lf,lf,
  "account income:ils",lf,"    ; role: income",lf,lf,"account expenses:ils",lf,"    ; role: expense",lf,lf,
  "2026-01-05 * fractional",lf,"    ; event-id: fractional",lf,"    ; layer: actual",lf,"    expenses:ils 0.1 ILS",lf,"    assets:ils -0.1 ILS",lf
⟩
overflowActual ← (snapshot.Build ⟨overflowAccountSource,overflowRaw,registry⟩).facts
overflowHistory ← envelopes.HistoryFor overflowActual
overflowEntitlement ← entitlementAdmission.Admit ⟨Raw ⟨"2026-01-01 origin ILS","2026-01-01 transfer unallocated -> food 999999999999999 ILS"⟩,overflowHistory,registry⟩
overflowPolicyRaw ← Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "assets:ils")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash")
⟩
overflowPolicy ← envelopePolicyAdmission.Admit ⟨overflowPolicyRaw,overflowActual.accounts⟩
"ok" lib.AssertEq overflowPolicy.state
overflowPlan ← (canonicalPlan.Build ⟨"",overflowActual.accounts,registry⟩).facts
overflow ← envelopes.Build ⟨overflowEntitlement,overflowPolicy,overflowActual,overflowPlan,"ILS",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-10"⟩
"error" lib.AssertEq overflow.state
0 lib.AssertEq overflow.envelopes.count
"coefficient_sum_failed" lib.AssertEq (⊑overflow.diagnostics).code
•Out "test_accounting_envelope_backing: ok"