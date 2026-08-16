#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
adapter ← •Import "../src/application/actual_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

base ← "fixtures/canonical-household-v1"
result ← adapter.Load ⟨base,registryResult.registry⟩
{𝕊:
  {𝕊 diagnostic: •Out diagnostic.code∾" | "∾(•Fmt diagnostic.line)∾" | " | "∾diagnostic.message}¨result.diagnostics
}⍟(result.state≢"ok") @
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
4 lib.AssertEq result.facts.transactions.count
8 lib.AssertEq result.facts.postings.count
7 lib.AssertEq result.facts.accounts.count
1 lib.AssertEq result.facts.domains.count
⟨"JPY"⟩ lib.AssertEq result.facts.domains.code
⟨"actual"⟩ lib.AssertEq result.facts.layers.name
⟨3,7,11,16⟩ lib.AssertEq result.facts.transactions.source_start_line
⟨"Opening","Salary","Groceries","Planned groceries completed"⟩ lib.AssertEq result.facts.transactions.description
⟨"Assets:Bank","Equity:Opening","Income:Salary","Expenses:Groceries","Budget:Opening","Budget:Unassigned","Budget:Daily"⟩ lib.AssertEq result.facts.accounts.key
⟨"100000","","50000","","-5000","","-4000",""⟩ lib.AssertEq result.facts.postings.amount_text

# A wider application lifetime may admit Accounts once and reuse that exact
# observation. The resulting Actual meaning is identical to the standalone load.
accounts ← accountSource.Load base
"ok" lib.AssertEq accounts.state
shared ← adapter.LoadFromAccounts ⟨base,accounts.accounts,registryResult.registry⟩
"ok" lib.AssertEq shared.state
result.facts.transactions.transaction_id lib.AssertEq shared.facts.transactions.transaction_id
result.facts.postings.posting_id lib.AssertEq shared.facts.postings.posting_id
result.facts.accounts.key lib.AssertEq shared.facts.accounts.key

# Account admission owns the first capability gate. This fixture deliberately has
# no actual.journal; reaching the Actual read would raise instead of returning an
# admitted error result.
accountFailure ← adapter.Load ⟨"tests/fixtures/actual-source-invalid-accounts",registryResult.registry⟩
"error" lib.AssertEq accountFailure.state
1 lib.AssertEq 0<≠accountFailure.diagnostics

•Out "test_application_actual_source_adapter: ok"
