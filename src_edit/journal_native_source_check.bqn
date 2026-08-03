# journal_native_source_check.bqn
# Mandatory post-write validator for one explicit supported-currency Journal candidate.

admission ← •Import "../src/ledger/journal_complete_admission.bqn"
editorAccounts ← •Import "../src/application/editor_accounts.bqn"
loader ← •Import "../src/application/source_io.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

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
{𝕊⋄Fail ⟨"usage", "expected BASE TARGET DATE DESCRIPTION IDENTITY_MODE EVENT_ID CANDIDATE_ORDINAL [currency=CODE] and at least two postings"⟩}⍟(9 > ≠ args) @
base ← 0⊑args
target ← 1⊑args
dateText ← 2⊑args
description ← 3⊑args
identityMode ← 4⊑args
eventId ← 5⊑args
candidateOrdinalText ← 6⊑args
argIndex ← 7
currency ← "JPY"
currencyMarker ← argIndex ⊑ args
{𝕊: currency ↩ 9 ↓ currencyMarker ⋄ argIndex +↩ 1}⍟("currency=" ≡ 9 ↑ currencyMarker) @
postingArgs ← argIndex↓args
policy ← setup.Policy currency
{𝕊⋄Fail ⟨"currency_unsupported", "transaction currency must be admitted by registry"⟩}⍟(policy.state≢"ok") @

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
  valid ← parsedAmount.state≡"ok"
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting amount is invalid"⟩}⍟(¬valid) @
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting precision exceeds currency policy"⟩}⍟((0≤policy.max_fraction_digits) ∧ parsedAmount.scale>policy.max_fraction_digits) @
  coefficient ← (1-2×negative) × parsedAmount.coefficient
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting amount is zero"⟩}⍟(0=coefficient) @
  expected ∾↩ ⟨{account_key⇐account, amount_text⇐amountText, source_coefficient⇐coefficient, source_scale⇐parsedAmount.scale, normalized_coefficient⇐0, commodity⇐currency}⟩
}¨postingArgs
{𝕊⋄Fail ⟨"expected_posting_invalid", "expected candidate requires at least two postings"⟩}⍟(2>≠expected) @
calculationScale ← ⌈´ {𝕩.source_scale}¨ expected
Normalize ← {𝕊 posting:
  zeros ← calculationScale-posting.source_scale
  magnitude ← decimal.Parse ((•Fmt |posting.source_coefficient)∾zeros⥊'0')
  {𝕊⋄Fail ⟨"expected_posting_invalid", "expected posting cannot normalize exactly"⟩}⍟(magnitude.state≢"ok") @
  normalized ← (1-2×posting.source_coefficient<0)×magnitude.coefficient
  {account_key⇐posting.account_key, amount_text⇐posting.amount_text, source_coefficient⇐posting.source_coefficient, source_scale⇐posting.source_scale, normalized_coefficient⇐normalized, commodity⇐posting.commodity}
}
expected ↩ Normalize¨expected
{𝕊⋄Fail ⟨"expected_posting_invalid", "expected candidate requires balanced postings"⟩}⍟(0≠+´{𝕩.normalized_coefficient}¨expected) @

resolved ← editorAccounts.Require loader.ReadLines (base∾"/accounts.tsv")
raw ← loader.ReadRaw target
admitted ← admission.Admit ⟨raw,resolved,setup.registry⟩
{𝕊⋄Fail ⟨"native_journal_invalid", "full written native Journal failed complete-source admission"⟩}⍟(admitted.state≢"ok") @
{𝕊⋄Fail ⟨"native_candidate_count_invalid", "written Journal transaction count does not match the pre-write candidate ordinal plus one"⟩}⍟((candidateOrdinal + 1) ≢ ≠ admitted.transactions) @

candidate ← candidateOrdinal ⊑ admitted.transactions
priorTransactions ← candidateOrdinal ↑ admitted.transactions
priorEndLine ← (0 < candidateOrdinal) ◶ ⟨0, {⌈´ {𝕩.source_end_line}¨ priorTransactions}⟩ @
{𝕊⋄Fail ⟨"native_candidate_boundary_invalid", "candidate start line must be greater than prior end line"⟩}⍟(candidate.source_start_line ≤ priorEndLine) @

expectedAccounts ← {𝕩.account_key}¨expected
expectedAmounts ← {𝕩.normalized_coefficient}¨expected
actualAccounts ← {𝕩.account_key}¨candidate.postings
actualAmounts ← {𝕩.normalized_coefficient}¨candidate.postings
commoditiesOk ← ∧´ {𝕩.commodity≡currency}¨candidate.postings
postingIndexesOk ← (↕≠candidate.postings) ≡ {𝕩.posting_index}¨candidate.postings
eventMetadataCount ← +´ {𝕩.key ≡ "event-id"}¨ candidate.metadata
hasPlanLink ← ∨´ 0 ∾ {𝕩.key ≡ "plan-id"}¨ candidate.metadata
isReverse ← "[reverse]" ≡ 9 ↑ candidate.description
derivedTransaction ← hasPlanLink ∨ isReverse
effectiveDurable ← (identityMode ≡ "durable") ∧ ¬ derivedTransaction
identityOk ← effectiveDurable ◶ ⟨
  {(candidate.identity_kind ≡ "physical_fallback") ∧ 0 = eventMetadataCount},
  {(candidate.identity_kind ≡ "durable") ∧ (candidate.source_event_id ≡ eventId) ∧ 1 = eventMetadataCount}
⟩ @
candidateOk ← (candidate.date≡dateText) ∧ (candidate.description≡description) ∧ identityOk ∧ (candidate.status_marker='*') ∧ (candidate.layer_name≡"actual") ∧ (candidate.domain≡currency) ∧ (candidate.calculation_scale=calculationScale) ∧ ((≠candidate.postings)=≠expected) ∧ postingIndexesOk ∧ (actualAccounts≡expectedAccounts) ∧ (actualAmounts≡expectedAmounts) ∧ commoditiesOk
{𝕊⋄Fail ⟨"native_candidate_mismatch", "written candidate does not exactly equal previewed candidate"⟩}⍟(¬candidateOk) @

identityToken ← effectiveDurable ◶ ⟨{"-"}, {eventId}⟩ @
•Out "OK"∾tab∾"NATIVE_JOURNAL_CANDIDATE"∾tab∾identityMode∾tab∾identityToken∾tab∾(•Fmt candidateOrdinal)∾tab∾(•Fmt ≠candidate.postings)
