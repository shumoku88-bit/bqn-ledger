#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
journalAdmission ← •Import "../src/ledger/journal_complete_admission.bqn"
facts ← •Import "../src/ledger/facts.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾ lines ∾¨ lf }
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics }

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountResult ← accountAdmission.Admit Raw ⟨
  "account Assets:Cash",
  "  type: Asset",
  "",
  "account Expenses:Food",
  "  type: Expense",
  "  commodity: JPY"
⟩
"ok" lib.AssertEq accountResult.state

canonicalRaw ← Raw ⟨
  "include accounts.journal",
  "",
  "2026-08-08 * canonical elision",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food"
⟩
admitted ← journalAdmission.Admit ⟨canonicalRaw,accountResult.accounts,registry⟩
"ok" lib.AssertEq admitted.state
0 lib.AssertEq ≠admitted.diagnostics
1 lib.AssertEq ≠admitted.transactions
transaction ← ⊑admitted.transactions
"JPY" lib.AssertEq transaction.domain
2 lib.AssertEq ≠transaction.postings
⟨-100,100⟩ lib.AssertEq {𝕩.normalized_coefficient}¨transaction.postings
⟨"-100",""⟩ lib.AssertEq {𝕩.amount_text}¨transaction.postings
⟨4,5⟩ lib.AssertEq {𝕩.source_line}¨transaction.postings

projected ← facts.Project ⟨admitted,accountResult.accounts⟩
"ok" lib.AssertEq projected.state
2 lib.AssertEq projected.postings.count

missingCommodity ← journalAdmission.Admit ⟨Raw ⟨
  "2026-08-08 * explicit amount without commodity",
  "  Assets:Cash  -100",
  "  Expenses:Food  100 JPY"
⟩,accountResult.accounts,registry⟩
"error" lib.AssertEq missingCommodity.state
lib.Assert HasCode ⟨"posting_shape_invalid",missingCommodity.diagnostics⟩

twoElided ← journalAdmission.Admit ⟨Raw ⟨
  "2026-08-08 * too many omissions",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food",
  "  Assets:Cash"
⟩,accountResult.accounts,registry⟩
"error" lib.AssertEq twoElided.state
lib.Assert HasCode ⟨"posting_elided_multiple",twoElided.diagnostics⟩

•Out "test_ledger_canonical_actual_admission: ok"
