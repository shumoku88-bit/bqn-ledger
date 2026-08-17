#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
empty ← ⟨⟩
lf ← @+10
tab ← @+9

Raw ← {𝕊 lines: ∾lines∾¨lf}
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← Raw ⟨
  "account assets:cash","  type: Asset","  commodity: JPY","",
  "account assets:savings","  type: Asset","  commodity: JPY","",
  "account expenses:food","  type: Expense","  commodity: JPY"
⟩

actualRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:cash",lf,"    ; role: asset",lf,lf,
  "account assets:savings",lf,"    ; role: asset",lf,lf,
  "account expenses:food",lf,"    ; role: expense",lf,lf,
  "2026-07-31 * routed accounting before Envelope stock origin",lf,
  "    ; event-id: pre-origin",lf,"    ; layer: actual",lf,
  "    expenses:food 9 JPY",lf,"    assets:cash -9 JPY",lf,lf,
  "2026-08-02 * routed use after source opening but before first grant",lf,
  "    ; event-id: consumption",lf,"    ; layer: actual",lf,
  "    expenses:food 40 JPY",lf,"    assets:cash -40 JPY",lf,lf,
  "2026-08-03 * previous-period fulfillment",lf,
  "    ; event-id: fulfillment",lf,"    ; layer: actual",lf,
  "    ; plan-id: p-save",lf,
  "    assets:savings 30 JPY",lf,"    assets:cash -30 JPY",lf
⟩
actual ← (snapshot.Build ⟨accountSource,actualRaw,registry⟩).facts
"ok" lib.AssertEq actual.state

planRaw ← Raw ⟨
  "2026-08-03 planned saving",
  "  ; plan-id: p-save",
  "  assets:savings 30 JPY",
  "  assets:cash -30 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
"ok" lib.AssertEq plan.state

policyRaw ← •FChars "../fixtures/ledger-facts-phase1-proof/envelope.toml"
policy ← envelopePolicyAdmission.Admit ⟨policyRaw,actual.accounts⟩
"ok" lib.AssertEq policy.state

baseHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"food"⟩⟩
history ← historyFixture.WithFulfillment ⟨
  baseHistory,⟨"2026-07-01"⟩,⟨"p-save"⟩,⟨"fulfills"⟩,⟨"food"⟩
⟩

entitlementRaw ← Raw ⟨
  "2026-08-01 origin JPY",
  "2026-08-03 transfer unallocated -> food 100 JPY ; first Envelope grant"
⟩
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

retirements ← {plan_id⇐empty,retired_on⇐empty}
reportStart ← dates.Ordinal "2026-09-01"
reportFinish ← dates.Ordinal "2026-10-01"
observation ← dates.Ordinal "2026-09-02"
stockOrigin ← dates.Ordinal "2026-08-01"

result ← envelopes.Build ⟨entitlement,policy,history,actual,plan,retirements,"JPY",reportStart,reportFinish,observation⟩
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
# Envelope position. The 40 JPY Actual after source opening must enter even though
# it precedes the first Envelope grant.
1 lib.AssertEq result.consumption_observation.evidence.count
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source

# No admitted StockOrigin through the observation means no
# Envelope stock horizon yet. The post-observation zero-width interval is a
# canonical empty array observation rather than a fallback to report Period start.
futureEntitlementRaw ← Raw ⟨
  "2026-09-10 origin JPY",
  "2026-09-10 transfer unallocated -> food 100 JPY ; future grant"
⟩
futureEntitlement ← entitlementAdmission.Admit ⟨futureEntitlementRaw,history,registry⟩
"ok" lib.AssertEq futureEntitlement.state
futureResult ← envelopes.Build ⟨futureEntitlement,policy,history,actual,plan,retirements,"JPY",reportStart,reportFinish,observation⟩
"ok" lib.AssertEq futureResult.state
(observation+1) lib.AssertEq futureResult.consumption_observation.start_ordinal
(observation+1) lib.AssertEq futureResult.consumption_observation.end_exclusive_ordinal
⟨0⟩ lib.AssertEq futureResult.envelopes.actual_consumption
⟨0⟩ lib.AssertEq futureResult.envelopes.fulfillment
⟨0⟩ lib.AssertEq futureResult.envelopes.ledger_remaining

•Out "test_accounting_envelope_stock_horizon: ok"
