# Pure Budget movement -> Envelope Entitlement observation.
#
# The input relation is source-ordered Budget movement Facts.  Account endpoints
# are qualified once against the current Household semantic policy:
#   allocation Account -> stable EnvelopeId; unassigned/opening -> source lanes;
#   spent/execution -> legacy compatibility lane (never an entitlement effect).
# Only opening/unassigned -> Envelope, Envelope -> Envelope, and Envelope ->
# unassigned produce entitlement effects.  The effect cells retain source order,
# date, endpoint, and the Posting provenance used by the grouped observation.
#
# Budget Account balances are deliberately not an input to this owner.  The
# opening position is the admitted relation before the period start; period
# movements are admitted through the observation day, with [start,end) still
# defining the request boundary.  A movement on end_exclusive or after the
# observation day is therefore absent.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items:∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items:⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_entitlement",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}
PostingReferences ← {𝕊 facts‿indices:{reference.Posting ⟨facts,𝕩⟩}¨indices}

EmptyObservation ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,amount⇐empty,effective_ordinal⇐empty,source_event_id⇐empty,source_posting_index⇐empty,contributors⇐empty}}
EmptyManaged ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,entitlement⇐empty,contributors⇐empty}}
EmptyResult ← {𝕊 stateValue‿domainValue‿startValue‿finishValue‿observationValue‿diagnosticsValue:
  {state⇐stateValue,domain⇐domainValue,start_ordinal⇐startValue,end_exclusive_ordinal⇐finishValue,observation_ordinal⇐observationValue,
   scale⇐0,managed⇐EmptyManaged @,observations⇐EmptyObservation @,unassigned⇐empty,unassigned_contributors⇐empty,diagnostics⇐diagnosticsValue}
}

Build ← {𝕊 facts‿household‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨facts.state≢"ok",Diagnostic ⟨"facts_not_ok","Budget Facts must be ok"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨facts,"budget.journal"⟩,Diagnostic ⟨"budget_facts_invalid","Facts must be admitted from budget.journal"⟩⟩
  diagnostics∾↩AddIf ⟨(household.state≢"ok") ∨ household.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","Household policy must be admitted from household.toml"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨domain,facts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Budget Facts"⟩⟩
  diagnostics∾↩AddIf ⟨(start≥finish) ∨ observation<start ∨ observation≥finish,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩

  result ← EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩
  {𝕊:
    accounts ← facts.accounts ⋄ accountKeys ← accounts.key ⋄ accountCount ← accounts.count
    envelopeIds ← household.budget.envelope_id ⋄ envelopeCount ← ≠envelopeIds
    allocationKeys ← household.budget.allocation_account_key
    unassignedKeys ← household.budget.unassigned_account_keys
    policy ← household.account_policy
    policyKeys ← policy.account_key
    policyColumns ← ≠¨⟨policyKeys,policy.budget_kind,policy.envelope_role⟩
    policyAligned ← ∧´(≠policyKeys)=policyColumns
    diagnostics∾↩AddIf ⟨¬policyAligned,Diagnostic ⟨"budget_endpoint_policy_invalid","Household Budget endpoint policy columns must align"⟩⟩
    diagnostics∾↩AddIf ⟨(≠allocationKeys)≠envelopeCount,Diagnostic ⟨"envelope_account_mapping_invalid","Every Envelope must have one allocation Account"⟩⟩
    diagnostics∾↩AddIf ⟨(≠allocationKeys)≠≠⍷allocationKeys,Diagnostic ⟨"envelope_account_mapping_invalid","Allocation Accounts must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨(≠unassignedKeys)≠≠⍷unassignedKeys,Diagnostic ⟨"unassigned_scope_invalid","Unassigned Accounts must be unique"⟩⟩

    allocationReferences ← accountKeys⊐allocationKeys
    unassignedReferences ← accountKeys⊐unassignedKeys
    policyReferences ← accountKeys⊐policyKeys
    allocationCoordinates ← allocationKeys⊐accountKeys
    policyCoordinates ← policyKeys⊐accountKeys
    allocationKnown ← allocationReferences<accountCount
    unassignedKnown ← unassignedReferences<accountCount
    policyKnown ← policyReferences<accountCount
    diagnostics∾↩AddIf ⟨¬∧´1∾allocationKnown,Diagnostic ⟨"envelope_account_unknown","Envelope allocation Account must occur in Budget Facts"⟩⟩
    diagnostics∾↩AddIf ⟨¬∧´1∾unassignedKnown,Diagnostic ⟨"unassigned_account_unknown","Unassigned Account must occur in Budget Facts"⟩⟩
    diagnostics∾↩AddIf ⟨¬∧´1∾policyKnown,Diagnostic ⟨"budget_endpoint_account_unknown","Household Budget endpoint Account must occur in Budget Facts"⟩⟩

    {𝕊:
      allocationRoles ← allocationReferences⊏accounts.role∾⟨""⟩
      allocationCurrencies ← allocationReferences⊏accounts.currency∾⟨""⟩
      unassignedRoles ← unassignedReferences⊏accounts.role∾⟨""⟩
      unassignedCurrencies ← unassignedReferences⊏accounts.currency∾⟨""⟩
      diagnostics∾↩AddIf ⟨¬∧´1∾("budget"⊸≡¨allocationRoles),Diagnostic ⟨"envelope_account_role_invalid","Envelope allocation Account must be Budget"⟩⟩
      diagnostics∾↩AddIf ⟨¬∧´1∾(domain⊸≡¨allocationCurrencies),Diagnostic ⟨"envelope_account_domain_invalid","Envelope allocation Account must be in the selected domain"⟩⟩
      diagnostics∾↩AddIf ⟨¬∧´1∾("budget"⊸≡¨unassignedRoles),Diagnostic ⟨"unassigned_account_role_invalid","Unassigned Account must be Budget"⟩⟩
      diagnostics∾↩AddIf ⟨¬∧´1∾(domain⊸≡¨unassignedCurrencies),Diagnostic ⟨"unassigned_account_domain_invalid","Unassigned Account must be in the selected domain"⟩⟩
    }⍟((∧´1∾allocationKnown)∧(∧´1∾unassignedKnown)) @

    openingMask ← "opening"⊸≡¨policy.budget_kind
    spentMask ← "spent"⊸≡¨policy.budget_kind
    executionMask ← ("execution"⊸≡¨policy.envelope_role) ∨ spentMask
    openingCoordinates ← openingMask/policyCoordinates
    executionCoordinates ← executionMask/policyCoordinates
    endpointRows ← {𝕊 i:
      envelopeRows ← (allocationReferences=i)/↕envelopeCount
      unassigned ← ∨´0∾i⊸≡¨unassignedReferences
      opening ← ∨´0∾i⊸≡¨openingCoordinates
      execution ← ∨´0∾i⊸≡¨executionCoordinates
      memberships ← (0<≠envelopeRows)+unassigned+opening+execution
      endpoint ← envelopeCount+3
      {𝕊:endpoint↩⊑envelopeRows}⍟((memberships=1)∧(0<≠envelopeRows)) @
      {𝕊:endpoint↩envelopeCount}⍟((memberships=1)∧unassigned) @
      {𝕊:endpoint↩envelopeCount+1}⍟((memberships=1)∧opening) @
      {𝕊:endpoint↩envelopeCount+2}⍟((memberships=1)∧execution) @
      endpoint
    }¨accounts.index
    endpointKnown ← {𝕊 i:((i⊑accounts.role)≢"budget") ∨ ((i⊑endpointRows)<envelopeCount+3)}¨accounts.index
    diagnostics∾↩AddIf ⟨¬∧´endpointKnown,Diagnostic ⟨"budget_endpoint_ambiguous","Every Budget Account must resolve to one Envelope or source endpoint"⟩⟩

    {𝕊:
      domainIndex ← IndexOf ⟨domain,facts.domains.code⟩
      layerIndex ← IndexOf ⟨"budget",facts.layers.name⟩
      transactions ← facts.transactions ⋄ postings ← facts.postings
      transactionIndices ← transactions.index
      postingGroups ← (transactionIndices⊐postings.transaction_index)⊔postings.index
      selectedTransactions ← (domainIndex=transactions.domain_index) ∧ (layerIndex=transactions.layer_index)
      selectedIndices ← selectedTransactions/transactionIndices
      selectedPostingGroups ← selectedIndices⊏postingGroups
      fromPostingIndices ← {⊑𝕩}¨selectedPostingGroups
      toPostingIndices ← {1⊑𝕩}¨selectedPostingGroups
      fromAccounts ← fromPostingIndices⊏postings.account_index
      toAccounts ← toPostingIndices⊏postings.account_index
      dates ← selectedIndices⊏transactions.date_ordinal
      amounts ← toPostingIndices⊏postings.coefficient
      fromAmounts ← fromPostingIndices⊏postings.coefficient
      scales ← toPostingIndices⊏postings.scale
      directionValid ← (0<amounts) ∧ fromAmounts=-amounts
      diagnostics∾↩∾{𝕊 i:AddIf ⟨¬i⊑directionValid,Diagnostic ⟨"budget_movement_direction_invalid","Budget movement must run from a negative source to a positive destination"⟩⟩}¨↕≠selectedIndices

      included ← (dates<start) ∨ ((dates≥start) ∧ (dates<finish))
      included ∧↩ dates<observation+1
      endpointFrom ← fromAccounts⊏endpointRows
      endpointTo ← toAccounts⊏endpointRows
      envelopeFrom ← endpointFrom<envelopeCount
      envelopeTo ← endpointTo<envelopeCount
      effectCells ← {𝕊 i:
        rows ← empty ⋄ fromEndpoint ← i⊑endpointFrom ⋄ toEndpoint ← i⊑endpointTo
        fromEnvelope ← fromEndpoint<envelopeCount ⋄ toEnvelope ← toEndpoint<envelopeCount
        grantRow ← ((fromEndpoint=envelopeCount) ∨ (fromEndpoint=envelopeCount+1)) ∧ toEnvelope
        releaseRow ← fromEnvelope ∧ (toEndpoint=envelopeCount)
        reallocationRow ← fromEnvelope ∧ toEnvelope
        {𝕊:rows∾↩⟨{target⇐toEndpoint,amount⇐i⊑amounts,effective_ordinal⇐i⊑dates,source_event_id⇐i⊑transactions.transaction_id,source_posting_index⇐i⊑toPostingIndices,source_scale⇐i⊑scales}⟩}⍟((i⊑included)∧grantRow) @
        {𝕊:rows∾↩⟨{target⇐fromEndpoint,amount⇐-(i⊑amounts),effective_ordinal⇐i⊑dates,source_event_id⇐i⊑transactions.transaction_id,source_posting_index⇐i⊑fromPostingIndices,source_scale⇐i⊑scales}⟩}⍟((i⊑included)∧releaseRow) @
        {𝕊:
          rows∾↩⟨
            {target⇐fromEndpoint,amount⇐-(i⊑amounts),effective_ordinal⇐i⊑dates,source_event_id⇐i⊑transactions.transaction_id,source_posting_index⇐i⊑fromPostingIndices,source_scale⇐i⊑scales},
            {target⇐toEndpoint,amount⇐i⊑amounts,effective_ordinal⇐i⊑dates,source_event_id⇐i⊑transactions.transaction_id,source_posting_index⇐i⊑toPostingIndices,source_scale⇐i⊑scales}
          ⟩
        }⍟((i⊑included)∧reallocationRow) @
        rows
      }¨selectedIndices
      effects ← ∾effectCells
      effectTargets ← {𝕩.target}¨effects ⋄ effectAmounts ← {𝕩.amount}¨effects
      effectDates ← {𝕩.effective_ordinal}¨effects ⋄ effectEvents ← {𝕩.source_event_id}¨effects
      effectPostingIndices ← {𝕩.source_posting_index}¨effects ⋄ effectScales ← {𝕩.source_scale}¨effects
      targetCoordinates ← effectTargets
      diagnostics∾↩AddIf ⟨¬∧´1∾targetCoordinates<envelopeCount,Diagnostic ⟨"envelope_identity_missing","Budget movement effect must resolve to a stable Envelope identity"⟩⟩
      targetScale ← ⌈´0∾effectScales
      normalizedResults ← effectAmounts {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨effectScales
      normalizedOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
      diagnostics∾↩AddIf ⟨¬normalizedOk,Diagnostic ⟨"coefficient_normalization_failed","Budget Entitlement movement cannot normalize exactly"⟩⟩

      {𝕊:
        normalized ← {𝕩.coefficient}¨normalizedResults
        valueGroups ← (targetCoordinates∾envelopeCount)⊔normalized
        postingGroupsByEnvelope ← (targetCoordinates∾envelopeCount)⊔effectPostingIndices
        entitlementResults ← scale.Sum¨valueGroups
        entitlementOk ← ∧´1∾{𝕩.state≡"ok"}¨entitlementResults
        diagnostics∾↩AddIf ⟨¬entitlementOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Entitlement exceeds exact range"⟩⟩
        unassignedToMask ← (endpointTo=envelopeCount)∧included
        unassignedFromMask ← (endpointFrom=envelopeCount)∧included
        unassignedAmounts ← (unassignedToMask/amounts)∾(unassignedFromMask/-amounts)
        unassignedPostingIndices ← (unassignedToMask/toPostingIndices)∾(unassignedFromMask/fromPostingIndices)
        unassignedScales ← (unassignedToMask/scales)∾(unassignedFromMask/scales)
        unassignedNormalized ← unassignedAmounts {scale.Normalize ⟨𝕨,𝕩,targetScale⟩}¨unassignedScales
        unassignedOk ← ∧´1∾{𝕩.state≡"ok"}¨unassignedNormalized
        diagnostics∾↩AddIf ⟨¬unassignedOk,Diagnostic ⟨"coefficient_normalization_failed","Unassigned Budget movement cannot normalize exactly"⟩⟩
        unassignedResult ← scale.Sum {𝕩.coefficient}¨unassignedNormalized
        diagnostics∾↩AddIf ⟨unassignedResult.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Unassigned Budget movement exceeds exact range"⟩⟩
        observations ← {
          count⇐≠effects,index⇐↕≠effects,envelope_id⇐targetCoordinates⊏envelopeIds,amount⇐normalized,
          effective_ordinal⇐effectDates,source_event_id⇐effectEvents,source_posting_index⇐effectPostingIndices,
          contributors⇐PostingReferences ⟨facts,effectPostingIndices⟩
        }
        managed ← {
          count⇐envelopeCount,index⇐↕envelopeCount,envelope_id⇐envelopeIds,
          entitlement⇐{𝕩.coefficient}¨entitlementResults,
          contributors⇐{PostingReferences ⟨facts,𝕩⟩}¨postingGroupsByEnvelope
        }
        {𝕊:result↩{
          state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐targetScale,
          managed⇐managed,observations⇐observations,unassigned⇐unassignedResult.coefficient,
          unassigned_contributors⇐PostingReferences ⟨facts,unassignedPostingIndices⟩,diagnostics⇐empty
        }}⍟(normalizedOk ∧ entitlementOk ∧ unassignedOk ∧ unassignedResult.state≡"ok") @
      }⍟1 @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
