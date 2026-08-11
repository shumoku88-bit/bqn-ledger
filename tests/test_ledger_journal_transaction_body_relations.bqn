#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
structure ← •Import "../src/ledger/journal_transaction_structure.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}

# Body rows are observed in physical source order. Row-local parse diagnostics
# come first; Account relation diagnostics are published after body parsing.
mixedInvalid ← structure.Parse Raw ⟨
  "commodity JPY",
  "",
  "account assets:cash",
  "",
  "account expenses:food",
  "",
  "2026-01-10 * mixed invalid body",
  "    ; broken metadata",
  "not indented",
  "    onlyaccount",
  "    unknown:account 5 JPY",
  "    assets:cash -5 JPY"
⟩
"error" lib.AssertEq mixedInvalid.state
⟨
  "metadata_colon_missing",
  "transaction_body_not_indented",
  "posting_shape_invalid",
  "posting_account_unknown"
⟩ lib.AssertEq {𝕩.code}¨mixedInvalid.diagnostics
⟨8,9,10,11⟩ lib.AssertEq {𝕩.line}¨mixedInvalid.diagnostics
0 lib.AssertEq ≠mixedInvalid.transactions

# Metadata and Posting cells keep their own source order even when interleaved.
# The two axes are published independently in the final Transaction.
interleaved ← structure.Parse Raw ⟨
  "commodity JPY",
  "",
  "account assets:cash",
  "",
  "account expenses:food",
  "",
  "2026-01-11 * interleaved body",
  "    ; note: before",
  "    expenses:food 5 JPY",
  "    ; event-id: interleaved-event",
  "    assets:cash -5 JPY"
⟩
"ok" lib.AssertEq interleaved.state
0 lib.AssertEq ≠interleaved.diagnostics
1 lib.AssertEq ≠interleaved.transactions
txn ← ⊑interleaved.transactions
⟨"note","event-id"⟩ lib.AssertEq {𝕩.key}¨txn.metadata
⟨8,10⟩ lib.AssertEq {𝕩.source_line}¨txn.metadata
⟨"expenses:food","assets:cash"⟩ lib.AssertEq {𝕩.account_key}¨txn.postings
⟨9,11⟩ lib.AssertEq {𝕩.source_line}¨txn.postings
⟨0,1⟩ lib.AssertEq {𝕩.posting_index}¨txn.postings
⟨"interleaved-event:0","interleaved-event:1"⟩ lib.AssertEq {𝕩.posting_id}¨txn.postings

# Duplicate metadata is an aggregate transaction diagnostic after row-local
# metadata admission; its coordinate is the transaction start.
duplicate ← structure.Parse Raw ⟨
  "commodity JPY",
  "",
  "account assets:cash",
  "",
  "account expenses:food",
  "",
  "2026-01-12 * duplicate relation",
  "    ; event-id: first",
  "    expenses:food 5 JPY",
  "    ; event-id: second",
  "    assets:cash -5 JPY"
⟩
"error" lib.AssertEq duplicate.state
⟨"metadata_duplicate"⟩ lib.AssertEq {𝕩.code}¨duplicate.diagnostics
⟨7⟩ lib.AssertEq {𝕩.line}¨duplicate.diagnostics
0 lib.AssertEq ≠duplicate.transactions

•Out "test_ledger_journal_transaction_body_relations: ok"
