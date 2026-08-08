# Pure individual report-route admission before source I/O or composition.
# Canonical companion files have fixed Household-root identities. Legacy argv
# coordinates remain only until report.toml Phase 6 and never select physical I/O.

request ← •Import "../report/request.bqn"
canonical ← •Import "canonical_household_sources.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_route",code⇐code,message⇐message}}
EmptySources ← {𝕊:{count⇐0,index⇐empty,argument_index⇐empty,kind⇐empty,role⇐empty,name⇐empty}}
Sources ← {𝕊 coordinates‿argumentIndices‿kinds‿roles:{
  count⇐≠argumentIndices,index⇐↕≠argumentIndices,argument_index⇐argumentIndices,
  kind⇐kinds,role⇐roles,name⇐argumentIndices⊏coordinates
}}
MakePlan ← {𝕊 diagnosticsValue‿coordinateRolesValue‿sourcesValue:{diagnostics⇐diagnosticsValue,coordinate_role⇐coordinateRolesValue,sources⇐sourcesValue}}
Reject ← {𝕊 code‿message:MakePlan ⟨⟨Diagnostic ⟨code,message⟩⟩,empty,EmptySources @⟩}
Accept ← {𝕊 coordinates‿coordinateRoles‿argumentIndices‿kinds‿roles:MakePlan ⟨empty,coordinateRoles,Sources ⟨coordinates,argumentIndices,kinds,roles⟩⟩}
AcceptCanonicalActual ← {𝕊 coordinates‿coordinateRoles‿argumentIndex:
  (canonical.actual≡argumentIndex⊑coordinates)◶⟨
    {𝕊:Reject ⟨"actual_source_not_canonical","Report requires canonical actual.journal"⟩},
    {𝕊:Accept ⟨coordinates,coordinateRoles,⟨argumentIndex⟩,⟨"canonical-journal"⟩,⟨"actual"⟩⟩}
  ⟩ @
}
AllowedCount ← {𝕊 count‿allowed:∨´0∾count⊸=¨allowed}
IsDigits ← {𝕊 text:(0<≠text) ∧ ∧´text∊"0123456789"}

# Plan/Budget/Cycle/Daily-Scope/funding coordinates remain in request shapes until
# Phase 6 only. Canonical plan.journal, budget.journal, budget.toml, household.toml
# own companion semantics and are loaded internally. Only actual.journal is a
# caller-visible physical source at this stage.
Envelopes ← {𝕊 coordinates:
  (8≤≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_envelopes","envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION JOURNAL PLAN BUDGET and one or more legacy funding coordinates until report.toml migration"⟩},
    {𝕊:
      roles ← ⟨"domain","start","end_exclusive","observation","actual_source","plan_source","budget_source"⟩∾((≠coordinates)-7)⥊⟨"funding_account"⟩
      AcceptCanonicalActual ⟨coordinates,roles,4⟩
    }
  ⟩ @
}
Balances ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_balances","balances requires DOMAIN AS_OF JOURNAL_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","as_of","actual_source"⟩,2⟩}
  ⟩ @
}
BalanceSheet ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_balance_sheet","balance-sheet requires DOMAIN AS_OF JOURNAL_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","as_of","actual_source"⟩,2⟩}
  ⟩ @
}
ProfitAndLoss ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_profit_and_loss","profit-and-loss requires DOMAIN START END_EXCLUSIVE JOURNAL_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","start","end_exclusive","actual_source"⟩,3⟩}
  ⟩ @
}
Recent ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_recent","recent requires LIMIT JOURNAL_BASENAME"⟩},
    {𝕊:
      (IsDigits ⊑coordinates)◶⟨
        {𝕊:Reject ⟨"limit_invalid","LIMIT must be decimal digits"⟩},
        {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"limit","actual_source"⟩,1⟩}
      ⟩ @
    }
  ⟩ @
}
Planned ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_planned","planned requires OBSERVATION JOURNAL_BASENAME PLAN_BASENAME CYCLE_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"observation","actual_source","plan_source","cycle_source"⟩,1⟩}
  ⟩ @
}
CycleAccounts ← {𝕊 coordinates:
  count ← ≠coordinates
  (AllowedCount ⟨count,⟨4,5⟩⟩)◶⟨
    {𝕊:Reject ⟨"usage_cycle_accounts","cycle-accounts requires DOMAIN OBSERVATION JOURNAL CYCLE and optional legacy PLAN coordinate until report.toml migration"⟩},
    {𝕊:
      roles ← (5=count)⊑⟨
        ⟨"domain","observation","actual_source","cycle_source"⟩,
        ⟨"domain","observation","actual_source","cycle_source","plan_source"⟩
      ⟩
      AcceptCanonicalActual ⟨coordinates,roles,2⟩
    }
  ⟩ @
}
CycleComparison ← {𝕊 coordinates:
  count ← ≠coordinates
  (AllowedCount ⟨count,⟨7,8⟩⟩)◶⟨
    {𝕊:Reject ⟨"usage_cycle_comparison","cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY JOURNAL two legacy CYCLE coordinates and optional legacy PLAN coordinate until report.toml migration"⟩},
    {𝕊:
      roles ← (8=count)⊑⟨
        ⟨"domain","current_observation","baseline_observation","policy","actual_source","current_cycle_source","baseline_cycle_source"⟩,
        ⟨"domain","current_observation","baseline_observation","policy","actual_source","current_cycle_source","baseline_cycle_source","plan_source"⟩
      ⟩
      AcceptCanonicalActual ⟨coordinates,roles,4⟩
    }
  ⟩ @
}
MonthlyAccounts ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE JOURNAL_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","first_month","last_month_exclusive","actual_source"⟩,3⟩}
  ⟩ @
}
DailyFlow ← {𝕊 coordinates:
  (5=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_daily_flow","daily-flow requires DOMAIN START END_EXCLUSIVE OBSERVATION JOURNAL_BASENAME"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","start","end_exclusive","observation","actual_source"⟩,4⟩}
  ⟩ @
}
DailyTarget ← {𝕊 coordinates:
  (6=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_daily_target","daily-target requires DOMAIN OBSERVATION TARGET JOURNAL PLAN DAILY_SCOPE until report.toml migration"⟩},
    {𝕊:AcceptCanonicalActual ⟨coordinates,⟨"domain","observation","target","actual_source","plan_source","daily_scope_source"⟩,3⟩}
  ⟩ @
}
Issues ← {𝕊 coordinates:
  (1=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_issues","issues requires ISSUE_BASENAME"⟩},
    {𝕊:Accept ⟨coordinates,⟨"issues_source"⟩,⟨0⟩,⟨"tsv"⟩,⟨"issues"⟩⟩}
  ⟩ @
}

routes ← ⟨Envelopes,Balances,BalanceSheet,ProfitAndLoss,Recent,Planned,CycleAccounts,CycleComparison,MonthlyAccounts,DailyFlow,DailyTarget,Issues⟩
RoutePlan ← {𝕊 catalogIndex‿coordinates:catalogIndex◶routes coordinates}
Admit ← {𝕊 key‿surface‿coordinates:
  admittedRequest ← request.Validate ⟨key,surface⟩
  plan ← (admittedRequest.state≡"ok")◶⟨
    {𝕊:MakePlan ⟨admittedRequest.diagnostics,empty,EmptySources @⟩},
    {𝕊:
      (key≡"all")◶⟨
        {𝕊:RoutePlan ⟨⊑admittedRequest.section_indices,coordinates⟩},
        {𝕊:Reject ⟨"report_route_all_unsupported","all is a manifest-level selection, not one individual route"⟩}
      ⟩ @
    }
  ⟩ @
  ok ← 0=≠plan.diagnostics
  {state⇐ok⊑"error"‿"ok",key⇐ok⊑""‿key,surface⇐ok⊑""‿surface,
   coordinates⇐ok⊑⟨empty,coordinates⟩,coordinate_role⇐ok⊑⟨empty,plan.coordinate_role⟩,
   sources⇐plan.sources,diagnostics⇐plan.diagnostics}
}

{Admit⇐Admit}
