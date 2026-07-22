#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
identity ← •Import "../src_next/journal_posting_identity_provenance_stage2b.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-external-plan-reference-profile"
strictProfile ← "strict_self_contained"
historicalProfile ← "historical_external_plan"

Load ← {𝕊 name: •FChars "../" ∾ base ∾ "/" ∾ name}
Codes ← {𝕊 result: {<𝕩.code}¨ result.diagnostics}
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics}
MetadataValue ← {𝕊 key‿items:
  matching ← ({key ≡ 𝕩.key}¨ items) / items
  (⊑ matching).value
}
Fields16 ← {𝕊 row: ⟨
  <row.source_file, row.source_row, <row.source_id, <row.tx_id,
  <row.posting_id, <row.date, row.day_index, <row.account_key,
  row.account_key_index, <row.layer_name, row.layer_index, <row.side,
  row.delta, <row.kind, <row.status, <row.message
⟩}
MetadataEvidence ← {𝕊 item: ⟨<item.key, <item.value, item.source_line⟩}
AccountEvidence ← {𝕊 account: ⟨
  <account.account_key, account.source_line, <account.role, <account.kind,
  <account.default_envelope, <MetadataEvidence¨ account.metadata
⟩}
CommodityEvidence ← {𝕊 commodity: ⟨<commodity.commodity, commodity.source_line⟩}
PostingEvidence ← {𝕊 posting: ⟨
  <posting.account_key, posting.delta, <posting.commodity, <posting.amount_text,
  <posting.side, posting.posting_index, <posting.posting_id, posting.source_line
⟩}
TransactionEvidence ← {𝕊 transaction: ⟨
  <transaction.source_event_id, <transaction.identity_kind,
  transaction.source_start_line, transaction.source_end_line, <transaction.date,
  <transaction.status_marker, <transaction.description, <transaction.layer_name,
  <transaction.txn_id, <transaction.plan_id, <transaction.allocation_id,
  <transaction.execution_envelope, <transaction.actual_event_id,
  <MetadataEvidence¨ transaction.metadata, <PostingEvidence¨ transaction.postings
⟩}
AssertEquivalent ← {𝕊 left‿right:
  left.state lib.AssertEq right.state
  (Codes left) lib.AssertEq Codes right
  (AccountEvidence¨ left.accounts) lib.AssertEq AccountEvidence¨ right.accounts
  (CommodityEvidence¨ left.commodities) lib.AssertEq CommodityEvidence¨ right.commodities
  (TransactionEvidence¨ left.transactions) lib.AssertEq TransactionEvidence¨ right.transactions
}

# A/B: Parse remains strict and is equivalent to explicit strict selection.
actualRaw ← Load "actual-only.journal"
defaultStrict ← parser.Parse actualRaw
explicitStrict ← parser.ParseWithProfile ⟨actualRaw, strictProfile⟩
"error" lib.AssertEq defaultStrict.state
lib.Assert HasCode ⟨"plan_completion_target_invalid", defaultStrict⟩
AssertEquivalent ⟨defaultStrict, explicitStrict⟩

# C/J: explicitly selected historical zero-match admission retains all source evidence.
historical ← parser.ParseWithProfile ⟨actualRaw, historicalProfile⟩
"ok" lib.AssertEq historical.state
0 lib.AssertEq ≠ historical.diagnostics
1 lib.AssertEq ≠ historical.transactions
actual ← ⊑ historical.transactions
"actual" lib.AssertEq actual.layer_name
"event-orchard-actual-001" lib.AssertEq actual.source_event_id
"durable" lib.AssertEq actual.identity_kind
"plan-orchard-2042" lib.AssertEq actual.plan_id
"plan-orchard-2042" lib.AssertEq MetadataValue ⟨"plan-id", actual.metadata⟩
"創作メモ🌿" lib.AssertEq MetadataValue ⟨"note", actual.metadata⟩
"星庭カフェ | 朝食 ☕" lib.AssertEq actual.description
'*' lib.AssertEq actual.status_marker
⟨<"expenses:orchard", <"assets:aurora"⟩ lib.AssertEq {<𝕩.account_key}¨ actual.postings
730‿¯730 lib.AssertEq {𝕩.delta}¨ actual.postings
0‿1 lib.AssertEq {𝕩.posting_index}¨ actual.postings
⟨<"event-orchard-actual-001:0", <"event-orchard-actual-001:1"⟩ lib.AssertEq {<𝕩.posting_id}¨ actual.postings

# D: unchanged account resolver, Stage 2A 16-field rows, and Stage 2B carrier.
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
stage2a ← adapter.Build ⟨historical.transactions, resolved, "2026-11-01"⟩
"ok" lib.AssertEq stage2a.state
0 lib.AssertEq ≠ stage2a.diagnostics
2 lib.AssertEq ≠ stage2a.posting_rows
lib.Assert ∧´ {16 = ≠ Fields16 𝕩}¨ stage2a.posting_rows
⟨<"event-orchard-actual-001", <"event-orchard-actual-001"⟩ lib.AssertEq {<𝕩.source_id}¨ stage2a.posting_rows
⟨<"event-orchard-actual-001", <"event-orchard-actual-001"⟩ lib.AssertEq {<𝕩.tx_id}¨ stage2a.posting_rows
⟨<"event-orchard-actual-001:0", <"event-orchard-actual-001:1"⟩ lib.AssertEq {<𝕩.posting_id}¨ stage2a.posting_rows
⟨<"expenses:orchard/JPY", <"assets:aurora/JPY"⟩ lib.AssertEq {<𝕩.account_key}¨ stage2a.posting_rows
730‿¯730 lib.AssertEq {𝕩.delta}¨ stage2a.posting_rows
stage2b ← identity.Build ⟨historical.transactions, stage2a.posting_rows⟩
"ok" lib.AssertEq stage2b.state
0 lib.AssertEq ≠ stage2b.diagnostics
2 lib.AssertEq ≠ stage2b.posting_rows
2 lib.AssertEq ≠ stage2b.provenance_rows
stage2a.posting_rows lib.AssertEq stage2b.posting_rows
({<𝕩.posting_id}¨ stage2a.posting_rows) lib.AssertEq {<𝕩.posting_id}¨ stage2b.provenance_rows

# E: one internal match retains strict completion and envelope semantics.
internalRaw ← Load "internal-match.journal"
internalStrict ← parser.ParseWithProfile ⟨internalRaw, strictProfile⟩
internalHistorical ← parser.ParseWithProfile ⟨internalRaw, historicalProfile⟩
"ok" lib.AssertEq internalStrict.state
"ok" lib.AssertEq internalHistorical.state
AssertEquivalent ⟨internalStrict, internalHistorical⟩
2 lib.AssertEq ≠ internalHistorical.transactions

# F: historical selection does not bypass a resolved internal envelope mismatch.
mismatch ← parser.ParseWithProfile ⟨Load "internal-envelope-mismatch.journal", historicalProfile⟩
"error" lib.AssertEq mismatch.state
lib.Assert HasCode ⟨"execution_envelope_mismatch", mismatch⟩

# G: duplicate internal plan targets remain fail closed.
duplicate ← parser.ParseWithProfile ⟨Load "duplicate-plan-target.journal", historicalProfile⟩
"error" lib.AssertEq duplicate.state
lib.Assert HasCode ⟨"plan_id_duplicate", duplicate⟩
lib.Assert HasCode ⟨"plan_completion_target_invalid", duplicate⟩

# H: no plan-id is profile-independent.
noPlanRaw ← Load "no-plan-id.journal"
noPlanStrict ← parser.ParseWithProfile ⟨noPlanRaw, strictProfile⟩
noPlanHistorical ← parser.ParseWithProfile ⟨noPlanRaw, historicalProfile⟩
"ok" lib.AssertEq noPlanStrict.state
AssertEquivalent ⟨noPlanStrict, noPlanHistorical⟩

# I: unrelated actual-event cross-link rejection remains active.
otherInvalid ← parser.ParseWithProfile ⟨Load "other-cross-link-invalid.journal", historicalProfile⟩
"error" lib.AssertEq otherInvalid.state
lib.Assert HasCode ⟨"actual_event_target_invalid", otherInvalid⟩

# K: invalid profile selection fails closed instead of parsing as strict.
{𝕊 unsupported:
  invalid ← parser.ParseWithProfile ⟨actualRaw, unsupported⟩
  "error" lib.AssertEq invalid.state
  ⟨<"parser_profile_unsupported"⟩ lib.AssertEq Codes invalid
  0 lib.AssertEq ≠ invalid.accounts
  0 lib.AssertEq ≠ invalid.commodities
  0 lib.AssertEq ≠ invalid.transactions
}¨ ⟨"", "unknown_profile", "historical-external-plan"⟩

•Out "test_journal_external_plan_reference_profile_prerequisite.bqn: OK"
