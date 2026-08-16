#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
recent ← •Import "../src/accounting/recent_transactions.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
facts ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
Ids ← {𝕊 references: {𝕩.transaction_id}¨references}
result ← recent.Build ⟨facts,10⟩
"ok" lib.AssertEq result.state
3 lib.AssertEq result.rows.count
⟨"proof-split-1","proof-food-1","proof-salary-1"⟩ lib.AssertEq Ids result.rows.transaction_reference
⟨"2026-01-12","2026-01-10","2026-01-02"⟩ lib.AssertEq result.rows.date
⟨15,20,1000⟩ lib.AssertEq result.rows.coefficient
⟨⟨"expenses:food","expenses:transport"⟩,⟨"expenses:food"⟩,⟨"assets:cash"⟩⟩ lib.AssertEq result.rows.debit_accounts
⟨⟨"assets:cash"⟩,⟨"assets:cash"⟩,⟨"income:salary"⟩⟩ lib.AssertEq result.rows.credit_accounts
"proof-split-1" lib.AssertEq (⊑result.rows.transaction_reference).transaction_id
3 lib.AssertEq ≠(⊑result.rows.debit_contributors)∾⊑result.rows.credit_contributors

limited ← recent.Build ⟨facts,2⟩
⟨"proof-split-1","proof-food-1"⟩ lib.AssertEq Ids limited.rows.transaction_reference
invalid ← recent.Build ⟨facts,0⟩
"error" lib.AssertEq invalid.state
0 lib.AssertEq invalid.rows.count
"limit_invalid" lib.AssertEq (⊑invalid.diagnostics).code

lf ← @+10
emptyAccounts ← ∾⟨
  "account assets:empty",lf,"  type: Asset",lf,"  commodity: JPY",lf,lf,
  "account expenses:empty",lf,"  type: Expense",lf,"  commodity: JPY",lf
⟩
emptyRaw ← ∾⟨
  "commodity JPY",lf,lf,
  "account assets:empty",lf,"    ; role: asset",lf,lf,
  "account expenses:empty",lf,"    ; role: expense",lf
⟩
emptyFacts ← (snapshot.Build ⟨emptyAccounts,emptyRaw,registry⟩).facts
emptyResult ← recent.Build ⟨emptyFacts,10⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.rows.count
wrongSource ← recent.Build ⟨{state⇐"ok",sources⇐{count⇐1,name⇐⟨"plan.tsv"⟩},diagnostics⇐⟨⟩},10⟩
"error" lib.AssertEq wrongSource.state
"actual_facts_invalid" lib.AssertEq (⊑wrongSource.diagnostics).code
•Out "test_accounting_recent_transactions: ok"
