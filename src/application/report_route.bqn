# Pure individual report-route admission before source I/O or composition.
# Canonical Household source files have fixed identities and never appear in
# request coordinates. Routes admit semantic query coordinates only.

request ← •Import "../report/request.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"application_report_route",code⇐code,message⇐message}}
MakePlan ← {𝕊 diagnosticsValue‿coordinateRolesValue:{diagnostics⇐diagnosticsValue,coordinate_role⇐coordinateRolesValue}}
Reject ← {𝕊 code‿message:MakePlan ⟨⟨Diagnostic ⟨code,message⟩⟩,empty⟩}
Accept ← {𝕊 coordinateRoles:MakePlan ⟨empty,coordinateRoles⟩}
IsDigits ← {𝕊 text:(0<≠text) ∧ ∧´text∊"0123456789"}

# Catalog-aligned semantic route schema. Request admission owns the catalog
# coordinate; this owner supplies only query-coordinate roles and usage errors.
coordinateRoles ← ⟨
  ⟨"domain","start","end_exclusive","observation"⟩,
  ⟨"domain","as_of"⟩,
  ⟨"domain","as_of"⟩,
  ⟨"domain","start","end_exclusive"⟩,
  ⟨"through","limit"⟩,
  ⟨"observation"⟩,
  ⟨"domain","observation"⟩,
  ⟨"domain","current_observation","baseline_observation","policy"⟩,
  ⟨"domain","first_month","last_month_exclusive"⟩,
  ⟨"domain","start","end_exclusive","observation"⟩,
  ⟨"domain","observation","target"⟩,
  ⟨⟩
⟩
usageCodes ← ⟨
  "usage_envelopes","usage_balances","usage_balance_sheet","usage_profit_and_loss",
  "usage_recent","usage_planned","usage_cycle_accounts","usage_cycle_comparison",
  "usage_monthly_accounts","usage_daily_flow","usage_daily_target","usage_issues"
⟩
usageMessages ← ⟨
  "envelopes requires DOMAIN START END_EXCLUSIVE OBSERVATION",
  "balances requires DOMAIN AS_OF",
  "balance-sheet requires DOMAIN AS_OF",
  "profit-and-loss requires DOMAIN START END_EXCLUSIVE",
  "recent requires THROUGH LIMIT",
  "planned requires OBSERVATION",
  "cycle-accounts requires DOMAIN OBSERVATION",
  "cycle-comparison requires DOMAIN CURRENT_OBS BASELINE_OBS POLICY",
  "monthly-accounts requires DOMAIN FIRST_MONTH LAST_MONTH_EXCLUSIVE",
  "daily-flow requires DOMAIN START END_EXCLUSIVE OBSERVATION",
  "daily-target requires DOMAIN OBSERVATION TARGET",
  "issues takes no source coordinate"
⟩

ShapePlan ← {𝕊 catalogIndex‿coordinates:
  roles ← catalogIndex⊑coordinateRoles
  ((≠roles)=≠coordinates)◶⟨
    {𝕊:Reject ⟨catalogIndex⊑usageCodes,catalogIndex⊑usageMessages⟩},
    {𝕊:Accept roles}
  ⟩ @
}
RoutePlan ← {𝕊 catalogIndex‿coordinates:
  shape ← ShapePlan ⟨catalogIndex,coordinates⟩
  ((0=≠shape.diagnostics) ∧ catalogIndex=4)◶⟨
    {𝕊:shape},
    {𝕊:
      (IsDigits 1⊑coordinates)◶⟨
        {𝕊:Reject ⟨"limit_invalid","LIMIT must be decimal digits"⟩},
        {𝕊:shape}
      ⟩ @
    }
  ⟩ @
}

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
   diagnostics⇐plan.diagnostics}
}

{Admit⇐Admit}
