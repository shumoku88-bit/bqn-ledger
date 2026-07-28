# Pure Envelope & Backing Statement from strict Budget/Actual/Plan evidence.

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

ValidateInputs ← {𝕊 budgetFacts‿actualFacts‿planFacts‿domain‿start‿finish‿observation‿fundingIndices:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨budgetFacts,"budget_alloc.tsv"⟩,Diagnostic ⟨"budget_facts_invalid","Budget facts must be admitted"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.tsv"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted"⟩⟩
  domainKnown ← Contains ⟨domain,actualFacts.accounts.currency⟩
  diagnostics ∾↩ AddIf ⟨¬domainKnown,Diagnostic ⟨"domain_unknown","selected domain must occur in admitted Accounts"⟩⟩
  rangeInvalid ← (start≥finish) ∨ (observation<start) ∨ observation≥finish
  diagnostics ∾↩ AddIf ⟨rangeInvalid,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩
  axesMatch ← (budgetFacts.accounts.key≡actualFacts.accounts.key) ∧ planFacts.accounts.key≡actualFacts.accounts.key
  diagnostics ∾↩ AddIf ⟨¬axesMatch,Diagnostic ⟨"account_axis_mismatch","all sources must share one Account axis"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠fundingIndices)≠≠Unique fundingIndices,Diagnostic ⟨"funding_scope_duplicate","funding indices must be unique"⟩⟩
  fundingKnown ← ∧´1∾{Contains ⟨𝕩,actualFacts.accounts.index⟩}¨fundingIndices
  diagnostics ∾↩ AddIf ⟨¬fundingKnown,Diagnostic ⟨"funding_scope_invalid","funding indices must be admitted Accounts"⟩⟩
  diagnostics
}

ResolveOwnership ← {𝕊 accounts‿domain‿fundingIndices:
  envelopeMask ← (domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ "envelope"⊸≡¨accounts.kind
  envelopeIndices ← envelopeMask/accounts.index
  categories ← envelopeMask/accounts.budget
  unassignedMask ← (domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ "unassigned"⊸≡¨accounts.kind
  unassignedIndices ← unassignedMask/accounts.index
  ownershipMissing ← (0=≠envelopeIndices) ∨ (0=≠fundingIndices) ∨ 1≠≠unassignedIndices
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨categories,Diagnostic ⟨"envelope_category_missing","Envelope Accounts require category metadata"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠categories)≠≠Unique categories,Diagnostic ⟨"envelope_category_duplicate","Envelope categories must be unique"⟩⟩
  fundingValid ← ∧´1∾{𝕊 i: ((i⊑accounts.currency)≡domain) ∧ (i⊑accounts.role)≡"asset"}¨fundingIndices
  diagnostics ∾↩ AddIf ⟨¬fundingValid,Diagnostic ⟨"funding_scope_invalid","funding scope requires selected-domain asset Accounts"⟩⟩
  state ← "ok" ⋄ reason ← "" ⋄ unassignedIndex ← empty
  {𝕊: state↩"unavailable" ⋄ reason↩"envelope_or_funding_ownership_missing" ⋄ diagnostics↩empty}⍟ownershipMissing @
  {𝕊: state↩"error"}⍟((¬ownershipMissing) ∧ 0<≠diagnostics) @
  {𝕊: unassignedIndex↩⊑unassignedIndices}⍟(¬ownershipMissing) @
  {
    state⇐state,reason⇐reason,envelope_indices⇐envelopeIndices,categories⇐categories,
    unassigned_index⇐unassignedIndex,diagnostics⇐diagnostics
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

BuildEnvelopeTerms ← {𝕊 budgetFacts‿actualFacts‿accounts‿ownership‿prepared‿domain‿targetScale:
  budgetPeriod ← prepared.budget_period
  actualPeriod ← prepared.actual_period
  joined ← prepared.completion_join
  diagnostics ← empty ⋄ rows ← empty
  {𝕊 envelopeIndex:
    category ← envelopeIndex⊑accounts.budget
    expenseMask ← (domain⊸≡¨accounts.currency) ∧ ("expense"⊸≡¨accounts.role) ∧ category⊸≡¨accounts.budget
    expenseIndices ← expenseMask/accounts.index
    budgetRow ← IndexOf ⟨envelopeIndex,budgetPeriod.accounts.account_index⟩
    entitlementResult ← NormalizeOne ⟨budgetRow⊑budgetPeriod.accounts.movement,budgetPeriod.scale,targetScale⟩
    expenseRows ← {IndexOf ⟨𝕩,actualPeriod.accounts.account_index⟩}¨expenseIndices
    consumptionResult ← SumNormalized ⟨expenseRows⊏actualPeriod.accounts.debit_movement,actualPeriod.scale,targetScale⟩
    refundResult ← SumNormalized ⟨-(expenseRows⊏actualPeriod.accounts.credit_movement),actualPeriod.scale,targetScale⟩
    expenseKeys ← expenseIndices⊏accounts.key
    openMask ← ("open"⊸≡¨joined.rows.status) ∧ {Contains ⟨𝕩,expenseKeys⟩}¨joined.rows.planned_to_account
    openRows ← openMask/joined.rows.index
    reserveNormalized ← {𝕊 i:
      NormalizeOne ⟨i⊑joined.rows.planned_coefficient,i⊑joined.rows.planned_scale,targetScale⟩
    }¨openRows
    reserveResult ← ErrorExact @
    {𝕊: reserveResult↩scale.Sum {𝕩.coefficient}¨reserveNormalized}⍟(∧´1∾{𝕩.state≡"ok"}¨reserveNormalized) @
    termsOk ← ∧´{𝕩.state≡"ok"}¨⟨entitlementResult,consumptionResult,refundResult,reserveResult⟩
    diagnostics ∾↩ AddIf ⟨¬termsOk,Diagnostic ⟨"coefficient_sum_failed","Envelope terms exceed exact range"⟩⟩
    {𝕊:
      remainingResult ← scale.Sum ⟨entitlementResult.coefficient,-consumptionResult.coefficient,refundResult.coefficient⟩
      headroomResult ← ErrorExact @
      {𝕊: headroomResult↩scale.Sum ⟨remainingResult.coefficient,-reserveResult.coefficient⟩}⍟(remainingResult.state≡"ok") @
      finalOk ← (remainingResult.state≡"ok") ∧ headroomResult.state≡"ok"
      diagnostics ∾↩ AddIf ⟨¬finalOk,Diagnostic ⟨"coefficient_sum_failed","Envelope remaining exceeds exact range"⟩⟩
      {𝕊:
        entitlementIndices ← budgetRow⊑budgetPeriod.accounts.period_contributors
        debitIndices ← ∾{𝕩⊑actualPeriod.accounts.debit_contributors}¨expenseRows
        creditIndices ← ∾{𝕩⊑actualPeriod.accounts.credit_contributors}¨expenseRows
        rows∾↩⟨{
          account_index⇐envelopeIndex,account_key⇐envelopeIndex⊑accounts.key,category⇐category,
          entitlement⇐entitlementResult.coefficient,actual_consumption⇐consumptionResult.coefficient,
          actual_refunds⇐refundResult.coefficient,ledger_remaining⇐remainingResult.coefficient,
          open_plan_reserve⇐reserveResult.coefficient,post_plan_headroom⇐headroomResult.coefficient,
          entitlement_contributors⇐PostingReferences ⟨budgetFacts,entitlementIndices⟩,
          consumption_contributors⇐PostingReferences ⟨actualFacts,debitIndices⟩,
          refund_contributors⇐PostingReferences ⟨actualFacts,creditIndices⟩,
          plan_contributors⇐openRows⊏joined.rows.plan_reference
        }⟩
      }⍟finalOk @
    }⍟termsOk @
  }¨ownership.envelope_indices
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",rows⇐rows,diagnostics⇐diagnostics}
}

RowsTable ← {𝕊 rows:
  {
    count⇐≠rows,index⇐↕≠rows,account_index⇐{𝕩.account_index}¨rows,
    account_key⇐{𝕩.account_key}¨rows,category⇐{𝕩.category}¨rows,
    entitlement⇐{𝕩.entitlement}¨rows,actual_consumption⇐{𝕩.actual_consumption}¨rows,
    actual_refunds⇐{𝕩.actual_refunds}¨rows,ledger_remaining⇐{𝕩.ledger_remaining}¨rows,
    open_plan_reserve⇐{𝕩.open_plan_reserve}¨rows,post_plan_headroom⇐{𝕩.post_plan_headroom}¨rows,
    entitlement_contributors⇐{𝕩.entitlement_contributors}¨rows,
    consumption_contributors⇐{𝕩.consumption_contributors}¨rows,
    refund_contributors⇐{𝕩.refund_contributors}¨rows,plan_contributors⇐{𝕩.plan_contributors}¨rows
  }
}

BuildBacking ← {𝕊 budgetFacts‿prepared‿ownership‿terms‿fundingIndices‿targetScale:
  budgetPeriod ← prepared.budget_period ⋄ actualBalance ← prepared.actual_balance
  rows ← terms.rows
  entitlement ← {𝕩.entitlement}¨rows ⋄ consumption ← {𝕩.actual_consumption}¨rows
  refunds ← {𝕩.actual_refunds}¨rows ⋄ remaining ← {𝕩.ledger_remaining}¨rows
  reserve ← {𝕩.open_plan_reserve}¨rows ⋄ headroom ← {𝕩.post_plan_headroom}¨rows
  termTotals ← scale.Sum¨⟨entitlement,consumption,refunds,remaining,reserve,headroom⟩
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
      state⇐"ok",table⇐RowsTable rows,
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

Build ← {𝕊 budgetFacts‿actualFacts‿planFacts‿domain‿start‿finish‿observation‿fundingIndices:
  diagnostics ← ValidateInputs ⟨budgetFacts,actualFacts,planFacts,domain,start,finish,observation,fundingIndices⟩
  result ← EmptyResult ⟨"error","",domain,diagnostics⟩
  {𝕊:
    ownership ← ResolveOwnership ⟨actualFacts.accounts,domain,fundingIndices⟩
    result↩EmptyResult ⟨ownership.state,ownership.reason,domain,ownership.diagnostics⟩
    {𝕊:
      prepared ← PrepareEvidence ⟨budgetFacts,actualFacts,planFacts,domain,start,finish,observation⟩
      result↩EmptyResult ⟨"error","",domain,prepared.diagnostics⟩
      {𝕊:
        sourceScales ← ⟨prepared.budget_period.scale,prepared.actual_period.scale,prepared.actual_balance.scale⟩
        targetScale ← ⌈´sourceScales∾prepared.completion_join.rows.planned_scale
        terms ← BuildEnvelopeTerms ⟨budgetFacts,actualFacts,actualFacts.accounts,ownership,prepared,domain,targetScale⟩
        result↩EmptyResult ⟨"error","",domain,terms.diagnostics⟩
        {𝕊:
          backing ← BuildBacking ⟨budgetFacts,prepared,ownership,terms,fundingIndices,targetScale⟩
          result↩EmptyResult ⟨"error","",domain,backing.diagnostics⟩
          {𝕊:
            result↩{
              state⇐"ok",reason⇐"",domain⇐domain,
              start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,
              scale⇐targetScale,status⇐(backing.totals.backing_surplus<0)⊑"backed"‿"under_backed",
              envelopes⇐backing.table,totals⇐backing.totals,
              funding_account_indices⇐fundingIndices,
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
