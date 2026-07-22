#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"

lf ← @+10
base ← "../fixtures/journal-resolved-envelope-assignment-persistence"

Join ← {𝕊 left‿right: left ∾ lf ∾ lf ∾ right }
HasCode ← {𝕊 code‿result: ∨´ 0 ∾ {code ≡ 𝕩.code}¨ result.diagnostics }

GetDefault ← {𝕊 key‿accounts:
  matching ← ({key ≡ 𝕩.account_key}¨ accounts) / accounts
  1 lib.AssertEq ≠ matching
  account ← ⊑ matching
  account.default_envelope
}

TotalForEnvelope ← {𝕊 envelope‿assignments:
  mask ← {envelope ≡ 𝕩.envelope}¨ assignments
  +´ 0 ∾ {𝕩.amount}¨ mask / assignments
}

v1Defaults ← •FChars (base ∾ "/defaults-v1.journal")
v2Defaults ← •FChars (base ∾ "/defaults-v2.journal")
persistedEvents ← •FChars (base ∾ "/persisted-events.journal")

v1 ← parser.Parse Join ⟨v1Defaults, persistedEvents⟩
v2 ← parser.Parse Join ⟨v2Defaults, persistedEvents⟩

# V1 source and cross-event structure.
"ok" lib.AssertEq v1.state
0 lib.AssertEq ≠ v1.diagnostics
3 lib.AssertEq ≠ v1.transactions
⟨"actual", "budget", "actual"⟩ lib.AssertEq {𝕩.layer_name}¨ v1.transactions

purchaseV1 ← 0 ⊑ v1.transactions
companionV1 ← 1 ⊑ v1.transactions
laterPurchaseV1 ← 2 ⊑ v1.transactions

"durable" lib.AssertEq purchaseV1.identity_kind
"event-purchase-2026-08-03-001" lib.AssertEq purchaseV1.source_event_id
"event-envelope-consumption-2026-08-03-001" lib.AssertEq companionV1.source_event_id
"event-purchase-2026-08-03-001" lib.AssertEq companionV1.actual_event_id
lib.Assert purchaseV1.source_event_id ≢ companionV1.source_event_id

⟨"expenses:food:daily", "expenses:food:stock", "expenses:household", "assets:bank"⟩ lib.AssertEq {𝕩.account_key}¨ purchaseV1.postings
⟨1400, 900, 500, ¯2800⟩ lib.AssertEq {𝕩.delta}¨ purchaseV1.postings
0 lib.AssertEq +´ {𝕩.delta}¨ purchaseV1.postings

⟨"budget:spent:daily", "budget:daily", "budget:spent:flex", "budget:flex"⟩ lib.AssertEq {𝕩.account_key}¨ companionV1.postings
⟨2300, ¯2300, 500, ¯500⟩ lib.AssertEq {𝕩.delta}¨ companionV1.postings
0 lib.AssertEq +´ {𝕩.delta}¨ companionV1.postings

# Account metadata is an entry-time default under V1.
"daily" lib.AssertEq GetDefault ⟨"expenses:food:daily", v1.accounts⟩
"daily" lib.AssertEq GetDefault ⟨"expenses:food:stock", v1.accounts⟩
"flex" lib.AssertEq GetDefault ⟨"expenses:household", v1.accounts⟩

resolvedV1 ← parser.ResolveEnvelopeDefaults ⟨purchaseV1, v1.accounts⟩
"ok" lib.AssertEq resolvedV1.state
0 lib.AssertEq ≠ resolvedV1.diagnostics
3 lib.AssertEq ≠ resolvedV1.assignments
⟨"daily", "daily", "flex"⟩ lib.AssertEq {𝕩.envelope}¨ resolvedV1.assignments
2300 lib.AssertEq TotalForEnvelope ⟨"daily", resolvedV1.assignments⟩
500 lib.AssertEq TotalForEnvelope ⟨"flex", resolvedV1.assignments⟩

# V2 changes future defaults, but the persisted V1 companion is unchanged.
"ok" lib.AssertEq v2.state
0 lib.AssertEq ≠ v2.diagnostics
"flex" lib.AssertEq GetDefault ⟨"expenses:food:daily", v2.accounts⟩
"flex" lib.AssertEq GetDefault ⟨"expenses:food:stock", v2.accounts⟩
"flex" lib.AssertEq GetDefault ⟨"expenses:household", v2.accounts⟩

purchaseUnderV2 ← 0 ⊑ v2.transactions
companionUnderV2 ← 1 ⊑ v2.transactions
laterPurchaseUnderV2 ← 2 ⊑ v2.transactions

oldCandidateV2 ← parser.ResolveEnvelopeDefaults ⟨purchaseUnderV2, v2.accounts⟩
"ok" lib.AssertEq oldCandidateV2.state
0 lib.AssertEq TotalForEnvelope ⟨"daily", oldCandidateV2.assignments⟩
2800 lib.AssertEq TotalForEnvelope ⟨"flex", oldCandidateV2.assignments⟩

newCandidateV2 ← parser.ResolveEnvelopeDefaults ⟨laterPurchaseUnderV2, v2.accounts⟩
"ok" lib.AssertEq newCandidateV2.state
0 lib.AssertEq TotalForEnvelope ⟨"daily", newCandidateV2.assignments⟩
2800 lib.AssertEq TotalForEnvelope ⟨"flex", newCandidateV2.assignments⟩

# Historical arithmetic comes from the persisted event, not the latest default.
"event-purchase-2026-08-03-001" lib.AssertEq companionUnderV2.actual_event_id
⟨"budget:spent:daily", "budget:daily", "budget:spent:flex", "budget:flex"⟩ lib.AssertEq {𝕩.account_key}¨ companionUnderV2.postings
⟨2300, ¯2300, 500, ¯500⟩ lib.AssertEq {𝕩.delta}¨ companionUnderV2.postings
0 lib.AssertEq +´ {𝕩.delta}¨ companionUnderV2.postings

# The budget companion does not duplicate actual money accounts.
lib.Assert ∧´ {"budget:" ≡ 7 ↑ 𝕩.account_key}¨ companionV1.postings
lib.Assert ∧´ {"budget:" ≢ 7 ↑ 𝕩.account_key}¨ purchaseV1.postings
lib.Assert ∧´ {"budget:" ≢ 7 ↑ 𝕩.account_key}¨ laterPurchaseV1.postings

# Focused fail-closed source evidence.
ActualBlock ← {𝕊:
  ∾ ⟨
    "2026-08-03 * Example Market | purchase", lf,
    "    ; event-id: event-purchase-1", lf,
    "    expenses:food:daily 10 JPY", lf,
    "    assets:bank -10 JPY", lf
  ⟩
}

BudgetBlock ← {𝕊 eventId‿linkId‿creditAmount:
  linkLine ← ""
  {𝕊: linkLine ↩ "    ; actual-event-id: " ∾ linkId ∾ lf}⍟(0 < ≠ linkId) @
  ∾ ⟨
    "2026-08-03 * Household budget | consume", lf,
    "    ; event-id: ", eventId, lf,
    "    ; layer: budget", lf,
    linkLine,
    "    budget:spent:daily 10 JPY", lf,
    "    budget:daily -", creditAmount, " JPY", lf
  ⟩
}

missingLink ← parser.Parse Join ⟨v1Defaults, BudgetBlock ⟨"event-budget-missing", "", "10"⟩⟩
"error" lib.AssertEq missingLink.state
lib.Assert HasCode ⟨"budget_link_missing", missingLink⟩

unknownTarget ← parser.Parse Join ⟨v1Defaults, BudgetBlock ⟨"event-budget-unknown", "event-does-not-exist", "10"⟩⟩
"error" lib.AssertEq unknownTarget.state
lib.Assert HasCode ⟨"actual_event_target_invalid", unknownTarget⟩

duplicateCompanions ← parser.Parse Join ⟨
  v1Defaults,
  ∾ ⟨
    ActualBlock @, lf,
    BudgetBlock ⟨"event-budget-a", "event-purchase-1", "10"⟩, lf,
    BudgetBlock ⟨"event-budget-b", "event-purchase-1", "10"⟩
  ⟩
⟩
"error" lib.AssertEq duplicateCompanions.state
lib.Assert HasCode ⟨"actual_event_companion_duplicate", duplicateCompanions⟩

unbalancedCompanion ← parser.Parse Join ⟨
  v1Defaults,
  ∾ ⟨ActualBlock @, lf, BudgetBlock ⟨"event-budget-unbalanced", "event-purchase-1", "9"⟩⟩
⟩
"error" lib.AssertEq unbalancedCompanion.state
lib.Assert HasCode ⟨"event_unbalanced", unbalancedCompanion⟩

UnknownDefaultDeclarations ← {𝕊:
  ∾ ⟨
    "commodity JPY", lf, lf,
    "account assets:bank", lf,
    "    ; role: asset", lf, lf,
    "account expenses:food:daily", lf,
    "    ; role: expense", lf,
    "    ; default-envelope: ghost", lf, lf,
    "account budget:spent:daily", lf,
    "    ; role: budget", lf, lf,
    "account budget:daily", lf,
    "    ; role: budget", lf
  ⟩
}

unknownDefaultParsed ← parser.Parse Join ⟨UnknownDefaultDeclarations @, ActualBlock @⟩
"ok" lib.AssertEq unknownDefaultParsed.state
unknownDefaultResolved ← parser.ResolveEnvelopeDefaults ⟨0 ⊑ unknownDefaultParsed.transactions, unknownDefaultParsed.accounts⟩
"error" lib.AssertEq unknownDefaultResolved.state
lib.Assert HasCode ⟨"default_envelope_unknown", unknownDefaultResolved⟩

MissingDefaultDeclarations ← {𝕊:
  ∾ ⟨
    "commodity JPY", lf, lf,
    "account assets:bank", lf,
    "    ; role: asset", lf, lf,
    "account expenses:food:daily", lf,
    "    ; role: expense", lf, lf,
    "account budget:spent:daily", lf,
    "    ; role: budget", lf, lf,
    "account budget:daily", lf,
    "    ; role: budget", lf
  ⟩
}

missingDefaultParsed ← parser.Parse Join ⟨MissingDefaultDeclarations @, ActualBlock @⟩
"ok" lib.AssertEq missingDefaultParsed.state
missingDefaultResolved ← parser.ResolveEnvelopeDefaults ⟨0 ⊑ missingDefaultParsed.transactions, missingDefaultParsed.accounts⟩
"error" lib.AssertEq missingDefaultResolved.state
lib.Assert HasCode ⟨"default_envelope_missing", missingDefaultResolved⟩

•Out "test_journal_resolved_envelope_assignment_persistence.bqn: OK"
