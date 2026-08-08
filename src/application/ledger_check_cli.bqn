# Strict source-facing readiness check for the canonical eight-file Household root.

sources ← •Import "report_source_adapter.bqn"
issueAdmission ← •Import "../ledger/issue_admission.bqn"
householdDaily ← •Import "household_daily_scope.bqn"
tab ← @+9 ⋄ args ← •args
Fail ← {𝕊 diagnostics:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.stage∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected canonical Household BASE" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨{stage⇐"currency_registry",code⇐registryResult.code,message⇐registryResult.message}⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
actual ← sources.CanonicalActual ⟨base,registry⟩
{𝕊:Fail actual.diagnostics}⍟(actual.state≢"ok") @
companions ← sources.Companions ⟨base,actual.facts.accounts,registry⟩
{𝕊:Fail companions.diagnostics}⍟(companions.state≢"ok") @
daily ← householdDaily.Build ⟨companions.household,companions.plan,registry⟩
{𝕊:Fail daily.diagnostics}⍟(daily.state≢"ok") @
issues ← issueAdmission.Admit ⟨sources.IssueLines base,registry⟩
{𝕊:Fail issues.diagnostics}⍟(issues.state≢"ok") @
reportPolicy ← sources.CanonicalReportPolicy base
{𝕊:Fail reportPolicy.diagnostics}⍟(reportPolicy.state≢"ok") @
•Out "ledger_check"∾tab∾"state"∾tab∾"ok"
•Out "ledger_check"∾tab∾"actual_transactions"∾tab∾•Fmt actual.facts.transactions.count
•Out "ledger_check"∾tab∾"actual_postings"∾tab∾•Fmt actual.facts.postings.count
•Out "ledger_check"∾tab∾"plan_transactions"∾tab∾•Fmt companions.plan.transactions.count
•Out "ledger_check"∾tab∾"budget_transactions"∾tab∾•Fmt companions.budget.transactions.count
•Out "ledger_check"∾tab∾"cycle_mode"∾tab∾companions.household.cycle.definition.mode
•Out "ledger_check"∾tab∾"issues"∾tab∾•Fmt issues.issues.count
•Out "ledger_check"∾tab∾"daily_scope_rows"∾tab∾•Fmt daily.rows.count
