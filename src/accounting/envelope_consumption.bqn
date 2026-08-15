# Pure Actual Posting -> historical Expense route -> Envelope Consumption relation.
# Routing is resolved at each Posting day before any Account or Envelope grouping.
# Current budget.toml Expense assignments are intentionally not an input.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_consumption",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}
PostingReferences ← {𝕊 facts‿indices:{reference.Posting ⟨facts,𝕩⟩}¨indices}

EmptyManaged ← {𝕊:{
  count⇐0,index⇐empty,envelope_id⇐empty,consumption⇐empty,refunds⇐empty,
  consumption_contributors⇐empty,refund_contributors⇐empty,
  consumption_route_source_rows⇐empty,refund_route_source_rows⇐empty
}}
EmptyLane ← {𝕊:{
  count⇐0,index⇐empty,posting_index⇐empty,account_index⇐empty,account_key⇐empty,
  date_ordinal⇐empty,side⇐empty,coefficient⇐empty,route_source_row⇐empty,
  contributors⇐empty
}}
EmptyEvidence ← {𝕊:{
  count⇐0,index⇐empty,posting_index⇐empty,account_index⇐empty,account_key⇐empty,
  date_ordinal⇐empty,side⇐empty,coefficient⇐empty,route⇐empty,target_id⇐empty,
  route_source_row⇐empty
}}
EmptyResult ← {𝕊 stateValue‿domainValue‿diagnosticsValue:{
  state⇐stateValue,domain⇐domainValue,start_ordinal⇐0,end_exclusive_ordinal⇐0,scale⇐0,
  managed⇐EmptyManaged @,unrouted⇐EmptyLane @,unmanaged⇐EmptyLane @,
  evidence⇐EmptyEvidence @,diagnostics⇐diagnosticsValue
}}

Lane ← {𝕊 facts‿mask‿postingIndices‿accountIndices‿accountKeys‿dates‿sides‿coefficients‿routeRows:
  indices ← mask/postingIndices
  {
    count⇐≠indices,index⇐↕≠indices,posting_index⇐indices,
    account_index⇐mask/accountIndices,account_key⇐mask/accountKeys,
    date_ordinal⇐mask/dates,side⇐mask/sides,coefficient⇐mask/coefficients,
    route_source_row⇐mask/routeRows,contributors⇐PostingReferences ⟨facts,indices⟩
  }
}

# Input: admitted Actual Facts, admitted Envelope history, domain, start, end-exclusive.
Build ← {𝕊 facts‿history‿domain‿start‿finish:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨facts.state≢"ok",Diagnostic ⟨"facts_not_ok","Actual facts must be ok"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Facts must be admitted from actual.journal"⟩⟩
  diagnostics∾↩AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history admission must be ok"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨domain,facts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Actual Facts"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨"actual",facts.layers.name⟩,Diagnostic ⟨"actual_layer_unknown","Actual Facts must declare the actual layer"⟩⟩
  diagnostics∾↩AddIf ⟨start≥finish,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩

  routing ← history.expense_routing
  routeAccountCoordinates ← facts.accounts.key⊐routing.expense_account_key
  routeAccountsKnown ← routeAccountCoordinates<facts.accounts.count
  routeAccountRoles ← routeAccountCoordinates⊏facts.accounts.role∾⟨""⟩
  diagnostics∾↩AddIf ⟨¬∧´1∾routeAccountsKnown,Diagnostic ⟨"expense_route_account_unknown","historical Expense routing Account must occur in Actual Facts"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾routeAccountsKnown ∧ ¬"expense"⊸≡¨routeAccountRoles,Diagnostic ⟨"expense_route_account_role_invalid","historical Expense routing Account must retain Expense role"⟩⟩

  result ← EmptyResult ⟨"error",domain,diagnostics⟩
  {𝕊:
    domainIndex ← IndexOf ⟨domain,facts.domains.code⟩
    layerIndex ← IndexOf ⟨"actual",facts.layers.name⟩
    postings ← facts.postings
    postingAccountRoles ← postings.account_index⊏facts.accounts.role
    selectedMask ← (domainIndex=postings.domain_index) ∧ (layerIndex=postings.layer_index) ∧
      (postings.date_ordinal≥start) ∧ (postings.date_ordinal<finish) ∧ "expense"⊸≡¨postingAccountRoles
    postingIndices ← selectedMask/postings.index
    accountIndices ← selectedMask/postings.account_index
    accountKeys ← accountIndices⊏facts.accounts.key
    postingDates ← selectedMask/postings.date_ordinal
    sides ← selectedMask/postings.side
    coefficients ← selectedMask/postings.coefficient
    sourceScales ← selectedMask/postings.scale
    amountScale ← ⌈´0∾sourceScales
    normalizedResults ← coefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨sourceScales
    normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
    diagnostics∾↩AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected Expense postings cannot normalize exactly"⟩⟩

    {𝕊:
      normalized ← {𝕩.coefficient}¨normalizedResults
      RouteAt ← {𝕊 i:
        key ← i⊑accountKeys ⋄ day ← i⊑postingDates
        eligibleMask ← (key⊸≡¨routing.expense_account_key) ∧ (routing.initial ∨ routing.effective_ordinal≤day)
        eligibleRows ← eligibleMask/routing.index
        route ← "unrouted" ⋄ target ← "" ⋄ sourceRow ← 0
        {𝕊:
          ordinals ← eligibleRows⊏routing.effective_ordinal
          latest ← ⌈´ordinals
          latestRows ← (ordinals=latest)/eligibleRows
          unique ← 1=≠latestRows
          diagnostics∾↩AddIf ⟨¬unique,Diagnostic ⟨"expense_route_effective_ambiguous","historical Expense route at Posting day must be unique"⟩⟩
          {𝕊:
            row ← ⊑latestRows
            route↩row⊑routing.route ⋄ target↩row⊑routing.target_id ⋄ sourceRow↩row⊑routing.source_row
          }⍟unique @
        }⍟(0<≠eligibleRows) @
        {route⇐route,target_id⇐target,source_row⇐sourceRow}
      }
      resolved ← RouteAt¨↕≠postingIndices
      routes ← {𝕩.route}¨resolved
      targets ← {𝕩.target_id}¨resolved
      routeRows ← {𝕩.source_row}¨resolved
      managedMask ← "managed"⊸≡¨routes
      unmanagedMask ← "unmanaged"⊸≡¨routes
      unroutedMask ← "unrouted"⊸≡¨routes
      envelopeIds ← history.registry.id
      managedTargetCoordinates ← envelopeIds⊐managedMask/targets
      managedTargetsKnown ← managedTargetCoordinates<≠envelopeIds
      diagnostics∾↩AddIf ⟨¬∧´1∾managedTargetsKnown,Diagnostic ⟨"expense_route_target_unknown","managed historical route must resolve to a stable Envelope identity"⟩⟩

      {𝕊:
        debitMask ← "debit"⊸≡¨sides
        creditMask ← "credit"⊸≡¨sides
        chargeMask ← managedMask ∧ debitMask
        refundMask ← managedMask ∧ creditMask
        chargeCoordinates ← envelopeIds⊐chargeMask/targets
        refundCoordinates ← envelopeIds⊐refundMask/targets
        envelopeCount ← ≠envelopeIds
        chargeGroups ← (chargeCoordinates∾⟨envelopeCount⟩)⊔chargeMask/normalized
        refundGroups ← (refundCoordinates∾⟨envelopeCount⟩)⊔-(refundMask/normalized)
        chargePostingGroups ← (chargeCoordinates∾⟨envelopeCount⟩)⊔chargeMask/postingIndices
        refundPostingGroups ← (refundCoordinates∾⟨envelopeCount⟩)⊔refundMask/postingIndices
        chargeRouteGroups ← (chargeCoordinates∾⟨envelopeCount⟩)⊔chargeMask/routeRows
        refundRouteGroups ← (refundCoordinates∾⟨envelopeCount⟩)⊔refundMask/routeRows
        chargeResults ← scale.Sum¨chargeGroups
        refundResults ← scale.Sum¨refundGroups
        sumsOk ← (∧´1∾{𝕩.state≡"ok"}¨chargeResults) ∧ ∧´1∾{𝕩.state≡"ok"}¨refundResults
        diagnostics∾↩AddIf ⟨¬sumsOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Consumption exceeds exact range"⟩⟩

        {𝕊:
          managed ← {
            count⇐envelopeCount,index⇐↕envelopeCount,envelope_id⇐envelopeIds,
            consumption⇐{𝕩.coefficient}¨chargeResults,refunds⇐{𝕩.coefficient}¨refundResults,
            consumption_contributors⇐{PostingReferences ⟨facts,𝕩⟩}¨chargePostingGroups,
            refund_contributors⇐{PostingReferences ⟨facts,𝕩⟩}¨refundPostingGroups,
            consumption_route_source_rows⇐chargeRouteGroups,refund_route_source_rows⇐refundRouteGroups
          }
          evidence ← {
            count⇐≠postingIndices,index⇐↕≠postingIndices,posting_index⇐postingIndices,
            account_index⇐accountIndices,account_key⇐accountKeys,date_ordinal⇐postingDates,
            side⇐sides,coefficient⇐normalized,route⇐routes,target_id⇐targets,route_source_row⇐routeRows
          }
          result↩{
            state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,scale⇐amountScale,
            managed⇐managed,
            unrouted⇐Lane ⟨facts,unroutedMask,postingIndices,accountIndices,accountKeys,postingDates,sides,normalized,routeRows⟩,
            unmanaged⇐Lane ⟨facts,unmanagedMask,postingIndices,accountIndices,accountKeys,postingDates,sides,normalized,routeRows⟩,
            evidence⇐evidence,diagnostics⇐empty
          }
        }⍟sumsOk @
      }⍟(0=≠diagnostics) @
    }⍟normalizationOk @
  }⍟(0=≠diagnostics) @
  result
}

{Build⇐Build}
