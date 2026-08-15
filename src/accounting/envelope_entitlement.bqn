# Pure admitted Budget movement -> Envelope Entitlement observation.
#
# Input shape:
#   movements: source-ordered admitted Budget transaction cells; each cell owns
#     one from/to endpoint, positive exact coefficient/scale, and two Postings;
#   accounts: the shared admitted Account relation used by Budget admission;
#   household: stable Envelope ids plus Account-policy endpoint classification.
# Endpoint coordinates are Envelope order followed by unassigned, opening, and
# legacy execution.  Each movement produces a ragged cell of zero, one, or two
# Envelope effects and at most one unassigned effect; joining those cells retains
# movement order, while Group retains canonical Envelope order and trailing empties.
# Every published coefficient is normalized to one scale chosen from both the
# Entitlement and unassigned observation universes.  Empty effects therefore keep
# a scale supplied by an included unassigned movement.  [start,end) and observation
# cutoffs exclude future rows; admitted rows before start carry the opening position.
# Historical nonnegative validation inspects all admitted native Envelope effects
# independently per Envelope without leaking future or cross-Envelope scale into the
# published observation. Same-day effects are combined with canonical exact addition
# before chronological cumulative exact validation checks the nonnegative law.

scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items:∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_entitlement",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic:invalid/⟨diagnostic⟩}
PostingReference ← {𝕊 sourceName‿posting:{source⇐sourceName,posting_id⇐posting.posting_id}}

EmptyObservation ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,amount⇐empty,effective_ordinal⇐empty,source_event_id⇐empty,source_posting_index⇐empty,source_posting_id⇐empty,contributors⇐empty}}
EmptyManaged ← {𝕊:{count⇐0,index⇐empty,envelope_id⇐empty,entitlement⇐empty,contributors⇐empty}}
EmptyResult ← {𝕊 stateValue‿domainValue‿startValue‿finishValue‿observationValue‿diagnosticsValue:
  {state⇐stateValue,domain⇐domainValue,start_ordinal⇐startValue,end_exclusive_ordinal⇐finishValue,observation_ordinal⇐observationValue,
   scale⇐0,managed⇐EmptyManaged @,observations⇐EmptyObservation @,unassigned⇐empty,unassigned_contributors⇐empty,diagnostics⇐diagnosticsValue}
}

Build ← {𝕊 movements‿accounts‿household‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨(movements.state≢"ok") ∨ movements.source_name≢"budget.journal",Diagnostic ⟨"budget_movements_invalid","Budget movements must be admitted from budget.journal"⟩⟩
  diagnostics∾↩AddIf ⟨(household.state≢"ok") ∨ household.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","Household policy must be admitted from household.toml"⟩⟩
  diagnostics∾↩AddIf ⟨¬Contains ⟨domain,movements.declared_domains⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Budget movements"⟩⟩
  diagnostics∾↩AddIf ⟨(start≥finish) ∨ observation<start ∨ observation≥finish,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩

  result ← EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩
  {𝕊:
    accountKeys ← accounts.key ⋄ accountCount ← accounts.count
    envelopeIds ← household.budget.envelope_id ⋄ envelopeCount ← ≠envelopeIds
    allocationKeys ← household.budget.allocation_account_key
    unassignedKeys ← household.budget.unassigned_account_keys
    policy ← household.account_policy ⋄ policyKeys ← policy.account_key
    policyColumns ← ≠¨⟨policyKeys,policy.budget_kind⟩
    diagnostics∾↩AddIf ⟨¬∧´(≠policyKeys)=policyColumns,Diagnostic ⟨"budget_endpoint_policy_invalid","Household Budget endpoint policy columns must align"⟩⟩
    diagnostics∾↩AddIf ⟨(≠allocationKeys)≠envelopeCount,Diagnostic ⟨"envelope_account_mapping_invalid","Every Envelope must have one allocation Account"⟩⟩
    diagnostics∾↩AddIf ⟨(≠allocationKeys)≠≠⍷allocationKeys,Diagnostic ⟨"envelope_account_mapping_invalid","Allocation Accounts must be unique"⟩⟩
    diagnostics∾↩AddIf ⟨(≠unassignedKeys)≠≠⍷unassignedKeys,Diagnostic ⟨"unassigned_scope_invalid","Unassigned Accounts must be unique"⟩⟩

    allocationReferences ← accountKeys⊐allocationKeys
    unassignedReferences ← accountKeys⊐unassignedKeys
    policyReferences ← accountKeys⊐policyKeys
    allocationKnown ← allocationReferences<accountCount
    unassignedKnown ← unassignedReferences<accountCount
    policyKnown ← policyReferences<accountCount
    diagnostics∾↩AddIf ⟨¬∧´1∾allocationKnown,Diagnostic ⟨"envelope_account_unknown","Envelope allocation Account must occur in admitted Accounts"⟩⟩
    diagnostics∾↩AddIf ⟨¬∧´1∾unassignedKnown,Diagnostic ⟨"unassigned_account_unknown","Unassigned Account must occur in admitted Accounts"⟩⟩
    diagnostics∾↩AddIf ⟨¬∧´1∾policyKnown,Diagnostic ⟨"budget_endpoint_account_unknown","Household Budget endpoint Account must occur in admitted Accounts"⟩⟩

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

    openingReferences ← accountKeys⊐("opening"⊸≡¨policy.budget_kind)/policyKeys
    executionMask ← "spent"⊸≡¨policy.budget_kind
    executionReferences ← accountKeys⊐executionMask/policyKeys
    endpointRows ← {𝕊 i:
      envelopeRows ← (allocationReferences=i)/↕envelopeCount
      unassigned ← ∨´0∾i⊸≡¨unassignedReferences
      opening ← ∨´0∾i⊸≡¨openingReferences
      execution ← ∨´0∾i⊸≡¨executionReferences
      memberships ← (0<≠envelopeRows)+unassigned+opening+execution
      endpoint ← envelopeCount+3
      {𝕊:endpoint↩⊑envelopeRows}⍟((memberships=1)∧(0<≠envelopeRows)) @
      {𝕊:endpoint↩envelopeCount}⍟((memberships=1)∧unassigned) @
      {𝕊:endpoint↩envelopeCount+1}⍟((memberships=1)∧opening) @
      {𝕊:endpoint↩envelopeCount+2}⍟((memberships=1)∧execution) @
      endpoint
    }¨↕accountCount

    {𝕊:
      transactions ← (domain⊸≡¨{𝕩.domain}¨movements.transactions)/movements.transactions
      transactionRows ← ↕≠transactions
      fromAccounts ← accountKeys⊐{𝕩.from_account_key}¨transactions
      toAccounts ← accountKeys⊐{𝕩.to_account_key}¨transactions
      accountKnown ← (fromAccounts<accountCount) ∧ toAccounts<accountCount
      diagnostics∾↩AddIf ⟨¬∧´1∾accountKnown,Diagnostic ⟨"budget_endpoint_account_unknown","Budget movement endpoint must occur in admitted Accounts"⟩⟩
      endpointFrom ← fromAccounts⊏endpointRows∾⟨envelopeCount+3⟩
      endpointTo ← toAccounts⊏endpointRows∾⟨envelopeCount+3⟩
      endpointKnown ← (endpointFrom<envelopeCount+3) ∧ endpointTo<envelopeCount+3
      diagnostics∾↩AddIf ⟨¬∧´1∾endpointKnown,Diagnostic ⟨"budget_endpoint_ambiguous","Every Budget movement endpoint must resolve to one Envelope or source endpoint"⟩⟩

      {𝕊:
        effectiveOrdinals ← dates.Ordinal¨{𝕩.date}¨transactions
        included ← (effectiveOrdinals<finish) ∧ effectiveOrdinals≤observation
        effectCells ← {𝕊 i:
          movement ← i⊑transactions ⋄ fromPosting‿toPosting ← movement.postings
          fromEndpoint ← i⊑endpointFrom ⋄ toEndpoint ← i⊑endpointTo
          fromEnvelope ← fromEndpoint<envelopeCount ⋄ toEnvelope ← toEndpoint<envelopeCount
          grant ← ((fromEndpoint=envelopeCount) ∨ fromEndpoint=envelopeCount+1) ∧ toEnvelope
          release ← fromEnvelope ∧ toEndpoint=envelopeCount
          reallocation ← fromEnvelope ∧ toEnvelope
          amount ← movement.movement_coefficient ⋄ sourceScale ← movement.movement_scale ⋄ effective ← i⊑effectiveOrdinals
          inc ← i⊑included
          Effect ← {𝕊 target‿coefficient‿posting:{target⇐target,amount⇐coefficient,effective_ordinal⇐effective,source_event_id⇐movement.source_event_id,source_posting_index⇐posting.posting_index,source_posting_id⇐posting.posting_id,source_scale⇐sourceScale,contributor⇐PostingReference ⟨movements.source_name,posting⟩,included⇐inc}}
          rows ← empty
          {𝕊:rows∾↩⟨Effect ⟨toEndpoint,amount,toPosting⟩⟩}⍟grant @
          {𝕊:rows∾↩⟨Effect ⟨fromEndpoint,-amount,fromPosting⟩⟩}⍟release @
          {𝕊:rows∾↩⟨Effect ⟨fromEndpoint,-amount,fromPosting⟩,Effect ⟨toEndpoint,amount,toPosting⟩⟩}⍟reallocation @
          rows
        }¨transactionRows
        unassignedCells ← {𝕊 i:
          movement ← i⊑transactions ⋄ fromPosting‿toPosting ← movement.postings
          fromEndpoint ← i⊑endpointFrom ⋄ toEndpoint ← i⊑endpointTo
          inc ← i⊑included
          rows ← empty
          {𝕊:rows∾↩⟨{amount⇐movement.movement_coefficient,source_scale⇐movement.movement_scale,contributor⇐PostingReference ⟨movements.source_name,toPosting⟩,included⇐inc}⟩}⍟(toEndpoint=envelopeCount) @
          {𝕊:rows∾↩⟨{amount⇐-movement.movement_coefficient,source_scale⇐movement.movement_scale,contributor⇐PostingReference ⟨movements.source_name,fromPosting⟩,included⇐inc}⟩}⍟(fromEndpoint=envelopeCount) @
          rows
        }¨transactionRows
        allEffects ← ∾effectCells ⋄ allUnassigned ← ∾unassignedCells
        allTargets ← {𝕩.target}¨allEffects ⋄ allAmounts ← {𝕩.amount}¨allEffects
        allDates ← {𝕩.effective_ordinal}¨allEffects ⋄ allScales ← {𝕩.source_scale}¨allEffects
        allIncluded ← {𝕩.included}¨allEffects
        allUnassignedAmounts ← {𝕩.amount}¨allUnassigned ⋄ allUnassignedScales ← {𝕩.source_scale}¨allUnassigned
        allUnassignedIncluded ← {𝕩.included}¨allUnassigned
        diagnostics∾↩AddIf ⟨¬∧´1∾allTargets<envelopeCount,Diagnostic ⟨"envelope_identity_missing","Budget movement effect must resolve to a stable Envelope identity"⟩⟩

        envAllAmounts ← (allTargets∾envelopeCount)⊔allAmounts
        envAllDates ← (allTargets∾envelopeCount)⊔allDates
        envAllScales ← (allTargets∾envelopeCount)⊔allScales
        ValidateEnvelopeHistory ← {
          0=≠⊑𝕩 ? ⟨1,1,0⟩ ;
          amounts‿dates‿scales ← 𝕩
          envScale ← ⌈´0∾scales
          normResults ← amounts {scale.Normalize ⟨𝕨,𝕩,envScale⟩}¨ scales
          {
            ¬∧´1∾{𝕩.state≡"ok"}¨𝕩 ? ⟨0,1,0⟩ ;
            normAmounts ← {𝕩.coefficient}¨𝕩
            order ← ⍋dates
            sdates ← order⊏dates ⋄ samounts ← order⊏normAmounts
            dayGroups ← ((⍷sdates)⊐sdates)⊔samounts
            daySums ← {scale.Sum (⍋𝕩)⊏𝕩}¨dayGroups
            {
              ¬∧´1∾{𝕩.state≡"ok"}¨𝕩 ? ⟨1,0,0⟩ ;
              dayTotals ← {𝕩.coefficient}¨𝕩
              cumSum ← scale.Sum dayTotals
              {
                𝕩.state≢"ok" ? ⟨1,0,0⟩ ;
                prefixes ← 1↓+`0∾dayTotals
                ⟨1, 1, ∨´0>prefixes⟩
              } cumSum
            } daySums
          } normResults
        }
        envValidations ← {ValidateEnvelopeHistory ⟨𝕩⊑envAllAmounts,𝕩⊑envAllDates,𝕩⊑envAllScales⟩}¨↕envelopeCount
        validationNormOk ← ∧´1∾{⊑𝕩}¨envValidations
        validationSumOk ← ∧´1∾{1⊑𝕩}¨envValidations
        validationNegative ← ∨´0∾{2⊑𝕩}¨envValidations
        diagnostics∾↩AddIf ⟨¬validationNormOk,Diagnostic ⟨"coefficient_normalization_failed","Budget Entitlement movement cannot normalize exactly"⟩⟩
        diagnostics∾↩AddIf ⟨¬validationSumOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Entitlement exceeds exact range"⟩⟩
        diagnostics∾↩AddIf ⟨validationNegative,Diagnostic ⟨"envelope_entitlement_negative","Envelope Entitlement cannot become negative in historical admission"⟩⟩

        {𝕊:
          effects ← allIncluded/allEffects
          effectTargets ← {𝕩.target}¨effects
          effectAmounts ← {𝕩.amount}¨effects
          effectDates ← {𝕩.effective_ordinal}¨effects
          effectScales ← {𝕩.source_scale}¨effects
          effectEvents ← {𝕩.source_event_id}¨effects
          effectPostingIndices ← {𝕩.source_posting_index}¨effects
          effectPostingIds ← {𝕩.source_posting_id}¨effects
          effectContributors ← {𝕩.contributor}¨effects

          unassignedEffects ← allUnassignedIncluded/allUnassigned
          unassignedAmounts ← {𝕩.amount}¨unassignedEffects
          unassignedScales ← {𝕩.source_scale}¨unassignedEffects
          unassignedContributors ← {𝕩.contributor}¨unassignedEffects

          observationScale ← ⌈´0∾effectScales∾unassignedScales
          normalizedObsResults ← effectAmounts {scale.Normalize ⟨𝕨,𝕩,observationScale⟩}¨effectScales
          normalizedUnassignedObsResults ← unassignedAmounts {scale.Normalize ⟨𝕨,𝕩,observationScale⟩}¨unassignedScales
          obsNormalizedOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedObsResults
          unassignedObsNormalizedOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedUnassignedObsResults
          diagnostics∾↩AddIf ⟨¬obsNormalizedOk,Diagnostic ⟨"coefficient_normalization_failed","Budget Entitlement movement cannot normalize exactly"⟩⟩
          diagnostics∾↩AddIf ⟨¬unassignedObsNormalizedOk,Diagnostic ⟨"coefficient_normalization_failed","Unassigned Budget movement cannot normalize exactly"⟩⟩

          {𝕊:
            normalizedObsAmounts ← {𝕩.coefficient}¨normalizedObsResults
            unassignedObsAmounts ← {𝕩.coefficient}¨normalizedUnassignedObsResults

            valueGroups ← (effectTargets∾envelopeCount)⊔normalizedObsAmounts
            contributorGroups ← (effectTargets∾envelopeCount)⊔effectContributors
            entitlementResults ← scale.Sum¨valueGroups
            unassignedResult ← scale.Sum unassignedObsAmounts
            entitlementOk ← ∧´1∾{𝕩.state≡"ok"}¨entitlementResults
            diagnostics∾↩AddIf ⟨¬entitlementOk,Diagnostic ⟨"coefficient_sum_failed","Envelope Entitlement exceeds exact range"⟩⟩
            diagnostics∾↩AddIf ⟨unassignedResult.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Unassigned Budget movement exceeds exact range"⟩⟩
            {𝕊:result↩{
              state⇐"ok",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,scale⇐observationScale,
              managed⇐{count⇐envelopeCount,index⇐↕envelopeCount,envelope_id⇐envelopeIds,entitlement⇐{𝕩.coefficient}¨entitlementResults,contributors⇐contributorGroups},
              observations⇐{count⇐≠effects,index⇐↕≠effects,envelope_id⇐effectTargets⊏envelopeIds,amount⇐normalizedObsAmounts,effective_ordinal⇐effectDates,source_event_id⇐effectEvents,source_posting_index⇐effectPostingIndices,source_posting_id⇐effectPostingIds,contributors⇐effectContributors},
              unassigned⇐unassignedResult.coefficient,unassigned_contributors⇐unassignedContributors,diagnostics⇐empty
            }}⍟(entitlementOk ∧ unassignedResult.state≡"ok") @
          }⍟(obsNormalizedOk ∧ unassignedObsNormalizedOk) @
        }⍟(0=≠diagnostics) @
      }⍟(0=≠diagnostics) @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @
  {𝕊:result↩EmptyResult ⟨"error",domain,start,finish,observation,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
