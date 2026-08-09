# Prepare one canonical budget.journal movement append.
# The complete candidate is re-admitted before any shell writer may publish it.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
rootAdmission ← •Import "../src/ledger/canonical_journal_root_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_journal_admission.bqn"
validate ← •Import "validate.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
lf ← @+10
empty ← ⟨⟩

Fail ← {𝕊 msg:
  •Out "ERROR"∾tab∾msg
  •Exit 1
}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Unique ← {𝕊 xs: ((xs⊐xs)=↕≠xs)/xs}

{𝕊:Fail "usage: budget_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> <currency-or-empty> [meta...]"}⍟(7>≠args) @
baseDir ← 0⊑args
dateVal ← 1⊑args
memoVal ← 2⊑args
fromVal ← 3⊑args
toVal ← 4⊑args
amountVal ← 5⊑args
explicitCurrency ← 6⊑args
metaTokens ← 7↓args

accountResult ← accountSource.Load baseDir
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @
accounts ← accountResult.accounts

ResolveBudgetAccount ← {𝕊 account:
  mask ← account⊸≡¨accounts.key
  {𝕊:Fail ("account must resolve exactly once in accounts.journal: "∾account)}⍟(1≠+´mask) @
  index ← ⊑mask/↕≠mask
  {𝕊:Fail ("Budget movement account is not type Budget: "∾account)}⍟((index⊑accounts.role)≢"budget") @
  index
}
fromIndex ← ResolveBudgetAccount fromVal
toIndex ← ResolveBudgetAccount toVal
{𝕊:Fail "Budget movement from/to Accounts must differ"}⍟(fromVal≡toVal) @
fromCommodity ← fromIndex⊑accounts.currency
toCommodity ← toIndex⊑accounts.currency
knownCommodities ← (0<≠¨fromCommodity‿toCommodity)/(fromCommodity‿toCommodity)
uniqueKnown ← Unique knownCommodities

currency ← explicitCurrency
{𝕊:
  {𝕊:Fail "--currency is required when selected Budget Accounts do not imply exactly one Commodity"}⍟(1≠≠uniqueKnown) @
  currency↩⊑uniqueKnown
}⍟(0=≠currency) @
policy ← setup.Policy currency
{𝕊:Fail ("unsupported currency: "∾currency)}⍟(policy.state≢"ok") @
{𝕊:Fail ("from Budget Account Commodity differs from selected currency: "∾fromVal)}⍟((0<≠fromCommodity) ∧ fromCommodity≢currency) @
{𝕊:Fail ("to Budget Account Commodity differs from selected currency: "∾toVal)}⍟((0<≠toCommodity) ∧ toCommodity≢currency) @

dateCheck ← validate.ValidateDate dateVal
{𝕊:Fail 1⊑dateCheck}⍟(¬0⊑dateCheck) @
memoCheck ← validate.ValidateNoTabNewline "memo"‿memoVal
{𝕊:Fail 1⊑memoCheck}⍟(¬0⊑memoCheck) @
{𝕊:Fail "Budget movement description must be nonempty in canonical budget.journal"}⍟(0=≠memoVal) @
amountCheck ← validate.ValidateExactAmountForCurrency currency‿amountVal
{𝕊:Fail 1⊑amountCheck}⍟(¬0⊑amountCheck) @
parsedAmount ← (•Import "../src/ledger/exact_decimal.bqn").Parse amountVal
{𝕊:Fail "Budget movement amount must be positive"}⍟(parsedAmount.coefficient≤0) @
metaCheck ← validate.ValidateMeta metaTokens
{𝕊:Fail 1⊑metaCheck}⍟(¬0⊑metaCheck) @
currencyMetaCheck ← validate.ValidateNoCurrencyMeta metaTokens
{𝕊:Fail 1⊑currencyMetaCheck}⍟(¬0⊑currencyMetaCheck) @

metadata ← empty
{𝕊 token:
  equalMask ← '='=token
  {𝕊:Fail "each --meta item must contain exactly one key=value pair"}⍟(1≠+´equalMask) @
  p ← ⊑equalMask/↕≠token
  key ← p↑token
  value ← (p+1)↓token
  metadata∾↩⟨{key⇐key,value⇐value}⟩
}¨metaTokens
metadataKeys ← {𝕩.key}¨metadata
{𝕊:Fail "metadata keys must be unique"}⍟((≠metadataKeys)≠≠⍷metadataKeys) @

raw ← loader.ReadRaw Join ⟨baseDir,canonical.budget⟩
rootResult ← rootAdmission.Admit ⟨raw,canonical.accounts⟩
{𝕊:Fail "canonical budget.journal root include topology rejected"}⍟(rootResult.state≢"ok") @
existing ← budgetAdmission.Admit ⟨raw,accounts,setup.registry⟩
{𝕊:Fail "existing canonical budget.journal rejected"}⍟(existing.state≢"ok") @

metadataLines ← {"    ; "∾𝕩.key∾": "∾𝕩.value}¨metadata
blockLines ← ⟨dateVal∾" "∾memoVal⟩∾metadataLines∾⟨
  "  "∾fromVal∾"  -"∾amountVal∾" "∾currency,
  "  "∾toVal∾"  "∾amountVal∾" "∾currency
⟩
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
{𝕊:Fail "proposed budget.journal root include topology rejected"}⍟(proposedRoot.state≢"ok") @
proposed ← budgetAdmission.Admit ⟨proposedRaw,accounts,setup.registry⟩
{𝕊:
  diagnostic ← ⊑proposed.diagnostics
  Fail ("proposed canonical Budget movement rejected: "∾diagnostic.code∾" at line "∾•Fmt diagnostic.line)
}⍟(proposed.state≢"ok") @
candidateOrdinal ← ≠existing.transactions
{𝕊:Fail "proposed budget.journal must contain exactly one new Budget movement"}⍟((candidateOrdinal+1)≠≠proposed.transactions) @
candidate ← candidateOrdinal⊑proposed.transactions
candidateAccounts ← {𝕩.account_key}¨candidate.postings
candidateAmounts ← {𝕩.amount_text}¨candidate.postings
candidateCommodities ← {𝕩.commodity}¨candidate.postings
candidateOk ← (candidate.date≡dateVal) ∧ (candidate.description≡memoVal) ∧ (candidateAccounts≡fromVal‿toVal) ∧ (candidateAmounts≡("-"∾amountVal)‿amountVal) ∧ ∧´{𝕩≡currency}¨candidateCommodities
{𝕊:Fail "parsed Budget candidate does not exactly match rendered movement intent"}⍟(¬candidateOk) @

•Out "OK"∾tab∾"APPEND"∾tab∾canonical.budget
•Out transportPayload