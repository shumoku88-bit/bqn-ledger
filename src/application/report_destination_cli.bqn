# Effectful production adapter for one admitted retained-report route.

request ← •Import "../report/request.bqn"
route ← •Import "report_route.bqn"
compose ← •Import "../report/compose.bqn"
render ← •Import "../report/render.bqn"
sources ← •Import "report_source_adapter.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
householdDaily ← •Import "household_daily_scope.bqn"
dailyScopeAdapter ← •Import "daily_scope_adapter.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9
args ← •args
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
ToNatural ← {𝕊 text: digits ← "0123456789"⊐text ⋄ +´digits×10⋆⌽↕≠digits}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic: •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
RegistryDiagnostic ← {𝕊 result:{severity⇐"error",stage⇐"currency_registry",code⇐result.code,message⇐result.message}}

{𝕊:Fail ⟨"usage","expected BASE KEY SURFACE and key-specific coordinates"⟩}⍟(3>≠args) @
base‿key‿surface ← 3↑args ⋄ coordinates ← 3↓args
admitted ← request.Validate ⟨key,surface⟩
{𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
{𝕊:Fail ⟨"all_not_implemented","parallel CLI currently requires one retained key"⟩}⍟(key≡"all") @
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics ⟨RegistryDiagnostic registryResult⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
routeAdmission ← route.Admit ⟨key,surface,coordinates⟩
{𝕊:PrintDiagnostics routeAdmission.diagnostics}⍟(routeAdmission.state≢"ok") @
coordinates↩routeAdmission.coordinates
composition ← {state⇐"error",key⇐key,result⇐empty,diagnostics⇐empty}

LoadActual ← {𝕊:
  result ← sources.CanonicalActual ⟨base,registry⟩
  {𝕊:PrintDiagnostics result.diagnostics}⍟(result.state≢"ok") @
  result
}
LoadHouseholdContext ← {𝕊 actual:
  plan ← sources.CanonicalPlan ⟨base,registry⟩
  {𝕊:PrintDiagnostics plan.diagnostics}⍟(plan.state≢"ok") @
  budget ← sources.CanonicalBudget ⟨base,registry⟩
  {𝕊:PrintDiagnostics budget.diagnostics}⍟(budget.state≢"ok") @
  household ← sources.CanonicalHousehold ⟨base,actual.facts.accounts,budget.policy⟩
  {𝕊:PrintDiagnostics household.diagnostics}⍟(household.state≢"ok") @
  {plan⇐plan,budget⇐budget,household⇐household}
}

{𝕊:
  domain‿observation‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.Balances ⟨actual.facts,domain,observation⟩
}⍟(key≡"balances") @
{𝕊:
  domain‿observation‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.BalanceSheet ⟨actual.facts,domain,observation⟩
}⍟(key≡"balance-sheet") @
{𝕊:
  domain‿start‿finish‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.ProfitAndLoss ⟨actual.facts,domain,start,finish⟩
}⍟(key≡"profit-and-loss") @
{𝕊:
  limitText‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.Recent ⟨actual.facts,ToNatural limitText⟩
}⍟(key≡"recent") @
{𝕊:
  domain‿start‿finish‿observation‿journal‿planCoordinate‿budgetCoordinate ← 7↑coordinates
  actual ← LoadActual @
  companions ← sources.Companions ⟨base,planCoordinate,budgetCoordinate,actual.facts.accounts,registry⟩
  {𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
  composition↩compose.Envelopes ⟨
    companions.budget,companions.budget_policy,companions.household,
    actual.facts,companions.plan,domain,start,finish,observation
  ⟩
}⍟(key≡"envelopes") @
{𝕊:
  observation‿journal‿planCoordinate‿cycleCoordinate ← coordinates
  actual ← LoadActual @ ⋄ context ← LoadHouseholdContext actual
  cycle ← cycleResolution.WithPlan ⟨context.household.cycle,observation,actual.facts,context.plan.facts⟩
  composition↩compose.Planned ⟨context.plan.facts,actual.facts,cycle,observation⟩
}⍟(key≡"planned") @
{𝕊:
  domain‿observation‿journal‿cycleCoordinate ← 4↑coordinates
  actual ← LoadActual @ ⋄ context ← LoadHouseholdContext actual
  cycle ← cycleResolution.WithPlan ⟨context.household.cycle,observation,actual.facts,context.plan.facts⟩
  composition↩compose.CycleAccounts ⟨actual.facts,domain,cycle,observation⟩
}⍟(key≡"cycle-accounts") @
{𝕊:
  domain‿currentObs‿baselineObs‿policy‿journal‿currentCycleCoordinate‿baselineCycleCoordinate ← 7↑coordinates
  actual ← LoadActual @ ⋄ context ← LoadHouseholdContext actual
  current ← cycleResolution.WithPlan ⟨context.household.cycle,currentObs,actual.facts,context.plan.facts⟩
  baseline ← cycleResolution.WithPlan ⟨context.household.cycle,baselineObs,actual.facts,context.plan.facts⟩
  composition↩compose.CycleComparison ⟨actual.facts,domain,current,currentObs,baseline,baselineObs,policy⟩
}⍟(key≡"cycle-comparison") @
{𝕊:
  domain‿firstMonth‿lastMonth‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.MonthlyAccounts ⟨actual.facts,domain,firstMonth,lastMonth⟩
}⍟(key≡"monthly-accounts") @
{𝕊:
  domain‿start‿finish‿observation‿journal ← coordinates ⋄ actual ← LoadActual @
  composition↩compose.DailyFlow ⟨actual.facts,domain,start,finish,observation⟩
}⍟(key≡"daily-flow") @
{𝕊:
  domain‿observation‿target‿journal‿planCoordinate‿scopeCoordinate ← coordinates
  actual ← LoadActual @ ⋄ context ← LoadHouseholdContext actual
  scopeAdmission ← householdDaily.Build ⟨context.household,context.plan.facts,registry⟩
  {𝕊:PrintDiagnostics scopeAdmission.diagnostics}⍟(scopeAdmission.state≢"ok") @
  scopes ← dailyScopeAdapter.Build ⟨scopeAdmission,actual.facts,context.plan.facts,domain,observation,target⟩
  {𝕊:PrintDiagnostics scopes.diagnostics}⍟(scopes.state≢"ok") @
  composition↩compose.DailyTarget ⟨observation,target,domain,scopes.asset_scope,scopes.obligation_scope⟩
}⍟(key≡"daily-target") @
{𝕊:composition↩compose.Issues ⟨sources.IssueLines ⟨base,⊑coordinates⟩,registry⟩}⍟(key≡"issues") @

{𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
rendered ← render.Render ⟨key,surface,composition⟩
{𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
text ← rendered.text
{𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
•Out text
