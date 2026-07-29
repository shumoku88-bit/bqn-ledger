# journal_block_add_cmd.bqn
# Semantic owner for one explicit native actual-layer Journal transaction append.

admission ← •Import "../src/ledger/journal_complete_admission.bqn"
carrier ← •Import "../src_next/journal_currency_proof_carrier_stage2a.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src/application/source_io.bqn"
decimal ← •Import "../src/ledger/exact_decimal.bqn"
setup ← •Import "../src_next/currency_setup.bqn"
dates ← •Import "../src_next/date.bqn"

args ← •args
tab ← @+9
lf ← @+10
space ← @+32
empty ← ⟨⟩
AdmissionAccounts ← {𝕊 resolved: {key⇐resolved.accounts,currency⇐resolved.currencies} }

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
{𝕊⋄Fail ⟨"usage", "expected BASE TARGET DATE DESCRIPTION IDENTITY_MODE EVENT_ID [currency=CODE] POSTING_COUNT postings and optional metadata"⟩}⍟(9 > ≠ args) @
base ← 0 ⊑ args
target ← 1 ⊑ args
dateText ← 2 ⊑ args
description ← 3 ⊑ args
identityMode ← 4 ⊑ args
eventId ← 5 ⊑ args
argIndex ← 6
currency ← "JPY"
currencyMarker ← argIndex ⊑ args
{𝕊: currency ↩ 9 ↓ currencyMarker ⋄ argIndex +↩ 1}⍟("currency=" ≡ 9 ↑ currencyMarker) @
policy ← setup.Policy currency
{𝕊⋄Fail ⟨"currency_unsupported", "transaction currency must be admitted by registry"⟩}⍟(policy.state ≢ "ok") @
postingCountText ← argIndex⊑args
postingCount ← •BQN postingCountText
{𝕊⋄Fail ⟨"posting_count_invalid", "posting count must be at least two"⟩}⍟((postingCount<2)∨postingCount≢⌊postingCount) @
{𝕊⋄Fail ⟨"posting_count_invalid", "posting count exceeds supplied arguments"⟩}⍟((argIndex+1+postingCount)>≠args) @
postingArgs ← postingCount↑(argIndex+1)↓args
metadataArgs ← (argIndex+1+postingCount)↓args

{𝕊⋄Fail ⟨"date_invalid", "date must be a valid YYYY-MM-DD calendar date"⟩}⍟(¬ dates.IsValidDateText dateText) @
{𝕊⋄Fail ⟨"description_invalid", "description must be nonempty and must not contain unsafe control input"⟩}⍟((0 = ≠ Trim description) ∨ (UnsafeText description) ∨ description ≢ Trim description) @
{𝕊⋄Fail ⟨"identity_mode_invalid", "identity mode must be ordinary or durable"⟩}⍟(¬ ((identityMode ≡ "ordinary") ∨ identityMode ≡ "durable")) @
{𝕊⋄Fail ⟨"event_id_unexpected", "ordinary actual must not carry an event-id"⟩}⍟((identityMode ≡ "ordinary") ∧ 0 < ≠ eventId) @
{𝕊⋄Fail ⟨"event_id_invalid", "event-id must be nonempty and must not contain unsafe control input"⟩}⍟((identityMode ≡ "durable") ∧ ((0 = ≠ Trim eventId) ∨ (UnsafeText eventId) ∨ eventId ≢ Trim eventId)) @
{𝕊⋄Fail ⟨"posting_count_invalid", "at least two --posting values are required"⟩}⍟(2 > ≠ postingArgs) @

postings ← empty
{𝕊 text:
  equalMask ← '=' = text
  {𝕊⋄Fail ⟨"posting_shape_invalid", "each posting must contain exactly one ACCOUNT=SIGNED_DECIMAL pair"⟩}⍟(1 ≠ +´ equalMask) @
  equalIndex ← ⊑ equalMask / ↕ ≠ text
  account ← equalIndex ↑ text
  amountText ← (equalIndex + 1) ↓ text
  {𝕊⋄Fail ⟨"posting_shape_invalid", "posting account and amount must both be nonempty"⟩}⍟((0 = ≠ account) ∨ 0 = ≠ amountText) @
  {𝕊⋄Fail ⟨"posting_account_invalid", "posting account contains unsafe control input"⟩}⍟(UnsafeText account) @
  negative ← '-' = ⊑ (amountText ∾ "0")
  unsigned ← negative ↓ amountText
  parsedAmount ← decimal.Parse unsigned
  validAmount ← parsedAmount.state ≡ "ok"
  {𝕊⋄Fail ⟨"posting_amount_invalid", "posting amount must be an explicit canonical signed exact decimal"⟩}⍟(¬ validAmount) @
  {𝕊⋄Fail ⟨"posting_precision_exceeded", "posting precision exceeds transaction currency policy"⟩}⍟((0 ≤ policy.max_fraction_digits) ∧ parsedAmount.scale > policy.max_fraction_digits) @
  coefficient ← (1 - 2 × negative) × parsedAmount.coefficient
  {𝕊⋄Fail ⟨"posting_amount_zero", "posting amount must be nonzero"⟩}⍟(0 = coefficient) @
  leadingZero ← (1 < ≠ unsigned) ∧ ('0' = ⊑ unsigned) ∧ ('.' ≠ 1 ⊑ unsigned ∾ " ")
  {𝕊⋄Fail ⟨"posting_amount_invalid", "posting amount must not contain a leading zero or explicit plus sign"⟩}⍟leadingZero @
  postings ∾↩ ⟨{account_key⇐account, amount_text⇐amountText, source_coefficient⇐coefficient, source_scale⇐parsedAmount.scale, normalized_coefficient⇐0, commodity⇐currency}⟩
}¨ postingArgs
calculationScale ← ⌈´ {𝕩.source_scale}¨ postings
NormalizePosting ← {𝕊 posting:
  zeros ← calculationScale - posting.source_scale
  magnitude ← decimal.Parse ((•Fmt | posting.source_coefficient) ∾ zeros ⥊ '0')
  {𝕊⋄Fail ⟨"posting_amount_invalid", "posting amount cannot normalize exactly"⟩}⍟(magnitude.state ≢ "ok") @
  normalized ← (1 - 2 × posting.source_coefficient < 0) × magnitude.coefficient
  {account_key⇐posting.account_key, amount_text⇐posting.amount_text, source_coefficient⇐posting.source_coefficient, source_scale⇐posting.source_scale, normalized_coefficient⇐normalized, commodity⇐posting.commodity}
}
postings ↩ NormalizePosting¨ postings
{𝕊⋄Fail ⟨"event_unbalanced", "normalized posting amounts must sum exactly to zero"⟩}⍟(0 ≠ +´ {𝕩.normalized_coefficient}¨ postings) @

legacyKeys ← ⟨"tax","biz","invoice","note","due_on","receipt","txn_id","party","plan_id","trip_id","payment","cashflow","currency","recur","series"⟩
nativeKeys ← ⟨"tax","biz","invoice","note","due-on","receipt","txn-id","party","plan-id","trip-id","payment","cashflow","currency","recur","series"⟩
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
{𝕊⋄Fail ⟨"metadata_payment_invalid", "payment metadata must be cash, card, or debit"⟩}⍟(∨´ 0 ∾ {(𝕩.key ≡ "payment") ∧ ¬ ∨´ 𝕩.value⊸≡¨ "cash"‿"card"‿"debit"}¨ metadata) @
{𝕊⋄Fail ⟨"ordinary_plan_link_invalid", "ordinary actual cannot carry plan-id; use a durable plan completion path"⟩}⍟((identityMode ≡ "ordinary") ∧ ∨´ 0 ∾ "plan-id"⊸≡¨ metadataKeys) @

resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
raw ← loader.ReadRaw target
existing ← admission.Admit ⟨raw,AdmissionAccounts resolved,setup.registry_value⟩
{𝕊⋄Fail ⟨"existing_journal_invalid", "existing complete Journal does not satisfy supported-currency admission"⟩}⍟(existing.state ≢ "ok") @
candidateOrdinal ← ≠ existing.transactions
{𝕊⋄Fail ⟨"event_id_duplicate", "event-id already exists in the complete Journal"⟩}⍟((identityMode ≡ "durable") ∧ ∨´ 0 ∾ {𝕩.source_event_id ≡ eventId}¨ existing.transactions) @

{𝕊 posting:
  registryMask ← posting.account_key⊸≡¨ resolved.accounts
  {𝕊⋄Fail ⟨"posting_account_unresolved", "posting account must resolve exactly once in accounts.tsv"⟩}⍟(1 ≠ +´ registryMask) @
  idx ← ⊑ registryMask / ↕ ≠ registryMask
  {𝕊⋄Fail ⟨"posting_currency_invalid", "resolved posting account currency must equal transaction currency"⟩}⍟(currency ≢ idx ⊑ resolved.currencies) @
}¨ postings

postingLines ← {"    " ∾ 𝕩.account_key ∾ "    " ∾ 𝕩.amount_text ∾ " " ∾ currency}¨ postings
metadataLines ← {"    ; "∾𝕩.key∾": "∾𝕩.value}¨metadata
headerLines ← (identityMode ≡ "durable") ◶ ⟨{⟨dateText ∾ " * " ∾ description⟩}, {⟨dateText ∾ " * " ∾ description, "    ; event-id: " ∾ eventId⟩}⟩ @
blockLines ← headerLines ∾ metadataLines ∾ postingLines
block ← ⊑ blockLines
{𝕊 line: block ∾↩ lf ∾ line}¨ 1 ↓ blockLines

rawCount ← ≠ raw
endsOne ← (0 < rawCount) ∧ lf = ¯1 ⊑ raw
endsTwo ← (1 < rawCount) ∧ (lf = ¯1 ⊑ raw) ∧ lf = ¯2 ⊑ raw
semanticSeparator ← endsTwo ◶ ⟨{endsOne ◶ ⟨{lf ∾ lf}, {lf}⟩ @}, {""}⟩ @
transportPrefixCount ← endsTwo ◶ ⟨{1}, {0}⟩ @
proposedRaw ← raw ∾ semanticSeparator ∾ block ∾ lf
proposed ← admission.Admit ⟨proposedRaw,AdmissionAccounts resolved,setup.registry_value⟩
{𝕊⋄diagnostic←⊑proposed.diagnostics ⋄ Fail ⟨"proposed_journal_invalid", "exact proposed complete Journal rejected: " ∾ diagnostic.code ∾ " at line " ∾ •Fmt diagnostic.line⟩}⍟(proposed.state ≢ "ok") @
{𝕊⋄Fail ⟨"candidate_count_invalid", "proposed Journal must contain exactly one transaction beyond the existing transaction count"⟩}⍟((candidateOrdinal + 1) ≢ ≠ proposed.transactions) @

checked ← carrier.Build ⟨proposed.transactions, resolved, dateText⟩
{𝕊⋄Fail ⟨"posting_ir_invalid", "Stage 2A currency-proof carrier rejected the proposed complete Journal"⟩}⍟(checked.state ≢ "ok") @

candidate ← candidateOrdinal ⊑ proposed.transactions

priorTransactions ← candidateOrdinal ↑ proposed.transactions
priorEndLine ← (0 < candidateOrdinal) ◶ ⟨0, {⌈´ {𝕩.source_end_line}¨ priorTransactions}⟩ @
{𝕊⋄Fail ⟨"candidate_boundary_invalid", "candidate start line must be greater than prior end line"⟩}⍟(candidate.source_start_line ≤ priorEndLine) @

candidateAccounts ← {𝕩.account_key}¨ candidate.postings
candidateAmounts ← {𝕩.normalized_coefficient}¨ candidate.postings
candidateCommodities ← {𝕩.commodity}¨ candidate.postings
expectedAccounts ← {𝕩.account_key}¨ postings
expectedAmounts ← {𝕩.normalized_coefficient}¨ postings
commoditiesOk ← ∧´ {𝕩 ≡ currency}¨ candidateCommodities
eventMetadataCount ← +´ {𝕩.key ≡ "event-id"}¨ candidate.metadata
MetadataPreserved ← {𝕊 item:
  matches ← ({(𝕩.key ≡ item.key) ∧ 𝕩.value ≡ item.value}¨ candidate.metadata) / candidate.metadata
  1 = ≠ matches
}
metadataOk ← ∧´ 1 ∾ MetadataPreserved¨ metadata
identityOk ← (identityMode ≡ "durable") ◶ ⟨
  {(candidate.identity_kind ≡ "physical_fallback") ∧ 0 = eventMetadataCount},
  {(candidate.identity_kind ≡ "durable") ∧ (candidate.source_event_id ≡ eventId) ∧ 1 = eventMetadataCount}
⟩ @
candidateOk ← (candidate.date ≡ dateText) ∧ (candidate.description ≡ description) ∧ identityOk ∧ metadataOk ∧ (candidate.layer_name ≡ "actual") ∧ (candidate.status_marker = '*') ∧ ((≠ candidate.postings) = ≠ postings) ∧ (candidateAccounts ≡ expectedAccounts) ∧ (candidateAmounts ≡ expectedAmounts) ∧ commoditiesOk
{𝕊⋄Fail ⟨"candidate_mismatch", "parsed candidate does not exactly match the rendered candidate"⟩}⍟(¬ candidateOk) @

identityToken ← (identityMode ≡ "durable") ◶ ⟨{"-"}, {eventId}⟩ @
•Out "OK" ∾ tab ∾ "APPEND_BLOCK" ∾ tab ∾ (•Fmt transportPrefixCount) ∾ tab ∾ identityMode ∾ tab ∾ identityToken ∾ tab ∾ (•Fmt ≠ postings) ∾ tab ∾ (•Fmt candidateOrdinal)
•Out block
