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
oneLeadingDescription ← space ∾ controlDescription
twoLeadingDescription ← space ∾ oneLeadingDescription

JournalWithHeader ← {𝕊 header:
  ∾ ⟨
    "commodity JPY", lf, lf,
    "account assets:synthetic-cash", lf,
    "    ; role: asset", lf, lf,
    "account expenses:synthetic-service", lf,
    "    ; role: expense", lf, lf,
    header, lf,
    "    ; event-id: synthetic-leading-space-event", lf,
    "    ; layer: actual", lf,
    "    expenses:synthetic-service 51 JPY", lf,
    "    assets:synthetic-cash -51 JPY", lf
  ⟩
}

# The header renderer supplies exactly one grammar delimiter. Any leading ASCII
# SPACE in description is independently owned by the payload.
JournalFor ← {𝕊 description:
  JournalWithHeader "2046-04-12 * " ∾ description
}

controlParsed ← parser.Parse JournalFor controlDescription
oneLeadingParsed ← parser.Parse JournalFor oneLeadingDescription
twoLeadingParsed ← parser.Parse JournalFor twoLeadingDescription
{𝕊 parsed:
  "ok" lib.AssertEq parsed.state
  0 lib.AssertEq ≠parsed.diagnostics
  1 lib.AssertEq ≠parsed.transactions
}¨ ⟨controlParsed,oneLeadingParsed,twoLeadingParsed⟩

controlTransaction ← ⊑controlParsed.transactions
oneLeadingTransaction ← ⊑oneLeadingParsed.transactions
twoLeadingTransaction ← ⊑twoLeadingParsed.transactions
controlDescription lib.AssertEq controlTransaction.description
oneLeadingDescription lib.AssertEq oneLeadingTransaction.description
twoLeadingDescription lib.AssertEq twoLeadingTransaction.description
lib.Assert controlTransaction.description ≢ oneLeadingTransaction.description
lib.Assert oneLeadingTransaction.description ≢ twoLeadingTransaction.description

HasCode ← {𝕊 code‿result: ∨´0∾{𝕩.code≡code}¨result.diagnostics}
missingDelimiter ← parser.Parse JournalWithHeader "2046-04-12 *Missing delimiter"
"error" lib.AssertEq missingDelimiter.state
lib.Assert HasCode ⟨"header_description_delimiter_missing",missingDelimiter⟩
lib.Assert ¬HasCode ⟨"header_description_missing",missingDelimiter⟩
emptyPayload ← parser.Parse JournalWithHeader "2046-04-12 * "
"error" lib.AssertEq emptyPayload.state
lib.Assert HasCode ⟨"header_description_missing",emptyPayload⟩
lib.Assert ¬HasCode ⟨"header_description_delimiter_missing",emptyPayload⟩

# Converter description admission now matches the parser's exact-preservation
# boundary without relaxing SafeValue for metadata or account text.
lib.Assert converter.DescriptionRepresentable oneLeadingDescription
lib.Assert converter.DescriptionRepresentable twoLeadingDescription

accountLines ← ⟨
  "assets:synthetic-cash"∾tab∾"role=asset"∾tab∾"currency=JPY",
  "expenses:synthetic-service"∾tab∾"role=expense"∾tab∾"currency=JPY"
⟩
resolved ← ak.Resolve accountLines
cycleStart ← "2046-04-01"
ConvertDescription ← {𝕊 description:
  legacySnapshot ← ∾ ⟨
    "2046-04-12",tab,description,tab,
    "assets:synthetic-cash",tab,"expenses:synthetic-service",tab,"51",lf
  ⟩
  converter.Convert ⟨legacySnapshot,"journal.tsv",accountLines,cycleStart⟩
}
oneLeadingConversion ← ConvertDescription oneLeadingDescription
twoLeadingConversion ← ConvertDescription twoLeadingDescription
{𝕊 description‿conversion:
  "ok" lib.AssertEq conversion.state
  0 lib.AssertEq ≠conversion.diagnostics
  lib.Assert 0 < +´ ("2046-04-12 * "∾description∾lf) ⍷ conversion.canonical_prefix_bytes
  description lib.AssertEq (⊑conversion.transactions).description
  1 lib.AssertEq conversion.validation_summary.parser_pass
  1 lib.AssertEq conversion.validation_summary.stage2a_pass
  1 lib.AssertEq conversion.validation_summary.stage2b_pass
  1 lib.AssertEq conversion.validation_summary.accounting_parity_pass
  1 lib.AssertEq conversion.validation_summary.identity_parity_pass
  1 lib.AssertEq conversion.validation_summary.metadata_parity_pass
}¨ ⟨⟨oneLeadingDescription,oneLeadingConversion⟩,⟨twoLeadingDescription,twoLeadingConversion⟩⟩

controlStage2 ← stage2a.Build ⟨controlParsed.transactions,resolved,cycleStart⟩
oneLeadingStage2 ← stage2a.Build ⟨oneLeadingParsed.transactions,resolved,cycleStart⟩
twoLeadingStage2 ← stage2a.Build ⟨twoLeadingParsed.transactions,resolved,cycleStart⟩
{𝕊 result:
  "ok" lib.AssertEq result.state
  0 lib.AssertEq ≠result.diagnostics
  2 lib.AssertEq ≠result.posting_rows
}¨ ⟨controlStage2,oneLeadingStage2,twoLeadingStage2⟩

# Enumerating all current fields fixes the unchanged 16-field Stage 2A shape.
PostingFields ← {𝕊 row: ⟨
  <row.source_file, <row.source_row, <row.source_id, <row.tx_id,
  <row.posting_id, <row.date, <row.day_index, <row.account_key,
  <row.account_key_index, <row.layer_name, <row.layer_index, <row.side,
  <row.delta, <row.kind, <row.status, <row.message
⟩}
16 lib.AssertEq ≠PostingFields ⊑controlStage2.posting_rows
16 lib.AssertEq ≠PostingFields ⊑oneLeadingStage2.posting_rows
16 lib.AssertEq ≠PostingFields ⊑twoLeadingStage2.posting_rows
(PostingFields¨controlStage2.posting_rows) lib.AssertEq PostingFields¨oneLeadingStage2.posting_rows
(PostingFields¨oneLeadingStage2.posting_rows) lib.AssertEq PostingFields¨twoLeadingStage2.posting_rows
⟨"expenses:synthetic-service/JPY","assets:synthetic-cash/JPY"⟩ lib.AssertEq {𝕩.account_key}¨oneLeadingStage2.posting_rows
⟨1,0⟩ lib.AssertEq {𝕩.account_key_index}¨oneLeadingStage2.posting_rows
⟨51,¯51⟩ lib.AssertEq {𝕩.delta}¨oneLeadingStage2.posting_rows
⟨"debit","credit"⟩ lib.AssertEq {𝕩.side}¨oneLeadingStage2.posting_rows

•Out "test_journal_leading_ascii_space_description_characterization.bqn: OK"
