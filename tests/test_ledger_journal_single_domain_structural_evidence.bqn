#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
single ← •Import "../src/ledger/journal_single_domain_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← {
  key⇐⟨"Assets:Cash","Expenses:Food"⟩,
  currency⇐⟨"JPY","JPY"⟩
}
prefixLines ← ⟨
  "commodity JPY",
  "",
  "account Assets:Cash",
  "",
  "account Expenses:Food",
  ""
⟩
Admit ← {𝕊 body: single.Admit ⟨Raw prefixLines∾body,accounts,registry⟩}

# Structural admission owns durable identity, Posting identity/side, and grammar
# metadata while semantic exact evidence remains attached to the same Postings.
durable ← Admit ⟨
  "2026-01-10 * durable structural evidence",
  "    ; event-id: structural-event",
  "    ; txn-id: structural-txn",
  "    ; currency: JPY",
  "  Assets:Cash  -1.20 JPY",
  "  Expenses:Food  1.20 JPY"
⟩
"ok" lib.AssertEq durable.state
0 lib.AssertEq ≠durable.diagnostics
1 lib.AssertEq ≠durable.transactions
txn ← ⊑durable.transactions
"structural-event" lib.AssertEq txn.source_event_id
"durable" lib.AssertEq txn.identity_kind
"structural-txn" lib.AssertEq txn.txn_id
"2026-01-10" lib.AssertEq txn.date
"durable structural evidence" lib.AssertEq txn.description
7 lib.AssertEq txn.source_start_line
12 lib.AssertEq txn.source_end_line
"JPY" lib.AssertEq txn.domain
1 lib.AssertEq txn.calculation_scale
3 lib.AssertEq ≠txn.metadata
⟨"structural-event:0","structural-event:1"⟩ lib.AssertEq {𝕩.posting_id}¨txn.postings
⟨0,1⟩ lib.AssertEq {𝕩.posting_index}¨txn.postings
⟨"credit","debit"⟩ lib.AssertEq {𝕩.side}¨txn.postings
⟨11,12⟩ lib.AssertEq {𝕩.source_line}¨txn.postings
⟨"-1.20","1.20"⟩ lib.AssertEq {𝕩.amount_text}¨txn.postings
⟨¯12,12⟩ lib.AssertEq {𝕩.source_coefficient}¨txn.postings
⟨1,1⟩ lib.AssertEq {𝕩.source_scale}¨txn.postings
⟨¯12,12⟩ lib.AssertEq {𝕩.normalized_coefficient}¨txn.postings

# Without durable event-id metadata, structural admission supplies the physical
# transaction-start fallback identity and derives Posting ids from it.
fallback ← Admit ⟨
  "2026-01-11 * fallback structural identity",
  "    ; currency: JPY",
  "  Assets:Cash  -2 JPY",
  "  Expenses:Food  2 JPY"
⟩
"ok" lib.AssertEq fallback.state
fallbackTxn ← ⊑fallback.transactions
"stage0-line-7" lib.AssertEq fallbackTxn.source_event_id
"physical_fallback" lib.AssertEq fallbackTxn.identity_kind
⟨"stage0-line-7:0","stage0-line-7:1"⟩ lib.AssertEq {𝕩.posting_id}¨fallbackTxn.postings
⟨9,10⟩ lib.AssertEq {𝕩.source_line}¨fallbackTxn.postings

# Currency metadata is structural metadata, but the semantic domain remains the
# authority for the transaction. A mismatch is owned by this adapter at the
# transaction start and publication remains fail closed.
mismatch ← Admit ⟨
  "2026-01-12 * mismatched currency metadata",
  "    ; currency: ILS",
  "  Assets:Cash  -3 JPY",
  "  Expenses:Food  3 JPY"
⟩
"error" lib.AssertEq mismatch.state
⟨"transaction_currency_mismatch"⟩ lib.AssertEq {𝕩.code}¨mismatch.diagnostics
⟨7⟩ lib.AssertEq {𝕩.line}¨mismatch.diagnostics
0 lib.AssertEq ≠mismatch.transactions

•Out "test_ledger_journal_single_domain_structural_evidence: ok"
