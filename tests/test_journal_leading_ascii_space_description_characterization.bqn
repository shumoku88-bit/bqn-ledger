#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
stage2a ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
converter ← •Import "../src_next/journal_canonical_prefix_converter.bqn"
ak ← •Import "../src_next/account_key.bqn"

lf ← @+10
space ← @+32
tab ← @+9
controlDescription ← "Synthetic description"
targetDescription ← space ∾ controlDescription

# The header renderer supplies exactly one grammar separator. The target payload
# independently owns one additional leading ASCII SPACE.
JournalFor ← {𝕊 description:
  ∾ ⟨
    "commodity JPY", lf, lf,
    "account assets:synthetic-cash", lf,
    "    ; role: asset", lf, lf,
    "account expenses:synthetic-service", lf,
    "    ; role: expense", lf, lf,
    "2046-04-12 * ", description, lf,
    "    ; event-id: synthetic-leading-space-event", lf,
    "    ; layer: actual", lf,
    "    expenses:synthetic-service 51 JPY", lf,
    "    assets:synthetic-cash -51 JPY", lf
  ⟩
}

controlSource ← JournalFor controlDescription
targetSource ← JournalFor targetDescription
lib.Assert controlDescription ≢ targetDescription

controlParsed ← parser.Parse controlSource
targetParsed ← parser.Parse targetSource
"ok" lib.AssertEq controlParsed.state
"ok" lib.AssertEq targetParsed.state
0 lib.AssertEq ≠controlParsed.diagnostics
0 lib.AssertEq ≠targetParsed.diagnostics
1 lib.AssertEq ≠controlParsed.transactions
1 lib.AssertEq ≠targetParsed.transactions

controlTransaction ← ⊑controlParsed.transactions
targetTransaction ← ⊑targetParsed.transactions
controlDescription lib.AssertEq controlTransaction.description

# Characterization only: this does not approve silent normalization as the
# desired contract. A future exact-preservation parser slice must intentionally
# update this expectation.
controlDescription lib.AssertEq targetTransaction.description
controlTransaction.description lib.AssertEq targetTransaction.description
lib.Assert targetDescription ≢ targetTransaction.description

# The converter remains fail closed until a parser contract can preserve or
# explicitly reject the payload without information loss.
lib.Assert ¬converter.DescriptionRepresentable targetDescription

accountLines ← ⟨
  "assets:synthetic-cash"∾tab∾"role=asset"∾tab∾"currency=JPY",
  "expenses:synthetic-service"∾tab∾"role=expense"∾tab∾"currency=JPY"
⟩
resolved ← ak.Resolve accountLines
cycleStart ← "2046-04-01"
controlStage2 ← stage2a.Build ⟨controlParsed.transactions,resolved,cycleStart⟩
targetStage2 ← stage2a.Build ⟨targetParsed.transactions,resolved,cycleStart⟩
"ok" lib.AssertEq controlStage2.state
"ok" lib.AssertEq targetStage2.state
0 lib.AssertEq ≠controlStage2.diagnostics
0 lib.AssertEq ≠targetStage2.diagnostics
2 lib.AssertEq ≠controlStage2.posting_rows
2 lib.AssertEq ≠targetStage2.posting_rows

# Enumerating all current fields both fixes the 16-field shape and demonstrates
# that Stage 2A owns no description field from which the source distinction
# could be recovered.
PostingFields ← {𝕊 row: ⟨
  <row.source_file, <row.source_row, <row.source_id, <row.tx_id,
  <row.posting_id, <row.date, <row.day_index, <row.account_key,
  <row.account_key_index, <row.layer_name, <row.layer_index, <row.side,
  <row.delta, <row.kind, <row.status, <row.message
⟩}
16 lib.AssertEq ≠PostingFields ⊑controlStage2.posting_rows
16 lib.AssertEq ≠PostingFields ⊑targetStage2.posting_rows
(PostingFields¨controlStage2.posting_rows) lib.AssertEq PostingFields¨targetStage2.posting_rows
⟨"expenses:synthetic-service/JPY","assets:synthetic-cash/JPY"⟩ lib.AssertEq {𝕩.account_key}¨targetStage2.posting_rows
⟨1,0⟩ lib.AssertEq {𝕩.account_key_index}¨targetStage2.posting_rows
⟨51,¯51⟩ lib.AssertEq {𝕩.delta}¨targetStage2.posting_rows
⟨"debit","credit"⟩ lib.AssertEq {𝕩.side}¨targetStage2.posting_rows

•Out "test_journal_leading_ascii_space_description_characterization.bqn: OK"
