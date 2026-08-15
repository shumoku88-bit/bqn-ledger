# Pure Envelope & Backing Statement from admitted Budget movements and canonical
# Actual/Plan Facts. Budget movements own Entitlement, historical routing owns
# Consumption, Fulfillment, and Commitment, while current budget.toml owns Backing.

entitlement ← •Import "envelope_entitlement.bqn"
balance ← •Import "account_balance.bqn"
consumption ← •Import "envelope_consumption.bqn"
fulfillment ← •Import "envelope_fulfillment.bqn"
commitment ← •Import "envelope_commitment.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_backing",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
ErrorExact ← {𝕊:{state⇐"error",coefficient⇐empty}}

EmptyRows ← {𝕊:{
  count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,category⇐empty,
  entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,fulfillment⇐empty,
  ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
  entitlement_contributors⇐empty,entitlement_observations⇐empty,consumption_contributors⇐empty,
  refund_contributors⇐empty,fulfillment_contributors⇐empty,plan_contributors⇐empty
}}
EmptyTotals ← {𝕊:{
  entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,fulfillment⇐empty,
  ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
  funding_balance⇐empty,signed_envelope_total⇐empty,backing_required⇐empty,
  backing_surplus⇐empty,ledger_unassigned⇐empty,reconciliation_delta⇐empty
}}
EmptyResult ← {𝕊 state‿reason‿domain‿diagnostics:{
  state⇐state,reason⇐reason,domain⇐domain,
  start_ordinal⇐empty,end_exclusive_ordinal⇐empty,observation_ordinal⇐empty,
  scale⇐0,status⇐"",envelopes⇐EmptyRows @,totals⇐EmptyTotals @,
  entitlement_observation⇐@,consumption_observation⇐@,fulfillment_observation⇐@,commitment_observation⇐@,
  funding_account_indices⇐empty,funding_contributors⇐empty,
  unassigned_contributors⇐empty,diagnostics⇐diagnostics
}}

ValidateInputs ← {𝕊 budgetMovements‿budgetPolicy‿householdPolicy‿envelopeHistory‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨(budgetMovements.state≢"ok") ∨ budgetMovements.source_name≢"budget.journal",Diagnostic ⟨"budget_movements_invalid","Budget movements must be admitted from budget.journal"⟩⟩
  diagnostics∾↩AddIf ⟨(budgetPolicy.state≢"ok") ∨ budgetPolicy.source_name≢"budget.toml",Diagnostic ⟨"budget_policy_invalid","Budget policy must be admitted from budget.toml"⟩⟩
  diagnostics∾↩AddIf ⟨(householdPolicy.state≢"ok") ∨ householdPolicy.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","Household policy must be admitted from household.toml"⟩⟩
  diagnostics∾↩AddIf ⟨envelopeHistory.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted before Envelope observation"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  domainKnown ← Contains ⟨domain,actualFacts.accounts.currency⟩
  diagnostics∾↩AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Accounts"⟩⟩
  rangeInvalid ← (start≥finish) ∨ (observation<start) ∨ observation≥finish
  diagnostics∾↩AddIf ⟨rangeInvalid,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩
  axesMatch ← planFacts.accounts.key≡actualFacts.accounts.key
  diagnostics∾↩AddIf ⟨¬axesMatch,Diagnostic ⟨"account_axis_mismatch","Actual and Plan facts must share one Account axis"⟩⟩
  diagnostics
}

ResolveOwnership ← {𝕊 accounts‿budgetPolicy‿householdPolicy‿domain:
  categories ← budgetPolicy.envelopes.id ⋄ householdIds ← householdPolicy.budget.envelope_id
  diagnostics ← empty

  householdCounts ← {+´𝕩⊸≡¨householdIds}¨categories
  mappingValid ← ∧´1∾1=householdCounts
  diagnostics∾↩AddIf ⟨¬mappingValid,Diagnostic ⟨"envelope_account_mapping_invalid","Each budget.toml envelope must have exactly one household.toml allocation Account"⟩⟩
  envelopeIndices ← empty
  {𝕊:
    householdRows ← householdIds⊐categories
    allocationKeys ← householdRows⊏householdPolicy.budget.allocation_account_key
    envelopeIndices↩accounts.key⊐allocationKeys
    allocationKnown ← envelopeIndices<accounts.count
    allocationRoles ← envelopeIndices⊏accounts.role∾⟨""⟩
    allocationCurrencies ← envelopeIndices⊏accounts.currency∾⟨""⟩
    allocationValid ← allocationKnown ∧ ("budget"⊸≡¨allocationRoles) ∧ domain⊸≡¨allocationCurrencies
    diagnostics∾↩AddIf ⟨¬∧´1∾allocationValid,Diagnostic ⟨"envelope_account_mapping_invalid","Household allocation Account must be a selected-domain Budget Account"⟩⟩
  }⍟mappingValid @

  unassignedKeys ← householdPolicy.budget.unassigned_account_keys
  unassignedIndices ← accounts.key⊐unassignedKeys
  unassignedKnown ← unassignedIndices<accounts.count
  unassignedRoles ← unassignedIndices⊏accounts.role∾⟨""⟩
  unassignedCurrencies ← unassignedIndices⊏accounts.currency∾⟨""⟩
  unassignedRowsValid ← unassignedKnown ∧ ("budget"⊸≡¨unassignedRoles) ∧ domain⊸≡¨unassignedCurrencies
  unassignedValid ← (0<≠unassignedKeys) ∧ ∧´1∾unassignedRowsValid
  diagnostics∾↩AddIf ⟨¬unassignedValid,Diagnostic ⟨"unassigned_scope_invalid","household.toml unassigned Accounts must be selected-domain Budget Accounts"⟩⟩

  # Backing topology is current policy. Envelope claim meaning is not.
  fundingKeys ← ∾budgetPolicy.backing_pools.asset_account_keys
  policyFundingIndices ← accounts.key⊐fundingKeys
  fundingKnown ← policyFundingIndices<accounts.count
  fundingRoles ← policyFundingIndices⊏accounts.role∾⟨""⟩
  fundingCurrencies ← policyFundingIndices⊏accounts.currency∾⟨""⟩
  diagnostics∾↩AddIf ⟨¬∧´1∾fundingKnown,Diagnostic ⟨"budget_policy_asset_account_unknown","budget.toml backing Accounts must occur on the current Facts Account axis"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾fundingKnown ∧ ¬"asset"⊸≡¨fundingRoles,Diagnostic ⟨"budget_policy_asset_account_role_invalid","budget.toml backing Accounts must remain Asset Accounts on the current Facts axis"⟩⟩
  fundingIndices ← (domain⊸≡¨fundingCurrencies)/policyFundingIndices
  diagnostics∾↩AddIf ⟨0=≠fundingIndices,Diagnostic ⟨"funding_scope_invalid","budget.toml backing policy requires an Asset Account in the selected domain"⟩⟩

  {state⇐(0=≠diagnostics)⊑"error"‿"ok",reason⇐"",envelope_indices⇐envelopeIndices,categories⇐categories,
   funding_indices⇐fundingIndices,unassigned_indices⇐unassignedIndices,diagnostics⇐diagnostics}
}

PrepareEvidence ← {𝕊 budgetMovements‿envelopeHistory‿householdPolicy‿actualFacts‿planFacts‿planRetirements‿domain‿start‿finish‿observation:
  entitlementObservation ← entitlement.Build ⟨budgetMovements,actualFacts.accounts,householdPolicy,domain,start,finish,observation⟩
  actualBalance ← balance.Build ⟨actualFacts,domain,observation⟩
  # Report Period is not the lower boundary of live Envelope stock. The first
  # native Entitlement effect visible through this observation owns that opening
  # coordinate. If no effect is visible yet, use an empty horizon immediately
  # after the observation; no accounting fact can consume capacity before the
  # selected Commodity enters the native Envelope world.
  stockStart ← observation+1
  {𝕊:stockStart↩⌊´entitlementObservation.observations.effective_ordinal}⍟(0<entitlementObservation.observations.count) @
  stockFinish ← observation+1
  consumptionObservation ← consumption.Build ⟨actualFacts,envelopeHistory,domain,stockStart,stockFinish⟩
  fulfillmentObservation ← fulfillment.Build ⟨planFacts,planRetirements,actualFacts,envelopeHistory,domain,stockStart,stockFinish,observation⟩
  commitmentObservation ← commitment.Build ⟨planFacts,planRetirements,actualFacts,envelopeHistory,domain,start,finish,observation⟩
  diagnostics ← AddIf ⟨entitlementObservation.state≢"ok",Diagnostic ⟨"entitlement_observation_invalid","Budget Entitlement observation failed"⟩⟩
  diagnostics∾↩entitlementObservation.diagnostics∾actualBalance.diagnostics∾consumptionObservation.diagnostics∾fulfillmentObservation.diagnostics∾commitmentObservation.diagnostics
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",entitlement_observation⇐entitlementObservation,actual_balance⇐actualBalance,
   consumption_observation⇐consumptionObservation,fulfillment_observation⇐fulfillmentObservation,
   commitment_observation⇐commitmentObservation,diagnostics⇐diagnostics}
}

NormalizeOne ← {𝕊 coefficient‿sourceScale‿targetScale:scale.Normalize ⟨coefficient,sourceScale,targetScale⟩}
SumNormalized ← {𝕊 coefficients‿sourceScale‿targetScale:
  normalized ← {𝕊 value:NormalizeOne ⟨value,sourceScale,targetScale⟩}¨coefficients ⋄ result ← ErrorExact @
  {𝕊:result↩scale.Sum {𝕩.coefficient}¨normalized}⍟(∧´1∾{𝕩.state≡"ok"}¨normalized) @ ⋄ result
}
PostingReferences ← {𝕊 facts‿indices:{reference.Posting ⟨facts,𝕩⟩}¨indices}

BuildEnvelopeTerms ← {𝕊 accounts‿ownership‿prepared‿targetScale:
  entitlementObservation ← prepared.entitlement_observation ⋄ entitlementManaged ← entitlementObservation.managed
  consumptionObservation ← prepared.consumption_observation ⋄ consumptionManaged ← consumptionObservation.managed
  fulfillmentObservation ← prepared.fulfillment_observation ⋄ fulfillmentManaged ← fulfillmentObservation.managed
  commitmentObservation ← prepared.commitment_observation ⋄ commitmentManaged ← commitmentObservation.managed
  envelopeIndices ← ownership.envelope_indices ⋄ categories ← ownership.categories ⋄ envelopeCount ← ≠envelopeIndices
  entitlementRows ← entitlementManaged.envelope_id⊐categories
  entitlementKnown ← entitlementRows<entitlementManaged.count
  diagnostics ← AddIf ⟨¬∧´1∾entitlementKnown,Diagnostic ⟨"envelope_identity_missing","Budget Entitlement must preserve stable Envelope identity"⟩⟩
  entitlementValues ← entitlementRows⊏entitlementManaged.entitlement∾⟨0⟩
  entitlementResults ← {NormalizeOne ⟨𝕩,entitlementObservation.scale,targetScale⟩}¨entitlementValues
  entitlementContributors ← entitlementRows⊏entitlementManaged.contributors∾⟨empty⟩

  consumptionRows ← consumptionManaged.envelope_id⊐categories
  fulfillmentRows ← fulfillmentManaged.envelope_id⊐categories
  commitmentRows ← commitmentManaged.envelope_id⊐categories
  known ← (consumptionRows<consumptionManaged.count) ∧ (fulfillmentRows<fulfillmentManaged.count) ∧ commitmentRows<commitmentManaged.count
  diagnostics∾↩AddIf ⟨¬∧´1∾known,Diagnostic ⟨"envelope_identity_missing","Current Envelope must have stable historical identity"⟩⟩

  consumptionValues ← consumptionRows⊏consumptionManaged.consumption∾⟨0⟩
  refundValues ← consumptionRows⊏consumptionManaged.refunds∾⟨0⟩
  fulfillmentValues ← fulfillmentRows⊏fulfillmentManaged.fulfillment∾⟨0⟩
  commitmentValues ← commitmentRows⊏commitmentManaged.commitment∾⟨0⟩
  consumptionResults ← {NormalizeOne ⟨𝕩,consumptionObservation.scale,targetScale⟩}¨consumptionValues
  refundResults ← {NormalizeOne ⟨𝕩,consumptionObservation.scale,targetScale⟩}¨refundValues
  fulfillmentResults ← {NormalizeOne ⟨𝕩,fulfillmentObservation.scale,targetScale⟩}¨fulfillmentValues
  commitmentResults ← {NormalizeOne ⟨𝕩,commitmentObservation.scale,targetScale⟩}¨commitmentValues

  consumptionContributors ← consumptionRows⊏consumptionManaged.consumption_contributors∾⟨empty⟩
  refundContributors ← consumptionRows⊏consumptionManaged.refund_contributors∾⟨empty⟩
  fulfillmentContributors ← fulfillmentRows⊏fulfillmentManaged.actual_contributors∾⟨empty⟩
  planContributors ← commitmentRows⊏commitmentManaged.plan_contributors∾⟨empty⟩

  entitlementOk ← {𝕩.state≡"ok"}¨entitlementResults ⋄ consumptionOk ← {𝕩.state≡"ok"}¨consumptionResults
  refundOk ← {𝕩.state≡"ok"}¨refundResults ⋄ fulfillmentOk ← {𝕩.state≡"ok"}¨fulfillmentResults
  commitmentOk ← {𝕩.state≡"ok"}¨commitmentResults
  termsOk ← entitlementOk ∧ consumptionOk ∧ refundOk ∧ fulfillmentOk ∧ commitmentOk
  remainingResults ← {𝕊 i:
    result ← ErrorExact @
    {𝕊:result↩scale.Sum ⟨(i⊑entitlementResults).coefficient,-(i⊑consumptionResults).coefficient,(i⊑refundResults).coefficient,-(i⊑fulfillmentResults).coefficient⟩}⍟(i⊑termsOk) @
    result
  }¨↕envelopeCount
  headroomResults ← {𝕊 i:
    result ← ErrorExact @ ⋄ remaining ← i⊑remainingResults
    {𝕊:result↩scale.Sum ⟨remaining.coefficient,-(i⊑commitmentResults).coefficient⟩}⍟(remaining.state≡"ok") @ ⋄ result
  }¨↕envelopeCount
  finalOk ← ({𝕩.state≡"ok"}¨remainingResults) ∧ {𝕩.state≡"ok"}¨headroomResults
  diagnostics∾↩∾{𝕊 i:
    rowDiagnostics ← empty
    {𝕊:rowDiagnostics↩⟨Diagnostic ⟨"coefficient_sum_failed","Envelope terms exceed exact range"⟩⟩}⍟(¬i⊑termsOk) @
    {𝕊:rowDiagnostics↩⟨Diagnostic ⟨"coefficient_sum_failed","Envelope remaining exceeds exact range"⟩⟩}⍟((i⊑termsOk)∧¬i⊑finalOk) @
    rowDiagnostics
  }¨↕envelopeCount
  table ← EmptyRows @
  {𝕊:table↩{
    count⇐envelopeCount,index⇐↕envelopeCount,account_index⇐envelopeIndices,account_key⇐envelopeIndices⊏accounts.key,category⇐categories,
    entitlement⇐{𝕩.coefficient}¨entitlementResults,actual_consumption⇐{𝕩.coefficient}¨consumptionResults,
    actual_refunds⇐{𝕩.coefficient}¨refundResults,fulfillment⇐{𝕩.coefficient}¨fulfillmentResults,
    ledger_remaining⇐{𝕩.coefficient}¨remainingResults,open_plan_reserve⇐{𝕩.coefficient}¨commitmentResults,
    post_plan_headroom⇐{𝕩.coefficient}¨headroomResults,
    entitlement_contributors⇐entitlementContributors,
    entitlement_observations⇐entitlementObservation.observations,
    consumption_contributors⇐consumptionContributors,refund_contributors⇐refundContributors,
    fulfillment_contributors⇐fulfillmentContributors,plan_contributors⇐planContributors
  }}⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",table⇐table,diagnostics⇐diagnostics}
}

BuildBacking ← {𝕊 prepared‿ownership‿terms‿targetScale:
  entitlementObservation ← prepared.entitlement_observation ⋄ actualBalance ← prepared.actual_balance ⋄ table ← terms.table
  entitlement ← table.entitlement ⋄ consumptionValues ← table.actual_consumption ⋄ refunds ← table.actual_refunds
  fulfillmentValues ← table.fulfillment ⋄ remaining ← table.ledger_remaining ⋄ reserve ← table.open_plan_reserve ⋄ headroom ← table.post_plan_headroom
  termTotals ← scale.Sum¨⟨entitlement,consumptionValues,refunds,fulfillmentValues,remaining,reserve,headroom⟩
  fundingIndices ← ownership.funding_indices
  fundingRows ← actualBalance.accounts.account_index⊐fundingIndices
  fundingValues ← fundingRows⊏actualBalance.accounts.closing
  fundingResult ← SumNormalized ⟨fundingValues,actualBalance.scale,targetScale⟩
  backingResult ← scale.Sum {0⌈𝕩}¨remaining ⋄ surplusResult ← ErrorExact @
  {𝕊:surplusResult↩scale.Sum ⟨fundingResult.coefficient,-backingResult.coefficient⟩}⍟((fundingResult.state≡"ok") ∧ backingResult.state≡"ok") @
  unassignedResult ← NormalizeOne ⟨entitlementObservation.unassigned,entitlementObservation.scale,targetScale⟩
  reconciliationResult ← ErrorExact @
  {𝕊:reconciliationResult↩scale.Sum ⟨surplusResult.coefficient,-unassignedResult.coefficient⟩}⍟((surplusResult.state≡"ok") ∧ unassignedResult.state≡"ok") @
  allResults ← termTotals∾⟨fundingResult,backingResult,surplusResult,unassignedResult,reconciliationResult⟩
  diagnostics ← AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨allResults,Diagnostic ⟨"coefficient_sum_failed","Statement totals exceed exact range"⟩⟩
  output ← {state⇐"error",table⇐EmptyRows @,totals⇐EmptyTotals @,funding_contributors⇐empty,unassigned_contributors⇐empty,diagnostics⇐diagnostics}
  {𝕊:
    totalCoefficients ← {𝕩.coefficient}¨termTotals
    fundingContributors ← ∾{𝕩⊑actualBalance.accounts.contributors}¨fundingRows
    output↩{
      state⇐"ok",table⇐table,
      totals⇐{
        entitlement⇐0⊑totalCoefficients,actual_consumption⇐1⊑totalCoefficients,actual_refunds⇐2⊑totalCoefficients,
        fulfillment⇐3⊑totalCoefficients,ledger_remaining⇐4⊑totalCoefficients,open_plan_reserve⇐5⊑totalCoefficients,
        post_plan_headroom⇐6⊑totalCoefficients,funding_balance⇐fundingResult.coefficient,
        signed_envelope_total⇐4⊑totalCoefficients,backing_required⇐backingResult.coefficient,
        backing_surplus⇐surplusResult.coefficient,ledger_unassigned⇐unassignedResult.coefficient,
        reconciliation_delta⇐reconciliationResult.coefficient
      },funding_contributors⇐fundingContributors,
      unassigned_contributors⇐entitlementObservation.unassigned_contributors,diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  output
}

Build ← {𝕊 budgetMovements‿budgetPolicy‿householdPolicy‿envelopeHistory‿actualFacts‿planFacts‿planRetirements‿domain‿start‿finish‿observation:
  diagnostics ← ValidateInputs ⟨budgetMovements,budgetPolicy,householdPolicy,envelopeHistory,actualFacts,planFacts,domain,start,finish,observation⟩
  result ← EmptyResult ⟨"error","",domain,diagnostics⟩
  {𝕊:
    ownership ← ResolveOwnership ⟨actualFacts.accounts,budgetPolicy,householdPolicy,domain⟩
    result↩EmptyResult ⟨ownership.state,ownership.reason,domain,ownership.diagnostics⟩
    {𝕊:
      prepared ← PrepareEvidence ⟨budgetMovements,envelopeHistory,householdPolicy,actualFacts,planFacts,planRetirements,domain,start,finish,observation⟩
      result↩EmptyResult ⟨"error","",domain,prepared.diagnostics⟩
      {𝕊:
        sourceScales ← ⟨prepared.entitlement_observation.scale,prepared.actual_balance.scale,prepared.consumption_observation.scale,prepared.fulfillment_observation.scale,prepared.commitment_observation.scale⟩
        targetScale ← ⌈´sourceScales
        terms ← BuildEnvelopeTerms ⟨actualFacts.accounts,ownership,prepared,targetScale⟩
        result↩EmptyResult ⟨"error","",domain,terms.diagnostics⟩
        {𝕊:
          backing ← BuildBacking ⟨prepared,ownership,terms,targetScale⟩
          result↩EmptyResult ⟨"error","",domain,backing.diagnostics⟩
          {𝕊:result↩{
            state⇐"ok",reason⇐"",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,
            scale⇐targetScale,status⇐(backing.totals.backing_surplus<0)⊑"backed"‿"under_backed",
            envelopes⇐backing.table,totals⇐backing.totals,entitlement_observation⇐prepared.entitlement_observation,consumption_observation⇐prepared.consumption_observation,
            fulfillment_observation⇐prepared.fulfillment_observation,commitment_observation⇐prepared.commitment_observation,
            funding_account_indices⇐ownership.funding_indices,funding_contributors⇐backing.funding_contributors,
            unassigned_contributors⇐backing.unassigned_contributors,diagnostics⇐empty
          }}⍟(backing.state≡"ok") @
        }⍟(terms.state≡"ok") @
      }⍟(prepared.state≡"ok") @
    }⍟(ownership.state≡"ok") @
  }⍟(0=≠diagnostics) @
  result
}

{Build⇐Build}