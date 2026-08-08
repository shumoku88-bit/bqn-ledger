#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
adapter ← •Import "../src/application/actual_source_adapter.bqn"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state

result ← adapter.Load ⟨"fixtures/canonical-household-v1",registryResult.registry⟩
{𝕊:
  {𝕊 diagnostic: •Out diagnostic.code∾" | "∾(•Fmt diagnostic.line)∾" | "∾diagnostic.message}¨result.diagnostics
}⍟(result.state≢"ok") @
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
4 lib.AssertEq result.facts.transactions.count
8 lib.AssertEq result.facts.postings.count
6 lib.AssertEq result.facts.accounts.count
1 lib.AssertEq result.facts.domains.count
⟨"JPY"⟩ lib.AssertEq result.facts.domains.code
⟨"actual"⟩ lib.AssertEq result.facts.layers.name
⟨3,7,11,16⟩ lib.AssertEq result.facts.transactions.source_start_line
⟨"Opening","Salary","Groceries","Planned groceries completed"⟩ lib.AssertEq result.facts.transactions.description
⟨"Assets:Bank","Equity:Opening","Income:Salary","Expenses:Groceries","Budget:Unassigned","Budget:Daily"⟩ lib.AssertEq result.facts.accounts.key
⟨"100000","","50000","","-5000","","-4000",""⟩ lib.AssertEq result.facts.postings.amount_text

•Out "test_application_actual_source_adapter: ok"
