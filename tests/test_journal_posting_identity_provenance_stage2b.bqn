#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
identity ← •Import "../src_next/journal_posting_identity_provenance_stage2b.bqn"
context ← •Import "../src_next/context.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

lf ← @+10
base ← "fixtures/journal-posting-ir-stage2b"
cycleStart ← "2026-09-01"

raw ← •FChars "../fixtures/journal-posting-ir-stage2b/profile.journal"
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
2 lib.AssertEq ≠ parsed.transactions
⟨<"plan", <"actual"⟩ lib.AssertEq {<𝕩.layer_name}¨ parsed.transactions
⟨2, 2⟩ lib.AssertEq {≠𝕩.postings}¨ parsed.transactions

accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
resolved.accounts lib.AssertEq {𝕩.account_key}¨ parsed.accounts

stage2a ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
"ok" lib.AssertEq stage2a.state
4 lib.AssertEq ≠ stage2a.posting_rows
rowsBefore ← stage2a.posting_rows
built ← identity.Build ⟨parsed.transactions, rowsBefore⟩
"ok" lib.AssertEq built.state
0 lib.AssertEq ≠ built.diagnostics
4 lib.AssertEq ≠ built.posting_rows
4 lib.AssertEq ≠ built.provenance_rows
rowsBefore lib.AssertEq built.posting_rows
({<𝕩.posting_id}¨ built.posting_rows) lib.AssertEq {<𝕩.posting_id}¨ built.provenance_rows

planCarrier ← 0‿1 ⊏ built.provenance_rows
actualCarrier ← 2‿3 ⊏ built.provenance_rows
lib.Assert ∧´ {𝕩.source_event_id ≡ "event-plan-service-2026-09"}¨ planCarrier
lib.Assert ∧´ {𝕩.identity_kind ≡ "durable"}¨ planCarrier
lib.Assert ∧´ {𝕩.source_id ≡ "event-plan-service-2026-09"}¨ 0‿1 ⊏ built.posting_rows
lib.Assert ∧´ {𝕩.tx_id ≡ "event-plan-service-2026-09"}¨ 0‿1 ⊏ built.posting_rows
lib.Assert ∧´ {𝕩.source_event_id ≡ (⊑ actualCarrier).source_event_id}¨ actualCarrier
lib.Assert ∧´ {𝕩.identity_kind ≡ "physical_fallback"}¨ actualCarrier
0‿1 lib.AssertEq {𝕩.posting_index}¨ planCarrier
0‿1 lib.AssertEq {𝕩.posting_index}¨ actualCarrier
lib.Assert ∧´ {𝕩.posting_id ≡ 𝕩.source_event_id ∾ ":" ∾ •Fmt 𝕩.posting_index}¨ built.provenance_rows
4 lib.AssertEq ≠ ⍷ {<𝕩.posting_id}¨ built.provenance_rows

# Reparse and rebuild identical source evidence to prove deterministic identity.
parsedAgain ← parser.Parse raw
stage2aAgain ← adapter.Build ⟨parsedAgain.transactions, resolved, cycleStart⟩
builtAgain ← identity.Build ⟨parsedAgain.transactions, stage2aAgain.posting_rows⟩
({<𝕩.source_event_id}¨ built.provenance_rows) lib.AssertEq {<𝕩.source_event_id}¨ builtAgain.provenance_rows
({<𝕩.posting_id}¨ built.provenance_rows) lib.AssertEq {<𝕩.posting_id}¨ builtAgain.provenance_rows

# Source transaction/posting order remains plan then actual and debit then credit.
⟨<"expenses:service/JPY", <"assets:cash/JPY", <"expenses:service/JPY", <"assets:cash/JPY"⟩ lib.AssertEq {<𝕩.account_key}¨ built.posting_rows
2400‿¯2400‿900‿¯900 lib.AssertEq {𝕩.delta}¨ built.posting_rows

# Project every established field: Stage 2B returns, rather than reconstructs,
# each current 16-field row.
Fields16 ← {𝕊 row: ⟨
  <row.source_file, row.source_row, <row.source_id, <row.tx_id,
  <row.posting_id, <row.date, row.day_index, <row.account_key,
  row.account_key_index, <row.layer_name, row.layer_index, <row.side,
  row.delta, <row.kind, <row.status, <row.message
⟩}
lib.Assert ∧´ {16 = ≠ Fields16 𝕩}¨ built.posting_rows
(Fields16¨ rowsBefore) lib.AssertEq Fields16¨ built.posting_rows

# Move the durable plan block below the actual in memory. Its physical span
# changes, but explicit semantic identity and deterministic posting IDs do not.
variantRaw ← ∾ ⟨
  "; In-memory movement variant", lf, lf,
  "commodity JPY", lf, lf,
  "account assets:cash", lf, "    ; role: asset", lf, lf,
  "account expenses:service", lf, "    ; role: expense", lf, lf,
  "2026-09-11 * Anonymous ordinary actual", lf,
  "    expenses:service 900 JPY", lf,
  "    assets:cash -900 JPY", lf, lf,
  "2026-09-10 ! Anonymous service plan", lf,
  "    ; event-id: event-plan-service-2026-09", lf,
  "    ; layer: plan", lf,
  "    ; plan-id: plan-service-2026-09", lf,
  "    ; execution-envelope: reserve", lf,
  "    expenses:service 2400 JPY", lf,
  "    assets:cash -2400 JPY", lf
⟩
variantParsed ← parser.Parse variantRaw
"ok" lib.AssertEq variantParsed.state
variantStage2a ← adapter.Build ⟨variantParsed.transactions, resolved, cycleStart⟩
variantBuilt ← identity.Build ⟨variantParsed.transactions, variantStage2a.posting_rows⟩
"ok" lib.AssertEq variantBuilt.state
originalPlan ← 0 ⊑ parsed.transactions
variantPlan ← ⊑ ({𝕩.layer_name ≡ "plan"}¨ variantParsed.transactions) / variantParsed.transactions
lib.Assert originalPlan.source_start_line ≠ variantPlan.source_start_line
lib.Assert originalPlan.source_end_line ≠ variantPlan.source_end_line
"event-plan-service-2026-09" lib.AssertEq variantPlan.source_event_id
({<𝕩.posting_id}¨ originalPlan.postings) lib.AssertEq {<𝕩.posting_id}¨ variantPlan.postings
variantPlanCarrier ← ({𝕩.source_event_id ≡ "event-plan-service-2026-09"}¨ variantBuilt.provenance_rows) / variantBuilt.provenance_rows
lib.Assert ∧´ {𝕩.identity_kind ≡ "durable"}¨ variantPlanCarrier
lib.Assert ∧´ {(𝕩.source_start_line = originalPlan.source_start_line) ∧ 𝕩.source_end_line = originalPlan.source_end_line}¨ planCarrier
lib.Assert ∧´ {(𝕩.source_start_line = variantPlan.source_start_line) ∧ 𝕩.source_end_line = variantPlan.source_end_line}¨ variantPlanCarrier
lib.Assert (⊑ planCarrier).source_start_line ≠ (⊑ variantPlanCarrier).source_start_line
lib.Assert (⊑ planCarrier).source_end_line ≠ (⊑ variantPlanCarrier).source_end_line
lib.Assert ∧´ {𝕩.source_event_id ≡ "event-plan-service-2026-09"}¨ variantPlanCarrier
({<𝕩.posting_id}¨ planCarrier) lib.AssertEq {<𝕩.posting_id}¨ variantPlanCarrier

# Legacy comparison stays on unchanged current 16-field rows. Labels and
# ordinals are test-only observations of each source movement.
snapshot ← {sources⇐⟨
  {source_file⇐"journal.tsv", required⇐1, lines⇐loader.ReadLines (base ∾ "/journal.tsv")},
  {source_file⇐"plan.tsv", required⇐0, lines⇐loader.ReadLines (base ∾ "/plan.tsv")},
  {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
⟩}
legacy ← context.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot, resolved, cycleStart⟩
"ok" lib.AssertEq legacy.state
4 lib.AssertEq ≠ legacy.posting_rows
lib.Assert ∧´ {16 = ≠ Fields16 𝕩}¨ legacy.posting_rows

{𝕊 sourceFile:
  movement ← ({𝕩.source_file ≡ sourceFile}¨ legacy.posting_rows) / legacy.posting_rows
  2 lib.AssertEq ≠ movement
  lib.Assert ∧´ {𝕩.source_file ≡ sourceFile}¨ movement
  lib.Assert (0 ⊑ movement).source_row = (1 ⊑ movement).source_row
  labels ← {<("legacy:" ∾ 𝕩.source_file ∾ ":" ∾ •Fmt 𝕩.source_row)}¨ movement
  lib.Assert (>0⊑labels) ≡ >1⊑labels
  2 lib.AssertEq ≠ ⍷ {<𝕩.posting_id}¨ movement
  0‿1 lib.AssertEq ↕ ≠ movement
  lib.Assert ¬ ∨´ 0 ∾ {(>⊑labels) ≡ 𝕩.posting_id}¨ built.provenance_rows
}¨ ⟨"journal.tsv", "plan.tsv"⟩

HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics}
CheckFail ← {𝕊 transactions‿postingRows‿expectedCode:
  failed ← identity.Build ⟨transactions, postingRows⟩
  "error" lib.AssertEq failed.state
  0 lib.AssertEq ≠ failed.posting_rows
  0 lib.AssertEq ≠ failed.provenance_rows
  lib.Assert 0 < ≠ failed.diagnostics
  lib.Assert HasCode ⟨expectedCode, failed⟩
}
P ← {𝕊 index‿postingId: {posting_index⇐index, posting_id⇐postingId}}
Tx ← {𝕊 eventId‿kind‿startLine‿endLine‿postings: {
  source_event_id⇐eventId, identity_kind⇐kind,
  source_start_line⇐startLine, source_end_line⇐endLine,
  txn_id⇐eventId, postings⇐postings
}}
Rows ← {𝕊 boxedIds: {{posting_id⇐>𝕩, source_id⇐"event-a", tx_id⇐"event-a"}}¨ boxedIds}

validTx ← Tx ⟨"event-a", "durable", 1, 4, ⟨P ⟨0,"event-a:0"⟩, P ⟨1,"event-a:1"⟩⟩⟩
validRows ← Rows ⟨<"event-a:0", <"event-a:1"⟩

# The Posting IR row carries the same malformed ID, so alignment still holds;
# the deterministic event-id/index encoding is the only violated invariant.
invalidPostingId ← Tx ⟨"event-a", "durable", 1, 4, ⟨P ⟨0,"event-a:not-zero"⟩, P ⟨1,"event-a:1"⟩⟩⟩
invalidPostingIdRows ← Rows ⟨<"event-a:not-zero", <"event-a:1"⟩
CheckFail ⟨⟨invalidPostingId⟩, invalidPostingIdRows, "posting_id_invalid"⟩

# Duplicate posting IDs (across events with the same event identity).
duplicateTxs ← ⟨validTx, Tx ⟨"event-a", "durable", 5, 8, ⟨P ⟨0,"event-a:0"⟩, P ⟨1,"event-a:1"⟩⟩⟩⟩
CheckFail ⟨duplicateTxs, Rows ⟨<"event-a:0", <"event-a:1", <"event-a:0", <"event-a:1"⟩, "posting_id_duplicate"⟩

nonContiguous ← Tx ⟨"event-a", "durable", 1, 4, ⟨P ⟨0,"event-a:0"⟩, P ⟨2,"event-a:2"⟩⟩⟩
CheckFail ⟨⟨nonContiguous⟩, Rows ⟨<"event-a:0", <"event-a:2"⟩, "posting_index_non_contiguous"⟩

duplicateIndex ← Tx ⟨"event-a", "durable", 1, 4, ⟨P ⟨0,"event-a:0"⟩, P ⟨0,"event-a:0"⟩⟩⟩
CheckFail ⟨⟨duplicateIndex⟩, Rows ⟨<"event-a:0", <"event-a:0"⟩, "posting_index_duplicate"⟩

emptyIdentity ← Tx ⟨"", "physical_fallback", 1, 4, ⟨P ⟨0,":0"⟩, P ⟨1,":1"⟩⟩⟩
CheckFail ⟨⟨emptyIdentity⟩, Rows ⟨<":0", <":1"⟩, "event_identity_missing"⟩

unknownKind ← Tx ⟨"event-a", "temporary", 1, 4, validTx.postings⟩
CheckFail ⟨⟨unknownKind⟩, validRows, "identity_kind_unknown"⟩

invalidSpan ← Tx ⟨"event-a", "durable", 0, ¯1, validTx.postings⟩
CheckFail ⟨⟨invalidSpan⟩, validRows, "source_span_invalid"⟩

CheckFail ⟨⟨validTx⟩, 1 ↑ validRows, "posting_count_mismatch"⟩
CheckFail ⟨⟨validTx⟩, 1‿0 ⊏ validRows, "posting_id_alignment_mismatch"⟩

•Out "test_journal_posting_identity_provenance_stage2b.bqn: OK"
