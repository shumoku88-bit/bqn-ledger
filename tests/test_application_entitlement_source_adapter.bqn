#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"
entitlementAdapter ← •Import "../src/application/entitlement_source_adapter.bqn"
envelopeAdapter ← •Import "../src/application/envelope_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

accounts ← accountSource.Load "fixtures/canonical-household-v1"
"ok" lib.AssertEq accounts.state

policyOnly ← envelopeAdapter.LoadPolicy ⟨"tests/fixtures/envelope-policy-only",accounts.accounts⟩
"ok" lib.AssertEq policyOnly.state
1 lib.AssertEq policyOnly.backing_pools.count
1 lib.AssertEq policyOnly.envelopes.count
⟨"main"⟩ lib.AssertEq policyOnly.backing_pools.id
⟨"Daily"⟩ lib.AssertEq policyOnly.envelopes.id

base ← "fixtures/canonical-household-v1"
household ← householdSource.LoadShared ⟨base,accounts.accounts⟩
"ok" lib.AssertEq household.state

entitlement ← entitlementAdapter.Load ⟨base,household.history,registryResult.registry⟩
"ok" lib.AssertEq entitlement.state
0 lib.AssertEq ≠entitlement.diagnostics
1 lib.AssertEq entitlement.origins.count
1 lib.AssertEq entitlement.transfers.count
"unallocated" lib.AssertEq ⊑entitlement.transfers.from
"Daily" lib.AssertEq ⊑entitlement.transfers.to
30000 lib.AssertEq ⊑entitlement.transfers.coefficient

•Out "test_application_entitlement_source_adapter: ok"
