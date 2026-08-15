# Completed Plan -> completion-day Fulfillment route -> Envelope Fulfillment.
# Lifecycle identity is role-neutral. Only `fulfills` pairs are shape-validated;
# positive non-Expense Plan posting positions select authoritative Actual amounts.

planObservation ← •Import "plan_observation.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_fulfillment",code⇐code,message⇐message}}
AddIf ← {𝕊 bad‿d:bad/⟨d⟩}
PostingIndices ← {𝕊 facts‿tx:(tx⊸=facts.postings.transaction_index)/facts.postings.index}
EmptyManaged ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,fulfillment⇐empty,plan_contributors⇐empty,actual_contributors⇐empty,posting_contributors⇐empty,route_source_rows⇐empty}}
EmptyEvidence ← {𝕊:{count⇐0,index⇐empty,plan_id⇐empty,completion_ordinal⇐empty,target_account_key⇐empty,actual_coefficient⇐empty,actual_scale⇐empty,route⇐empty,target_id⇐empty,route_source_row⇐empty,plan_reference⇐empty,actual_reference⇐empty,actual_posting_reference⇐empty}}
EmptyResult ← {𝕊 state‿domain‿start‿finish‿observation‿ds:{state⇐state,domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐0,managed⇐EmptyManaged @,evidence⇐EmptyEvidence @,diagnostics⇐ds}}
RouteAt ← {𝕊 planId‿day‿routing:
  mask←(planId⊸≡¨routing.plan_id)∧routing.effective_ordinal≤day ⋄ rows←mask/routing.index ⋄ route←"none" ⋄ target←"" ⋄ sourceRow←0 ⋄ ambiguous←0
  {𝕊:ords←rows⊏routing.effective_ordinal ⋄ latest←⌈´ords ⋄ rs←(ords=latest)/rows ⋄ ambiguous↩1≠≠rs ⋄ {𝕊:r←⊑rs ⋄ route↩r⊑routing.route ⋄ target↩r⊑routing.target_id ⋄ sourceRow↩r⊑routing.source_row}⍟(1=≠rs) @}⍟(0<≠rows) @
  {route⇐route,target_id⇐target,source_row⇐sourceRow,ambiguous⇐ambiguous}}

# [start,finish) may be zero-width when no native Entitlement origin exists yet.
# In that case the empty horizon must remain an ordinary empty array observation,
# not a fabricated current-Period Fulfillment.
Build ← {𝕊 planFacts‿retirements‿actualFacts‿history‿domain‿start‿finish‿observation:
  ds←empty ⋄ ds∾↩AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted"⟩⟩
  domainKnown←∨´0∾domain⊸≡¨actualFacts.domains.code ⋄ ds∾↩AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in Actual facts"⟩⟩
  emptyHorizon←(start=finish)∧start=observation+1
  rangeInvalid←(start>finish)∨(¬emptyHorizon∧((observation<start)∨observation≥finish))
  ds∾↩AddIf ⟨rangeInvalid,Diagnostic ⟨"observation_range_invalid","require start <= observation < end_exclusive, or the canonical empty post-observation horizon"⟩⟩
  ds∾↩AddIf ⟨planFacts.accounts.key≢actualFacts.accounts.key,Diagnostic ⟨"account_axis_mismatch","Plan and Actual must share Account axis"⟩⟩
  routeCoords←planFacts.transactions.plan_id⊐history.fulfillment_routing.plan_id
  ds∾↩AddIf ⟨¬∧´1∾routeCoords<planFacts.transactions.count,Diagnostic ⟨"fulfillment_route_plan_unknown","Fulfillment route PlanId must be admitted"⟩⟩
  result←EmptyResult ⟨"error",domain,start,finish,observation,ds⟩
  {𝕊:
    life←planObservation.Build ⟨planFacts,retirements,actualFacts,observation⟩ ⋄ ds∾↩life.diagnostics
    {𝕊:
      c←life.completed ⋄ completionDays←c.actual_transaction_index⊏actualFacts.transactions.date_ordinal
      completedDomainCodes←(c.plan_transaction_index⊏planFacts.transactions.domain_index)⊏planFacts.domains.code
      routes←{RouteAt ⟨𝕩⊑c.plan_id,𝕩⊑completionDays,history.fulfillment_routing⟩}¨c.index
      ds∾↩AddIf ⟨∨´0∾{𝕩.ambiguous}¨routes,Diagnostic ⟨"fulfillment_route_effective_ambiguous","completion-day route must be unique"⟩⟩
      routeNames←{𝕩.route}¨routes ⋄ routeTargets←{𝕩.target_id}¨routes ⋄ routeRows←{𝕩.source_row}¨routes
      routedMask←("fulfills"⊸≡¨routeNames)∧domain⊸≡¨completedDomainCodes ⋄ routedMask∧↩completionDays≥start
      routedRows←routedMask/c.index
      ShapeOk←{𝕊 row:
        pt←row⊑c.plan_transaction_index ⋄ at←row⊑c.actual_transaction_index ⋄ pp←PostingIndices ⟨planFacts,pt⟩ ⋄ ap←PostingIndices ⟨actualFacts,at⟩
        accountOk←(pp⊏planFacts.postings.account_index)≡ap⊏actualFacts.postings.account_index
        sideOk←(pp⊏planFacts.postings.side)≡ap⊏actualFacts.postings.side
        commodityOk←((pt⊑planFacts.transactions.domain_index)⊑planFacts.domains.code)≡(at⊑actualFacts.transactions.domain_index)⊑actualFacts.domains.code
        ds∾↩AddIf ⟨¬accountOk,Diagnostic ⟨"fulfillment_completion_account_shape_mismatch","Plan/Actual Account order must match"⟩⟩
        ds∾↩AddIf ⟨¬sideOk,Diagnostic ⟨"fulfillment_completion_direction_mismatch","Plan/Actual posting directions must match"⟩⟩
        ds∾↩AddIf ⟨¬commodityOk,Diagnostic ⟨"fulfillment_completion_commodity_mismatch","Plan/Actual Commodity must match"⟩⟩}
      ShapeOk¨routedRows
      {𝕊:
        TargetCell←{𝕊 row:
          pt←row⊑c.plan_transaction_index ⋄ at←row⊑c.actual_transaction_index ⋄ pp←PostingIndices ⟨planFacts,pt⟩ ⋄ ap←PostingIndices ⟨actualFacts,at⟩
          roles←(pp⊏planFacts.postings.account_index)⊏planFacts.accounts.role ⋄ mask←(pp⊏planFacts.postings.coefficient)>0 ⋄ mask∧↩¬"expense"⊸≡¨roles ⋄ pos←mask/↕≠pp
          {count⇐≠pos,row⇐row,plan_posting⇐pos⊏pp,actual_posting⇐pos⊏ap}}
        cells←TargetCell¨routedRows ⋄ entryRows←∾{𝕩.count⥊𝕩.row}¨cells ⋄ planPostings←∾{𝕩.plan_posting}¨cells ⋄ actualPostings←∾{𝕩.actual_posting}¨cells
        targets←entryRows⊏routeTargets ⋄ sourceRows←entryRows⊏routeRows ⋄ envelopeIds←history.registry.id ⋄ envelopeCoords←envelopeIds⊐targets
        ds∾↩AddIf ⟨¬∧´1∾envelopeCoords<≠envelopeIds,Diagnostic ⟨"fulfillment_route_target_unknown","Fulfillment route target must be a stable Envelope"⟩⟩
        coefficients←actualPostings⊏actualFacts.postings.coefficient ⋄ sourceScales←actualPostings⊏actualFacts.postings.scale ⋄ targetScale←⌈´0∾sourceScales
        norms←coefficients {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨sourceScales ⋄ ds∾↩AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨norms,Diagnostic ⟨"coefficient_normalization_failed","Fulfillment quantities cannot normalize exactly"⟩⟩
        {𝕊:
          normalized←{𝕩.coefficient}¨norms ⋄ sums←{scale.Sum (envelopeCoords=𝕩)/normalized}¨↕≠envelopeIds
          ds∾↩AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨sums,Diagnostic ⟨"coefficient_sum_failed","Envelope Fulfillment exceeds exact range"⟩⟩
          {𝕊:
            planRefs←entryRows⊏c.plan_reference ⋄ actualRefs←entryRows⊏c.actual_reference ⋄ postingRefs←{reference.Posting ⟨actualFacts,𝕩⟩}¨actualPostings
            managed←{count⇐≠envelopeIds,index⇐↕≠envelopeIds,envelope_id⇐envelopeIds,fulfillment⇐{𝕩.coefficient}¨sums,plan_contributors⇐{(envelopeCoords=𝕩)/planRefs}¨↕≠envelopeIds,actual_contributors⇐{(envelopeCoords=𝕩)/actualRefs}¨↕≠envelopeIds,posting_contributors⇐{(envelopeCoords=𝕩)/postingRefs}¨↕≠envelopeIds,route_source_rows⇐{(envelopeCoords=𝕩)/sourceRows}¨↕≠envelopeIds}
            evidence←{count⇐≠entryRows,index⇐↕≠entryRows,plan_id⇐entryRows⊏c.plan_id,completion_ordinal⇐entryRows⊏completionDays,target_account_key⇐(planPostings⊏planFacts.postings.account_index)⊏planFacts.accounts.key,actual_coefficient⇐coefficients,actual_scale⇐sourceScales,route⇐(≠entryRows)⥊⟨"fulfills"⟩,target_id⇐targets,route_source_row⇐sourceRows,plan_reference⇐planRefs,actual_reference⇐actualRefs,actual_posting_reference⇐postingRefs}
            result↩{state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐targetScale,managed⇐managed,evidence⇐evidence,diagnostics⇐empty}
          }⍟(0=≠ds) @
        }⍟(0=≠ds) @
      }⍟(0=≠ds) @
    }⍟(0=≠ds) @
  }⍟(0=≠ds) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,ds⟩}⍟(0<≠ds) @ ⋄ result
}
{Build⇐Build}
