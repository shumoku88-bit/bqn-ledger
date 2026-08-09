# Prepare one canonical plan.journal transaction append.
# The complete candidate is re-admitted before any shell writer may publish it.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
rootAdmission ← •Import "../src/ledger/canonical_journal_root_admission.bqn"
planAdmission ← •Import "../src/ledger/plan_journal_admission.bqn"
validate ← •Import "validate.bqn"
plan_id ← •Import "plan_id.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
actualSource ← •Import "../src/application/editor_actual.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
lf ← @+10
empty ← ⟨⟩

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Unique ← {𝕊 xs: ((xs⊐xs)=↕≠xs)/xs}

{𝕊:Fail "usage: plan_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> <planID-or-empty> <currency-or-empty> [meta...]"}⍟(8>≠args) @
baseDir ← 0⊑args
dateVal ← 1⊑args
memoVal ← 2⊑args
fromVal ← 3⊑args
toVal ← 4⊑args
amountVal ← 5⊑args
planIdArg ← 6⊑args
explicitCurrency ← 7⊑args
metaTokens ← 8↓args

accountResult ← accountSource.Load baseDir
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @
accounts ← accountResult.accounts

ResolveAccount ← {𝕊 account:
  mask ← account⊸≡¨accounts.key
  {𝕊:Fail ("account must resolve exactly once in accounts.journal: "∾account)}⍟(1≠+´mask) @
  ⊑mask/↕≠mask
}
fromIndex ← ResolveAccount fromVal
toIndex ← ResolveAccount toVal
fromCommodity ← fromIndex⊑accounts.currency
toCommodity ← toIndex⊑accounts.currency
knownCommodities ← (0<≠¨fromCommodity‿toCommodity)/(fromCommodity‿toCommodity)
uniqueKnown ← Unique knownCommodities

currency ← explicitCurrency
{𝕊:
  {𝕊:Fail "--currency is required when selected Accounts do not imply exactly one Commodity"}⍟(1≠≠uniqueKnown) @
  currency↩⊑uniqueKnown
}⍟(0=≠currency) @
policy ← setup.Policy currency
{𝕊:Fail ("unsupported currency: "∾currency)}⍟(policy.state≢"ok") @
{𝕊:Fail ("from account Commodity differs from selected currency: "∾fromVal)}⍟((0<≠fromCommodity) ∧ fromCommodity≢currency) @
{𝕊:Fail ("to account Commodity differs from selected currency: "∾toVal)}⍟((0<≠toCommodity) ∧ toCommodity≢currency) @

dateCheck ← validate.ValidateDate dateVal
{𝕊:Fail 1⊑dateCheck}⍟(¬0⊑dateCheck) @
memoCheck ← validate.ValidateNoTabNewline "memo"‿memoVal
{𝕊:Fail 1⊑memoCheck}⍟(¬0⊑memoCheck) @
{𝕊:Fail "Plan description must be nonempty in canonical plan.journal"}⍟(0=≠memoVal) @
amountCheck ← validate.ValidateExactAmountForCurrency currency‿amountVal
{𝕊:Fail 1⊑amountCheck}⍟(¬0⊑amountCheck) @
metaCheck ← validate.ValidateMeta metaTokens
{𝕊:Fail 1⊑metaCheck}⍟(¬0⊑metaCheck) @
currencyMetaCheck ← validate.ValidateNoCurrencyMeta metaTokens
{𝕊:Fail 1⊑currencyMetaCheck}⍟(¬0⊑currencyMetaCheck) @

aliases ← ⟨
  "due_on","txn_id","trip_id","execution_envelope","allocation_id","agreement_id",
  "income_budget","daily_target_id","reservation_id","reservation_amount","reservation_commodity"
⟩
nativeAliases ← ⟨
  "due-on","txn-id","trip-id","execution-envelope","allocation-id","agreement-id",
  "income-budget","daily-target-id","reservation-id","reservation-amount","reservation-commodity"
⟩
NormalizeKey ← {𝕊 key:
  result ← key
  i ← ⊑aliases⊐⟨key⟩
  {𝕊:result↩i⊑nativeAliases}⍟(i<≠aliases) @
  result
}
allowedMeta ← ⟨
  "action","receipt-id","tax","biz","invoice","note","due-on","receipt","txn-id",
  "party","trip-id","payment","cashflow","income-budget","recur","series",
  "execution-envelope","allocation-id","agreement-id","daily-target-id",
  "reservation-id","reservation-amount","reservation-commodity"
⟩
metadata ← empty
{𝕊 token:
  equalMask ← '='=token
  {𝕊:Fail "each --meta item must contain exactly one key=value pair"}⍟(1≠+´equalMask) @
  p ← ⊑equalMask/↕≠token
  key ← NormalizeKey p↑token
  value ← (p+1)↓token
  {𝕊:Fail "--meta plan_id/plan-id is not allowed; use --id"}⍟(key≡"plan-id") @
  {𝕊:Fail ("metadata key is not admitted for canonical Plan: "∾key)}⍟(¬∨´0∾key⊸≡¨allowedMeta) @
  metadata∾↩⟨{key⇐key,value⇐value}⟩
}¨metaTokens
metadataKeys ← {𝕩.key}¨metadata
{𝕊:Fail "metadata keys must be unique after canonical key normalization"}⍟((≠metadataKeys)≠≠⍷metadataKeys) @

raw ← loader.ReadRaw Join ⟨baseDir,canonical.plan⟩
rootResult ← rootAdmission.Admit ⟨raw,canonical.accounts⟩
{𝕊:Fail "canonical plan.journal root include topology rejected"}⍟(rootResult.state≢"ok") @
existing ← planAdmission.Admit ⟨raw,accounts,setup.registry⟩
{𝕊:Fail "existing canonical plan.journal rejected"}⍟(existing.state≢"ok") @
planIDs ← {𝕩.plan_id}¨existing.transactions
completionIDs ← {𝕩.plan_id}¨actualSource.CompletionEvidence baseDir
existingIDs ← Unique (0<≠¨planIDs∾completionIDs)/(planIDs∾completionIDs)

finalPlanID ← ""
{𝕊:
  idCheck ← plan_id.ValidatePlanIDFormat planIdArg
  {𝕊:Fail ("invalid plan_id: "∾planIdArg)}⍟(¬0⊑idCheck) @
  {𝕊:Fail ("plan_id already exists: "∾planIdArg)}⍟(∨´0∾planIdArg⊸≡¨existingIDs) @
  finalPlanID↩planIdArg
}⍟(0<≠planIdArg) @
{𝕊:
  finalPlanID↩plan_id.GeneratePlanID {
    date⇐dateVal,memo⇐memoVal,meta⇐metaTokens,existing_ids⇐existingIDs
  }
}⍟(0=≠planIdArg) @

metadataLines ← {"  ; "∾𝕩.key∾": "∾𝕩.value}¨metadata
blockLines ← ⟨dateVal∾" "∾memoVal,"  ; plan-id: "∾finalPlanID⟩
blockLines ∾↩ metadataLines
blockLines ∾↩ ⟨"  "∾fromVal∾"  -"∾amountVal∾" "∾currency,"  "∾toVal∾"  "∾amountVal∾" "∾currency⟩
block ← ⊑blockLines
{𝕊 line:block∾↩lf∾line}¨1↓blockLines

rawCount ← ≠raw
endsOne ← (0<rawCount) ∧ lf=¯1⊑raw
endsTwo ← (1<rawCount) ∧ (lf=¯1⊑raw) ∧ lf=¯2⊑raw
transportPayload ← block
{𝕊:transportPayload↩lf∾block}⍟(¬endsTwo) @
transportBase ← raw
{𝕊:transportBase↩raw∾lf}⍟(¬endsOne) @
proposedRaw ← transportBase∾transportPayload∾lf

proposedRoot ← rootAdmission.Admit ⟨proposedRaw,canonical.accounts⟩
{𝕊:Fail "proposed plan.journal root include topology rejected"}⍟(proposedRoot.state≢"ok") @
proposed ← planAdmission.Admit ⟨proposedRaw,accounts,setup.registry⟩
{𝕊:
  diagnostic ← ⊑proposed.diagnostics
  Fail ("proposed canonical Plan rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
}⍟(proposed.state≢"ok") @
candidateOrdinal ← ≠existing.transactions
{𝕊:Fail "proposed plan.journal must contain exactly one new Plan transaction"}⍟((candidateOrdinal+1)≠≠proposed.transactions) @
candidate ← candidateOrdinal⊑proposed.transactions
candidateAccounts ← {𝕩.account_key}¨candidate.postings
candidateAmounts ← {𝕩.amount_text}¨candidate.postings
candidateCommodities ← {𝕩.commodity}¨candidate.postings
planIdCount ← +´{"plan-id"≡𝕩.key}¨candidate.metadata
MetadataPreserved ← {𝕊 item:1=+´{(𝕩.key≡item.key) ∧ 𝕩.value≡item.value}¨candidate.metadata}
metadataOk ← ∧´1∾MetadataPreserved¨metadata
candidateOk ←
  (candidate.date≡dateVal) ∧ (candidate.description≡memoVal) ∧ (candidate.status_marker≡"") ∧
  (candidate.plan_id≡finalPlanID) ∧ (candidate.domain≡currency) ∧
  (candidateAccounts≡fromVal‿toVal) ∧ (candidateAmounts≡("-"∾amountVal)‿amountVal) ∧
  (∧´{𝕩≡currency}¨candidateCommodities) ∧ (1=planIdCount) ∧ metadataOk
{𝕊:Fail "parsed Plan candidate does not exactly match rendered intent"}⍟(¬candidateOk) @

•Out "OK"∾tab∾"APPEND"∾tab∾canonical.plan
•Out transportPayload