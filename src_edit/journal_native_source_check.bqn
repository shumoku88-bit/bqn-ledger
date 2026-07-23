# journal_native_source_check.bqn
# Mandatory post-write validator for an explicit native Journal candidate.

parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
decimal ← •Import "../src_next/exact_decimal.bqn"

args ← •args
tab ← @+9
empty ← ⟨⟩
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
{𝕊⋄Fail ⟨"usage", "expected BASE TARGET DATE DESCRIPTION EVENT_ID and at least two postings"⟩}⍟(7 > ≠ args) @
base ← 0⊑args
target ← 1⊑args
dateText ← 2⊑args
description ← 3⊑args
eventId ← 4⊑args
postingArgs ← 5↓args

expected ← empty
{𝕊 text:
  equalMask ← '=' = text
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting protocol is malformed"⟩}⍟(1 ≠ +´ equalMask) @
  i ← ⊑ equalMask / ↕≠text
  account ← i↑text
  amountText ← (i+1)↓text
  negative ← '-' = ⊑ (amountText∾"0")
  unsigned ← negative↓amountText
  parsedAmount ← decimal.Parse unsigned
  valid ← (parsedAmount.state≡"ok") ∧ (0=parsedAmount.scale) ∧ unsigned≡•Fmt parsedAmount.coefficient
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting amount is invalid"⟩}⍟(¬valid) @
  delta ← (1-2×negative) × parsedAmount.coefficient
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting amount is zero"⟩}⍟(0=delta) @
  expected ∾↩ ⟨{account_key⇐account, delta⇐delta, commodity⇐"JPY"}⟩
}¨postingArgs
{𝕊⋄Fail ⟨"expected_posting_invalid", "expected candidate requires at least two balanced postings"⟩}⍟((2>≠expected) ∨ 0≠+´{𝕩.delta}¨expected) @

raw ← loader.ReadRaw target
parsed ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
{𝕊⋄Fail ⟨"native_journal_invalid", "full written native Journal failed parsing or global invariants"⟩}⍟(parsed.state≢"ok") @

resolved ← ak.Resolve loader.ReadLines (base∾"/accounts.tsv")
allPostings ← ∾ {𝕩.postings}¨ parsed.transactions
{𝕊 posting:
  mask ← posting.account_key⊸≡¨ resolved.accounts
  {𝕊⋄Fail ⟨"native_account_unresolved", "every native posting account must resolve exactly once"⟩}⍟(1≠+´mask) @
  idx ← ⊑ mask/↕≠mask
  {𝕊⋄Fail ⟨"native_account_currency_invalid", "every native posting account must resolve to JPY"⟩}⍟("JPY"≢idx⊑resolved.currencies) @
  {𝕊⋄Fail ⟨"native_posting_invalid", "every native posting must be explicit nonzero JPY exact integer evidence"⟩}⍟((0=posting.delta) ∨ posting.commodity≢"JPY") @
}¨allPostings

checked ← adapter.Build ⟨parsed.transactions, resolved, dateText⟩
{𝕊⋄Fail ⟨"native_posting_ir_invalid", "checked Stage 2A rejected the full written Journal"⟩}⍟(checked.state≢"ok") @

matching ← ({(𝕩.identity_kind≡"durable") ∧ 𝕩.source_event_id≡eventId}¨parsed.transactions)/parsed.transactions
{𝕊⋄Fail ⟨"native_candidate_identity_invalid", "new durable event must exist exactly once"⟩}⍟(1≠≠matching) @
candidate ← ⊑matching
expectedAccounts ← {𝕩.account_key}¨expected
expectedAmounts ← {𝕩.delta}¨expected
actualAccounts ← {𝕩.account_key}¨candidate.postings
actualAmounts ← {𝕩.delta}¨candidate.postings
commoditiesOk ← ∧´ {𝕩.commodity≡"JPY"}¨candidate.postings
postingIndexesOk ← (↕≠candidate.postings) ≡ {𝕩.posting_index}¨candidate.postings
candidateOk ← (candidate.date≡dateText) ∧ (candidate.description≡description) ∧ (candidate.source_event_id≡eventId) ∧ (candidate.identity_kind≡"durable") ∧ (candidate.status_marker='*') ∧ (candidate.layer_name≡"actual") ∧ ((≠candidate.postings)=≠expected) ∧ postingIndexesOk ∧ (actualAccounts≡expectedAccounts) ∧ (actualAmounts≡expectedAmounts) ∧ commoditiesOk
{𝕊⋄Fail ⟨"native_candidate_mismatch", "written candidate does not exactly equal previewed candidate"⟩}⍟(¬candidateOk) @

•Out "OK"∾tab∾"NATIVE_JOURNAL_CANDIDATE"∾tab∾eventId∾tab∾(•Fmt ≠candidate.postings)
