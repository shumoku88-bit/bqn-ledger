# Pure Envelope & Backing Statement from canonical Budget/Actual/Plan evidence.
# budget.journal owns Budget movements, historical Envelope routing owns Actual
# Consumption, budget.toml owns current Plan/Backing policy, and household.toml
# owns Household structural Budget Account coordinates.

period ← •Import "account_period.bqn"
balance ← •Import "account_balance.bqn"
completion ← •Import "plan_completion_join.bqn"
consumption ← •Import "envelope_consumption.bqn"
reference ← •Import "../ledger/fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 code‿message:{severity⇐"error",stage⇐"accounting_envelope_backing",code⇐code,message⇐message}}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
ErrorExact ← {𝕊:{state⇐"error",coefficient⇐empty}}

EmptyRows ← {𝕊:{
  count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,category⇐empty,
  entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
  ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
  entitlement_contributors⇐empty,consumption_contributors⇐empty,
  refund_contributors⇐empty,plan_contributors⇐empty
}}
EmptyTotals ← {𝕊:{
  entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
  ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
  funding_balance⇐empty,signed_envelope_total⇐empty,backing_required⇐empty,
  backing_surplus⇐empty,ledger_unassigned⇐empty,reconciliation_delta⇐empty
}}
EmptyResult ← {𝕊 state‿reason‿domain‿diagnostics:{
  state⇐state,reason⇐reason,domain⇐domain,
  start_ordinal⇐empty,end_exclusive_ordinal⇐empty,observation_ordinal⇐empty,
  scale⇐0,status⇐"",envelopes⇐EmptyRows @,totals⇐EmptyTotals @,
  consumption_observation⇐@,funding_account_indices⇐empty,funding_contributors⇐empty,
  unassigned_contributors⇐empty,diagnostics⇐diagnostics
}}

ValidateInputs ← {𝕊 budgetFacts‿budgetPolicy‿householdPolicy‿envelopeHistory‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨budgetFacts,"budget.journal"⟩,Diagnostic ⟨"budget_facts_invalid","Budget facts must be admitted from budget.journal"⟩⟩
  diagnostics∾↩AddIf ⟨(budgetPolicy.state≢"ok") ∨ budgetPolicy.source_name≢"budget.toml",Diagnostic ⟨"budget_policy_invalid","Budget policy must be admitted from budget.toml"⟩⟩
  diagnostics∾↩AddIf ⟨(householdPolicy.state≢"ok") ∨ householdPolicy.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","Household policy must be admitted from household.toml"⟩⟩
  diagnostics∾↩AddIf ⟨envelopeHistory.state≢"ok",Diagnostic ⟨"envelope_history_invalid","Envelope history must be admitted before Envelope observation"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  domainKnown ← Contains ⟨domain,actualFacts.accounts.currency⟩
  diagnostics∾↩AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Accounts"⟩⟩
  rangeInvalid ← (start≥finish) ∨ (observation<start) ∨ observation≥finish
  diagnostics∾↩AddIf ⟨rangeInvalid,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩
  axesMatch ← (budgetFacts.accounts.key≡actualFacts.accounts.key) ∧ planFacts.accounts.key≡actualFacts.accounts.key
  diagnostics∾↩AddIf ⟨¬axesMatch,Diagnostic ⟨"account_axis_mismatch","Budget, Actual, and Plan facts must share one Account axis"⟩⟩
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

  # Current Expense assignments remain only as the temporary open-Plan reserve
  # compatibility relation. Actual Consumption is owned by historical routing.
  planExpenseKeys ← ∾budgetPolicy.envelopes.expense_account_keys
  planExpenseEnvelopeIds ← ∾{𝕊 i:(≠i⊑budgetPolicy.envelopes.expense_account_keys)⥊⟨i⊑categories⟩}¨↕≠categories
  planExpenseIndices ← accounts.key⊐planExpenseKeys
  expenseKnown ← planExpenseIndices<accounts.count
  expenseRoles ← planExpenseIndices⊏accounts.role∾⟨""⟩
  diagnostics∾↩AddIf ⟨¬∧´1∾expenseKnown,Diagnostic ⟨"budget_policy_expense_account_unknown","budget.toml Expense Accounts must occur on the current Facts Account axis"⟩⟩
  diagnostics∾↩AddIf ⟨∨´0∾expenseKnown ∧ ¬"expense"⊸≡¨expenseRoles,Diagnostic ⟨"budget_policy_expense_account_role_invalid","budget.toml Expense Accounts must remain Expense Accounts on the current Facts axis"⟩⟩

  # Pool membership may span Commodities; resolve by key first, then project the
  # current Account axis to the requested domain while preserving policy order.
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
   plan_expense_indices⇐planExpenseIndices,plan_expense_envelope_ids⇐planExpenseEnvelopeIds,
   funding_indices⇐fundingIndices,unassigned_indices⇐unassignedIndices,diagnostics⇐diagnostics}
}

PrepareEvidence ← {𝕊 budgetFacts‿envelopeHistory‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  budgetPeriod ← period.Build ⟨budgetFacts,domain,"budget",start,finish⟩
  actualBalance ← balance.Build ⟨actualFacts,domain,observation⟩
  consumptionObservation ← consumption.Build ⟨actualFacts,envelopeHistory,domain,start,observation+1⟩
  planMask ← (planFacts.transactions.date_ordinal≥observation) ∧ planFacts.transactions.date_ordinal<finish
  planSelection ← planMask/planFacts.transactions.index
  actualSelection ← (actualFacts.transactions.date_ordinal≤observation)/actualFacts.transactions.index
  joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
  diagnostics ← budgetPeriod.diagnostics∾actualBalance.diagnostics∾consumptionObservation.diagnostics∾joined.diagnostics
  badStatus ← ∨´0∾{Contains ⟨𝕩,⟨"duplicate","ambiguous"⟩⟩}¨joined.rows.status
  badCurrency ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.currency_matches
  badDirection ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.direction_matches
  conflict ← badStatus ∨ badCurrency ∨ badDirection
  diagnostics∾↩AddIf ⟨conflict,Diagnostic ⟨"plan_completion_conflict","Plan completion evidence must be unique and matching"⟩⟩
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",budget_period⇐budgetPeriod,actual_balance⇐actualBalance,
   consumption_observation⇐consumptionObservation,completion_join⇐joined,diagnostics⇐diagnostics}
}

NormalizeOne ← {𝕊 coefficient‿sourceScale‿targetScale:scale.Normalize ⟨coefficient,sourceScale,targetScale⟩}
SumNormalized ← {𝕊 coefficients‿sourceScale‿targetScale:
  normalized ← {𝕊 value:NormalizeOne ⟨value,sourceScale,targetScale⟩}¨coefficients ⋄ result ← ErrorExact @
  {𝕊:result↩scale.Sum {𝕩.coefficient}¨normalized}⍟(∧´1∾{𝕩.state≡"ok"}¨normalized) @ ⋄ result
}
PostingReferences ← {𝕊 facts‿indices:{reference.Posting ⟨facts,𝕩⟩}¨indices}

BuildEnvelopeTerms ← {𝕊 budgetFacts‿accounts‿ownership‿prepared‿domain‿targetScale:
  budgetPeriod ← prepared.budget_period ⋄ joined ← prepared.completion_join
  consumptionObservation ← prepared.consumption_observation ⋄ managed ← consumptionObservation.managed
  envelopeIndices ← ownership.envelope_indices ⋄ categories ← ownership.categories ⋄ envelopeCount ← ≠envelopeIndices
  budgetRows ← budgetPeriod.accounts.account_index⊐envelopeIndices
  entitlementResults ← {𝕊 row:NormalizeOne ⟨row⊑budgetPeriod.accounts.closing,budgetPeriod.scale,targetScale⟩}¨budgetRows
  entitlementIndices ← {𝕊 row:(row⊑budgetPeriod.accounts.opening_contributors)∾row⊑budgetPeriod.accounts.period_contributors}¨budgetRows

  # Stable historical Envelope identity is qualified against the current report
  # row axis here. Missing identity fails closed; current assignments never fill it.
  managedRows ← managed.envelope_id⊐categories
  managedKnown ← managedRows<managed.count
  diagnostics ← AddIf ⟨¬∧´1∾managedKnown,Diagnostic ⟨"envelope_identity_missing","Current Envelope must have a stable historical Envelope identity"⟩⟩
  consumptionValues ← managedRows⊏managed.consumption∾⟨0⟩
  refundValues ← managedRows⊏managed.refunds∾⟨0⟩
  consumptionResults ← {NormalizeOne ⟨𝕩,consumptionObservation.scale,targetScale⟩}¨consumptionValues
  refundResults ← {NormalizeOne ⟨𝕩,consumptionObservation.scale,targetScale⟩}¨refundValues
  consumptionContributors ← managedRows⊏managed.consumption_contributors∾⟨empty⟩
  refundContributors ← managedRows⊏managed.refund_contributors∾⟨empty⟩

  # Plan reserve remains on the current assignment compatibility relation in this
  # cutover. It is intentionally independent from Actual historical Consumption.
  expenseIndices ← ownership.plan_expense_indices ⋄ expenseEnvelopeIds ← ownership.plan_expense_envelope_ids
  domainMask ← domain⊸≡¨expenseIndices⊏accounts.currency
  expenseIndices↩domainMask/expenseIndices ⋄ expenseEnvelopeIds↩domainMask/expenseEnvelopeIds
  planAccountRows ← accounts.key⊐joined.rows.planned_to_account
  assignmentRows ← expenseIndices⊐planAccountRows
  assigned ← assignmentRows<≠expenseIndices
  planEnvelopeIds ← assignmentRows⊏expenseEnvelopeIds∾⟨""⟩
  planCoordinates ← categories⊐planEnvelopeIds
  openMask ← ("open"⊸≡¨joined.rows.status) ∧ assigned
  openCoordinates ← openMask/planCoordinates ⋄ planCoefficients ← openMask/joined.rows.planned_coefficient
  planScales ← openMask/joined.rows.planned_scale
  reserveNormalized ← planCoefficients {NormalizeOne ⟨𝕨,𝕩,targetScale⟩}¨planScales
  planGroups ← openCoordinates∾⟨envelopeCount⟩ ⋄ reserveGroups ← planGroups⊔reserveNormalized
  reserveResults ← {𝕊 results:
    result ← ErrorExact @
    {𝕊:result↩scale.Sum {𝕩.coefficient}¨results}⍟(∧´1∾{𝕩.state≡"ok"}¨results) @ ⋄ result
  }¨reserveGroups

  entitlementOk ← {𝕩.state≡"ok"}¨entitlementResults ⋄ consumptionOk ← {𝕩.state≡"ok"}¨consumptionResults
  refundOk ← {𝕩.state≡"ok"}¨refundResults ⋄ reserveOk ← {𝕩.state≡"ok"}¨reserveResults
  termsOk ← entitlementOk ∧ consumptionOk ∧ refundOk ∧ reserveOk
  remainingResults ← {𝕊 i:
    result ← ErrorExact @
    {𝕊:result↩scale.Sum ⟨(i⊑entitlementResults).coefficient,-(i⊑consumptionResults).coefficient,(i⊑refundResults).coefficient⟩}⍟(i⊑termsOk) @
    result
  }¨↕envelopeCount
  headroomResults ← {𝕊 i:
    result ← ErrorExact @ ⋄ remaining ← i⊑remainingResults
    {𝕊:result↩scale.Sum ⟨remaining.coefficient,-(i⊑reserveResults).coefficient⟩}⍟(remaining.state≡"ok") @ ⋄ result
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
    actual_refunds⇐{𝕩.coefficient}¨refundResults,ledger_remaining⇐{𝕩.coefficient}¨remainingResults,
    open_plan_reserve⇐{𝕩.coefficient}¨reserveResults,post_plan_headroom⇐{𝕩.coefficient}¨headroomResults,
    entitlement_contributors⇐{PostingReferences ⟨budgetFacts,𝕩⟩}¨entitlementIndices,
    consumption_contributors⇐consumptionContributors,refund_contributors⇐refundContributors,
    plan_contributors⇐planGroups⊔openMask/joined.rows.plan_reference
  }}⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",table⇐table,diagnostics⇐diagnostics}
}

BuildBacking ← {𝕊 budgetFacts‿prepared‿ownership‿terms‿targetScale:
  budgetPeriod ← prepared.budget_period ⋄ actualBalance ← prepared.actual_balance ⋄ table ← terms.table
  entitlement ← table.entitlement ⋄ consumptionValues ← table.actual_consumption ⋄ refunds ← table.actual_refunds
  remaining ← table.ledger_remaining ⋄ reserve ← table.open_plan_reserve ⋄ headroom ← table.post_plan_headroom
  termTotals ← scale.Sum¨⟨entitlement,consumptionValues,refunds,remaining,reserve,headroom⟩
  fundingIndices ← ownership.funding_indices
  fundingRows ← actualBalance.accounts.account_index⊐fundingIndices
  fundingValues ← fundingRows⊏actualBalance.accounts.closing
  fundingResult ← SumNormalized ⟨fundingValues,actualBalance.scale,targetScale⟩
  backingResult ← scale.Sum {0⌈𝕩}¨remaining ⋄ surplusResult ← ErrorExact @
  {𝕊:surplusResult↩scale.Sum ⟨fundingResult.coefficient,-backingResult.coefficient⟩}⍟((fundingResult.state≡"ok") ∧ backingResult.state≡"ok") @
  unassignedRows ← budgetPeriod.accounts.account_index⊐ownership.unassigned_indices
  unassignedValues ← unassignedRows⊏budgetPeriod.accounts.closing
  unassignedResult ← SumNormalized ⟨unassignedValues,budgetPeriod.scale,targetScale⟩
  reconciliationResult ← ErrorExact @
  {𝕊:reconciliationResult↩scale.Sum ⟨surplusResult.coefficient,-unassignedResult.coefficient⟩}⍟((surplusResult.state≡"ok") ∧ unassignedResult.state≡"ok") @
  allResults ← termTotals∾⟨fundingResult,backingResult,surplusResult,unassignedResult,reconciliationResult⟩
  diagnostics ← AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨allResults,Diagnostic ⟨"coefficient_sum_failed","Statement totals exceed exact range"⟩⟩
  output ← {state⇐"error",table⇐EmptyRows @,totals⇐EmptyTotals @,funding_contributors⇐empty,unassigned_contributors⇐empty,diagnostics⇐diagnostics}
  {𝕊:
    totalCoefficients ← {𝕩.coefficient}¨termTotals
    fundingContributors ← ∾{𝕩⊑actualBalance.accounts.contributors}¨fundingRows
    unassignedPostingIndices ← ∾{𝕊 row:(row⊑budgetPeriod.accounts.opening_contributors)∾row⊑budgetPeriod.accounts.period_contributors}¨unassignedRows
    output↩{
      state⇐"ok",table⇐table,
      totals⇐{
        entitlement⇐0⊑totalCoefficients,actual_consumption⇐1⊑totalCoefficients,actual_refunds⇐2⊑totalCoefficients,
        ledger_remaining⇐3⊑totalCoefficients,open_plan_reserve⇐4⊑totalCoefficients,post_plan_headroom⇐5⊑totalCoefficients,
        funding_balance⇐fundingResult.coefficient,signed_envelope_total⇐3⊑totalCoefficients,
        backing_required⇐backingResult.coefficient,backing_surplus⇐surplusResult.coefficient,
        ledger_unassigned⇐unassignedResult.coefficient,reconciliation_delta⇐reconciliationResult.coefficient
      },funding_contributors⇐fundingContributors,
      unassigned_contributors⇐PostingReferences ⟨budgetFacts,unassignedPostingIndices⟩,diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  output
}

Build ← {𝕊 budgetFacts‿budgetPolicy‿householdPolicy‿envelopeHistory‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  diagnostics ← ValidateInputs ⟨budgetFacts,budgetPolicy,householdPolicy,envelopeHistory,actualFacts,planFacts,domain,start,finish,observation⟩
  result ← EmptyResult ⟨"error","",domain,diagnostics⟩
  {𝕊:
    ownership ← ResolveOwnership ⟨actualFacts.accounts,budgetPolicy,householdPolicy,domain⟩
    result↩EmptyResult ⟨ownership.state,ownership.reason,domain,ownership.diagnostics⟩
    {𝕊:
      prepared ← PrepareEvidence ⟨budgetFacts,envelopeHistory,actualFacts,planFacts,domain,start,finish,observation⟩
      result↩EmptyResult ⟨"error","",domain,prepared.diagnostics⟩
      {𝕊:
        sourceScales ← ⟨prepared.budget_period.scale,prepared.actual_balance.scale,prepared.consumption_observation.scale⟩
        targetScale ← ⌈´sourceScales∾prepared.completion_join.rows.planned_scale
        terms ← BuildEnvelopeTerms ⟨budgetFacts,actualFacts.accounts,ownership,prepared,domain,targetScale⟩
        result↩EmptyResult ⟨"error","",domain,terms.diagnostics⟩
        {𝕊:
          backing ← BuildBacking ⟨budgetFacts,prepared,ownership,terms,targetScale⟩
          result↩EmptyResult ⟨"error","",domain,backing.diagnostics⟩
          {𝕊:result↩{
            state⇐"ok",reason⇐"",domain⇐domain,start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,
            scale⇐targetScale,status⇐(backing.totals.backing_surplus<0)⊑"backed"‿"under_backed",
            envelopes⇐backing.table,totals⇐backing.totals,consumption_observation⇐prepared.consumption_observation,
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
