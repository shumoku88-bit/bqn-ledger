#!/usr/bin/env bqn

# Proved:
# - pre-write transaction count can serve as the appended candidate ordinal
# - it works for both durable and physical-fallback actual transactions
# - prior semantically identical transactions do not make ordinal selection ambiguous
# - exactly-one-append count guard fails closed for multiple additions
# - selected candidate semantics can then be checked exactly
#
# Not proved:
# - event-id can now be removed from production
# - concurrent arbitrary file rewrites are solved
# - transaction ordinal is a durable identity
# - fallback source_event_id should become a public identity
# - plan or budget events may omit event-id
# - actual-event-id cross-links can target identity-free transactions

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-append-candidate-ordinal"
cycleStart ← "2026-07-01"

accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines

beforeRaw ← •FChars ("../" ∾ base ∾ "/before.journal")
durableRaw ← •FChars ("../" ∾ base ∾ "/after-durable.journal")
fallbackRaw ← •FChars ("../" ∾ base ∾ "/after-fallback.journal")
multipleRaw ← •FChars ("../" ∾ base ∾ "/after-multiple.journal")

beforeParsed ← parser.Parse beforeRaw
durableParsed ← parser.Parse durableRaw
fallbackParsed ← parser.Parse fallbackRaw
multipleParsed ← parser.Parse multipleRaw

# 9.1 Parse success
"ok" lib.AssertEq beforeParsed.state
"ok" lib.AssertEq durableParsed.state
"ok" lib.AssertEq fallbackParsed.state
"ok" lib.AssertEq multipleParsed.state

0 lib.AssertEq ≠ beforeParsed.diagnostics
0 lib.AssertEq ≠ durableParsed.diagnostics
0 lib.AssertEq ≠ fallbackParsed.diagnostics
0 lib.AssertEq ≠ multipleParsed.diagnostics

2 lib.AssertEq ≠ beforeParsed.transactions
3 lib.AssertEq ≠ durableParsed.transactions
3 lib.AssertEq ≠ fallbackParsed.transactions
4 lib.AssertEq ≠ multipleParsed.transactions

# 9.2 Account resolution
3 lib.AssertEq resolved.count
⟨"assets:cash", "expenses:food", "expenses:household"⟩ lib.AssertEq resolved.accounts
⟨"assets:cash/JPY", "expenses:food/JPY", "expenses:household/JPY"⟩ lib.AssertEq resolved.account_keys

# 9.3 Full Stage 2A success
beforeStage2a ← adapter.Build ⟨beforeParsed.transactions, resolved, cycleStart⟩
durableStage2a ← adapter.Build ⟨durableParsed.transactions, resolved, cycleStart⟩
fallbackStage2a ← adapter.Build ⟨fallbackParsed.transactions, resolved, cycleStart⟩
multipleStage2a ← adapter.Build ⟨multipleParsed.transactions, resolved, cycleStart⟩

"ok" lib.AssertEq beforeStage2a.state
"ok" lib.AssertEq durableStage2a.state
"ok" lib.AssertEq fallbackStage2a.state
"ok" lib.AssertEq multipleStage2a.state

0 lib.AssertEq ≠ beforeStage2a.diagnostics
0 lib.AssertEq ≠ durableStage2a.diagnostics
0 lib.AssertEq ≠ fallbackStage2a.diagnostics
0 lib.AssertEq ≠ multipleStage2a.diagnostics

lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ beforeStage2a.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ durableStage2a.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ fallbackStage2a.posting_rows
lib.Assert ∧´ {𝕩.status ≡ "ok"}¨ multipleStage2a.posting_rows

# 9.4 Append ordinal
candidateIndex ← ≠ beforeParsed.transactions
2 lib.AssertEq candidateIndex

durableCandidate ← candidateIndex ⊑ durableParsed.transactions
fallbackCandidate ← candidateIndex ⊑ fallbackParsed.transactions

# 9.5 Exactly-one-append guard
3 lib.AssertEq ≠ durableParsed.transactions
3 lib.AssertEq ≠ fallbackParsed.transactions
4 lib.AssertEq ≠ multipleParsed.transactions

lib.Assert (≠ durableParsed.transactions) ≡ (≠ beforeParsed.transactions) + 1
lib.Assert (≠ fallbackParsed.transactions) ≡ (≠ beforeParsed.transactions) + 1
lib.Assert (≠ multipleParsed.transactions) ≢ (≠ beforeParsed.transactions) + 1

# 9.6 Prefix preservation
MakePostingCarrier ← {𝕊 p:
  ⟨
    < p.account_key,
    < p.delta,
    < p.commodity,
    < p.amount_text,
    < p.side,
    < p.posting_index,
    < p.posting_id,
    < p.source_line
  ⟩
}

MakeMetadataCarrier ← {𝕊 m:
  ⟨
    < m.key,
    < m.value,
    < m.source_line
  ⟩
}

MakeTxCarrier ← {𝕊 tx:
  ⟨
    < tx.source_event_id,
    < tx.identity_kind,
    < tx.source_start_line,
    < tx.source_end_line,
    < tx.date,
    < tx.status_marker,
    < tx.description,
    < tx.layer_name,
    < tx.txn_id,
    < tx.plan_id,
    < tx.allocation_id,
    < tx.execution_envelope,
    < tx.actual_event_id,
    < MakeMetadataCarrier¨ tx.metadata,
    < MakePostingCarrier¨ tx.postings
  ⟩
}

beforePrefixCarriers ← MakeTxCarrier¨ beforeParsed.transactions
durablePrefixCarriers ← MakeTxCarrier¨ 2 ↑ durableParsed.transactions
fallbackPrefixCarriers ← MakeTxCarrier¨ 2 ↑ fallbackParsed.transactions
multiplePrefixCarriers ← MakeTxCarrier¨ 2 ↑ multipleParsed.transactions

beforePrefixCarriers lib.AssertEq durablePrefixCarriers
beforePrefixCarriers lib.AssertEq fallbackPrefixCarriers
beforePrefixCarriers lib.AssertEq multiplePrefixCarriers

# 9.7 Physical append boundary
maxBeforeEndLine ← ⌈´ {𝕩.source_end_line}¨ beforeParsed.transactions
lib.Assert durableCandidate.source_start_line > maxBeforeEndLine
lib.Assert fallbackCandidate.source_start_line > maxBeforeEndLine

multipleCandidate0 ← candidateIndex ⊑ multipleParsed.transactions
lib.Assert multipleCandidate0.source_start_line > maxBeforeEndLine

# 9.8 Candidate identity difference
"durable" lib.AssertEq durableCandidate.identity_kind
"appended-candidate" lib.AssertEq durableCandidate.source_event_id
⟨"event-id"⟩ lib.AssertEq {𝕩.key}¨ durableCandidate.metadata

"physical_fallback" lib.AssertEq fallbackCandidate.identity_kind
lib.Assert 0 < ≠ fallbackCandidate.source_event_id
"stage0-line-" lib.AssertEq (≠"stage0-line-") ↑ fallbackCandidate.source_event_id
0 lib.AssertEq ≠ fallbackCandidate.metadata

# 9.9 Candidate semantic equality
MakeSemanticPostingCarrier ← {𝕊 p:
  ⟨
    < p.account_key,
    < p.delta,
    < p.commodity,
    < p.amount_text,
    < p.side,
    < p.posting_index
  ⟩
}

MakeSemanticTxCarrier ← {𝕊 tx:
  ⟨
    < tx.date,
    < tx.status_marker,
    < tx.description,
    < tx.layer_name,
    < tx.txn_id,
    < tx.plan_id,
    < tx.allocation_id,
    < tx.execution_envelope,
    < tx.actual_event_id,
    < MakeSemanticPostingCarrier¨ tx.postings
  ⟩
}

durableSemanticCarrier ← MakeSemanticTxCarrier durableCandidate
fallbackSemanticCarrier ← MakeSemanticTxCarrier fallbackCandidate

durableSemanticCarrier lib.AssertEq fallbackSemanticCarrier

"2026-07-23" lib.AssertEq durableCandidate.date
'*' lib.AssertEq durableCandidate.status_marker
"Duplicate purchase" lib.AssertEq durableCandidate.description
"actual" lib.AssertEq durableCandidate.layer_name
⟨"expenses:food", "assets:cash"⟩ lib.AssertEq {𝕩.account_key}¨ durableCandidate.postings
⟨25, ¯25⟩ lib.AssertEq {𝕩.delta}¨ durableCandidate.postings
⟨"JPY", "JPY"⟩ lib.AssertEq {𝕩.commodity}¨ durableCandidate.postings
⟨"debit", "credit"⟩ lib.AssertEq {𝕩.side}¨ durableCandidate.postings
⟨0, 1⟩ lib.AssertEq {𝕩.posting_index}¨ durableCandidate.postings
0 lib.AssertEq +´ {𝕩.delta}¨ durableCandidate.postings

# 9.10 Semantic-only lookup ambiguity
# Semantic equality validates a selected candidate.
# Semantic equality alone does not select the candidate.
# The append ordinal selects it.
CountSemanticMatches ← {𝕊 txs:
  +´ { (MakeSemanticTxCarrier 𝕩) ≡ durableSemanticCarrier }¨ txs
}

2 lib.AssertEq CountSemanticMatches durableParsed.transactions
2 lib.AssertEq CountSemanticMatches fallbackParsed.transactions

# 9.11 Event-id lookup boundary
1 lib.AssertEq +´ {𝕩.source_event_id ≡ "appended-candidate"}¨ durableParsed.transactions
0 lib.AssertEq +´ { "event-id" ≡ 𝕩.key }¨ fallbackCandidate.metadata

# 9.12 Multiple-append fail-closed evidence
# A valid Journal is not sufficient evidence that exactly one candidate was appended.
# The transaction-count delta is part of the selection contract.
"ok" lib.AssertEq multipleParsed.state
"ok" lib.AssertEq multipleStage2a.state
beforePrefixCarriers lib.AssertEq multiplePrefixCarriers
lib.Assert multipleCandidate0.source_start_line > maxBeforeEndLine
2 lib.AssertEq (≠ multipleParsed.transactions) - (≠ beforeParsed.transactions)
lib.Assert (≠ multipleParsed.transactions) ≢ (≠ beforeParsed.transactions) + 1

•Out "test_journal_append_candidate_ordinal_characterization.bqn: OK"
