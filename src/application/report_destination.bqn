# Pure semantic destination dispatch over route-admitted coordinates and already-admitted evidence.
# Source I/O, request/route admission, rendering, and process transport are owned by application adapters.

compose ← •Import "../report/compose.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
householdDaily ← •Import "household_daily_scope.bqn"
dailyScopeAdapter ← •Import "daily_scope_adapter.bqn"
parse ← •Import "../text/parse.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_report_destination",code⇐code,message⇐message}
}
Failure ← {𝕊 keyValue‿diagnosticsValue:
  {state⇐"error",key⇐keyValue,result⇐empty,diagnostics⇐diagnosticsValue}
}

Build ← {𝕊 key‿coordinates‿evidence:
  composition ← Failure ⟨key,⟨Diagnostic ⟨"destination_key_unhandled","route-admitted report key has no semantic destination"⟩⟩⟩

  {𝕊:
    domain‿observation ← coordinates
    composition↩compose.Balances ⟨evidence.actual,domain,observation⟩
  }⍟(key≡"balances") @
  {𝕊:
    domain‿observation ← coordinates
    composition↩compose.BalanceSheet ⟨evidence.actual,domain,observation⟩
  }⍟(key≡"balance-sheet") @
  {𝕊:
    domain‿start‿finish ← coordinates
    composition↩compose.ProfitAndLoss ⟨evidence.actual,domain,start,finish⟩
  }⍟(key≡"profit-and-loss") @
  {𝕊:
    through‿limitText ← coordinates
    composition↩compose.RecentThrough ⟨evidence.actual,through,parse.ToNum limitText⟩
  }⍟(key≡"recent") @
  {𝕊:
    domain‿start‿finish‿observation ← coordinates
    composition↩compose.Envelopes ⟨
      evidence.budget,evidence.budget_policy,evidence.household,evidence.actual,evidence.plan,
      domain,start,finish,observation
    ⟩
  }⍟(key≡"envelopes") @
  {𝕊:
    observation ← ⊑coordinates
    cycle ← cycleResolution.WithPlan ⟨evidence.household.cycle,observation,evidence.actual,evidence.plan⟩
    composition↩compose.Planned ⟨evidence.plan,evidence.actual,cycle,observation⟩
  }⍟(key≡"planned") @
  {𝕊:
    domain‿observation ← coordinates
    cycle ← cycleResolution.WithPlan ⟨evidence.household.cycle,observation,evidence.actual,evidence.plan⟩
    composition↩compose.CycleAccounts ⟨evidence.actual,domain,cycle,observation⟩
  }⍟(key≡"cycle-accounts") @
  {𝕊:
    domain‿currentObs‿baselineObs‿policy ← coordinates
    current ← cycleResolution.WithPlan ⟨evidence.household.cycle,currentObs,evidence.actual,evidence.plan⟩
    baseline ← cycleResolution.WithPlan ⟨evidence.household.cycle,baselineObs,evidence.actual,evidence.plan⟩
    composition↩compose.CycleComparison ⟨evidence.actual,domain,current,currentObs,baseline,baselineObs,policy⟩
  }⍟(key≡"cycle-comparison") @
  {𝕊:
    domain‿firstMonth‿lastMonth ← coordinates
    composition↩compose.MonthlyAccounts ⟨evidence.actual,domain,firstMonth,lastMonth⟩
  }⍟(key≡"monthly-accounts") @
  {𝕊:
    domain‿start‿finish‿observation ← coordinates
    composition↩compose.DailyFlow ⟨
      evidence.actual,evidence.budget_policy,evidence.household,domain,start,finish,observation
    ⟩
  }⍟(key≡"daily-flow") @
  {𝕊:
    domain‿observation‿target ← coordinates
    scopeAdmission ← householdDaily.Build ⟨evidence.household,evidence.plan,evidence.registry⟩
    {𝕊:composition↩Failure ⟨key,scopeAdmission.diagnostics⟩}⍟(scopeAdmission.state≢"ok") @
    {𝕊:
      scopes ← dailyScopeAdapter.Build ⟨scopeAdmission,evidence.actual,evidence.plan,domain,observation,target⟩
      {𝕊:composition↩Failure ⟨key,scopes.diagnostics⟩}⍟(scopes.state≢"ok") @
      {𝕊:
        composition↩compose.DailyTarget ⟨observation,target,domain,scopes.asset_scope,scopes.obligation_scope⟩
      }⍟(scopes.state≡"ok") @
    }⍟(scopeAdmission.state≡"ok") @
  }⍟(key≡"daily-target") @
  {𝕊:
    composition↩compose.Issues ⟨evidence.issue_lines,evidence.registry⟩
  }⍟(key≡"issues") @

  composition
}

{Build⇐Build}
