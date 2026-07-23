#!/usr/bin/env bqn

# Proved:
# - an identity-free ordinary actual transaction parses as physical_fallback
# - it contributes normal actual postings to Stage 2A
# - plan completion may remain durable beside it
# - a budget companion cannot target its physical fallback source_event_id
#
# Not proved:
# - the production writer may now omit event-id
# - physical fallback source_event_id is stable across file edits
# - physical fallback source_event_id is a public identifier
# - reverse-by-id is safe for identity-free transactions
# - plan completion writers may omit event-id
# - budget cross-link policy should be weakened

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

fixtureDir ← "fixtures/journal-ordinary-actual-fallback-boundary"
cycleStart ← "2026-07-01"
profile ← "historical_external_plan"

# 8.1 Valid Journal assertions
rawValid ← loader.ReadRaw (fixtureDir ∾ "/actual.journal")
parsedValid ← parser.ParseWithProfile ⟨rawValid, profile⟩
"ok" lib.AssertEq parsedValid.state
0 lib.AssertEq ≠ parsedValid.diagnostics
3 lib.AssertEq ≠ parsedValid.transactions

txs ← parsedValid.transactions
tx1 ← 0 ⊑ txs
tx2 ← 1 ⊑ txs
tx3 ← 2 ⊑ txs

"durable" lib.AssertEq tx1.identity_kind
"physical_fallback" lib.AssertEq tx2.identity_kind
"durable" lib.AssertEq tx3.identity_kind

lib.Assert ∧´ {𝕩.layer_name ≡ "actual"}¨ txs

# 8.2 Ordinary actual identity boundary
"2026-07-23" lib.AssertEq tx2.date
"Ordinary purchase" lib.AssertEq tx2.description
'*' lib.AssertEq tx2.status_marker
"actual" lib.AssertEq tx2.layer_name
"physical_fallback" lib.AssertEq tx2.identity_kind
lib.Assert "stage0-line-" ≡ 12 ↑ tx2.source_event_id
0 lib.AssertEq ≠ tx2.metadata
"" lib.AssertEq tx2.plan_id
"" lib.AssertEq tx2.allocation_id
"" lib.AssertEq tx2.actual_event_id
"" lib.AssertEq tx2.txn_id
2 lib.AssertEq ≠ tx2.postings

p1 ← 0 ⊑ tx2.postings
p2 ← 1 ⊑ tx2.postings

⟨<"expenses:food", <"assets:cash"⟩ lib.AssertEq ⟨<p1.account_key, <p2.account_key⟩
⟨25, ¯25⟩ lib.AssertEq ⟨p1.delta, p2.delta⟩
⟨<"JPY", <"JPY"⟩ lib.AssertEq ⟨<p1.commodity, <p2.commodity⟩
⟨0, 1⟩ lib.AssertEq ⟨p1.posting_index, p2.posting_index⟩
0 lib.AssertEq p1.delta + p2.delta

# 8.3 Plan completion boundary
# The identity-free ordinary actual case does not relax the durable identity policy for plan completion writers.
"durable" lib.AssertEq tx3.identity_kind
"completion-plan-household-001-20260724" lib.AssertEq tx3.source_event_id
"plan-household-001" lib.AssertEq tx3.plan_id
"daily" lib.AssertEq tx3.execution_envelope

metaKeys3 ← {𝕩.key}¨ tx3.metadata
lib.Assert ∨´ {"event-id" ≡ 𝕩}¨ metaKeys3
lib.Assert ∨´ {"plan-id" ≡ 𝕩}¨ metaKeys3
lib.Assert ∨´ {"execution-envelope" ≡ 𝕩}¨ metaKeys3

# 8.4 Account resolution and Stage 2A
accountLines ← loader.ReadLines (fixtureDir ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
lib.Assert 0 < resolved.count
lib.Assert ∧´ {"JPY" ≡ 𝕩}¨ resolved.currencies

stage2aResult ← adapter.Build ⟨txs, resolved, cycleStart⟩
"ok" lib.AssertEq stage2aResult.state
0 lib.AssertEq ≠ stage2aResult.diagnostics
6 lib.AssertEq ≠ stage2aResult.posting_rows

rows ← stage2aResult.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ rows

ordinaryRows ← 2‿3 ⊏ rows
⟨<"expenses:food/JPY", <"assets:cash/JPY"⟩ lib.AssertEq {<𝕩.account_key}¨ ordinaryRows
⟨25, ¯25⟩ lib.AssertEq {𝕩.delta}¨ ordinaryRows
lib.Assert ∧´ {𝕩.layer_name ≡ "actual"}¨ ordinaryRows

# 8.5 Invalid budget companion
rawInvalid ← loader.ReadRaw (fixtureDir ∾ "/invalid-budget-companion.journal")
parsedInvalid ← parser.ParseWithProfile ⟨rawInvalid, profile⟩
"error" lib.AssertEq parsedInvalid.state

diagCodes ← {𝕩.code}¨ parsedInvalid.diagnostics
lib.Assert ∨´ {"actual_event_target_invalid" ≡ 𝕩}¨ diagCodes

invalidTxs ← parsedInvalid.transactions
companionTx ← 3 ⊑ invalidTxs
tx2FallbackId ← tx2.source_event_id
tx2FallbackId lib.AssertEq companionTx.actual_event_id

•Out "test_journal_ordinary_actual_fallback_boundary.bqn: OK"
