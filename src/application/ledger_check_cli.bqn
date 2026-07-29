# Strict source-facing destination readiness check. Not a report section.

io ← •Import "source_io.bqn"
sources ← •Import "report_source_adapter.bqn"
configAdmission ← •Import "../ledger/config_admission.bqn"
cycleAdmission ← •Import "../ledger/cycle_admission.bqn"
issueAdmission ← •Import "../ledger/issue_admission.bqn"
dailyAdmission ← •Import "daily_scope_admission.bqn"
tab ← @+9 ⋄ args ← •args
Fail ← {𝕊 diagnostics:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.stage∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected BASE JOURNAL PLAN BUDGET CYCLE ISSUES DAILY_SCOPE" ⋄ •Exit 2}⍟(7≠≠args) @
base‿journal‿planName‿budgetName‿cycleName‿issueName‿dailyName ← args
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨{stage⇐"currency_registry",code⇐registryResult.code,message⇐registryResult.message}⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
config ← configAdmission.Admit ⟨io.ReadLines base∾"/config.tsv",registry⟩
{𝕊:Fail config.diagnostics}⍟(config.state≢"ok") @
actual ← sources.Actual ⟨base,journal,registry⟩
{𝕊:Fail actual.diagnostics}⍟(actual.state≢"ok") @
companions ← sources.Companions ⟨base,planName,budgetName,actual.facts.accounts,registry⟩
{𝕊:Fail companions.diagnostics}⍟(companions.state≢"ok") @
cycle ← cycleAdmission.Admit ⟨sources.CycleLines ⟨base,cycleName⟩,actual.facts.accounts⟩
{𝕊:Fail cycle.diagnostics}⍟(cycle.state≢"ok") @
issues ← issueAdmission.Admit ⟨sources.IssueLines ⟨base,issueName⟩,registry⟩
{𝕊:Fail issues.diagnostics}⍟(issues.state≢"ok") @
daily ← dailyAdmission.Admit ⟨sources.DailyScopeLines ⟨base,dailyName⟩,registry⟩
{𝕊:Fail daily.diagnostics}⍟(daily.state≢"ok") @
•Out "ledger_check"∾tab∾"state"∾tab∾"ok"
•Out "ledger_check"∾tab∾"actual_transactions"∾tab∾•Fmt actual.facts.transactions.count
•Out "ledger_check"∾tab∾"actual_postings"∾tab∾•Fmt actual.facts.postings.count
•Out "ledger_check"∾tab∾"plan_transactions"∾tab∾•Fmt companions.plan.transactions.count
•Out "ledger_check"∾tab∾"budget_transactions"∾tab∾•Fmt companions.budget.transactions.count
•Out "ledger_check"∾tab∾"cycle_mode"∾tab∾cycle.definition.mode
•Out "ledger_check"∾tab∾"issues"∾tab∾•Fmt issues.issues.count
•Out "ledger_check"∾tab∾"daily_scope_rows"∾tab∾•Fmt daily.rows.count
