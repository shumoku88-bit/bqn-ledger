# Admit one typed Budget Add intent and prepare a canonical budget.journal block.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
candidate ← •Import "budget_movement_candidate.bqn"
validate ← •Import "validate.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
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
  index ← ⊑mask/↕accounts.count
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

checks ← ⟨
  validate.ValidateDate dateVal,
  validate.ValidateNoTabNewline "memo"‿memoVal,
  validate.ValidateExactAmountForCurrency currency‿amountVal,
  validate.ValidateMeta metaTokens,
  validate.ValidateNoCurrencyMeta metaTokens
⟩
errors ← (¬⊑¨checks)/1⊸⊑¨checks
{𝕊:Fail ⊑errors}⍟(0<≠errors) @
{𝕊:Fail "Budget movement description must be nonempty in canonical budget.journal"}⍟(0=≠memoVal) @

# After generic metadata admission, Budget Add's stricter one-equals contract is
# a regular source-ordered collection: each token maps to exactly one key/value
# record. No mutable accumulator models domain state here.
MetadataRecord ← {𝕊 token:
  equalMask ← '='=token
  {𝕊:Fail "each --meta item must contain exactly one key=value pair"}⍟(1≠+´equalMask) @
  p ← ⊑equalMask/↕≠token
  {key⇐p↑token,value⇐(p+1)↓token}
}
metadata ← MetadataRecord¨metaTokens

raw ← loader.ReadRaw Join ⟨baseDir,canonical.budget⟩
prepared ← candidate.Prepare ⟨raw,accounts,setup.registry,{
  date⇐dateVal,description⇐memoVal,from_account⇐fromVal,to_account⇐toVal,
  amount⇐amountVal,currency⇐currency,metadata⇐metadata
}⟩
{𝕊:Fail prepared.message}⍟(prepared.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾canonical.budget
•Out prepared.payload
