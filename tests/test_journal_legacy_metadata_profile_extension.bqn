#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
identity ← •Import "../src_next/journal_posting_identity_provenance_stage2b.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

raw ← •FChars "../fixtures/journal-legacy-metadata-profile/profile.journal"
parsed ← parser.Parse raw
"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
3 lib.AssertEq ≠ parsed.transactions
⟨2, 2, 2⟩ lib.AssertEq {≠𝕩.postings}¨ parsed.transactions

first ← 0 ⊑ parsed.transactions
second ← 1 ⊑ parsed.transactions
third ← 2 ⊑ parsed.transactions
lib.Assert 0 < ≠ first.source_event_id
lib.Assert 0 < ≠ second.source_event_id
lib.Assert first.source_event_id ≢ second.source_event_id
"durable" lib.AssertEq first.identity_kind
"durable" lib.AssertEq second.identity_kind
"physical_fallback" lib.AssertEq third.identity_kind
"demo-business-bundle-7" lib.AssertEq first.txn_id
"demo-business-bundle-7" lib.AssertEq second.txn_id
"" lib.AssertEq third.txn_id

metadataKeys ← {<𝕩.key}¨ first.metadata
expectedKeys ← ⟨<"event-id", <"action", <"tax", <"biz", <"invoice", <"note", <"due-on", <"receipt", <"txn-id", <"party", <"cashflow", <"currency", <"income-budget"⟩
expectedKeys lib.AssertEq metadataKeys
MetadataValue ← {𝕊 key‿items:
  matching ← ({key ≡ 𝕩.key}¨ items) / items
  (⊑ matching).value
}
"business" lib.AssertEq MetadataValue ⟨"tax", first.metadata⟩
"1" lib.AssertEq MetadataValue ⟨"biz", first.metadata⟩
"会議用の昼食" lib.AssertEq MetadataValue ⟨"note", first.metadata⟩
"demo-receipt-001" lib.AssertEq MetadataValue ⟨"receipt", first.metadata⟩
"demo-business-bundle-7" lib.AssertEq MetadataValue ⟨"txn-id", first.metadata⟩
"JPY" lib.AssertEq MetadataValue ⟨"currency", first.metadata⟩

planRaw ← ∾ ⟨
  "commodity JPY", @+10, @+10,
  "account assets:bank", @+10, @+10,
  "account expenses:food", @+10, @+10,
  "2026-10-05 ! planned metadata", @+10,
  "    ; event-id: demo-plan-event", @+10,
  "    ; layer: plan", @+10,
  "    ; plan-id: demo-plan-2026-10", @+10,
  "    expenses:food 10 JPY", @+10,
  "    assets:bank -10 JPY", @+10
⟩
planParsed ← parser.Parse planRaw
"ok" lib.AssertEq planParsed.state
"demo-plan-2026-10" lib.AssertEq (⊑ planParsed.transactions).plan_id

accountLines ← loader.ReadLines "fixtures/journal-legacy-metadata-profile/accounts.tsv"
resolved ← ak.Resolve accountLines
stage2a ← adapter.Build ⟨parsed.transactions, resolved, "2026-10-01"⟩
"ok" lib.AssertEq stage2a.state
0 lib.AssertEq ≠ stage2a.diagnostics
6 lib.AssertEq ≠ stage2a.posting_rows
rows ← stage2a.posting_rows
sourceIds ← {<𝕩.source_id}¨ rows
lib.Assert (0 ⊑ sourceIds) ≢ (2 ⊑ sourceIds)
lib.Assert (0 ⊑ sourceIds) ≢ (4 ⊑ sourceIds)
⟨<"demo-business-bundle-7", <"demo-business-bundle-7", <"demo-business-bundle-7", <"demo-business-bundle-7", <"stage0-line-35", <"stage0-line-35"⟩ lib.AssertEq {<𝕩.tx_id}¨ rows
⟨<"demo-business-bundle-7", <"demo-business-bundle-7", <"stage0-line-35"⟩ lib.AssertEq {<𝕩.tx_id}¨ 0‿2‿4 ⊏ rows
⟨<"expenses:food/JPY", <"assets:bank/JPY", <"expenses:food/JPY", <"assets:bank/JPY", <"expenses:food/JPY", <"assets:bank/JPY"⟩ lib.AssertEq {<𝕩.account_key}¨ rows
1200‿¯1200‿800‿¯800‿300‿¯300 lib.AssertEq {𝕩.delta}¨ rows
expectedPostingIds ← ⟨
  <(first.source_event_id ∾ ":0"), <(first.source_event_id ∾ ":1"),
  <(second.source_event_id ∾ ":0"), <(second.source_event_id ∾ ":1"),
  <(third.source_event_id ∾ ":0"), <(third.source_event_id ∾ ":1")
⟩
expectedPostingIds lib.AssertEq {<𝕩.posting_id}¨ rows
lib.Assert ∧´ {𝕩.source_id ≡ 𝕩.tx_id}¨ 4‿5 ⊏ rows
lib.Assert ∧´ {𝕩.source_id ≢ 𝕩.tx_id}¨ 0‿1‿2‿3 ⊏ rows

built ← identity.Build ⟨parsed.transactions, rows⟩
"ok" lib.AssertEq built.state
0 lib.AssertEq ≠ built.diagnostics
6 lib.AssertEq ≠ built.posting_rows
6 lib.AssertEq ≠ built.provenance_rows
rows lib.AssertEq built.posting_rows
({<𝕩.posting_id}¨ built.provenance_rows) lib.AssertEq {<𝕩.posting_id}¨ rows
lib.Assert ∧´ {0 < ≠ 𝕩.source_event_id}¨ built.provenance_rows

CheckFail ← {𝕊 source‿code:
  failed ← parser.Parse source
  "error" lib.AssertEq failed.state
  lib.Assert ∨´ {code ≡ 𝕩.code}¨ failed.diagnostics
}
lf ← @+10
Prefix ← {𝕊: ∾ ⟨"commodity JPY", lf, lf, "account assets:bank", lf, lf, "account expenses:food", lf, lf⟩}
duplicate ← ∾ ⟨Prefix @, "2026-10-04 * duplicate", lf, "    ; txn-id: one", lf, "    ; txn-id: two", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨duplicate, "metadata_duplicate"⟩
unknown ← ∾ ⟨Prefix @, "2026-10-04 * unknown", lf, "    ; legacy-secret: no", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨unknown, "metadata_unsupported"⟩
malformed ← ∾ ⟨Prefix @, "2026-10-04 * malformed", lf, "    ; biz: yes", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨malformed, "metadata_value_invalid"⟩
emptyMapped ← ∾ ⟨Prefix @, "2026-10-04 * empty", lf, "    ; tax:", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨emptyMapped, "metadata_shape_invalid"⟩
badDate ← ∾ ⟨Prefix @, "2026-10-04 * bad date", lf, "    ; due-on: 2026-02-30", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨badDate, "metadata_value_invalid"⟩
unsupportedCurrency ← ∾ ⟨Prefix @, "2026-10-04 * unsupported currency", lf, "    ; currency: ILS", lf, "    expenses:food 10 JPY", lf, "    assets:bank -10 JPY", lf⟩
CheckFail ⟨unsupportedCurrency, "metadata_value_invalid"⟩

•Out "test_journal_legacy_metadata_profile_extension.bqn: OK"
