# Pure open Plan -> observation-day routing -> Envelope Commitment relation.
# Expense targets use historical Expense routing. Non-Expense targets require
# explicit stable PlanId Fulfillment routing. Current budget.toml assignments are
# intentionally not an input.

completion ← •Import "plan_completion_join.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_commitment",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}

EmptyManaged ← {𝕊:{
  count⇐0,index⇐empty,envelope_id⇐empty,commitment⇐empty,
  plan_contributors⇐empty,route_source_rows⇐empty
}}
EmptyLane ← {𝕊:{
  count⇐0,index⇐empty,plan_transaction_index⇐empty,plan_id⇐empty,
  target_account_key⇐empty,coefficient⇐empty,route_source_row⇐empty,
  contributors⇐empty
}}
EmptyEvidence ← {𝕊:{
  count⇐0,index⇐empty,plan_transaction_index⇐empty,plan_id⇐empty,
  plan_date⇐empty,target_account_key⇐empty,target_role⇐empty,
  source_account_key⇐empty,source_role⇐empty,planned_coefficient⇐empty,
  planned_scale⇐empty,route⇐empty,target_id⇐empty,route_source_row⇐empty,
  plan_reference⇐empty
}}
EmptyResult ← {𝕊 stateValue‿domainValue‿startValue‿finishValue‿observationValue‿diagnosticsValue:{
  state⇐stateValue,domain⇐domainValue,start_ordinal⇐startValue,
  end_exclusive_ordinal⇐finishValue,observation_ordinal⇐observationValue,scale⇐0,
  managed⇐EmptyManaged @,unmanaged⇐EmptyLane @,unrouted⇐EmptyLane @,
  evidence⇐EmptyEvidence @,diagnostics⇐diagnosticsValue
}}

Build ← {𝕊 planFacts‿actualFacts‿history‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  diagnostics∾↩AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted before Commitment observation"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨domain,planFacts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Plan facts"⟩⟩
  diagnostics∾↩AddIf ⟨(start≥finish) ∨ (observation<start) ∨ observation≥finish,Diagnostic ⟨"observation_range_invalid","require start <= observation < end_exclusive"⟩⟩
  diagnostics∾↩AddIf ⟨planFacts.accounts.key≢actualFacts.accounts.key,Diagnostic ⟨"account_axis_mismatch","Plan and Actual facts must share one Account axis"⟩⟩

  expenseRouting ← history.expense_routing
  expenseRouteCoordinates ← planFacts.accounts.key⊐expenseRouting.expense_account_key
  expenseRoutesKnown ← expenseRouteCoordinates<planFacts.accounts.count
  expenseRouteRoles ← expenseRouteCoordinates⊏planFacts.accounts.role∾⟨""⟩
  diagnostics∾↩AddIf ⟨¬∧´1∾expenseRoutesKnown,Diagnostic ⟨"expense_route_account_unknown","historical Expense routing Account must occur in admitted Plan facts"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾expenseRoutesKnown ∧ ¬"expense"⊸≡¨expenseRouteRoles,Diagnostic ⟨"expense_route_account_role_invalid","historical Expense routing Account must retain Expense role"⟩⟩

  fulfillmentRouting ← history.fulfillment_routing
  fulfillmentPlanCoordinates ← planFacts.transactions.plan_id⊐fulfillmentRouting.plan_id
  fulfillmentPlansKnown ← fulfillmentPlanCoordinates<planFacts.transactions.count
  diagnostics∾↩AddIf ⟨¬∧´1∾fulfillmentPlansKnown,Diagnostic ⟨"fulfillment_route_plan_unknown","historical Fulfillment routing PlanId must occur in admitted Plan facts"⟩⟩

  result ← EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩
  {𝕊:
    planSelection ← (planFacts.transactions.date_ordinal<finish)/planFacts.transactions.index
    actualSelection ← (actualFacts.transactions.date_ordinal≤observation)/actualFacts.transactions.index
    joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
    diagnostics∾↩joined.diagnostics
    badStatus ← ∨´0∾{Contains ⟨𝕩,⟨"duplicate","ambiguous"⟩⟩}¨joined.rows.status
    badCurrency ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.currency_matches
    badDirection ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.direction_matches
    diagnostics∾↩AddIf ⟨badStatus ∨ badCurrency ∨ badDirection,Diagnostic ⟨"plan_completion_conflict","Commitment completion evidence must be unique and shape-matching"⟩⟩

    {𝕊:
      openMask ← ("open"⊸≡¨joined.rows.status) ∧ domain⊸≡¨joined.rows.currency
      openRows ← openMask/joined.rows.index
      openPlanIds ← openRows⊏joined.rows.plan_id
      targetKeys ← openRows⊏joined.rows.planned_to_account
      sourceKeys ← openRows⊏joined.rows.planned_from_account
      targetCoordinates ← planFacts.accounts.key⊐targetKeys
      sourceCoordinates ← planFacts.accounts.key⊐sourceKeys
      targetsKnown ← targetCoordinates<planFacts.accounts.count
      sourcesKnown ← sourceCoordinates<planFacts.accounts.count
      accountsKnown ← (∧´1∾targetsKnown) ∧ ∧´1∾sourcesKnown
      diagnostics∾↩AddIf ⟨¬accountsKnown,Diagnostic ⟨"plan_account_unknown","open Plan source/target Accounts must occur on the admitted Account axis"⟩⟩

      {𝕊:
        targetRoles ← targetCoordinates⊏planFacts.accounts.role
        sourceRoles ← sourceCoordinates⊏planFacts.accounts.role
        expenseTargets ← "expense"⊸≡¨targetRoles
        invalidExpenseFlow ← expenseTargets ∧ ¬"asset"⊸≡¨sourceRoles
        diagnostics∾↩AddIf ⟨∨´0∾invalidExpenseFlow,Diagnostic ⟨"expense_commitment_flow_invalid","positive Expense commitment requires an Asset funding source"⟩⟩

        ExpenseRouteAt ← {𝕊 key:
          eligibleMask ← (key⊸≡¨expenseRouting.expense_account_key) ∧ (expenseRouting.initial ∨ expenseRouting.effective_ordinal≤observation)
          eligibleRows ← eligibleMask/expenseRouting.index
          route ← "unrouted" ⋄ target ← "" ⋄ sourceRow ← 0
          {𝕊:
            ordinals ← eligibleRows⊏expenseRouting.effective_ordinal
            latest ← ⌈´ordinals
            latestRows ← (ordinals=latest)/eligibleRows
            diagnostics∾↩AddIf ⟨1≠≠latestRows,Diagnostic ⟨"expense_route_effective_ambiguous","Expense route at observation day must be unique"⟩⟩
            {𝕊:
              routeRow ← ⊑latestRows
              route↩routeRow⊑expenseRouting.route
              target↩routeRow⊑expenseRouting.target_id
              sourceRow↩routeRow⊑expenseRouting.source_row
            }⍟(1=≠latestRows) @
          }⍟(0<≠eligibleRows) @
          {route⇐route,target_id⇐target,source_row⇐sourceRow}
        }
        FulfillmentRouteAt ← {𝕊 planId:
          eligibleMask ← (planId⊸≡¨fulfillmentRouting.plan_id) ∧ fulfillmentRouting.effective_ordinal≤observation
          eligibleRows ← eligibleMask/fulfillmentRouting.index
          route ← "none" ⋄ target ← "" ⋄ sourceRow ← 0
          {𝕊:
            ordinals ← eligibleRows⊏fulfillmentRouting.effective_ordinal
            latest ← ⌈´ordinals
            latestRows ← (ordinals=latest)/eligibleRows
            diagnostics∾↩AddIf ⟨1≠≠latestRows,Diagnostic ⟨"fulfillment_route_effective_ambiguous","Fulfillment route at observation day must be unique"⟩⟩
            {𝕊:
              routeRow ← ⊑latestRows
              route↩routeRow⊑fulfillmentRouting.route
              target↩routeRow⊑fulfillmentRouting.target_id
              sourceRow↩routeRow⊑fulfillmentRouting.source_row
            }⍟(1=≠latestRows) @
          }⍟(0<≠eligibleRows) @
          {route⇐route,target_id⇐target,source_row⇐sourceRow}
        }
        ResolveRow ← {𝕊 i:
          (i⊑expenseTargets)◶⟨
            {𝕊:FulfillmentRouteAt i⊑openPlanIds},
            {𝕊:ExpenseRouteAt i⊑targetKeys}
          ⟩ @
        }
        resolved ← ResolveRow¨↕≠openRows
        routes ← {𝕩.route}¨resolved
        routeTargets ← {𝕩.target_id}¨resolved
        routeRows ← {𝕩.source_row}¨resolved
        managedMask ← ("managed"⊸≡¨routes) ∨ "fulfills"⊸≡¨routes
        unmanagedMask ← "unmanaged"⊸≡¨routes
        unroutedMask ← "unrouted"⊸≡¨routes
        relevantMask ← managedMask ∨ unmanagedMask ∨ unroutedMask
        relevantRows ← relevantMask/openRows
        relevantRoutes ← relevantMask/routes
        relevantTargets ← relevantMask/routeTargets
        relevantRouteRows ← relevantMask/routeRows
        coefficients ← relevantRows⊏joined.rows.planned_coefficient
        sourceScales ← relevantRows⊏joined.rows.planned_scale
        targetScale ← ⌈´0∾sourceScales
        normalizedResults ← coefficients {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨sourceScales
        normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
        diagnostics∾↩AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","open Plan commitment quantities cannot normalize exactly"⟩⟩

        {𝕊:
          normalized ← {𝕩.coefficient}¨normalizedResults
          relevantManagedMask ← ("managed"⊸≡¨relevantRoutes) ∨ "fulfills"⊸≡¨relevantRoutes
          relevantUnmanagedMask ← "unmanaged"⊸≡¨relevantRoutes
          relevantUnroutedMask ← "unrouted"⊸≡¨relevantRoutes
          managedTargets ← relevantManagedMask/relevantTargets
          envelopeIds ← history.registry.id
          envelopeCoordinates ← envelopeIds⊐managedTargets
          managedTargetsKnown ← envelopeCoordinates<≠envelopeIds
          diagnostics∾↩AddIf ⟨¬∧´1∾managedTargetsKnown,Diagnostic ⟨"commitment_route_target_unknown","managed Commitment route must resolve to a stable Envelope identity"⟩⟩
          {𝕊:
            envelopeCount ← ≠envelopeIds
            managedAmounts ← relevantManagedMask/normalized
            amountGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔managedAmounts
            amountResults ← scale.Sum¨amountGroups
            sumsOk ← ∧´1∾{𝕩.state≡"ok"}¨amountResults
            diagnostics∾↩AddIf ⟨¬sumsOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Commitment exceeds exact range"⟩⟩
            Lane ← {𝕊 mask:
              rows ← mask/relevantRows
              {
                count⇐≠rows,index⇐↕≠rows,plan_transaction_index⇐rows⊏joined.rows.plan_transaction_index,
                plan_id⇐rows⊏joined.rows.plan_id,target_account_key⇐rows⊏joined.rows.planned_to_account,
                coefficient⇐mask/normalized,route_source_row⇐mask/relevantRouteRows,
                contributors⇐rows⊏joined.rows.plan_reference
              }
            }
            {𝕊:
              managedReferences ← relevantManagedMask/(relevantRows⊏joined.rows.plan_reference)
              planGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔managedReferences
              routeSourceGroups ← (envelopeCoordinates∾⟨envelopeCount⟩)⊔relevantManagedMask/relevantRouteRows
              managed ← {
                count⇐envelopeCount,index⇐↕envelopeCount,envelope_id⇐envelopeIds,
                commitment⇐{𝕩.coefficient}¨amountResults,
                plan_contributors⇐planGroups,route_source_rows⇐routeSourceGroups
              }
              evidence ← {
                count⇐≠openRows,index⇐↕≠openRows,
                plan_transaction_index⇐openRows⊏joined.rows.plan_transaction_index,
                plan_id⇐openPlanIds,plan_date⇐openRows⊏joined.rows.plan_date,
                target_account_key⇐targetKeys,target_role⇐targetRoles,
                source_account_key⇐sourceKeys,source_role⇐sourceRoles,
                planned_coefficient⇐openRows⊏joined.rows.planned_coefficient,
                planned_scale⇐openRows⊏joined.rows.planned_scale,
                route⇐routes,target_id⇐routeTargets,route_source_row⇐routeRows,
                plan_reference⇐openRows⊏joined.rows.plan_reference
              }
              result↩{
                state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,
                observation_ordinal⇐observation,scale⇐targetScale,managed⇐managed,
                unmanaged⇐Lane relevantUnmanagedMask,unrouted⇐Lane relevantUnroutedMask,
                evidence⇐evidence,diagnostics⇐empty
              }
            }⍟sumsOk @
          }⍟(0=≠diagnostics) @
        }⍟normalizationOk @
      }⍟accountsKnown @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
