#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
transactionRows ← •Import "../src/ledger/transaction_rows.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountRaw ← Raw ⟨
  "account Assets:Cash","  type: Asset","  commodity: JPY","",
  "account Expenses:Food","  type: Expense","  commodity: JPY","",
  "account Expenses:Books","  type: Expense","  commodity: JPY","",
  "account Income:Salary","  type: Income","  commodity: JPY"
⟩
accountResult ← accountsAdmission.Admit accountRaw
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts

journalRaw ← Raw ⟨
  "2026-08-12 Split purchase",
  "  ; event-id: rows-split",
  "  Expenses:Food 60 JPY",
  "  Expenses:Books 40 JPY",
  "  Assets:Cash -100 JPY","",
  "2026-08-13 Salary",
  "  ; event-id: rows-salary",
  "  Assets:Cash 1000 JPY",
  "  Income:Salary -1000 JPY"
⟩
built ← snapshot.BuildFromAccounts ⟨accounts,journalRaw,registry⟩
"ok" lib.AssertEq built.state
view ← transactionRows.Build built.facts
"ok" lib.AssertEq view.state
0 lib.AssertEq ≠view.diagnostics
2 lib.AssertEq ≠view.rows

# Transaction rows remain in canonical Facts transaction order.
⟨0,1⟩ lib.AssertEq {𝕩.transaction_index}¨view.rows
⟨"rows-split","rows-salary"⟩ lib.AssertEq {𝕩.transaction_id}¨view.rows
⟨"2026-08-12","2026-08-13"⟩ lib.AssertEq {𝕩.date_text}¨view.rows

# Multi-Posting Transactions remain intact. Posting cells preserve the canonical
# global Posting axis while transaction_posting_index preserves local order.
split ← 0⊑view.rows
salary ← 1⊑view.rows
3 lib.AssertEq ≠split.postings
2 lib.AssertEq ≠salary.postings
⟨0,1,2⟩ lib.AssertEq {𝕩.posting_index}¨split.postings
⟨3,4⟩ lib.AssertEq {𝕩.posting_index}¨salary.postings
⟨0,1,2⟩ lib.AssertEq {𝕩.transaction_posting_index}¨split.postings
⟨0,1⟩ lib.AssertEq {𝕩.transaction_posting_index}¨salary.postings
⟨"Expenses:Food","Expenses:Books","Assets:Cash"⟩ lib.AssertEq {𝕩.account_key}¨split.postings
⟨60,40,¯100⟩ lib.AssertEq {𝕩.coefficient}¨split.postings
⟨"Assets:Cash","Income:Salary"⟩ lib.AssertEq {𝕩.account_key}¨salary.postings
⟨1000,¯1000⟩ lib.AssertEq {𝕩.coefficient}¨salary.postings
⟨"rows-split:0","rows-split:1","rows-split:2"⟩ lib.AssertEq {𝕩.posting_id}¨split.postings

# Rejected Facts remain fail-closed and carry their diagnostics unchanged.
proofDiagnostic ← {severity⇐"error",stage⇐"proof",code⇐"facts_rejected",message⇐"proof"}
rejected ← transactionRows.Build {state⇐"error",diagnostics⇐⟨proofDiagnostic⟩}
"error" lib.AssertEq rejected.state
0 lib.AssertEq ≠rejected.rows
⟨"facts_rejected"⟩ lib.AssertEq {𝕩.code}¨rejected.diagnostics

•Out "test_ledger_transaction_rows_relations: ok"
