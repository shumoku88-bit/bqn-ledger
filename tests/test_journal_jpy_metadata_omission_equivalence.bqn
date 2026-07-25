#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-jpy-metadata-omission"
withRaw ← •FChars ("../" ∾ base ∾ "/with-currency.journal")
withoutRaw ← •FChars ("../" ∾ base ∾ "/without-currency.journal")

withParsed ← parser.ParseWithProfile ⟨withRaw, "historical_external_plan"⟩
withoutParsed ← parser.ParseWithProfile ⟨withoutRaw, "historical_external_plan"⟩

"ok" lib.AssertEq withParsed.state
"ok" lib.AssertEq withoutParsed.state
0 lib.AssertEq ≠ withParsed.diagnostics
0 lib.AssertEq ≠ withoutParsed.diagnostics
1 lib.AssertEq ≠ withParsed.transactions
1 lib.AssertEq ≠ withoutParsed.transactions

withTx ← ⊑ withParsed.transactions
withoutTx ← ⊑ withoutParsed.transactions

⟨"event-id", "plan-id", "currency"⟩ lib.AssertEq {𝕩.key}¨ withTx.metadata
⟨"event-id", "plan-id"⟩ lib.AssertEq {𝕩.key}¨ withoutTx.metadata

withTx.source_event_id lib.AssertEq withoutTx.source_event_id
"completion-plan-example-2026-07-23" lib.AssertEq withTx.source_event_id
withTx.identity_kind lib.AssertEq withoutTx.identity_kind
"durable" lib.AssertEq withTx.identity_kind
withTx.date lib.AssertEq withoutTx.date
withTx.status_marker lib.AssertEq withoutTx.status_marker
withTx.description lib.AssertEq withoutTx.description
withTx.layer_name lib.AssertEq withoutTx.layer_name
withTx.txn_id lib.AssertEq withoutTx.txn_id
withTx.plan_id lib.AssertEq withoutTx.plan_id
"plan-example" lib.AssertEq withTx.plan_id
withTx.allocation_id lib.AssertEq withoutTx.allocation_id
withTx.execution_envelope lib.AssertEq withoutTx.execution_envelope
withTx.actual_event_id lib.AssertEq withoutTx.actual_event_id

PostingCarrier ← {𝕊 postings:
  ⟨
    {𝕩.posting_id}¨ postings,
    {𝕩.posting_index}¨ postings,
    {𝕩.side}¨ postings,
    {𝕩.account_key}¨ postings,
    {𝕩.delta}¨ postings,
    {𝕩.commodity}¨ postings,
    {𝕩.amount_text}¨ postings
  ⟩
}
(PostingCarrier withTx.postings) lib.AssertEq PostingCarrier withoutTx.postings

resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
withStage2a ← adapter.Build ⟨withParsed.transactions, resolved, "2026-07-01"⟩
withoutStage2a ← adapter.Build ⟨withoutParsed.transactions, resolved, "2026-07-01"⟩

"ok" lib.AssertEq withStage2a.state
"ok" lib.AssertEq withoutStage2a.state
0 lib.AssertEq ≠ withStage2a.diagnostics
0 lib.AssertEq ≠ withoutStage2a.diagnostics

PostingFields ← {𝕊 row: ⟨
  <row.source_file, <row.source_row, <row.source_id, <row.tx_id,
  <row.posting_id, <row.date, <row.day_index, <row.account_key,
  <row.account_key_index, <row.layer_name, <row.layer_index, <row.side,
  <row.delta, <row.kind, <row.status, <row.message
⟩}
(PostingFields¨ withStage2a.posting_rows) lib.AssertEq PostingFields¨ withoutStage2a.posting_rows

•Out "test_journal_jpy_metadata_omission_equivalence.bqn: OK"
