#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
adapter ← •Import "../src/application/plan_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

base ← "fixtures/canonical-household-v1"
result ← adapter.Load ⟨base,registryResult.registry⟩
{𝕊:
  {𝕊 diagnostic: •Out diagnostic.code∾" | "∾(•Fmt diagnostic.line)∾" | "∾diagnostic.message}¨result.diagnostics
}⍟(result.state≢"ok") @
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
2 lib.AssertEq result.facts.transactions.count
4 lib.AssertEq result.facts.postings.count
4 lib.AssertEq result.facts.accounts.count
1 lib.AssertEq result.facts.domains.count
⟨"JPY"⟩ lib.AssertEq result.facts.domains.code
⟨"plan"⟩ lib.AssertEq result.facts.layers.name
⟨3,9⟩ lib.AssertEq result.facts.transactions.source_start_line
⟨"plan-groceries","plan-salary"⟩ lib.AssertEq result.facts.transactions.plan_id
⟨"durable_relation","durable_relation"⟩ lib.AssertEq result.facts.transactions.identity_kind
⟨"plan.journal:plan_id:plan-groceries","plan.journal:plan_id:plan-salary"⟩ lib.AssertEq result.facts.transactions.transaction_id
⟨"Planned groceries","Planned salary"⟩ lib.AssertEq result.facts.transactions.description
⟨"Assets:Bank","Equity:Opening","Income:Salary","Expenses:Groceries"⟩ lib.AssertEq result.facts.accounts.key

firstMetadata ← ⊑result.facts.transactions.metadata
⟨"plan-id","daily-target-id"⟩ lib.AssertEq {𝕩.key}¨firstMetadata
⟨"plan-groceries","groceries"⟩ lib.AssertEq {𝕩.value}¨firstMetadata

# A wider application lifetime may admit Accounts once and reuse that exact
# observation. The resulting Plan meaning is identical to the standalone load.
accounts ← accountSource.Load base
"ok" lib.AssertEq accounts.state
shared ← adapter.LoadFromAccounts ⟨base,accounts.accounts,registryResult.registry⟩
"ok" lib.AssertEq shared.state
result.facts.transactions.transaction_id lib.AssertEq shared.facts.transactions.transaction_id
result.facts.postings.posting_id lib.AssertEq shared.facts.postings.posting_id
result.facts.accounts.key lib.AssertEq shared.facts.accounts.key

•Out "test_application_plan_source_adapter: ok"
