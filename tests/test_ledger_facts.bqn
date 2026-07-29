#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
facts ← •Import "../src/ledger/facts.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
transaction_rows ← •Import "../src/ledger/transaction_rows.bqn"
amount_text ← •Import "../src/ledger/amount_text.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
accountLines ← loader.ReadLines base∾"accounts.tsv"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
strictAccounts ← account_admission.Admit ⟨accountLines,registry⟩
rawJournal ← •FChars "../"∾base∾"actual.journal"
admitted ← admission.Admit ⟨rawJournal,strictAccounts.accounts,registry⟩
admittedAccounts ← strictAccounts.accounts
result ← facts.Project ⟨admitted,admittedAccounts⟩

"ok" lib.AssertEq strictAccounts.state
"ok" lib.AssertEq admitted.state
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
⟨"actual.journal"⟩ lib.AssertEq result.sources.name
⟨0,0,0⟩ lib.AssertEq result.transactions.source_index
⟨0,0,0,0,0,0,0⟩ lib.AssertEq result.postings.source_index
canonicalSnapshot ← snapshot.Build ⟨accountLines,rawJournal,registry⟩
"ok" lib.AssertEq canonicalSnapshot.state
0 lib.AssertEq ≠canonicalSnapshot.diagnostics
result.transactions.transaction_id lib.AssertEq canonicalSnapshot.facts.transactions.transaction_id
result.postings.posting_id lib.AssertEq canonicalSnapshot.facts.postings.posting_id
result.postings.coefficient lib.AssertEq canonicalSnapshot.facts.postings.coefficient
transactionView ← transaction_rows.Build canonicalSnapshot.facts
"ok" lib.AssertEq transactionView.state
3 lib.AssertEq ≠transactionView.rows
splitView ← 2⊑transactionView.rows
"proof-split-1" lib.AssertEq splitView.transaction_id
"split purchase" lib.AssertEq splitView.description
"actual" lib.AssertEq splitView.layer
"JPY" lib.AssertEq splitView.domain
⟨"expenses:food","expenses:transport","assets:cash"⟩ lib.AssertEq {𝕩.account_key}¨splitView.postings
⟨10,5,¯15⟩ lib.AssertEq {𝕩.source_coefficient}¨splitView.postings
⟨"debit","debit","credit"⟩ lib.AssertEq {𝕩.side}¨splitView.postings
invalidAccountSnapshot ← snapshot.Build ⟨⟨"assets:cash"∾(@+9)∾"role=asset"⟩,rawJournal,registry⟩
"error" lib.AssertEq invalidAccountSnapshot.state
0 lib.AssertEq invalidAccountSnapshot.facts.transactions.count
0 lib.AssertEq invalidAccountSnapshot.facts.postings.count
lib.Assert ∨´{𝕩.code≡"account_currency_missing"}¨invalidAccountSnapshot.diagnostics
⟨"JPY"⟩ lib.AssertEq result.domains.code
⟨"actual"⟩ lib.AssertEq result.layers.name
8 lib.AssertEq result.accounts.count
strictAccounts.accounts.key lib.AssertEq result.accounts.key
strictAccounts.accounts.currency lib.AssertEq result.accounts.currency
strictAccounts.accounts.role lib.AssertEq result.accounts.role
strictAccounts.accounts.type lib.AssertEq result.accounts.type
strictAccounts.accounts.metadata lib.AssertEq result.accounts.metadata
strictAccounts.accounts.source_row lib.AssertEq result.accounts.source_row

3 lib.AssertEq result.transactions.count
⟨0,1,2⟩ lib.AssertEq result.transactions.index
⟨"proof-salary-1","proof-food-1","proof-split-1"⟩ lib.AssertEq result.transactions.transaction_id
⟨"durable","durable","durable"⟩ lib.AssertEq result.transactions.identity_kind
⟨27,34,42⟩ lib.AssertEq result.transactions.source_start_line
⟨32,40,48⟩ lib.AssertEq result.transactions.source_end_line
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.transactions.date_text
"***" lib.AssertEq result.transactions.status_marker
⟨"event-id","layer","currency"⟩ lib.AssertEq {𝕩.key}¨0⊑result.transactions.metadata
⟨0,0,0⟩ lib.AssertEq result.transactions.layer_index
⟨0,0,0⟩ lib.AssertEq result.transactions.domain_index
⟨0,0,0⟩ lib.AssertEq result.transactions.calculation_scale
⟨"","plan-food-2026-01",""⟩ lib.AssertEq result.transactions.plan_id
8 lib.AssertEq (1⊑result.transactions.date_ordinal) - 0⊑result.transactions.date_ordinal
2 lib.AssertEq (2⊑result.transactions.date_ordinal) - 1⊑result.transactions.date_ordinal

7 lib.AssertEq result.postings.count
⟨0,1,2,3,4,5,6⟩ lib.AssertEq result.postings.index
⟨0,0,1,1,2,2,2⟩ lib.AssertEq result.postings.transaction_index
⟨0,1,0,1,0,1,2⟩ lib.AssertEq result.postings.transaction_posting_index
⟨0,1,2,0,2,3,0⟩ lib.AssertEq result.postings.account_index
⟨0,0,0,0,0,0,0⟩ lib.AssertEq result.postings.layer_index
⟨0,0,0,0,0,0,0⟩ lib.AssertEq result.postings.domain_index
⟨1000,¯1000,20,¯20,10,5,¯15⟩ lib.AssertEq result.postings.coefficient
⟨0,0,0,0,0,0,0⟩ lib.AssertEq result.postings.scale
⟨"debit","credit","debit","credit","debit","debit","credit"⟩ lib.AssertEq result.postings.side
⟨31,32,39,40,46,47,48⟩ lib.AssertEq result.postings.source_line
⟨"proof-salary-1:0","proof-salary-1:1","proof-food-1:0","proof-food-1:1","proof-split-1:0","proof-split-1:1","proof-split-1:2"⟩ lib.AssertEq result.postings.posting_id

{result.transactions.count lib.AssertEq ≠𝕩}¨ ⟨
  result.transactions.index,result.transactions.source_index,result.transactions.transaction_id,result.transactions.identity_kind,
  result.transactions.source_start_line,result.transactions.source_end_line,result.transactions.date_text,
  result.transactions.date_ordinal,result.transactions.description,result.transactions.status_marker,
  result.transactions.metadata,result.transactions.layer_index,
  result.transactions.domain_index,result.transactions.calculation_scale,result.transactions.txn_id,
  result.transactions.plan_id,result.transactions.allocation_id,result.transactions.execution_envelope,
  result.transactions.actual_event_id
⟩
{result.postings.count lib.AssertEq ≠𝕩}¨ ⟨
  result.postings.index,result.postings.source_index,result.postings.posting_id,result.postings.transaction_index,
  result.postings.transaction_posting_index,result.postings.date_ordinal,result.postings.account_index,
  result.postings.layer_index,result.postings.domain_index,result.postings.coefficient,result.postings.scale,
  result.postings.side,result.postings.source_line,result.postings.source_coefficient,
  result.postings.source_scale,result.postings.amount_text
⟩

{𝕊 ti:
  selected ← (ti=result.postings.transaction_index)/result.postings.coefficient
  0 lib.AssertEq +´selected
}¨ ↕result.transactions.count

"0" lib.AssertEq amount_text.Format ⟨0,0⟩
"12.34" lib.AssertEq amount_text.Format ⟨1234,2⟩
"-0.05" lib.AssertEq amount_text.Format ⟨¯5,2⟩
lib.Assert dates.IsValid "2000-02-29"
lib.Assert ¬dates.IsValid "1900-02-29"
lib.Assert ¬dates.IsValid "2026-02-30"
1 lib.AssertEq (dates.Ordinal "2026-01-02") - dates.Ordinal "2026-01-01"

emptyAccountTable ← {
  key⇐⟨⟩,currency⇐⟨⟩,role⇐⟨⟩,type⇐⟨⟩,budget⇐⟨⟩,budget_group⇐⟨⟩,
  spend_class⇐⟨⟩,kind⇐⟨⟩,envelope_role⇐⟨⟩,metadata⇐⟨⟩,source_row⇐⟨⟩
}
errorResult ← facts.Project ⟨{state⇐"error"},emptyAccountTable⟩
"error" lib.AssertEq errorResult.state
1 lib.AssertEq ≠errorResult.diagnostics
"admission_not_ok" lib.AssertEq (⊑errorResult.diagnostics).code
0 lib.AssertEq errorResult.transactions.count
0 lib.AssertEq errorResult.postings.count

misalignedAccounts ← {
  key⇐admittedAccounts.key,currency⇐⟨⟩,role⇐admittedAccounts.role,type⇐admittedAccounts.type,
  budget⇐admittedAccounts.budget,budget_group⇐admittedAccounts.budget_group,
  spend_class⇐admittedAccounts.spend_class,kind⇐admittedAccounts.kind,
  envelope_role⇐admittedAccounts.envelope_role,metadata⇐admittedAccounts.metadata,
  source_row⇐admittedAccounts.source_row
}
misaligned ← facts.Project ⟨admitted,misalignedAccounts⟩
"error" lib.AssertEq misaligned.state
lib.Assert ∨´ {𝕩.code ≡ "account_columns_misaligned"}¨ misaligned.diagnostics
0 lib.AssertEq misaligned.transactions.count
0 lib.AssertEq misaligned.postings.count

lf ← @+10
currencyMismatchRaw ← ∾⟨
  "commodity JPY"∾lf,""∾lf,
  "account assets:cash"∾lf,""∾lf,
  "account expenses:food"∾lf,""∾lf,
  "2026-01-15 * currency mismatch"∾lf,
  "    ; currency: USD"∾lf,
  "    expenses:food 1 JPY"∾lf,
  "    assets:cash -1 JPY"∾lf
⟩
currencyMismatch ← admission.Admit ⟨currencyMismatchRaw,strictAccounts.accounts,registry⟩
"error" lib.AssertEq currencyMismatch.state
lib.Assert ∨´{𝕩.code≡"transaction_currency_mismatch"}¨currencyMismatch.diagnostics
0 lib.AssertEq ≠currencyMismatch.transactions
invalidJournalSnapshot ← snapshot.Build ⟨accountLines,currencyMismatchRaw,registry⟩
"error" lib.AssertEq invalidJournalSnapshot.state
0 lib.AssertEq invalidJournalSnapshot.facts.transactions.count
0 lib.AssertEq invalidJournalSnapshot.facts.postings.count
lib.Assert ∨´{𝕩.code≡"transaction_currency_mismatch"}¨invalidJournalSnapshot.diagnostics

emptyRaw ← ∾ ⟨"commodity JPY"∾lf,""∾lf,"account assets:cash"∾lf⟩
emptyAdmitted ← admission.Admit ⟨emptyRaw,strictAccounts.accounts,registry⟩
emptyResult ← facts.Project ⟨emptyAdmitted,admittedAccounts⟩
"ok" lib.AssertEq emptyResult.state
⟨"JPY"⟩ lib.AssertEq emptyResult.domains.code
0 lib.AssertEq emptyResult.transactions.count
0 lib.AssertEq emptyResult.postings.count
⟨"actual"⟩ lib.AssertEq emptyResult.layers.name

•Out "test_ledger_facts: ok"
