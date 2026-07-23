# journal_native_source_check.bqn
# Mandatory post-write validator for an explicit native Journal candidate.

parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
decimal ← •Import "../src_next/exact_decimal.bqn"

args ← •args
tab ← @+9
space ← @+32
empty ← ⟨⟩
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
TrimLeft ← {𝕊 xs: (+´ ∧` (xs = space)) ↓ xs}
TrimRight ← {𝕊 xs: ((≠ xs) - +´ ∧` ((⌽ xs) = space)) ↑ xs}
Trim ← {TrimRight TrimLeft 𝕩}
UnsafeText ← {𝕊 text:
  controls ← ((@+0) + ↕32) ∾ ⟨@+127⟩
  ∨´ 0 ∾ text ∊ controls
}
{𝕊⋄Fail ⟨"usage", "expected BASE TARGET DATE DESCRIPTION IDENTITY_MODE EVENT_ID CANDIDATE_ORDINAL and at least two postings"⟩}⍟(9 > ≠ args) @
base ← 0⊑args
target ← 1⊑args
dateText ← 2⊑args
description ← 3⊑args
identityMode ← 4⊑args
eventId ← 5⊑args
candidateOrdinalText ← 6⊑args
postingArgs ← 7↓args

{𝕊⋄Fail ⟨"identity_mode_invalid", "identity mode must be ordinary or durable"⟩}⍟(¬ ((identityMode ≡ "ordinary") ∨ identityMode ≡ "durable")) @
{𝕊⋄Fail ⟨"event_id_unexpected", "ordinary actual must not carry an event-id"⟩}⍟((identityMode ≡ "ordinary") ∧ 0 < ≠ eventId) @
{𝕊⋄Fail ⟨"event_id_invalid", "event-id must be nonempty and must not contain unsafe control input"⟩}⍟((identityMode ≡ "durable") ∧ ((0 = ≠ Trim eventId) ∨ (UnsafeText eventId) ∨ eventId ≢ Trim eventId)) @

parsedOrdinal ← decimal.Parse candidateOrdinalText
isOk ← (parsedOrdinal.state ≡ "ok") ∧ (0 ≡ parsedOrdinal.scale)
validOrdinal ← (isOk ◶ ⟨ {0}, {(0 ≤ parsedOrdinal.coefficient) ∧ candidateOrdinalText ≡ •Fmt parsedOrdinal.coefficient} ⟩) @
{𝕊⋄Fail ⟨"candidate_ordinal_invalid", "candidate ordinal must be a canonical nonnegative exact integer"⟩}⍟(¬ validOrdinal) @
candidateOrdinal ← parsedOrdinal.coefficient

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
{𝕊⋄Fail ⟨"native_candidate_count_invalid", "written Journal transaction count does not match the pre-write candidate ordinal plus one"⟩}⍟((candidateOrdinal + 1) ≢ ≠ parsed.transactions) @

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

candidate ← candidateOrdinal ⊑ parsed.transactions

priorTransactions ← candidateOrdinal ↑ parsed.transactions
priorEndLine ← (0 < candidateOrdinal) ◶ ⟨0, {⌈´ {𝕩.source_end_line}¨ priorTransactions}⟩ @
{𝕊⋄Fail ⟨"native_candidate_boundary_invalid", "candidate start line must be greater than prior end line"⟩}⍟(candidate.source_start_line ≤ priorEndLine) @

expectedAccounts ← {𝕩.account_key}¨expected
expectedAmounts ← {𝕩.delta}¨expected
actualAccounts ← {𝕩.account_key}¨candidate.postings
actualAmounts ← {𝕩.delta}¨candidate.postings
commoditiesOk ← ∧´ {𝕩.commodity≡"JPY"}¨candidate.postings
postingIndexesOk ← (↕≠candidate.postings) ≡ {𝕩.posting_index}¨candidate.postings
eventMetadataCount ← +´ {𝕩.key ≡ "event-id"}¨ candidate.metadata
identityOk ← (identityMode ≡ "durable") ◶ ⟨
  {(candidate.identity_kind ≡ "physical_fallback") ∧ 0 = eventMetadataCount},
  {(candidate.identity_kind ≡ "durable") ∧ (candidate.source_event_id ≡ eventId) ∧ 1 = eventMetadataCount}
⟩ @
candidateOk ← (candidate.date≡dateText) ∧ (candidate.description≡description) ∧ identityOk ∧ (candidate.status_marker='*') ∧ (candidate.layer_name≡"actual") ∧ ((≠candidate.postings)=≠expected) ∧ postingIndexesOk ∧ (actualAccounts≡expectedAccounts) ∧ (actualAmounts≡expectedAmounts) ∧ commoditiesOk
{𝕊⋄Fail ⟨"native_candidate_mismatch", "written candidate does not exactly equal previewed candidate"⟩}⍟(¬candidateOk) @

identityToken ← (identityMode ≡ "durable") ◶ ⟨{"-"}, {eventId}⟩ @
•Out "OK"∾tab∾"NATIVE_JOURNAL_CANDIDATE"∾tab∾identityMode∾tab∾identityToken∾tab∾(•Fmt candidateOrdinal)∾tab∾(•Fmt ≠candidate.postings)
