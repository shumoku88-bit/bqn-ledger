# Pure completed Plan -> completion-day Fulfillment route -> Envelope Fulfillment.
# Stable PlanId owns non-Expense target intent. Actual completion quantities are
# authoritative; current destination Account configuration is never consulted.

completion ← •Import "plan_completion_join.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_fulfillment",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}

EmptyManaged ← {𝕊:{
  count⇐0,index⇐empty,envelope_id⇐empty,fulfillment⇐empty,
  plan_contributors⇐empty,actual_contributors⇐empty,route_source_rows⇐empty
}}
EmptyEvidence ← {𝕊:{
  count⇐0,index⇐empty,plan_id⇐empty,completion_ordinal⇐empty,
  planned_target_account⇐empty,actual_coefficient⇐empty,actual_scale⇐empty,
  route⇐empty,target_id⇐empty,route_source_row⇐empty,
  plan_reference⇐empty,actual_reference⇐empty
}}
EmptyResult ← {𝕊 stateValue‿domainValue‿startValue‿finishValue‿observationValue‿diagnosticsValue:{
  state⇐stateValue,domain⇐domainValue,start_ordinal⇐startValue,
  end_exclusive_ordinal⇐finishValue,observation_ordinal⇐observationValue,scale⇐0,
  managed⇐EmptyManaged @,evidence⇐EmptyEvidence @,diagnostics⇐diagnosticsValue
}}

Build ← {𝕊 planFacts‿actualFacts‿history‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  diagnostics∾↩AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted before Fulfillment observation"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨domain,planFacts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Plan facts"⟩⟩
  diagnostics∾↩AddIf ⟨(start≥finish) ∨ (observation<start) ∨ observation≥finish,Diagnostic ⟨"observation_range_invalid","require start <= observation < end_exclusive"⟩⟩
  diagnostics∾↩AddIf ⟨planFacts.accounts.key≢actualFacts.accounts.key,Diagnostic ⟨"account_axis_mismatch","Plan and Actual facts must share one Account axis"⟩⟩

  routing ← history.fulfillment_routing
  routePlanCoordinates ← planFacts.transactions.plan_id⊐routing.plan_id
  routePlansKnown ← routePlanCoordinates<planFacts.transactions.count
  diagnostics∾↩AddIf ⟨¬∧´1∾routePlansKnown,Diagnostic ⟨"fulfillment_route_plan_unknown","historical Fulfillment routing PlanId must occur in admitted Plan facts"⟩⟩

  result ← EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩
  {𝕊:
    actualSelection ← (actualFacts.transactions.date_ordinal≤observation)/actualFacts.transactions.index
    selectedActualPlanIds ← actualSelection⊏actualFacts.transactions.plan_id
    linkedPlanIds ← ({0<≠𝕩}¨selectedActualPlanIds)/selectedActualPlanIds
    planMask ← {Contains ⟨𝕩,linkedPlanIds⟩}¨planFacts.transactions.plan_id
    planSelection ← planMask/planFacts.transactions.index
    joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
    diagnostics∾↩joined.diagnostics
    diagnostics∾↩AddIf ⟨0<≠joined.unmatched_actual_references,Diagnostic ⟨"completion_plan_unknown","Fulfillment Actual plan_id must name an admitted Plan"⟩⟩
    badStatus ← ∨´0∾{Contains ⟨𝕩,⟨"duplicate","ambiguous"⟩⟩}¨joined.rows.status
    badCurrency ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.currency_matches
    badDirection ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.direction_matches
    diagnostics∾↩AddIf ⟨badStatus ∨ badCurrency ∨ badDirection,Diagnostic ⟨"plan_completion_conflict","Fulfillment completion evidence must be unique and shape-matching"⟩⟩

    {𝕊:
      completedRows ← ("completed"⊸≡¨joined.rows.status)/joined.rows.index
      completionOrdinals ← {dates.Ordinal ⊑𝕩}¨completedRows⊏joined.rows.actual_dates
      targetKeys ← completedRows⊏joined.rows.planned_to_account
      targetCoordinates ← planFacts.accounts.key⊐targetKeys
      targetsKnown ← targetCoordinates<planFacts.accounts.count
      diagnostics∾↩AddIf ⟨¬∧´1∾targetsKnown,Diagnostic ⟨"fulfillment_target_account_unknown","completed Plan target Account must occur on the admitted Account axis"⟩⟩

      {𝕊:
        targetRoles ← targetCoordinates⊏planFacts.accounts.role
        candidateMask ← domain⊸≡¨completedRows⊏joined.rows.currency
        candidateMask ∧↩ (completionOrdinals≥start) ∧ completionOrdinals≤observation
        candidateMask ∧↩ ¬"expense"⊸≡¨targetRoles
        candidateRows ← candidateMask/completedRows

        RouteAt ← {𝕊 row:
          planId ← row⊑joined.rows.plan_id
          day ← dates.Ordinal ⊑row⊑joined.rows.actual_dates
          eligibleMask ← (planId⊸≡¨routing.plan_id) ∧ routing.effective_ordinal≤day
          eligibleRows ← eligibleMask/routing.index
          route ← "none" ⋄ target ← "" ⋄ sourceRow ← 0
          {𝕊:
            ordinals ← eligibleRows⊏routing.effective_ordinal
            latest ← ⌈´ordinals
            latestRows ← (ordinals=latest)/eligibleRows
            diagnostics∾↩AddIf ⟨1≠≠latestRows,Diagnostic ⟨"fulfillment_route_effective_ambiguous","Fulfillment route at completion day must be unique"⟩⟩
            {𝕊:
              routeRow ← ⊑latestRows
              route↩routeRow⊑routing.route
              target↩routeRow⊑routing.target_id
              sourceRow↩routeRow⊑routing.source_row
            }⍟(1=≠latestRows) @
          }⍟(0<≠eligibleRows) @
          {route⇐route,target_id⇐target,source_row⇐sourceRow}
        }
        resolved ← RouteAt¨candidateRows
        routes ← {𝕩.route}¨resolved
        targets ← {𝕩.target_id}¨resolved
        routeRows ← {𝕩.source_row}¨resolved
        managedMask ← "fulfills"⊸≡¨routes
        managedRows ← managedMask/candidateRows
        managedTargets ← managedMask/targets
        envelopeIds ← history.registry.id
        envelopeCoordinates ← envelopeIds⊐managedTargets
        managedTargetsKnown ← envelopeCoordinates<≠envelopeIds
        diagnostics∾↩AddIf ⟨¬∧´1∾managedTargetsKnown,Diagnostic ⟨"fulfillment_route_target_unknown","Fulfillment route must resolve to a stable Envelope identity"⟩⟩

        {𝕊:
          coefficients ← {⊑𝕩}¨managedRows⊏joined.rows.actual_coefficients
          sourceScales ← {⊑𝕩}¨managedRows⊏joined.rows.actual_scales
          targetScale ← ⌈´0∾sourceScales
          normalizedResults ← coefficients {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨sourceScales
          normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
          diagnostics∾↩AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","Fulfillment Actual quantities cannot normalize exactly"⟩⟩
          {𝕊:
            normalized ← {𝕩.coefficient}¨normalizedResults
            envelopeCount ← ≠envelopeIds
            amountGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔normalized
            amountResults ← scale.Sum¨amountGroups
            sumsOk ← ∧´1∾{𝕩.state≡"ok"}¨amountResults
            diagnostics∾↩AddIf ⟨¬sumsOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Fulfillment exceeds exact range"⟩⟩
            {𝕊:
              planGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔managedRows⊏joined.rows.plan_reference
              actualReferences ← {⊑𝕩}¨managedRows⊏joined.rows.actual_references
              actualGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔actualReferences
              routeSourceGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔managedMask/routeRows
              managed ← {
                count⇐envelopeCount,index⇐↕envelopeCount,envelope_id⇐envelopeIds,
                fulfillment⇐{𝕩.coefficient}¨amountResults,
                plan_contributors⇐planGroups,actual_contributors⇐actualGroups,
                route_source_rows⇐routeSourceGroups
              }
              evidenceCoefficients ← {⊑𝕩}¨candidateRows⊏joined.rows.actual_coefficients
              evidenceScales ← {⊑𝕩}¨candidateRows⊏joined.rows.actual_scales
              evidenceActualReferences ← {⊑𝕩}¨candidateRows⊏joined.rows.actual_references
              evidence ← {
                count⇐≠candidateRows,index⇐↕≠candidateRows,
                plan_id⇐candidateRows⊏joined.rows.plan_id,
                completion_ordinal⇐{dates.Ordinal ⊑𝕩}¨candidateRows⊏joined.rows.actual_dates,
                planned_target_account⇐candidateRows⊏joined.rows.planned_to_account,
                actual_coefficient⇐evidenceCoefficients,actual_scale⇐evidenceScales,
                route⇐routes,target_id⇐targets,route_source_row⇐routeRows,
                plan_reference⇐candidateRows⊏joined.rows.plan_reference,
                actual_reference⇐evidenceActualReferences
              }
              result↩{
                state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,
                observation_ordinal⇐observation,scale⇐targetScale,
                managed⇐managed,evidence⇐evidence,diagnostics⇐empty
              }
            }⍟sumsOk @
          }⍟normalizationOk @
        }⍟(0=≠diagnostics) @
      }⍟(∧´1∾targetsKnown) @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
