# journal_block_add_cmd.bqn
# Semantic owner for one explicit native actual-layer Journal transaction append.

parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"
decimal ← •Import "../src_next/exact_decimal.bqn"
dates ← •Import "../src_next/date.bqn"

args ← •args
tab ← @+9
lf ← @+10
space ← @+32
empty ← ⟨⟩

Fail ← {𝕊 code‿message:
  •Out "ERROR" ∾ tab ∾ code ∾ tab ∾ message
  •Exit 1
}

TrimLeft ← {𝕊 xs: (+´ ∧` (xs = space)) ↓ xs}
TrimRight ← {𝕊 xs: ((≠ xs) - +´ ∧` ((⌽ xs) = space)) ↑ xs}
Trim ← {TrimRight TrimLeft 𝕩}
UnsafeText ← {𝕊 text:
  controls ← ((@+0) + ↕32) ∾ ⟨@+127⟩
  ∨´ 0 ∾ text ∊ controls
}
{𝕊⋄Fail ⟨"usage", "expected BASE TARGET DATE DESCRIPTION EVENT_ID POSTING_COUNT postings and optional metadata"⟩}⍟(8 > ≠ args) @
base ← 0 ⊑ args
target ← 1 ⊑ args
dateText ← 2 ⊑ args
description ← 3 ⊑ args
eventId ← 4 ⊑ args
postingCountText ← 5⊑args
postingCount ← •BQN postingCountText
{𝕊⋄Fail ⟨"posting_count_invalid", "posting count must be at least two"⟩}⍟((postingCount<2)∨postingCount≢⌊postingCount) @
{𝕊⋄Fail ⟨"posting_count_invalid", "posting count exceeds supplied arguments"⟩}⍟((6+postingCount)>≠args) @
postingArgs ← postingCount↑6↓args
metadataArgs ← (6+postingCount)↓args

{𝕊⋄Fail ⟨"date_invalid", "date must be a valid YYYY-MM-DD calendar date"⟩}⍟(¬ dates.IsValidDateText dateText) @
{𝕊⋄Fail ⟨"description_invalid", "description must be nonempty and must not contain unsafe control input"⟩}⍟((0 = ≠ Trim description) ∨ (UnsafeText description) ∨ description ≢ Trim description) @
{𝕊⋄Fail ⟨"event_id_invalid", "event-id must be nonempty and must not contain unsafe control input"⟩}⍟((0 = ≠ Trim eventId) ∨ (UnsafeText eventId) ∨ eventId ≢ Trim eventId) @
{𝕊⋄Fail ⟨"posting_count_invalid", "at least two --posting values are required"⟩}⍟(2 > ≠ postingArgs) @

postings ← empty
{𝕊 text:
  equalMask ← '=' = text
  {𝕊⋄Fail ⟨"posting_shape_invalid", "each posting must contain exactly one ACCOUNT=SIGNED_INTEGER pair"⟩}⍟(1 ≠ +´ equalMask) @
  equalIndex ← ⊑ equalMask / ↕ ≠ text
  account ← equalIndex ↑ text
  amountText ← (equalIndex + 1) ↓ text
  {𝕊⋄Fail ⟨"posting_shape_invalid", "posting account and amount must both be nonempty"⟩}⍟((0 = ≠ account) ∨ 0 = ≠ amountText) @
  {𝕊⋄Fail ⟨"posting_account_invalid", "posting account contains unsafe control input"⟩}⍟(UnsafeText account) @
  negative ← '-' = ⊑ (amountText ∾ "0")
  unsigned ← negative ↓ amountText
  parsedAmount ← decimal.Parse unsigned
  exactInteger ← (parsedAmount.state ≡ "ok") ∧ (0 = parsedAmount.scale) ∧ unsigned ≡ •Fmt parsedAmount.coefficient
  {𝕊⋄Fail ⟨"posting_amount_invalid", "posting amount must be a canonical nonzero exact integer"⟩}⍟(¬ exactInteger) @
  delta ← (1 - 2 × negative) × parsedAmount.coefficient
  {𝕊⋄Fail ⟨"posting_amount_zero", "posting amount must be nonzero"⟩}⍟(0 = delta) @
  canonical ← negative ◶ ⟨{•Fmt parsedAmount.coefficient}, {"-" ∾ •Fmt parsedAmount.coefficient}⟩ @
  {𝕊⋄Fail ⟨"posting_amount_invalid", "posting amount must be a canonical signed integer"⟩}⍟(amountText ≢ canonical) @
  postings ∾↩ ⟨{account_key⇐account, amount_text⇐amountText, delta⇐delta, commodity⇐"JPY"}⟩
}¨ postingArgs
{𝕊⋄Fail ⟨"event_unbalanced", "signed posting amounts must sum exactly to zero"⟩}⍟(0 ≠ +´ {𝕩.delta}¨ postings) @

legacyKeys ← ⟨"tax","biz","invoice","note","due_on","receipt","txn_id","party","plan_id","cashflow","currency","income_budget","recur","series"⟩
nativeKeys ← ⟨"tax","biz","invoice","note","due-on","receipt","txn-id","party","plan-id","cashflow","currency","income-budget","recur","series"⟩
metadata ← empty
{𝕊 text:
  equalMask ← '='=text
  {𝕊⋄Fail ⟨"metadata_shape_invalid", "each metadata item must contain exactly one key=value pair"⟩}⍟(1≠+´equalMask) @
  equalIndex ← ⊑equalMask/↕≠text
  key ← equalIndex↑text ⋄ value ← (equalIndex+1)↓text
  keyIndex ← ⊑legacyKeys⊐⟨key⟩
  {𝕊⋄Fail ⟨"metadata_key_invalid", "metadata key is not supported by the native Journal profile"⟩}⍟(keyIndex=≠legacyKeys) @
  {𝕊⋄Fail ⟨"metadata_value_invalid", "metadata value must be nonempty and structurally safe"⟩}⍟((0=≠value)∨(UnsafeText value)∨(value≢Trim value)) @
  metadata ∾↩ ⟨{key⇐keyIndex⊑nativeKeys,value⇐value}⟩
}¨metadataArgs
metadataKeys ← {𝕩.key}¨metadata
{𝕊⋄Fail ⟨"metadata_duplicate", "metadata keys must be unique"⟩}⍟((≠metadataKeys)≠≠⍷metadataKeys) @

raw ← loader.ReadRaw target
existing ← parser.ParseWithProfile ⟨raw,"historical_external_plan"⟩
{𝕊⋄Fail ⟨"existing_journal_invalid", "existing complete Journal does not satisfy the supported profile"⟩}⍟(existing.state ≢ "ok") @
{𝕊⋄Fail ⟨"event_id_duplicate", "event-id already exists in the complete Journal"⟩}⍟(∨´ 0 ∾ {𝕩.source_event_id ≡ eventId}¨ existing.transactions) @

resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
{𝕊 posting:
  registryMask ← posting.account_key⊸≡¨ resolved.accounts
  {𝕊⋄Fail ⟨"posting_account_unresolved", "posting account must resolve exactly once in accounts.tsv"⟩}⍟(1 ≠ +´ registryMask) @
  idx ← ⊑ registryMask / ↕ ≠ registryMask
  {𝕊⋄Fail ⟨"posting_currency_invalid", "every resolved posting account must use JPY"⟩}⍟("JPY" ≢ idx ⊑ resolved.currencies) @
}¨ postings

postingLines ← {"    " ∾ 𝕩.account_key ∾ "    " ∾ 𝕩.amount_text ∾ " JPY"}¨ postings
metadataLines ← {"    ; "∾𝕩.key∾": "∾𝕩.value}¨metadata
blockLines ← ⟨dateText ∾ " * " ∾ description, "    ; event-id: " ∾ eventId, "    ; layer: actual"⟩ ∾ metadataLines ∾ postingLines
block ← ⊑ blockLines
{𝕊 line: block ∾↩ lf ∾ line}¨ 1 ↓ blockLines

rawCount ← ≠ raw
endsOne ← (0 < rawCount) ∧ lf = ¯1 ⊑ raw
endsTwo ← (1 < rawCount) ∧ (lf = ¯1 ⊑ raw) ∧ lf = ¯2 ⊑ raw
semanticSeparator ← endsTwo ◶ ⟨{endsOne ◶ ⟨{lf ∾ lf}, {lf}⟩ @}, {""}⟩ @
transportPrefixCount ← endsTwo ◶ ⟨{1}, {0}⟩ @
proposedRaw ← raw ∾ semanticSeparator ∾ block ∾ lf
proposed ← parser.ParseWithProfile ⟨proposedRaw,"historical_external_plan"⟩
{𝕊⋄Fail ⟨"proposed_journal_invalid", "exact proposed complete Journal does not satisfy the supported profile"⟩}⍟(proposed.state ≢ "ok") @

checked ← adapter.Build ⟨proposed.transactions, resolved, dateText⟩
{𝕊⋄Fail ⟨"posting_ir_invalid", "checked Stage 2A Posting IR rejected the proposed complete Journal"⟩}⍟(checked.state ≢ "ok") @

matching ← ({(𝕩.identity_kind ≡ "durable") ∧ 𝕩.source_event_id ≡ eventId}¨ proposed.transactions) / proposed.transactions
{𝕊⋄Fail ⟨"candidate_identity_invalid", "candidate durable event must exist exactly once in proposed Journal"⟩}⍟(1 ≠ ≠ matching) @
candidate ← ⊑ matching
candidateAccounts ← {𝕩.account_key}¨ candidate.postings
candidateAmounts ← {𝕩.delta}¨ candidate.postings
candidateCommodities ← {𝕩.commodity}¨ candidate.postings
expectedAccounts ← {𝕩.account_key}¨ postings
expectedAmounts ← {𝕩.delta}¨ postings
commoditiesOk ← ∧´ {𝕩 ≡ "JPY"}¨ candidateCommodities
candidateOk ← (candidate.date ≡ dateText) ∧ (candidate.description ≡ description) ∧ (candidate.source_event_id ≡ eventId) ∧ (candidate.layer_name ≡ "actual") ∧ (candidate.status_marker = '*') ∧ (candidateAccounts ≡ expectedAccounts) ∧ (candidateAmounts ≡ expectedAmounts) ∧ commoditiesOk
{𝕊⋄Fail ⟨"candidate_mismatch", "parsed candidate does not exactly match the rendered candidate"⟩}⍟(¬ candidateOk) @

•Out "OK" ∾ tab ∾ "APPEND_BLOCK" ∾ tab ∾ (•Fmt transportPrefixCount) ∾ tab ∾ eventId ∾ tab ∾ (•Fmt ≠ postings)
•Out block
