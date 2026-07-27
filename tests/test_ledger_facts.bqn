#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
account_key ← •Import "../src_next/account_key.bqn"
admission ← •Import "../src_next/journal_complete_source_admission.bqn"
loader ← •Import "../src_next/loader.bqn"
facts ← •Import "../src/ledger/facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
resolved ← account_key.Resolve loader.ReadLines base∾"accounts.tsv"
admitted ← admission.Admit ⟨•FChars "../"∾base∾"actual.journal", resolved⟩
admittedAccounts ← {key⇐resolved.accounts,currency⇐resolved.currencies,role⇐resolved.roles}
result ← facts.Project ⟨admitted,admittedAccounts⟩

"ok" lib.AssertEq admitted.state
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
⟨"JPY"⟩ lib.AssertEq result.domains.code
⟨"actual"⟩ lib.AssertEq result.layers.name
8 lib.AssertEq result.accounts.count
resolved.accounts lib.AssertEq result.accounts.key
resolved.currencies lib.AssertEq result.accounts.currency
resolved.roles lib.AssertEq result.accounts.role

3 lib.AssertEq result.transactions.count
⟨0,1,2⟩ lib.AssertEq result.transactions.index
⟨"proof-salary-1","proof-food-1","proof-split-1"⟩ lib.AssertEq result.transactions.transaction_id
⟨"durable","durable","durable"⟩ lib.AssertEq result.transactions.identity_kind
⟨27,34,42⟩ lib.AssertEq result.transactions.source_start_line
⟨32,40,48⟩ lib.AssertEq result.transactions.source_end_line
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.transactions.date_text
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
  result.transactions.index,result.transactions.transaction_id,result.transactions.identity_kind,
  result.transactions.source_start_line,result.transactions.source_end_line,result.transactions.date_text,
  result.transactions.date_ordinal,result.transactions.description,result.transactions.layer_index,
  result.transactions.domain_index,result.transactions.calculation_scale,result.transactions.txn_id,
  result.transactions.plan_id,result.transactions.allocation_id,result.transactions.execution_envelope,
  result.transactions.actual_event_id
⟩
{result.postings.count lib.AssertEq ≠𝕩}¨ ⟨
  result.postings.index,result.postings.posting_id,result.postings.transaction_index,
  result.postings.transaction_posting_index,result.postings.date_ordinal,result.postings.account_index,
  result.postings.layer_index,result.postings.domain_index,result.postings.coefficient,result.postings.scale,
  result.postings.side,result.postings.source_line,result.postings.source_coefficient,
  result.postings.source_scale,result.postings.amount_text
⟩

{𝕊 ti:
  selected ← (ti=result.postings.transaction_index)/result.postings.coefficient
  0 lib.AssertEq +´selected
}¨ ↕result.transactions.count

lib.Assert dates.IsValid "2000-02-29"
lib.Assert ¬dates.IsValid "1900-02-29"
lib.Assert ¬dates.IsValid "2026-02-30"
1 lib.AssertEq (dates.Ordinal "2026-01-02") - dates.Ordinal "2026-01-01"

errorResult ← facts.Project ⟨{state⇐"error"},{key⇐⟨⟩,currency⇐⟨⟩,role⇐⟨⟩}⟩
"error" lib.AssertEq errorResult.state
1 lib.AssertEq ≠errorResult.diagnostics
"admission_not_ok" lib.AssertEq (⊑errorResult.diagnostics).code
0 lib.AssertEq errorResult.transactions.count
0 lib.AssertEq errorResult.postings.count

misaligned ← facts.Project ⟨admitted,{key⇐resolved.accounts,currency⇐⟨⟩,role⇐resolved.roles}⟩
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
currencyMismatch ← admission.Admit ⟨currencyMismatchRaw,resolved⟩
"error" lib.AssertEq currencyMismatch.state
lib.Assert ∨´{𝕩.code≡"transaction_currency_mismatch"}¨currencyMismatch.diagnostics
0 lib.AssertEq ≠currencyMismatch.transactions

emptyRaw ← ∾ ⟨"commodity JPY"∾lf,""∾lf,"account assets:cash"∾lf⟩
emptyAdmitted ← admission.Admit ⟨emptyRaw,resolved⟩
emptyResult ← facts.Project ⟨emptyAdmitted,admittedAccounts⟩
"ok" lib.AssertEq emptyResult.state
⟨"JPY"⟩ lib.AssertEq emptyResult.domains.code
0 lib.AssertEq emptyResult.transactions.count
0 lib.AssertEq emptyResult.postings.count

•Out "test_ledger_facts: ok"
