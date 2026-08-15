# Pure semantic destination dispatch over route-admitted catalog coordinates and already-admitted evidence.
# Source I/O, request/route admission, rendering, and process transport are owned by application adapters.

compose ← •Import "../report/compose.bqn"
cycleResolution ← •Import "cycle_resolution.bqn"
householdDaily ← •Import "household_daily_scope.bqn"
dailyScopeAdapter ← •Import "daily_scope_adapter.bqn"
parse ← •Import "../text/parse.bqn"
empty ← ⟨⟩

Failure ← {𝕊 keyValue‿diagnosticsValue:
  {state⇐"error",key⇐keyValue,result⇐empty,diagnostics⇐diagnosticsValue}
}

Envelopes ← {𝕊 coordinates‿evidence:
  domain‿start‿finish‿observation ← coordinates
  compose.Envelopes ⟨
    evidence.budget,evidence.budget_policy,evidence.household,evidence.envelope_history,evidence.actual,evidence.plan,
    domain,start,finish,observation
  ⟩
}
Balances ← {𝕊 coordinates‿evidence:
  domain‿observation ← coordinates
  compose.Balances ⟨evidence.actual,domain,observation⟩
}
BalanceSheet ← {𝕊 coordinates‿evidence:
  domain‿observation ← coordinates
  compose.BalanceSheet ⟨evidence.actual,domain,observation⟩
}
ProfitAndLoss ← {𝕊 coordinates‿evidence:
  domain‿start‿finish ← coordinates
  compose.ProfitAndLoss ⟨evidence.actual,domain,start,finish⟩
}
Recent ← {𝕊 coordinates‿evidence:
  through‿limitText ← coordinates
  compose.RecentThrough ⟨evidence.actual,through,parse.ToNum limitText⟩
}
Planned ← {𝕊 coordinates‿evidence:
  observation ← ⊑coordinates
  cycle ← cycleResolution.WithPlan ⟨evidence.household.cycle,observation,evidence.actual,evidence.plan⟩
  compose.Planned ⟨evidence.plan,evidence.actual,cycle,observation⟩
}
CycleAccounts ← {𝕊 coordinates‿evidence:
  domain‿observation ← coordinates
  cycle ← cycleResolution.WithPlan ⟨evidence.household.cycle,observation,evidence.actual,evidence.plan⟩
  compose.CycleAccounts ⟨evidence.actual,domain,cycle,observation⟩
}
CycleComparison ← {𝕊 coordinates‿evidence:
  domain‿currentObs‿baselineObs‿policy ← coordinates
  current ← cycleResolution.WithPlan ⟨evidence.household.cycle,currentObs,evidence.actual,evidence.plan⟩
  baseline ← cycleResolution.WithPlan ⟨evidence.household.cycle,baselineObs,evidence.actual,evidence.plan⟩
  compose.CycleComparison ⟨evidence.actual,domain,current,currentObs,baseline,baselineObs,policy⟩
}
MonthlyAccounts ← {𝕊 coordinates‿evidence:
  domain‿firstMonth‿lastMonth ← coordinates
  compose.MonthlyAccounts ⟨evidence.actual,domain,firstMonth,lastMonth⟩
}
DailyFlow ← {𝕊 coordinates‿evidence:
  domain‿start‿finish‿observation ← coordinates
  compose.DailyFlow ⟨
    evidence.actual,evidence.budget_policy,evidence.household,domain,start,finish,observation
  ⟩
}
DailyTarget ← {𝕊 coordinates‿evidence:
  domain‿observation‿target ← coordinates
  scopeAdmission ← householdDaily.Build ⟨evidence.household,evidence.plan,evidence.registry⟩
  (scopeAdmission.state≡"ok")◶⟨
    {𝕊:Failure ⟨"daily-target",scopeAdmission.diagnostics⟩},
    {𝕊:
      scopes ← dailyScopeAdapter.Build ⟨scopeAdmission,evidence.actual,evidence.plan,domain,observation,target⟩
      (scopes.state≡"ok")◶⟨
        {𝕊:Failure ⟨"daily-target",scopes.diagnostics⟩},
        {𝕊:compose.DailyTarget ⟨observation,target,domain,scopes.asset_scope,scopes.obligation_scope⟩}
      ⟩ @
    }
  ⟩ @
}
Issues ← {𝕊 coordinates‿evidence:
  compose.Issues ⟨evidence.issue_lines,evidence.registry⟩
}

destinations ← ⟨
  Envelopes,Balances,BalanceSheet,ProfitAndLoss,Recent,Planned,
  CycleAccounts,CycleComparison,MonthlyAccounts,DailyFlow,DailyTarget,Issues
⟩
Build ← {𝕊 catalogIndex‿coordinates‿evidence:
  catalogIndex◶destinations ⟨coordinates,evidence⟩
}

{Build⇐Build}
