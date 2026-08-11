#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
single ← •Import "../src/ledger/journal_single_domain_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← {
  key⇐⟨"Assets:Cash","Expenses:Food"⟩,
  currency⇐⟨"JPY","JPY"⟩
}

# One single-domain partition has one successful transaction. Metadata/blank
# rows do not consume Posting coordinates; final durable Postings retain the
# physical source rows and transaction-local Posting order.
source ← Raw ⟨
  "commodity JPY",
  "",
  "account Assets:Cash",
  "",
  "account Expenses:Food",
  "",
  "2026-01-01 * one partition",
  "    ; event-id: one-event",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food  100 JPY"
⟩
result ← single.Admit ⟨source,accounts,registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
1 lib.AssertEq ≠result.transactions
transaction ← ⊑result.transactions
⟨0,1⟩ lib.AssertEq {𝕩.posting_index}¨transaction.postings
⟨9,10⟩ lib.AssertEq {𝕩.source_line}¨transaction.postings
⟨"Assets:Cash","Expenses:Food"⟩ lib.AssertEq {𝕩.account_key}¨transaction.postings

# Direct multi-transaction use is outside the successful single-partition
# contract and remains rejected by structural admission. No partial Transaction
# is published from the failing helper result.
multi ← single.Admit ⟨Raw ⟨
  "commodity JPY",
  "",
  "account Assets:Cash",
  "",
  "account Expenses:Food",
  "",
  "2026-01-01 * first",
  "  Assets:Cash  -100 JPY",
  "  Expenses:Food  100 JPY",
  "",
  "2026-01-02 * second",
  "    ; event-id: second-event",
  "  Expenses:Food  50 JPY",
  "  Assets:Cash  -50 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq multi.state
lib.Assert HasCode ⟨"transaction_count_invalid",multi.diagnostics⟩
0 lib.AssertEq ≠multi.transactions

# A Posting before the first dated transaction is row-local admission failure.
# Later valid rows cannot publish a partial Transaction, and the physical source
# row owns the diagnostic.
outside ← single.Admit ⟨Raw ⟨
  "commodity JPY",
  "",
  "account Assets:Cash",
  "",
  "account Expenses:Food",
  "",
  "  Assets:Cash  5 JPY",
  "2026-01-01 * valid later",
  "  Assets:Cash  -5 JPY",
  "  Expenses:Food  5 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq outside.state
⟨"posting_outside_transaction"⟩ lib.AssertEq {𝕩.code}¨outside.diagnostics
⟨7⟩ lib.AssertEq {𝕩.line}¨outside.diagnostics
0 lib.AssertEq ≠outside.transactions

•Out "test_ledger_journal_single_domain_collect_coordinates: ok"
