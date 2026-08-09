# Strict post-write validation for canonical budget.journal only.

loader ← •Import "../src/application/source_io.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
rootAdmission ← •Import "../src/ledger/canonical_journal_root_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_journal_admission.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}

accountsResult ← accountSource.Load base
{𝕊:•Out "ERROR"∾tab∾"accounts"∾tab∾"canonical accounts.journal rejected" ⋄ •Exit 1}⍟(accountsResult.state≢"ok") @
raw ← loader.ReadRaw Join ⟨base,canonical.budget⟩
rootResult ← rootAdmission.Admit ⟨raw,canonical.accounts⟩
{𝕊:•Out "ERROR"∾tab∾"budget_root"∾tab∾"canonical budget.journal root rejected" ⋄ •Exit 1}⍟(rootResult.state≢"ok") @
result ← budgetAdmission.Admit ⟨raw,accountsResult.accounts,setup.registry⟩
{𝕊:
  diagnostic ← ⊑result.diagnostics
  •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message
  •Exit 1
}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"BUDGET_JOURNAL"∾tab∾canonical.budget∾tab∾•Fmt ≠result.transactions