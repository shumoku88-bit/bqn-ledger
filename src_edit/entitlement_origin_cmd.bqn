# Admit one typed Entitlement StockOrigin intent and prepare candidate entitlement.journal line.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
candidate ← •Import "entitlement_origin_candidate.bqn"
validate ← •Import "validate.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}

{𝕊:Fail "usage: entitlement_origin_cmd.bqn <baseDir> <date> <memo> <currency>"}⍟(4≠≠args) @
baseDir ← 0⊑args
dateVal ← 1⊑args
memoVal ← 2⊑args
currency ← 3⊑args

accountResult ← accountSource.Load baseDir
{𝕊:Fail "canonical accounts.journal rejected"}⍟(accountResult.state≢"ok") @

household ← householdSource.LoadShared ⟨baseDir,accountResult.accounts⟩
{𝕊:Fail "canonical household.toml rejected"}⍟(household.state≢"ok") @

policy ← setup.Policy currency
{𝕊:Fail ("unsupported currency: "∾currency)}⍟(policy.state≢"ok") @

checks ← ⟨
  validate.ValidateDate dateVal,
  validate.ValidateNoTabNewline "memo"‿memoVal
⟩
errors ← (¬⊑¨checks)/1⊸⊑¨checks
{𝕊:Fail ⊑errors}⍟(0<≠errors) @

lf ← @+10
raw ← loader.ReadRaw Join ⟨baseDir,canonical.entitlement⟩
prepared ← candidate.Prepare ⟨raw,household.history,setup.registry,{
  date⇐dateVal,currency⇐currency,memo⇐memoVal
}⟩

{𝕊:Fail prepared.message}⍟(prepared.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾canonical.entitlement∾lf∾prepared.payload
