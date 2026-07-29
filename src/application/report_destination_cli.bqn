# Parallel destination CLI proof. Production tools/report remains unchanged.

request ← •Import "../report/request.bqn"
compose ← •Import "../report/compose.bqn"
render ← •Import "../report/render.bqn"
sources ← •Import "report_source_adapter.bqn"
cycleAdmission ← •Import "../ledger/cycle_admission.bqn"
fixedCycle ← •Import "../accounting/cycle_fixed_resolution.bqn"
calendarCycle ← •Import "../accounting/cycle_calendar_month_resolution.bqn"
incomeCycle ← •Import "../accounting/cycle_income_anchor_resolution.bqn"
cycleResult ← •Import "../accounting/cycle_result.bqn"
fundingScope ← •Import "funding_scope.bqn"
dailyScopeAdmission ← •Import "daily_scope_admission.bqn"
dailyScopeAdapter ← •Import "daily_scope_adapter.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9
args ← •args
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}
ToNatural ← {𝕊 text:
  digits ← "0123456789"⊐text
  +´digits×10⋆⌽↕≠digits
}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic: •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
AdmitCycle ← {𝕊 base‿name‿accounts:
  cycleAdmission.Admit ⟨sources.CycleLines ⟨base,name⟩,accounts⟩
}
ResolveWithoutPlan ← {𝕊 admitted‿observation:
  mode ← admitted.definition.mode
  resolved ← cycleResult.Error ⟨mode,observation,"cycle_plan_required","incomeAnchor requires Plan facts"⟩
  {𝕊:resolved↩fixedCycle.Resolve admitted}⍟(mode≡"fixed") @
  {𝕊:resolved↩calendarCycle.Resolve ⟨admitted,observation⟩}⍟(mode≡"calendarMonth") @
  resolved
}
ResolveWithPlan ← {𝕊 admitted‿observation‿actualFacts‿planFacts:
  resolved ← ResolveWithoutPlan ⟨admitted,observation⟩
  {𝕊:resolved↩incomeCycle.Resolve ⟨admitted,observation,actualFacts,planFacts⟩}⍟(admitted.definition.mode≡"incomeAnchor") @
  resolved
}

{𝕊:Fail ⟨"usage","expected BASE KEY SURFACE and key-specific coordinates"⟩}⍟(3>≠args) @
base‿key‿surface ← 3↑args ⋄ coordinates ← 3↓args
admitted ← request.Validate ⟨key,surface⟩
{𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
{𝕊:Fail ⟨"all_not_implemented","parallel CLI currently requires one retained key"⟩}⍟(key≡"all") @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics registryResult.diagnostics}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
composition ← {state⇐"error",key⇐key,result⇐empty,diagnostics⇐empty}

{𝕊:
  {𝕊:Fail ⟨"usage_balances","balances requires DOMAIN AS_OF JOURNAL_BASENAME"⟩}⍟(3≠≠coordinates) @
  domain‿observation‿journal ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.Balances ⟨actual.facts,domain,observation⟩
}⍟(key≡"balances") @
{𝕊:
  {𝕊:Fail ⟨"usage_recent","recent requires LIMIT JOURNAL_BASENAME"⟩}⍟(2≠≠coordinates) @
  limitText‿journal ← coordinates
  {𝕊:Fail ⟨"limit_invalid","LIMIT must be decimal digits"⟩}⍟(¬IsDigits limitText) @
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.Recent ⟨actual.facts,ToNatural limitText⟩
}⍟(key≡"recent") @
{𝕊:
  usageMessage ← "envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION JOURNAL PLAN BUDGET and one or more FUNDING_ACCOUNT_KEY"
  {𝕊:Fail ⟨"usage_envelopes",usageMessage⟩}⍟(8>≠coordinates) @
  domain‿start‿finish‿observation‿journal‿planName‿budgetName ← 7↑coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  companions ← sources.Companions ⟨base,planName,budgetName,actual.facts.accounts,registry⟩
  {𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
  funding ← fundingScope.Build ⟨actual.facts.accounts,domain,7↓coordinates⟩
  {𝕊:PrintDiagnostics funding.diagnostics}⍟(funding.state≢"ok") @
  composition↩compose.Envelopes ⟨
    companions.budget,actual.facts,companions.plan,domain,start,finish,observation,funding.account_indices
  ⟩
}⍟(key≡"envelopes") @
{𝕊:
  {𝕊:Fail ⟨"usage_planned","planned requires OBSERVATION JOURNAL_BASENAME PLAN_BASENAME CYCLE_BASENAME"⟩}⍟(4≠≠coordinates) @
  observation‿journal‿planName‿cycleName ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  plan ← sources.Plan ⟨base,planName,actual.facts.accounts,registry⟩
  {𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
  admittedCycle ← AdmitCycle ⟨base,cycleName,actual.facts.accounts⟩
  {𝕊:PrintDiagnostics admittedCycle.diagnostics}⍟(admittedCycle.state≢"ok") @
  cycle ← ResolveWithPlan ⟨admittedCycle,observation,actual.facts,plan.facts⟩
  composition↩compose.Planned ⟨plan.facts,actual.facts,cycle,observation⟩
}⍟(key≡"planned") @
{𝕊:
  usageMessage ← "cycle-accounts requires DOMAIN OBSERVATION JOURNAL CYCLE and PLAN only for incomeAnchor"
  {𝕊:Fail ⟨"usage_cycle_accounts",usageMessage⟩}⍟(¬∨´(≠coordinates)⊸=¨⟨4,5⟩) @
  domain‿observation‿journal‿cycleName ← 4↑coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  admittedCycle ← AdmitCycle ⟨base,cycleName,actual.facts.accounts⟩
  {𝕊:PrintDiagnostics admittedCycle.diagnostics}⍟(admittedCycle.state≢"ok") @
  cycle ← ResolveWithoutPlan ⟨admittedCycle,observation⟩
  {𝕊:
    {𝕊:Fail ⟨"plan_required","incomeAnchor cycle requires PLAN_BASENAME"⟩}⍟(5≠≠coordinates) @
    plan ← sources.Plan ⟨base,4⊑coordinates,actual.facts.accounts,registry⟩
    {𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
    cycle↩ResolveWithPlan ⟨admittedCycle,observation,actual.facts,plan.facts⟩
  }⍟(admittedCycle.definition.mode≡"incomeAnchor") @
  {𝕊:Fail ⟨"plan_unexpected","PLAN_BASENAME is accepted only for incomeAnchor"⟩}⍟((admittedCycle.definition.mode≢"incomeAnchor") ∧ 5=≠coordinates) @
  composition↩compose.CycleAccounts ⟨actual.facts,domain,cycle,observation⟩
}⍟(key≡"cycle-accounts") @
{𝕊:
  usageMessage ← "cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY JOURNAL two CYCLE files and optional incomeAnchor PLAN"
  {𝕊:Fail ⟨"usage_cycle_comparison",usageMessage⟩}⍟(¬∨´(≠coordinates)⊸=¨⟨7,8⟩) @
  domain‿currentObs‿baselineObs‿policy‿journal‿currentName‿baselineName ← 7↑coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  currentAdmission ← AdmitCycle ⟨base,currentName,actual.facts.accounts⟩
  baselineAdmission ← AdmitCycle ⟨base,baselineName,actual.facts.accounts⟩
  cycleDiagnostics ← currentAdmission.diagnostics∾baselineAdmission.diagnostics
  {𝕊:PrintDiagnostics cycleDiagnostics}⍟(0<≠cycleDiagnostics) @
  modesMatch ← currentAdmission.definition.mode≡baselineAdmission.definition.mode
  {𝕊:Fail ⟨"comparison_cycle_mode_mismatch","current and baseline cycle modes must agree"⟩}⍟(¬modesMatch) @
  current ← ResolveWithoutPlan ⟨currentAdmission,currentObs⟩
  baseline ← ResolveWithoutPlan ⟨baselineAdmission,baselineObs⟩
  {𝕊:
    {𝕊:Fail ⟨"plan_required","incomeAnchor comparison requires PLAN_BASENAME"⟩}⍟(8≠≠coordinates) @
    plan ← sources.Plan ⟨base,7⊑coordinates,actual.facts.accounts,registry⟩
    {𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
    current↩ResolveWithPlan ⟨currentAdmission,currentObs,actual.facts,plan.facts⟩
    baseline↩ResolveWithPlan ⟨baselineAdmission,baselineObs,actual.facts,plan.facts⟩
  }⍟(currentAdmission.definition.mode≡"incomeAnchor") @
  {𝕊:Fail ⟨"plan_unexpected","PLAN_BASENAME is accepted only for incomeAnchor"⟩}⍟((currentAdmission.definition.mode≢"incomeAnchor") ∧ 8=≠coordinates) @
  composition↩compose.CycleComparison ⟨actual.facts,domain,current,currentObs,baseline,baselineObs,policy⟩
}⍟(key≡"cycle-comparison") @
{𝕊:
  {𝕊:Fail ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE JOURNAL_BASENAME"⟩}⍟(4≠≠coordinates) @
  domain‿firstMonth‿lastMonth‿journal ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  composition↩compose.MonthlyAccounts ⟨actual.facts,domain,firstMonth,lastMonth⟩
}⍟(key≡"monthly-accounts") @
{𝕊:
  usageMessage ← "daily-target requires DOMAIN OBSERVATION TARGET JOURNAL PLAN DAILY_SCOPE"
  {𝕊:Fail ⟨"usage_daily_target",usageMessage⟩}⍟(6≠≠coordinates) @
  domain‿observation‿target‿journal‿planName‿scopeName ← coordinates
  actual ← sources.Actual ⟨base,journal,registry⟩
  {𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
  plan ← sources.Plan ⟨base,planName,actual.facts.accounts,registry⟩
  {𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
  scopeAdmission ← dailyScopeAdmission.Admit ⟨sources.DailyScopeLines ⟨base,scopeName⟩,registry⟩
  {𝕊:PrintDiagnostics scopeAdmission.diagnostics}⍟(scopeAdmission.state≢"ok") @
  scopes ← dailyScopeAdapter.Build ⟨scopeAdmission,actual.facts,plan.facts,domain,observation,target⟩
  {𝕊:PrintDiagnostics scopes.diagnostics}⍟(scopes.state≢"ok") @
  composition↩compose.DailyTarget ⟨observation,target,domain,scopes.asset_scope,scopes.obligation_scope⟩
}⍟(key≡"daily-target") @
{𝕊:
  {𝕊:Fail ⟨"usage_issues","issues requires ISSUE_BASENAME"⟩}⍟(1≠≠coordinates) @
  composition↩compose.Issues ⟨sources.IssueLines ⟨base,⊑coordinates⟩,registry⟩
}⍟(key≡"issues") @

{𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
rendered ← render.Render ⟨key,surface,composition⟩
{𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
text ← rendered.text
{𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
•Out text
