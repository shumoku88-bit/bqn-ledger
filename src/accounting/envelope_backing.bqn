# Pure Envelope & Backing Statement from canonical Budget/Actual/Plan evidence.
# Budget movement comes from budget.journal and general Envelope/Backing policy
# comes from budget.toml. Household structural Budget Account classification is
# intentionally retained until household.toml Phase 5.

period ← •Import "account_period.bqn"
balance ← •Import "account_balance.bqn"
completion ← •Import "plan_completion_join.bqn"
reference ← •Import "fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Unique ← {𝕊 values:
  result ← empty
  {𝕊 value: {𝕊: result∾↩⟨value⟩}⍟(¬Contains ⟨value,result⟩) @}¨values
  result
}
Diagnostic ← {𝕊 code‿message:
  {severity⇐"error",stage⇐"accounting_envelope_backing",code⇐code,message⇐message}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
ErrorExact ← {𝕊: {state⇐"error",coefficient⇐empty}}

EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,category⇐empty,
    entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
    ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
    entitlement_contributors⇐empty,consumption_contributors⇐empty,
    refund_contributors⇐empty,plan_contributors⇐empty
  }
}
EmptyTotals ← {𝕊:
  {
    entitlement⇐empty,actual_consumption⇐empty,actual_refunds⇐empty,
    ledger_remaining⇐empty,open_plan_reserve⇐empty,post_plan_headroom⇐empty,
    funding_balance⇐empty,signed_envelope_total⇐empty,backing_required⇐empty,
    backing_surplus⇐empty,ledger_unassigned⇐empty,reconciliation_delta⇐empty
  }
}
EmptyResult ← {𝕊 state‿reason‿domain‿diagnostics:
  {
    state⇐state,reason⇐reason,domain⇐domain,
    start_ordinal⇐empty,end_exclusive_ordinal⇐empty,observation_ordinal⇐empty,
    scale⇐0,status⇐"",envelopes⇐EmptyRows @,totals⇐EmptyTotals @,
    funding_account_indices⇐empty,funding_contributors⇐empty,
    unassigned_contributors⇐empty,diagnostics⇐diagnostics
  }
}

ValidateInputs ← {𝕊 budgetFacts‿budgetPolicy‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨budgetFacts,"budget.journal"⟩,Diagnostic ⟨"budget_facts_invalid","Budget facts must be admitted from budget.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨(budgetPolicy.state≢"ok") ∨ budgetPolicy.source_name≢"budget.toml",Diagnostic ⟨"budget_policy_invalid","Budget policy must be admitted from budget.toml"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  domainKnown ← Contains ⟨domain,actualFacts.accounts.currency⟩
  diagnostics ∾↩ AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Accounts"⟩⟩
  rangeInvalid ← (start≥finish) ∨ (observation<start) ∨ observation≥finish
  diagnostics ∾↩ AddIf ⟨rangeInvalid,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩
  axesMatch ← (budgetFacts.accounts.key≡actualFacts.accounts.key) ∧ planFacts.accounts.key≡actualFacts.accounts.key
  diagnostics ∾↩ AddIf ⟨¬axesMatch,Diagnostic ⟨"account_axis_mismatch","all sources must share one Account axis"⟩⟩
  fundingIndices ← budgetPolicy.asset_account_index
  diagnostics ∾↩ AddIf ⟨(≠fundingIndices)≠≠Unique fundingIndices,Diagnostic ⟨"funding_scope_duplicate","Budget policy funding Accounts must be unique"⟩⟩
  fundingKnown ← ∧´1∾{Contains ⟨𝕩,actualFacts.accounts.index⟩}¨fundingIndices
  diagnostics ∾↩ AddIf ⟨¬fundingKnown,Diagnostic ⟨"funding_scope_invalid","Budget policy funding Accounts must be admitted"⟩⟩
  diagnostics
}

ResolveOwnership ← {𝕊 accounts‿budgetPolicy‿domain:
  categories ← budgetPolicy.envelopes.id
  envelopeIndices ← empty
  diagnostics ← empty
  {𝕊 category:
    mask ← (domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ ("envelope"⊸≡¨accounts.kind) ∧ category⊸≡¨accounts.budget
    diagnostics ∾↩ AddIf ⟨1≠+´mask,Diagnostic ⟨"envelope_account_mapping_invalid","Each budget.toml envelope must map to exactly one structural Budget Account until household.toml Phase 5"⟩⟩
    {𝕊:envelopeIndices∾↩⟨⊑mask/accounts.index⟩}⍟(1=+´mask) @
  }¨categories
  unassignedMask ← (domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ "unassigned"⊸≡¨accounts.kind
  unassignedIndices ← unassignedMask/accounts.index
  fundingIndices ← budgetPolicy.asset_account_index
  ownershipMissing ← (0=≠envelopeIndices) ∨ (0=≠fundingIndices) ∨ 1≠≠unassignedIndices
  fundingValid ← ∧´1∾{𝕊 i: ((i⊑accounts.currency)≡domain) ∧ (i⊑accounts.role)≡"asset"}¨fundingIndices
  diagnostics ∾↩ AddIf ⟨¬fundingValid,Diagnostic ⟨"funding_scope_invalid","budget.toml backing Accounts require selected-domain Asset Accounts"⟩⟩
  hasDiagnostics ← 0<≠diagnostics
  state ← "ok" ⋄ reason ← "" ⋄ unassignedIndex ← empty
  {𝕊: state↩"error"}⍟hasDiagnostics @
  {𝕊: state↩"unavailable" ⋄ reason↩"envelope_or_funding_ownership_missing"}⍟((¬hasDiagnostics) ∧ ownershipMissing) @
  {𝕊: unassignedIndex↩⊑unassignedIndices}⍟((¬hasDiagnostics) ∧ ¬ownershipMissing) @
  {
    state⇐state,reason⇐reason,envelope_indices⇐envelopeIndices,categories⇐categories,
    funding_indices⇐fundingIndices,unassigned_index⇐unassignedIndex,diagnostics⇐diagnostics
  }
}

PrepareEvidence ← {𝕊 budgetFacts‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  budgetPeriod ← period.Build ⟨budgetFacts,domain,"budget",start,finish⟩
  actualPeriod ← period.Build ⟨actualFacts,domain,"actual",start,observation+1⟩
  actualBalance ← balance.Build ⟨actualFacts,domain,observation⟩
  planMask ← (planFacts.transactions.date_ordinal≥observation) ∧ planFacts.transactions.date_ordinal<finish
  planSelection ← planMask/planFacts.transactions.index
  actualSelection ← (actualFacts.transactions.date_ordinal≤observation)/actualFacts.transactions.index
  joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
  diagnostics ← budgetPeriod.diagnostics∾actualPeriod.diagnostics∾actualBalance.diagnostics∾joined.diagnostics
  badStatus ← ∨´0∾{Contains ⟨𝕩,⟨"duplicate","ambiguous"⟩⟩}¨joined.rows.status
  badCurrency ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.currency_matches
  badDirection ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.direction_matches
  conflict ← badStatus ∨ badCurrency ∨ badDirection
  diagnostics ∾↩ AddIf ⟨conflict,Diagnostic ⟨"plan_completion_conflict","Plan completion evidence must be unique and matching"⟩⟩
  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",
    budget_period⇐budgetPeriod,actual_period⇐actualPeriod,actual_balance⇐actualBalance,
    completion_join⇐joined,diagnostics⇐diagnostics
  }
}

NormalizeOne ← {𝕊 coefficient‿sourceScale‿targetScale:
  scale.Normalize ⟨coefficient,sourceScale,targetScale⟩
}
SumNormalized ← {𝕊 coefficients‿sourceScale‿targetScale:
  normalized ← {𝕊 value: NormalizeOne ⟨value,sourceScale,targetScale⟩}¨coefficients
  result ← ErrorExact @
  {𝕊: result↩scale.Sum {𝕩.coefficient}¨normalized}⍟(∧´1∾{𝕩.state≡"ok"}¨normalized) @
  result
}
PostingReferences ← {𝕊 facts‿indices:
  {reference.Posting ⟨facts,𝕩⟩}¨indices
}

BuildEnvelopeTerms ← {𝕊 budgetFacts‿budgetPolicy‿actualFacts‿accounts‿ownership‿prepared‿domain‿targetScale:
  budgetPeriod ← prepared.budget_period
  actualPeriod ← prepared.actual_period
  joined ← prepared.completion_join
  envelopeIndices ← ownership.envelope_indices
  categories ← ownership.categories
  envelopeCount ← ≠envelopeIndices

  budgetRows ← budgetPeriod.accounts.account_index⊐envelopeIndices
  entitlementResults ← {𝕊 row:
    NormalizeOne ⟨row⊑budgetPeriod.accounts.movement,budgetPeriod.scale,targetScale⟩
  }¨budgetRows

  expenseIndices ← budgetPolicy.expense_account_index
  expenseEnvelopeIds ← budgetPolicy.expense_envelope_id
  domainMask ← domain⊸≡¨expenseIndices⊏accounts.currency
  expenseIndices ↩ domainMask/expenseIndices
  expenseEnvelopeIds ↩ domainMask/expenseEnvelopeIds
  expenseCoordinates ← categories⊐expenseEnvelopeIds
  matched ← expenseCoordinates<envelopeCount
  expenseIndices ↩ matched/expenseIndices
  expenseCoordinates ↩ matched/expenseCoordinates
  expenseRows ← actualPeriod.accounts.account_index⊐expenseIndices
  expenseGroups ← expenseCoordinates∾⟨envelopeCount⟩
  debitGroups ← expenseGroups⊔expenseRows⊏actualPeriod.accounts.debit_movement
  creditGroups ← expenseGroups⊔-(expenseRows⊏actualPeriod.accounts.credit_movement)
  consumptionResults ← {SumNormalized ⟨𝕩,actualPeriod.scale,targetScale⟩}¨debitGroups
  refundResults ← {SumNormalized ⟨𝕩,actualPeriod.scale,targetScale⟩}¨creditGroups

  debitCells ← expenseGroups⊔expenseRows⊏actualPeriod.accounts.debit_contributors
  creditCells ← expenseGroups⊔expenseRows⊏actualPeriod.accounts.credit_contributors
  debitIndices ← {∾⟨empty⟩∾𝕩}¨debitCells
  creditIndices ← {∾⟨empty⟩∾𝕩}¨creditCells

  planAccountRows ← accounts.key⊐joined.rows.planned_to_account
  assignmentRows ← budgetPolicy.expense_account_index⊐planAccountRows
  assigned ← assignmentRows<≠budgetPolicy.expense_account_index
  planEnvelopeIds ← assignmentRows⊏budgetPolicy.expense_envelope_id∾⟨""⟩
  planCoordinates ← categories⊐planEnvelopeIds
  planCurrencyMatches ← domain⊸≡¨planAccountRows⊏accounts.currency
  planRoleMatches ← "expense"⊸≡¨planAccountRows⊏accounts.role
  planEligible ← assigned ∧ planCurrencyMatches ∧ planRoleMatches ∧ planCoordinates<envelopeCount
  openMask ← ("open"⊸≡¨joined.rows.status) ∧ planEligible
  openCoordinates ← openMask/planCoordinates
  planCoefficients ← openMask/joined.rows.planned_coefficient
  planScales ← openMask/joined.rows.planned_scale
  reserveNormalized ← planCoefficients {NormalizeOne ⟨𝕨,𝕩,targetScale⟩}¨ planScales
  planGroups ← openCoordinates∾⟨envelopeCount⟩
  reserveGroups ← planGroups⊔reserveNormalized
  reserveResults ← {𝕊 results:
    result ← ErrorExact @
    {𝕊: result↩scale.Sum {𝕩.coefficient}¨results}⍟(∧´1∾{𝕩.state≡"ok"}¨results) @
    result
  }¨reserveGroups

  entitlementOk ← {𝕩.state≡"ok"}¨entitlementResults
  consumptionOk ← {𝕩.state≡"ok"}¨consumptionResults
  refundOk ← {𝕩.state≡"ok"}¨refundResults
  reserveOk ← {𝕩.state≡"ok"}¨reserveResults
  termsOk ← entitlementOk ∧ consumptionOk ∧ refundOk ∧ reserveOk
  remainingResults ← {𝕊 i:
    result ← ErrorExact @
    {𝕊:
      result↩scale.Sum ⟨(i⊑entitlementResults).coefficient,-(i⊑consumptionResults).coefficient,(i⊑refundResults).coefficient⟩
    }⍟(i⊑termsOk) @
    result
  }¨↕envelopeCount
  headroomResults ← {𝕊 i:
    result ← ErrorExact @
    remaining ← i⊑remainingResults
    {𝕊:
      result↩scale.Sum ⟨remaining.coefficient,-(i⊑reserveResults).coefficient⟩
    }⍟(remaining.state≡"ok") @
    result
  }¨↕envelopeCount
  finalOk ← ({𝕩.state≡"ok"}¨remainingResults) ∧ {𝕩.state≡"ok"}¨headroomResults

  diagnostics ← ∾{𝕊 i:
    rowDiagnostics ← empty
    {𝕊:
      rowDiagnostics↩⟨Diagnostic ⟨"coefficient_sum_failed","Envelope terms exceed exact range"⟩⟩
    }⍟(¬i⊑termsOk) @
    {𝕊:
      rowDiagnostics↩⟨Diagnostic ⟨"coefficient_sum_failed","Envelope remaining exceeds exact range"⟩⟩
    }⍟((i⊑termsOk)∧¬i⊑finalOk) @
    rowDiagnostics
  }¨↕envelopeCount

  table ← EmptyRows @
  {𝕊:
    table↩{
      count⇐envelopeCount,index⇐↕envelopeCount,
      account_index⇐envelopeIndices,account_key⇐envelopeIndices⊏accounts.key,category⇐categories,
      entitlement⇐{𝕩.coefficient}¨entitlementResults,
      actual_consumption⇐{𝕩.coefficient}¨consumptionResults,
      actual_refunds⇐{𝕩.coefficient}¨refundResults,
      ledger_remaining⇐{𝕩.coefficient}¨remainingResults,
      open_plan_reserve⇐{𝕩.coefficient}¨reserveResults,
      post_plan_headroom⇐{𝕩.coefficient}¨headroomResults,
      entitlement_contributors⇐{PostingReferences ⟨budgetFacts,𝕩⟩}¨budgetRows⊏budgetPeriod.accounts.period_contributors,
      consumption_contributors⇐{PostingReferences ⟨actualFacts,𝕩⟩}¨debitIndices,
      refund_contributors⇐{PostingReferences ⟨actualFacts,𝕩⟩}¨creditIndices,
      plan_contributors⇐planGroups⊔openMask/joined.rows.plan_reference
    }
  }⍟(0=≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",table⇐table,diagnostics⇐diagnostics}
}

BuildBacking ← {𝕊 budgetFacts‿prepared‿ownership‿terms‿targetScale:
  budgetPeriod ← prepared.budget_period ⋄ actualBalance ← prepared.actual_balance
  table ← terms.table
  entitlement ← table.entitlement ⋄ consumption ← table.actual_consumption
  refunds ← table.actual_refunds ⋄ remaining ← table.ledger_remaining
  reserve ← table.open_plan_reserve ⋄ headroom ← table.post_plan_headroom
  termTotals ← scale.Sum¨⟨entitlement,consumption,refunds,remaining,reserve,headroom⟩
  fundingIndices ← ownership.funding_indices
  fundingRows ← {IndexOf ⟨𝕩,actualBalance.accounts.account_index⟩}¨fundingIndices
  fundingValues ← fundingRows⊏actualBalance.accounts.closing
  fundingResult ← SumNormalized ⟨fundingValues,actualBalance.scale,targetScale⟩
  backingResult ← scale.Sum {0⌈𝕩}¨remaining
  surplusResult ← ErrorExact @
  {𝕊: surplusResult↩scale.Sum ⟨fundingResult.coefficient,-backingResult.coefficient⟩}⍟((fundingResult.state≡"ok") ∧ backingResult.state≡"ok") @
  unassignedRow ← IndexOf ⟨ownership.unassigned_index,budgetPeriod.accounts.account_index⟩
  unassignedResult ← NormalizeOne ⟨unassignedRow⊑budgetPeriod.accounts.closing,budgetPeriod.scale,targetScale⟩
  reconciliationResult ← ErrorExact @
  {𝕊:
    reconciliationResult↩scale.Sum ⟨surplusResult.coefficient,-unassignedResult.coefficient⟩
  }⍟((surplusResult.state≡"ok") ∧ unassignedResult.state≡"ok") @
  allResults ← termTotals∾⟨fundingResult,backingResult,surplusResult,unassignedResult,reconciliationResult⟩
  diagnostics ← AddIf ⟨¬∧´1∾{𝕩.state≡"ok"}¨allResults,Diagnostic ⟨"coefficient_sum_failed","Statement totals exceed exact range"⟩⟩
  output ← {
    state⇐"error",table⇐EmptyRows @,totals⇐EmptyTotals @,
    funding_contributors⇐empty,unassigned_contributors⇐empty,diagnostics⇐diagnostics
  }
  {𝕊:
    totalCoefficients ← {𝕩.coefficient}¨termTotals
    fundingContributors ← ∾{𝕩⊑actualBalance.accounts.contributors}¨fundingRows
    unassignedIndices ← (unassignedRow⊑budgetPeriod.accounts.opening_contributors)∾unassignedRow⊑budgetPeriod.accounts.period_contributors
    output↩{
      state⇐"ok",table⇐table,
      totals⇐{
        entitlement⇐0⊑totalCoefficients,actual_consumption⇐1⊑totalCoefficients,actual_refunds⇐2⊑totalCoefficients,
        ledger_remaining⇐3⊑totalCoefficients,open_plan_reserve⇐4⊑totalCoefficients,post_plan_headroom⇐5⊑totalCoefficients,
        funding_balance⇐fundingResult.coefficient,signed_envelope_total⇐3⊑totalCoefficients,
        backing_required⇐backingResult.coefficient,backing_surplus⇐surplusResult.coefficient,
        ledger_unassigned⇐unassignedResult.coefficient,reconciliation_delta⇐reconciliationResult.coefficient
      },
      funding_contributors⇐fundingContributors,
      unassigned_contributors⇐PostingReferences ⟨budgetFacts,unassignedIndices⟩,
      diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  output
}

Build ← {𝕊 budgetFacts‿budgetPolicy‿actualFacts‿planFacts‿domain‿start‿finish‿observation:
  diagnostics ← ValidateInputs ⟨budgetFacts,budgetPolicy,actualFacts,planFacts,domain,start,finish,observation⟩
  result ← EmptyResult ⟨"error","",domain,diagnostics⟩
  {𝕊:
    ownership ← ResolveOwnership ⟨actualFacts.accounts,budgetPolicy,domain⟩
    result↩EmptyResult ⟨ownership.state,ownership.reason,domain,ownership.diagnostics⟩
    {𝕊:
      prepared ← PrepareEvidence ⟨budgetFacts,actualFacts,planFacts,domain,start,finish,observation⟩
      result↩EmptyResult ⟨"error","",domain,prepared.diagnostics⟩
      {𝕊:
        sourceScales ← ⟨prepared.budget_period.scale,prepared.actual_period.scale,prepared.actual_balance.scale⟩
        targetScale ← ⌈´sourceScales∾prepared.completion_join.rows.planned_scale
        terms ← BuildEnvelopeTerms ⟨budgetFacts,budgetPolicy,actualFacts,actualFacts.accounts,ownership,prepared,domain,targetScale⟩
        result↩EmptyResult ⟨"error","",domain,terms.diagnostics⟩
        {𝕊:
          backing ← BuildBacking ⟨budgetFacts,prepared,ownership,terms,targetScale⟩
          result↩EmptyResult ⟨"error","",domain,backing.diagnostics⟩
          {𝕊:
            result↩{
              state⇐"ok",reason⇐"",domain⇐domain,
              start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,
              scale⇐targetScale,status⇐(backing.totals.backing_surplus<0)⊑"backed"‿"under_backed",
              envelopes⇐backing.table,totals⇐backing.totals,
              funding_account_indices⇐ownership.funding_indices,
              funding_contributors⇐backing.funding_contributors,
              unassigned_contributors⇐backing.unassigned_contributors,diagnostics⇐empty
            }
          }⍟(backing.state≡"ok") @
        }⍟(terms.state≡"ok") @
      }⍟(prepared.state≡"ok") @
    }⍟(ownership.state≡"ok") @
  }⍟(0=≠diagnostics) @
  result
}

{Build⇐Build}
