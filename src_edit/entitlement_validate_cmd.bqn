# Strict post-write validation for canonical entitlement.journal only.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
householdSource ← •Import "../src/application/household_source_adapter.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}

accountResult ← accountSource.Load base
{𝕊:•Out "ERROR"∾tab∾"accounts"∾tab∾"canonical accounts.journal rejected" ⋄ •Exit 1}⍟(accountResult.state≢"ok") @

household ← householdSource.LoadShared ⟨base,accountResult.accounts⟩
{𝕊:•Out "ERROR"∾tab∾"household"∾tab∾"canonical household.toml rejected" ⋄ •Exit 1}⍟(household.state≢"ok") @

raw ← loader.ReadRaw Join ⟨base,canonical.entitlement⟩
result ← entitlementAdmission.Admit ⟨raw,household.history,setup.registry⟩
{𝕊:
  diagnostic ← ⊑result.diagnostics
  •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message
  •Exit 1
}⍟(result.state≢"ok") @

•Out "OK"∾tab∾"ENTITLEMENT_JOURNAL"∾tab∾canonical.entitlement∾tab∾(•Fmt result.origins.count)∾tab∾•Fmt result.transfers.count
