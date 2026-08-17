# Admit one typed Entitlement Transfer intent and prepare candidate entitlement.journal line.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
envelopeSource ← •Import "../src/application/envelope_source_adapter.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"
candidate ← •Import "entitlement_transfer_candidate.bqn"
validate ← •Import "validate.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
lf ← @+10
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}

{𝕊:Fail "usage: entitlement_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> <currency-or-empty>"}⍟(7≠≠args) @
baseDir ← 0⊑args
dateVal ← 1⊑args
memoVal ← 2⊑args
fromVal ← 3⊑args
toVal ← 4⊑args
amountVal ← 5⊑args
explicitCurrency ← 6⊑args

accountResult ← accountSource.Load baseDir
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @
accounts ← accountResult.accounts

envelopePolicy ← envelopeSource.LoadPolicy ⟨baseDir,accounts⟩
{𝕊:Fail "canonical envelope.toml rejected"}⍟(envelopePolicy.state≢"ok") @

household ← householdSource.LoadShared ⟨baseDir,accounts⟩
{𝕊:Fail "canonical household.toml rejected"}⍟(household.state≢"ok") @

# Endpoint validation:
# Current writer is only permitted to write to CURRENT envelopes in envelope.toml
# or 'unallocated'. Retired envelopes (in history but not in current envelope.toml)
# must fail closed.
currentEnvelopeIds ← envelopePolicy.envelopes.id
historicalEnvelopeIds ← household.history.registry.id

ValidateEndpoint ← {𝕊 endpoint:
  isUnalloc ← endpoint ≡ "unallocated"
  isCurrent ← Contains ⟨endpoint,currentEnvelopeIds⟩
  isRetired ← (¬isCurrent) ∧ Contains ⟨endpoint,historicalEnvelopeIds⟩
  {𝕊:Fail ("cannot write Entitlement transfer to retired Envelope: "∾endpoint)}⍟isRetired @
  {𝕊:Fail ("unknown Envelope endpoint: "∾endpoint)}⍟(¬ isUnalloc ∨ isCurrent) @
}

ValidateEndpoint fromVal
ValidateEndpoint toVal
{𝕊:Fail "Entitlement transfer from/to endpoints must differ"}⍟(fromVal≡toVal) @

currency ← explicitCurrency
{𝕊:
  # Default currency to household primary commodity if set, or "JPY"
  primary ← household.current.money.primary_commodity
  {𝕊:currency↩primary}⍟(0<≠primary) @
  {𝕊:currency↩"JPY"}⍟(0=≠currency) @
}⍟(0=≠currency) @

policy ← setup.Policy currency
{𝕊:Fail ("unsupported currency: "∾currency)}⍟(policy.state≢"ok") @

checks ← ⟨
  validate.ValidateDate dateVal,
  validate.ValidateNoTabNewline "memo"‿memoVal,
  validate.ValidateExactAmountForPolicy ⟨currency,policy,amountVal⟩
⟩
errors ← (¬⊑¨checks)/1⊸⊑¨checks
{𝕊:Fail ⊑errors}⍟(0<≠errors) @

raw ← loader.ReadRaw Join ⟨baseDir,canonical.entitlement⟩
prepared ← candidate.Prepare ⟨raw,household.history,setup.registry,{
  date⇐dateVal,from⇐fromVal,to⇐toVal,
  amount⇐amountVal,currency⇐currency,memo⇐memoVal
}⟩

{𝕊:Fail prepared.message}⍟(prepared.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾canonical.entitlement∾lf∾prepared.payload
