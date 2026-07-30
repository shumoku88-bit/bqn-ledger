# Pure individual report-route admission before source I/O or composition.
# Operational filesystem checks remain in Shell; semantic source admission remains downstream.

request ← •Import "../report/request.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"application_report_route",code⇐code,message⇐message}
}
EmptySources ← {𝕊:
  {count⇐0,index⇐empty,argument_index⇐empty,kind⇐empty,role⇐empty,name⇐empty}
}
Sources ← {𝕊 coordinates‿argumentIndices‿kinds‿roles:
  {
    count⇐≠argumentIndices,index⇐↕≠argumentIndices,argument_index⇐argumentIndices,
    kind⇐kinds,role⇐roles,name⇐argumentIndices⊏coordinates
  }
}
Plan ← {𝕊 diagnosticsValue‿sourcesValue: {diagnostics⇐diagnosticsValue,sources⇐sourcesValue}}
Reject ← {𝕊 code‿message: Plan ⟨⟨Diagnostic ⟨code,message⟩⟩,EmptySources @⟩}
Accept ← {𝕊 coordinates‿argumentIndices‿kinds‿roles:
  Plan ⟨empty,Sources ⟨coordinates,argumentIndices,kinds,roles⟩⟩
}
AllowedCount ← {𝕊 count‿allowed: ∨´0∾count⊸=¨allowed}
IsDigits ← {𝕊 text: (0<≠text) ∧ ∧´text∊"0123456789"}

Envelopes ← {𝕊 coordinates:
  (8≤≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_envelopes","envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION JOURNAL PLAN BUDGET and one or more FUNDING_ACCOUNT_KEY"⟩},
    {𝕊:Accept ⟨coordinates,⟨4,5,6⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","budget"⟩⟩}
  ⟩ @
}
Balances ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_balances","balances requires DOMAIN AS_OF JOURNAL_BASENAME"⟩},
    {𝕊:Accept ⟨coordinates,⟨2⟩,⟨"journal"⟩,⟨"actual"⟩⟩}
  ⟩ @
}
Recent ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_recent","recent requires LIMIT JOURNAL_BASENAME"⟩},
    {𝕊:
      (IsDigits ⊑coordinates)◶⟨
        {𝕊:Reject ⟨"limit_invalid","LIMIT must be decimal digits"⟩},
        {𝕊:Accept ⟨coordinates,⟨1⟩,⟨"journal"⟩,⟨"actual"⟩⟩}
      ⟩ @
    }
  ⟩ @
}
Planned ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_planned","planned requires OBSERVATION JOURNAL_BASENAME PLAN_BASENAME CYCLE_BASENAME"⟩},
    {𝕊:Accept ⟨coordinates,⟨1,2,3⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","cycle"⟩⟩}
  ⟩ @
}
CycleAccounts ← {𝕊 coordinates:
  count ← ≠coordinates
  (AllowedCount ⟨count,⟨4,5⟩⟩)◶⟨
    {𝕊:Reject ⟨"usage_cycle_accounts","cycle-accounts requires DOMAIN OBSERVATION JOURNAL CYCLE and PLAN only for incomeAnchor"⟩},
    {𝕊:
      (5=count)◶⟨
        {𝕊:Accept ⟨coordinates,⟨2,3⟩,⟨"journal","tsv"⟩,⟨"actual","cycle"⟩⟩},
        {𝕊:Accept ⟨coordinates,⟨2,3,4⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","cycle","plan"⟩⟩}
      ⟩ @
    }
  ⟩ @
}
CycleComparison ← {𝕊 coordinates:
  count ← ≠coordinates
  (AllowedCount ⟨count,⟨7,8⟩⟩)◶⟨
    {𝕊:Reject ⟨"usage_cycle_comparison","cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY JOURNAL two CYCLE files and optional incomeAnchor PLAN"⟩},
    {𝕊:
      (8=count)◶⟨
        {𝕊:Accept ⟨coordinates,⟨4,5,6⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","current_cycle","baseline_cycle"⟩⟩},
        {𝕊:Accept ⟨coordinates,⟨4,5,6,7⟩,⟨"journal","tsv","tsv","tsv"⟩,⟨"actual","current_cycle","baseline_cycle","plan"⟩⟩}
      ⟩ @
    }
  ⟩ @
}
MonthlyAccounts ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE JOURNAL_BASENAME"⟩},
    {𝕊:Accept ⟨coordinates,⟨3⟩,⟨"journal"⟩,⟨"actual"⟩⟩}
  ⟩ @
}
DailyTarget ← {𝕊 coordinates:
  (6=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_daily_target","daily-target requires DOMAIN OBSERVATION TARGET JOURNAL PLAN DAILY_SCOPE"⟩},
    {𝕊:Accept ⟨coordinates,⟨3,4,5⟩,⟨"journal","tsv","tsv"⟩,⟨"actual","plan","daily_scope"⟩⟩}
  ⟩ @
}
Issues ← {𝕊 coordinates:
  (1=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_issues","issues requires ISSUE_BASENAME"⟩},
    {𝕊:Accept ⟨coordinates,⟨0⟩,⟨"tsv"⟩,⟨"issues"⟩⟩}
  ⟩ @
}

keys ← ⟨
  "envelopes","balances","recent","planned","cycle-accounts",
  "cycle-comparison","monthly-accounts","daily-target","issues"
⟩
routes ← ⟨Envelopes,Balances,Recent,Planned,CycleAccounts,CycleComparison,MonthlyAccounts,DailyTarget,Issues⟩
RoutePlan ← {𝕊 key‿coordinates:
  matches ← key⊸≡¨keys
  index ← ⊑matches/↕≠keys
  (index⊑routes) coordinates
}

Admit ← {𝕊 key‿surface‿coordinates:
  admittedRequest ← request.Validate ⟨key,surface⟩
  plan ← (admittedRequest.state≡"ok")◶⟨
    {𝕊:Plan ⟨admittedRequest.diagnostics,EmptySources @⟩},
    {𝕊:
      (key≡"all")◶⟨
        {𝕊:RoutePlan ⟨key,coordinates⟩},
        {𝕊:Reject ⟨"report_route_all_unsupported","all is a manifest-level selection, not one individual route"⟩}
      ⟩ @
    }
  ⟩ @
  ok ← 0=≠plan.diagnostics
  {
    state⇐ok⊑"error"‿"ok",key⇐ok⊑""‿key,surface⇐ok⊑""‿surface,
    coordinates⇐ok⊑⟨empty,coordinates⟩,sources⇐plan.sources,
    diagnostics⇐plan.diagnostics
  }
}

{Admit⇐Admit}
