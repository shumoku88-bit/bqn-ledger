#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
adapter ← •Import "../src/application/budget_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

accounts ← accountSource.Load "fixtures/canonical-household-v1"
"ok" lib.AssertEq accounts.state

# Budget policy is an independently admitted capability. This fixture deliberately
# contains no budget.journal; LoadPolicy must not depend on Budget movement bytes.
policyOnly ← adapter.LoadPolicy ⟨"tests/fixtures/budget-policy-only",accounts.accounts⟩
"ok" lib.AssertEq policyOnly.state
1 lib.AssertEq policyOnly.backing_pools.count
1 lib.AssertEq policyOnly.envelopes.count
⟨"main"⟩ lib.AssertEq policyOnly.backing_pools.id
⟨"Daily"⟩ lib.AssertEq policyOnly.envelopes.id

combined ← adapter.Load ⟨"fixtures/canonical-household-v1",registryResult.registry⟩
"ok" lib.AssertEq combined.state
0 lib.AssertEq ≠combined.diagnostics
1 lib.AssertEq combined.facts.transactions.count
2 lib.AssertEq combined.facts.postings.count
1 lib.AssertEq combined.policy.backing_pools.count
1 lib.AssertEq combined.policy.envelopes.count

•Out "test_application_budget_source_adapter: ok"
