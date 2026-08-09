# Experiment only: execute current human report rows in one BQN destination lifetime.
# This deliberately reuses production source adapters, pure composition, and rendering.
# It is not a production owner and must not become a second report contract.

parse ← •Import "../../src/text/parse.bqn"
route ← •Import "../../src/application/report_route.bqn"
sources ← •Import "../../src/application/report_source_adapter.bqn"
cycleResolution ← •Import "../../src/application/cycle_resolution.bqn"
householdDaily ← •Import "../../src/application/household_daily_scope.bqn"
dailyScopeAdapter ← •Import "../../src/application/daily_scope_adapter.bqn"
compose ← •Import "../../src/report/compose.bqn"
render ← •Import "../../src/report/render.bqn"

empty ← ⟨⟩ ⋄ tab ← @+9
Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
RegistryDiagnostic ← {𝕊 result:{severity⇐"error",stage⇐"currency_registry",code⇐result.code,message⇐result.message}}

args ← •args
{𝕊:Fail ⟨"usage","expected BASE followed by current human request rows"⟩}⍟(2>≠args) @
base ← ⊑args ⋄ rows ← 1↓args

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics ⟨RegistryDiagnostic registryResult⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
actual ← sources.CanonicalActual ⟨base,registry⟩
{𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
companions ← sources.Companions ⟨base,actual.facts.accounts,registry⟩
{𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
policy ← sources.CanonicalReportPolicy base
{𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
presentation ← policy.presentation

RenderText ← {𝕊 key‿composition:
  {𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
  rendered ← render.Render ⟨key,"human",composition,presentation⟩
  {𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
  text ← rendered.text
  {𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
  text
}

BuildRow ← {𝕊 row:
  fields ← tab parse.SplitKeepEmpty row
  {𝕊:Fail ⟨"prototype_request_row_invalid","current request row must contain key and surface"⟩}⍟(2>≠fields) @
  key‿surface ← 2↑fields ⋄ coordinates ← 2↓fields
  {𝕊:Fail ⟨"prototype_surface_invalid","prototype accepts current human rows only"⟩}⍟(surface≢"human") @
  admitted ← route.Admit ⟨key,surface,coordinates⟩
  {𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
  coordinates↩admitted.coordinates
  composition ← {state⇐"error",key⇐key,result⇐empty,diagnostics⇐empty}

  {𝕊:
    domain‿observation ← coordinates
    composition↩compose.Balances ⟨actual.facts,domain,observation⟩
  }⍟(key≡"balances") @
  {𝕊:
    domain‿observation ← coordinates
    composition↩compose.BalanceSheet ⟨actual.facts,domain,observation⟩
  }⍟(key≡"balance-sheet") @
  {𝕊:
    domain‿start‿finish ← coordinates
    composition↩compose.ProfitAndLoss ⟨actual.facts,domain,start,finish⟩
  }⍟(key≡"profit-and-loss") @
  {𝕊:
    through‿limitText ← coordinates
    composition↩compose.RecentThrough ⟨actual.facts,through,parse.ToNum limitText⟩
  }⍟(key≡"recent") @
  {𝕊:
    domain‿start‿finish‿observation ← coordinates
    composition↩compose.Envelopes ⟨companions.budget,companions.budget_policy,companions.household,actual.facts,companions.plan,domain,start,finish,observation⟩
  }⍟(key≡"envelopes") @
  {𝕊:
    observation ← ⊑coordinates
    cycle ← cycleResolution.WithPlan ⟨companions.household.cycle,observation,actual.facts,companions.plan⟩
    composition↩compose.Planned ⟨companions.plan,actual.facts,cycle,observation⟩
  }⍟(key≡"planned") @
  {𝕊:
    domain‿observation ← coordinates
    cycle ← cycleResolution.WithPlan ⟨companions.household.cycle,observation,actual.facts,companions.plan⟩
    composition↩compose.CycleAccounts ⟨actual.facts,domain,cycle,observation⟩
  }⍟(key≡"cycle-accounts") @
  {𝕊:
    domain‿currentObs‿baselineObs‿comparisonPolicy ← coordinates
    current ← cycleResolution.WithPlan ⟨companions.household.cycle,currentObs,actual.facts,companions.plan⟩
    baseline ← cycleResolution.WithPlan ⟨companions.household.cycle,baselineObs,actual.facts,companions.plan⟩
    composition↩compose.CycleComparison ⟨actual.facts,domain,current,currentObs,baseline,baselineObs,comparisonPolicy⟩
  }⍟(key≡"cycle-comparison") @
  {𝕊:
    domain‿firstMonth‿lastMonth ← coordinates
    composition↩compose.MonthlyAccounts ⟨actual.facts,domain,firstMonth,lastMonth⟩
  }⍟(key≡"monthly-accounts") @
  {𝕊:
    domain‿start‿finish‿observation ← coordinates
    composition↩compose.DailyFlow ⟨actual.facts,companions.budget_policy,companions.household,domain,start,finish,observation⟩
  }⍟(key≡"daily-flow") @
  {𝕊:
    domain‿observation‿target ← coordinates
    scopeAdmission ← householdDaily.Build ⟨companions.household,companions.plan,registry⟩
    {𝕊:PrintDiagnostics scopeAdmission.diagnostics}⍟(scopeAdmission.state≢"ok") @
    scopes ← dailyScopeAdapter.Build ⟨scopeAdmission,actual.facts,companions.plan,domain,observation,target⟩
    {𝕊:PrintDiagnostics scopes.diagnostics}⍟(scopes.state≢"ok") @
    composition↩compose.DailyTarget ⟨observation,target,domain,scopes.asset_scope,scopes.obligation_scope⟩
  }⍟(key≡"daily-target") @
  {𝕊:
    composition↩compose.Issues ⟨sources.IssueLines base,registry⟩
  }⍟(key≡"issues") @

  RenderText ⟨key,composition⟩
}

{𝕊 row:•Out BuildRow row}¨rows
