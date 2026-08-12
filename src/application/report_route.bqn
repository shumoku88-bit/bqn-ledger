# Pure individual report-route admission before source I/O or composition.
# Canonical Household source files have fixed identities and never appear in
# request coordinates. Routes admit semantic query coordinates only.

request ← •Import "../report/request.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_route",code⇐code,message⇐message}}
EmptySources ← {𝕊:{count⇐0,index⇐empty,argument_index⇐empty,kind⇐empty,role⇐empty,name⇐empty}}
MakePlan ← {𝕊 diagnosticsValue‿coordinateRolesValue:{diagnostics⇐diagnosticsValue,coordinate_role⇐coordinateRolesValue,sources⇐EmptySources @}}
Reject ← {𝕊 code‿message:MakePlan ⟨⟨Diagnostic ⟨code,message⟩⟩,empty⟩}
Accept ← {𝕊 coordinateRoles:MakePlan ⟨empty,coordinateRoles⟩}
IsDigits ← {𝕊 text:(0<≠text) ∧ ∧´text∊"0123456789"}

Envelopes ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_envelopes","envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION"⟩},
    {𝕊:Accept ⟨"domain","start","end_exclusive","observation"⟩}
  ⟩ @
}
Balances ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_balances","balances requires DOMAIN AS_OF"⟩},
    {𝕊:Accept ⟨"domain","as_of"⟩}
  ⟩ @
}
BalanceSheet ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_balance_sheet","balance-sheet requires DOMAIN AS_OF"⟩},
    {𝕊:Accept ⟨"domain","as_of"⟩}
  ⟩ @
}
ProfitAndLoss ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_profit_and_loss","profit-and-loss requires DOMAIN START END_EXCLUSIVE"⟩},
    {𝕊:Accept ⟨"domain","start","end_exclusive"⟩}
  ⟩ @
}
Recent ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_recent","recent requires THROUGH LIMIT"⟩},
    {𝕊:
      (IsDigits 1⊑coordinates)◶⟨
        {𝕊:Reject ⟨"limit_invalid","LIMIT must be decimal digits"⟩},
        {𝕊:Accept ⟨"through","limit"⟩}
      ⟩ @
    }
  ⟩ @
}
Planned ← {𝕊 coordinates:
  (1=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_planned","planned requires OBSERVATION"⟩},
    {𝕊:Accept ⟨"observation"⟩}
  ⟩ @
}
CycleAccounts ← {𝕊 coordinates:
  (2=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_cycle_accounts","cycle-accounts requires DOMAIN OBSERVATION"⟩},
    {𝕊:Accept ⟨"domain","observation"⟩}
  ⟩ @
}
CycleComparison ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_cycle_comparison","cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY"⟩},
    {𝕊:Accept ⟨"domain","current_observation","baseline_observation","policy"⟩}
  ⟩ @
}
MonthlyAccounts ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_monthly_accounts","monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE"⟩},
    {𝕊:Accept ⟨"domain","first_month","last_month_exclusive"⟩}
  ⟩ @
}
DailyFlow ← {𝕊 coordinates:
  (4=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_daily_flow","daily-flow requires DOMAIN START END_EXCLUSIVE OBSERVATION"⟩},
    {𝕊:Accept ⟨"domain","start","end_exclusive","observation"⟩}
  ⟩ @
}
DailyTarget ← {𝕊 coordinates:
  (3=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_daily_target","daily-target requires DOMAIN OBSERVATION TARGET"⟩},
    {𝕊:Accept ⟨"domain","observation","target"⟩}
  ⟩ @
}
Issues ← {𝕊 coordinates:
  (0=≠coordinates)◶⟨
    {𝕊:Reject ⟨"usage_issues","issues takes no source coordinate"⟩},
    {𝕊:Accept empty}
  ⟩ @
}

routes ← ⟨Envelopes,Balances,BalanceSheet,ProfitAndLoss,Recent,Planned,CycleAccounts,CycleComparison,MonthlyAccounts,DailyFlow,DailyTarget,Issues⟩
RoutePlan ← {𝕊 catalogIndex‿coordinates:catalogIndex◶routes coordinates}
Admit ← {𝕊 key‿surface‿coordinates:
  admittedRequest ← request.Validate ⟨key,surface⟩
  plan ← (admittedRequest.state≡"ok")◶⟨
    {𝕊:MakePlan ⟨admittedRequest.diagnostics,empty⟩},
    {𝕊:
      (key≡"all")◶⟨
        {𝕊:RoutePlan ⟨⊑admittedRequest.section_indices,coordinates⟩},
        {𝕊:Reject ⟨"report_route_all_unsupported","all is a request-set selection, not one individual route"⟩}
      ⟩ @
    }
  ⟩ @
  ok ← 0=≠plan.diagnostics
  catalogIndex ← ok◶⟨{𝕊:empty},{𝕊:⊑admittedRequest.section_indices}⟩ @
  {state⇐ok⊑"error"‿"ok",key⇐ok⊑""‿key,surface⇐ok⊑""‿surface,
   catalog_index⇐catalogIndex,
   coordinates⇐ok⊑⟨empty,coordinates⟩,coordinate_role⇐ok⊑⟨empty,plan.coordinate_role⟩,
   sources⇐plan.sources,diagnostics⇐plan.diagnostics}
}

{Admit⇐Admit}
