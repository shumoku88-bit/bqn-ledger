#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
empty ← ⟨⟩
lf ← @+10
tab ← @+9

Raw ← {𝕊 lines: ∾lines∾¨lf}
Join ← {𝕊 fields:
  out ← ⊑fields
  {𝕊 field:out∾↩tab∾field}¨1↓fields
  out
}
Has ← {𝕊 item‿items:∨´0∾item⊸≡¨items}
Kind ← {𝕊 key:
  result ← ""
  {𝕊:result↩"opening"}⍟(key≡"budget:opening") @
  {𝕊:result↩"unassigned"}⍟(key≡"budget:unassigned") @
  {𝕊:result↩"envelope"}⍟(key≡"budget:food") @
  result
}

registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← ⟨
  Join ⟨"assets:cash","role=asset","type=liquid","currency=JPY"⟩,
  Join ⟨"assets:savings","role=asset","type=savings","currency=JPY"⟩,
  Join ⟨"expenses:food","role=expense","currency=JPY"⟩,
  Join ⟨"budget:opening","role=budget","kind=opening","currency=JPY"⟩,
  Join ⟨"budget:unassigned","role=budget","kind=unassigned","currency=JPY"⟩,
  Join ⟨"budget:food","role=budget","kind=envelope","currency=JPY"⟩
⟩

actualRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account assets:savings",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "account budget:opening",lf,"    ; role: budget",lf,lf,
  "account budget:unassigned",lf,"    ; role: budget",lf,lf,
  "account budget:food",lf,"    ; role: budget",lf,lf,
  "2026-07-31 * routed accounting before Envelope stock origin",lf,
  "    ; event-id: pre-origin",lf,"    ; layer: actual",lf,
  "    expenses:food 9 JPY",lf,"    assets:cash -9 JPY",lf,lf,
  "2026-08-02 * previous-period consumption",lf,
  "    ; event-id: consumption",lf,"    ; layer: actual",lf,
  "    expenses:food 40 JPY",lf,"    assets:cash -40 JPY",lf,lf,
  "2026-08-03 * previous-period fulfillment",lf,
  "    ; event-id: fulfillment",lf,"    ; layer: actual",lf,
  "    ; plan-id: p-save",lf,
  "    assets:savings 30 JPY",lf,"    assets:cash -30 JPY",lf
⟩
actual ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
"ok" lib.AssertEq actual.state

planRaw ← Raw ⟨
  "2026-08-03 planned saving",
  "  ; plan-id: p-save",
  "  assets:savings 30 JPY",
  "  assets:cash -30 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
"ok" lib.AssertEq plan.state

budgetRaw ← Raw ⟨
  "2026-08-01 seed",
  "  budget:opening -100 JPY",
  "  budget:unassigned 100 JPY","",
  "2026-08-01 allocate",
  "  budget:unassigned -100 JPY",
  "  budget:food 100 JPY"
⟩
budget ← (canonicalBudget.Build ⟨budgetRaw,actual.accounts,registry⟩).movements
"ok" lib.AssertEq budget.state

policyRaw ← •FChars "../fixtures/ledger-facts-phase1-proof/budget.toml"
policy ← budgetPolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

household ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{
    envelope_id⇐⟨"food"⟩,
    allocation_account_key⇐⟨"budget:food"⟩,
    allocation_account_index⇐actual.accounts.key⊐⟨"budget:food"⟩,
    unassigned_account_keys⇐⟨"budget:unassigned"⟩,
    unassigned_account_indices⇐actual.accounts.key⊐⟨"budget:unassigned"⟩
  },
  account_policy⇐{account_key⇐actual.accounts.key,budget_kind⇐Kind¨actual.accounts.key}
}

baseHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"food"⟩⟩
history ← historyFixture.WithFulfillment ⟨
  baseHistory,⟨"2026-07-01"⟩,⟨"p-save"⟩,⟨"fulfills"⟩,⟨"food"⟩
⟩
retirements ← {plan_id⇐empty,retired_on⇐empty}
reportStart ← dates.Ordinal "2026-09-01"
reportFinish ← dates.Ordinal "2026-10-01"
observation ← dates.Ordinal "2026-09-02"
stockOrigin ← dates.Ordinal "2026-08-01"

result ← envelopes.Build ⟨budget,policy,household,history,actual,plan,retirements,"JPY",reportStart,reportFinish,observation⟩
"ok" lib.AssertEq result.state
reportStart lib.AssertEq result.start_ordinal
reportFinish lib.AssertEq result.end_exclusive_ordinal
stockOrigin lib.AssertEq result.consumption_observation.start_ordinal
stockOrigin lib.AssertEq result.fulfillment_observation.start_ordinal
⟨100⟩ lib.AssertEq result.envelopes.entitlement
⟨40⟩ lib.AssertEq result.envelopes.actual_consumption
⟨30⟩ lib.AssertEq result.envelopes.fulfillment
⟨30⟩ lib.AssertEq result.envelopes.ledger_remaining

# The pre-origin 9 JPY Actual is routed historically but must not enter the live
# Envelope position. If it leaked in, Consumption would be 49 and Remaining 21.
1 lib.AssertEq result.consumption_observation.evidence.count
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source

# No native Entitlement effect through the observation means no Envelope stock
# horizon yet. The post-observation zero-width interval is a canonical empty
# array observation rather than a fallback to the report Period start.
futureBudgetRaw ← Raw ⟨
  "2026-09-10 seed",
  "  budget:opening -100 JPY",
  "  budget:unassigned 100 JPY","",
  "2026-09-10 allocate",
  "  budget:unassigned -100 JPY",
  "  budget:food 100 JPY"
⟩
futureBudget ← (canonicalBudget.Build ⟨futureBudgetRaw,actual.accounts,registry⟩).movements
futureResult ← envelopes.Build ⟨futureBudget,policy,household,history,actual,plan,retirements,"JPY",reportStart,reportFinish,observation⟩
"ok" lib.AssertEq futureResult.state
(observation+1) lib.AssertEq futureResult.consumption_observation.start_ordinal
(observation+1) lib.AssertEq futureResult.consumption_observation.end_exclusive_ordinal
⟨0⟩ lib.AssertEq futureResult.envelopes.actual_consumption
⟨0⟩ lib.AssertEq futureResult.envelopes.fulfillment
⟨0⟩ lib.AssertEq futureResult.envelopes.ledger_remaining
