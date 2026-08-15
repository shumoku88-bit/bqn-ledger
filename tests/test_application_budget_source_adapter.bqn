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

base ← "fixtures/canonical-household-v1"
combined ← adapter.Load ⟨base,registryResult.registry⟩
"ok" lib.AssertEq combined.state
0 lib.AssertEq ≠combined.diagnostics
1 lib.AssertEq combined.facts.transactions.count
2 lib.AssertEq combined.facts.postings.count
1 lib.AssertEq ≠combined.movements.transactions
"Budget:Unassigned" lib.AssertEq (⊑combined.movements.transactions).from_account_key
"Budget:Daily" lib.AssertEq (⊑combined.movements.transactions).to_account_key
30000 lib.AssertEq (⊑combined.movements.transactions).movement_coefficient
1 lib.AssertEq combined.policy.backing_pools.count
1 lib.AssertEq combined.policy.envelopes.count

# A wider application observation can reuse one admitted Account Registry without
# changing Budget transaction identity, Posting identity, Account axes, or policy.
shared ← adapter.LoadFromAccounts ⟨base,accounts.accounts,registryResult.registry⟩
"ok" lib.AssertEq shared.state
combined.facts.transactions.transaction_id lib.AssertEq shared.facts.transactions.transaction_id
combined.facts.postings.posting_id lib.AssertEq shared.facts.postings.posting_id
combined.facts.accounts.key lib.AssertEq shared.facts.accounts.key
({𝕩.source_event_id}¨combined.movements.transactions) lib.AssertEq ({𝕩.source_event_id}¨shared.movements.transactions)
({𝕩.posting_id}¨(⊑combined.movements.transactions).postings) lib.AssertEq ({𝕩.posting_id}¨(⊑shared.movements.transactions).postings)
combined.policy.backing_pools.id lib.AssertEq shared.policy.backing_pools.id
combined.policy.envelopes.id lib.AssertEq shared.policy.envelopes.id

•Out "test_application_budget_source_adapter: ok"
