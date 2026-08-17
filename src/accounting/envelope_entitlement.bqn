# Pure admitted Entitlement source -> Envelope Entitlement observation.
#
# Input shape:
#   entitlementSource: source-ordered admitted Entitlement relation from entitlement.journal;
#     owns StockOrigins and Transfer cells;
#   envelopeHistory: stable historical Envelope identities from household.toml [envelope-history];
#   domain: selected Currency / Commodity string;
#   start: statement window start ordinal;
#   finish: statement window end-exclusive ordinal;
#   observation: observation day ordinal.
#
# Semantic rules:
#   - Each transfer from/to endpoint projects directly onto the stable Envelope axis:
#     an Envelope source contributes a negative effect and an Envelope destination
#     contributes a positive effect.
#   - unallocated is an open boundary endpoint without a stored balance pool.
#   - Every published coefficient is normalized to observationScale.
#   - [start, finish) and observation cutoffs exclude future rows; admitted rows before
#     start carry historical opening positions.
#   - StockOrigin for domain is exposed as first-class evidence for live stock horizon.

scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message: {severity⇐"error",stage⇐"accounting_envelope_entitlement",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}

EmptyObservation ← {𝕊:
  {
    count⇐0,index⇐empty,envelope_id⇐empty,amount⇐empty,effective_ordinal⇐empty,
    source_event_id⇐empty,source_line⇐empty,source_posting_index⇐empty,
    source_posting_id⇐empty,contributors⇐empty
  }
}
EmptyManaged ← {𝕊: {count⇐0,index⇐empty,envelope_id⇐empty,entitlement⇐empty,contributors⇐empty}}
EmptyOrigin ← {𝕊: {present⇐0,date⇐"",date_ordinal⇐0,commodity⇐"",memo⇐"",source_event_id⇐"",source_line⇐0}}

EmptyResult ← {𝕊 stateValue‿domainValue‿startValue‿finishValue‿observationValue‿diagnosticsValue:
  {
    state⇐stateValue,domain⇐domainValue,start_ordinal⇐startValue,
    end_exclusive_ordinal⇐finishValue,observation_ordinal⇐observationValue,
    scale⇐0,managed⇐EmptyManaged @,observations⇐EmptyObservation @,
    origin⇐EmptyOrigin @,diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 entitlementSource‿envelopeHistory‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨(entitlementSource.state≢"ok") ∨ entitlementSource.source_name≢"entitlement.journal", Diagnostic ⟨"entitlement_source_invalid","Entitlement source must be admitted from entitlement.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨(envelopeHistory.state≢"ok") ∨ envelopeHistory.source_name≢"household.toml", Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted from household.toml"⟩⟩

  hasOrigins ← 0<entitlementSource.origins.count
  hasTransfers ← 0<entitlementSource.transfers.count
  hasAny ← hasOrigins ∨ hasTransfers
  diagnostics ∾↩ AddIf ⟨hasAny ∧ ¬Contains ⟨domain,entitlementSource.declared_domains⟩, Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Entitlement declarations"⟩⟩
  diagnostics ∾↩ AddIf ⟨(start≥finish) ∨ (observation<start) ∨ observation≥finish, Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩

  result ← EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩

  {𝕊:
    envelopeIds ← envelopeHistory.registry.id
    envelopeCount ← ≠envelopeIds

    # Extract domain StockOrigin
    originCommodities ← entitlementSource.origins.commodity
    matchingOriginIndices ← (domain⊸≡¨originCommodities)/entitlementSource.origins.index
    originPresent ← 1 = ≠matchingOriginIndices
    originDate ← ⊑ (matchingOriginIndices⊏entitlementSource.origins.date) ∾ ⟨""⟩
    originOrdinal ← ⊑ (matchingOriginIndices⊏entitlementSource.origins.date_ordinal) ∾ ⟨observation+1⟩
    originMemo ← ⊑ (matchingOriginIndices⊏entitlementSource.origins.memo) ∾ ⟨""⟩
    originEventId ← ⊑ (matchingOriginIndices⊏entitlementSource.origins.source_event_id) ∾ ⟨""⟩
    originLine ← ⊑ (matchingOriginIndices⊏entitlementSource.origins.source_line) ∾ ⟨0⟩
    originCarrier ← {
      present⇐originPresent,
      date⇐originDate,
      date_ordinal⇐originOrdinal,
      commodity⇐domain,
      memo⇐originMemo,
      source_event_id⇐originEventId,
      source_line⇐originLine
    }

    # T transfers become ragged two-endpoint cells in source order. Filtering
    # unallocated inside each cell and then joining preserves T-major from/to
    # order while publishing aligned Envelope-effect columns.
    transferRows ← (domain⊸≡¨entitlementSource.transfers.commodity)/entitlementSource.transfers.index
    transferDates ← transferRows⊏entitlementSource.transfers.date_ordinal
    fromEndpoints ← transferRows⊏entitlementSource.transfers.from
    toEndpoints ← transferRows⊏entitlementSource.transfers.to
    transferCoefficients ← transferRows⊏entitlementSource.transfers.coefficient
    transferScales ← transferRows⊏entitlementSource.transfers.scale
    sourceLines ← transferRows⊏entitlementSource.transfers.source_line
    sourceEvents ← transferRows⊏entitlementSource.transfers.source_event_id

    endpointCells ← fromEndpoints {⟨𝕨,𝕩⟩}¨ toEndpoints
    envelopeMasks ← {"unallocated"⊸≢¨𝕩}¨endpointCells
    targetCells ← {envelopeIds⊐𝕩}¨endpointCells
    amountCells ← {𝕩×¯1‿1}¨transferCoefficients
    dateCells ← {2⥊𝕩}¨transferDates
    scaleCells ← {2⥊𝕩}¨transferScales
    eventCells ← {2⥊⟨𝕩⟩}¨sourceEvents
    lineCells ← {2⥊𝕩}¨sourceLines
    postingIndexCells ← {𝕩 ⋄ 0‿1}¨transferRows
    includedCells ← {2⥊𝕩}¨((transferDates<finish) ∧ transferDates≤observation)
    contributorCells ← sourceLines {
      line ← 𝕨 ⋄ event ← 𝕩
      2⥊⟨{source⇐"entitlement.journal",line⇐line,event_id⇐event,posting_id⇐event}⟩
    }¨ sourceEvents
    JoinSelected ← {𝕊 masks‿cells: ∾masks {𝕨/𝕩}¨ cells}

    allTargets ← JoinSelected ⟨envelopeMasks,targetCells⟩
    allAmounts ← JoinSelected ⟨envelopeMasks,amountCells⟩
    allDates ← JoinSelected ⟨envelopeMasks,dateCells⟩
    allScales ← JoinSelected ⟨envelopeMasks,scaleCells⟩
    allEvents ← JoinSelected ⟨envelopeMasks,eventCells⟩
    allLines ← JoinSelected ⟨envelopeMasks,lineCells⟩
    allPostingIndices ← JoinSelected ⟨envelopeMasks,postingIndexCells⟩
    allContributors ← JoinSelected ⟨envelopeMasks,contributorCells⟩
    allIncluded ← JoinSelected ⟨envelopeMasks,includedCells⟩

    diagnostics ∾↩ AddIf ⟨¬∧´1∾allTargets<envelopeCount, Diagnostic ⟨"envelope_identity_missing","Entitlement effect must resolve to a stable Envelope identity"⟩⟩

    {𝕊:
      effectTargets ← allIncluded/allTargets
      effectAmounts ← allIncluded/allAmounts
      effectDates ← allIncluded/allDates
      effectScales ← allIncluded/allScales
      effectEvents ← allIncluded/allEvents
      effectLines ← allIncluded/allLines
      effectPostingIndices ← allIncluded/allPostingIndices
      effectPostingIds ← effectEvents
      effectContributors ← allIncluded/allContributors

      observationScale ← ⌈´0∾effectScales
      normalizedObsResults ← effectAmounts {scale.Normalize ⟨𝕨,𝕩,observationScale⟩}¨ effectScales
      obsNormalizedOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedObsResults
      diagnostics ∾↩ AddIf ⟨¬obsNormalizedOk, Diagnostic ⟨"coefficient_normalization_failed","Entitlement transfer cannot normalize exactly"⟩⟩

      {𝕊:
        normalizedObsAmounts ← {𝕩.coefficient}¨normalizedObsResults
        valueGroups ← (effectTargets∾envelopeCount)⊔normalizedObsAmounts
        contributorGroups ← (effectTargets∾envelopeCount)⊔effectContributors
        entitlementResults ← scale.Sum¨valueGroups
        entitlementOk ← ∧´1∾{𝕩.state≡"ok"}¨entitlementResults
        diagnostics ∾↩ AddIf ⟨¬entitlementOk, Diagnostic ⟨"coefficient_sum_failed","Envelope Entitlement exceeds exact range"⟩⟩

        {𝕊:
          result ↩ {
            state⇐"ok",
            domain⇐domain,
            start_ordinal⇐start,
            end_exclusive_ordinal⇐finish,
            observation_ordinal⇐observation,
            scale⇐observationScale,
            managed⇐{
              count⇐envelopeCount,
              index⇐↕envelopeCount,
              envelope_id⇐envelopeIds,
              entitlement⇐{𝕩.coefficient}¨entitlementResults,
              contributors⇐contributorGroups
            },
            observations⇐{
              count⇐≠effectTargets,
              index⇐↕≠effectTargets,
              envelope_id⇐effectTargets⊏envelopeIds,
              amount⇐normalizedObsAmounts,
              effective_ordinal⇐effectDates,
              source_event_id⇐effectEvents,
              source_line⇐effectLines,
              source_posting_index⇐effectPostingIndices,
              source_posting_id⇐effectPostingIds,
              contributors⇐effectContributors
            },
            origin⇐originCarrier,
            diagnostics⇐empty
          }
        }⍟entitlementOk @
      }⍟obsNormalizedOk @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {𝕊: result ↩ EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}