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

Build ← {𝕊 budgetFacts‿actualFacts‿planFacts‿domain‿start‿finish‿observation‿fundingIndices:
  # Stage 1: source, coordinate, axis, and explicit funding-scope validation.
  diagnostics ← empty
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨budgetFacts,"budget_alloc.tsv"⟩,Diagnostic ⟨"budget_facts_invalid","Budget facts must be admitted"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted"⟩⟩
  diagnostics∾↩AddIf ⟨¬reference.SourceIs ⟨planFacts,"plan.tsv"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted"⟩⟩
  diagnostics∾↩AddIf ⟨(start≥finish)∨(observation<start)∨observation≥finish,Diagnostic ⟨"statement_range_invalid","require start <= observation < end_exclusive"⟩⟩
  axesMatch ← (budgetFacts.accounts.key≡actualFacts.accounts.key) ∧ planFacts.accounts.key≡actualFacts.accounts.key
  diagnostics∾↩AddIf ⟨¬axesMatch,Diagnostic ⟨"account_axis_mismatch","all sources must share one Account axis"⟩⟩
  diagnostics∾↩AddIf ⟨(≠fundingIndices)≠≠Unique fundingIndices,Diagnostic ⟨"funding_scope_duplicate","funding indices must be unique"⟩⟩
  diagnostics∾↩AddIf ⟨¬∧´1∾{Contains ⟨𝕩,actualFacts.accounts.index⟩}¨fundingIndices,Diagnostic ⟨"funding_scope_invalid","funding indices must be admitted Accounts"⟩⟩
  result ← EmptyResult ⟨"error","",domain,diagnostics⟩
  # Stage 2: admitted Envelope, unassigned, and funding ownership resolution.
  {𝕊:
    accounts ← actualFacts.accounts
    envelopeMask ← (domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ "envelope"⊸≡¨accounts.kind
    envelopeIndices ← envelopeMask/accounts.index ⋄ categories ← envelopeMask/accounts.budget
    unassignedIndices ← ((domain⊸≡¨accounts.currency) ∧ ("budget"⊸≡¨accounts.role) ∧ "unassigned"⊸≡¨accounts.kind)/accounts.index
    ownershipUnavailable ← (0=≠envelopeIndices) ∨ (0=≠fundingIndices) ∨ 1≠≠unassignedIndices
    {𝕊: result↩EmptyResult ⟨"unavailable","envelope_or_funding_ownership_missing",domain,empty⟩}⍟ownershipUnavailable @
    {𝕊:
      diagnostics∾↩AddIf ⟨∨´0∾{0=≠𝕩}¨categories,Diagnostic ⟨"envelope_category_missing","Envelope Accounts require category metadata"⟩⟩
      diagnostics∾↩AddIf ⟨(≠categories)≠≠Unique categories,Diagnostic ⟨"envelope_category_duplicate","Envelope categories must be unique"⟩⟩
      fundingValid ← ∧´1∾{𝕊 i: ((i⊑accounts.currency)≡domain) ∧ (i⊑accounts.role)≡"asset"}¨fundingIndices
      diagnostics∾↩AddIf ⟨¬fundingValid,Diagnostic ⟨"funding_scope_invalid","funding scope requires selected-domain asset Accounts"⟩⟩
      # Stage 3: prepare exact bounded source evidence and durable completion Join.
      {𝕊:
        budgetPeriod ← period.Build ⟨budgetFacts,domain,"budget",start,finish⟩
        actualPeriod ← period.Build ⟨actualFacts,domain,"actual",start,observation+1⟩
        actualBalance ← balance.Build ⟨actualFacts,domain,observation⟩
        planSelection ← ((planFacts.transactions.date_ordinal≥observation) ∧ planFacts.transactions.date_ordinal<finish)/planFacts.transactions.index
        actualSelection ← (actualFacts.transactions.date_ordinal≤observation)/actualFacts.transactions.index
        joined ← completion.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
        diagnostics∾↩budgetPeriod.diagnostics∾actualPeriod.diagnostics∾actualBalance.diagnostics∾joined.diagnostics
        badCompletion ← ∨´0∾{Contains ⟨𝕩,⟨"duplicate","ambiguous"⟩⟩}¨joined.rows.status
        badMatch ← ∨´0∾{¬∧´1∾𝕩}¨joined.rows.currency_matches∾joined.rows.direction_matches
        diagnostics∾↩AddIf ⟨badCompletion∨badMatch,Diagnostic ⟨"plan_completion_conflict","Plan completion evidence must be unique and matching"⟩⟩
        {𝕊:
          targetScale ← ⌈´⟨budgetPeriod.scale,actualPeriod.scale,actualBalance.scale⟩∾joined.rows.planned_scale
          Norm ← {𝕊 coefficient‿sourceScale: scale.Normalize ⟨coefficient,sourceScale,targetScale⟩}
          SumNorm ← {𝕊 coefficients‿sourceScale:
            normalized ← {𝕊 x:Norm ⟨x,sourceScale⟩}¨coefficients
            output ← {state⇐"error",coefficient⇐empty}
            {𝕊:output↩scale.Sum {𝕩.coefficient}¨normalized}⍟(∧´1∾{𝕩.state≡"ok"}¨normalized) @
            output
          }
          # Stage 4: derive each Envelope's independent accounting terms.
          candidate ← empty
          {𝕊 ei:
            category ← ei⊑accounts.budget
            expenseIndices ← ((domain⊸≡¨accounts.currency) ∧ ("expense"⊸≡¨accounts.role) ∧ category⊸≡¨accounts.budget)/accounts.index
            bi ← IndexOf ⟨ei,budgetPeriod.accounts.account_index⟩
            entitlementResult ← Norm ⟨bi⊑budgetPeriod.accounts.movement,budgetPeriod.scale⟩
            entitlement ← entitlementResult.coefficient
            expenseRows ← {IndexOf ⟨𝕩,actualPeriod.accounts.account_index⟩}¨expenseIndices
            consumptionResult ← SumNorm ⟨expenseRows⊏actualPeriod.accounts.debit_movement,actualPeriod.scale⟩
            refundResult ← SumNorm ⟨-(expenseRows⊏actualPeriod.accounts.credit_movement),actualPeriod.scale⟩
            openMask ← ("open"⊸≡¨joined.rows.status) ∧ {Contains ⟨𝕩,expenseIndices⊏accounts.key⟩}¨joined.rows.planned_to_account
            reserveResults ← {𝕊 i: Norm ⟨i⊑joined.rows.planned_coefficient,i⊑joined.rows.planned_scale⟩}¨openMask/joined.rows.index
            reserveResult ← {state⇐"error",coefficient⇐empty}
            {𝕊:reserveResult↩scale.Sum {𝕩.coefficient}¨reserveResults}⍟(∧´1∾{𝕩.state≡"ok"}¨reserveResults) @
            arithmeticOk ← ∧´{𝕩.state≡"ok"}¨⟨entitlementResult,consumptionResult,refundResult,reserveResult⟩
            diagnostics∾↩AddIf ⟨¬arithmeticOk,Diagnostic ⟨"coefficient_sum_failed","Envelope terms exceed exact range"⟩⟩
            {𝕊:
              remainingResult ← scale.Sum ⟨entitlement,-consumptionResult.coefficient,refundResult.coefficient⟩
              headroomResult ← scale.Sum ⟨remainingResult.coefficient,-reserveResult.coefficient⟩
              diagnostics∾↩AddIf ⟨(remainingResult.state≢"ok")∨headroomResult.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Envelope remaining exceeds exact range"⟩⟩
              {𝕊:
                candidate∾↩⟨{
                  account_index⇐ei,account_key⇐ei⊑accounts.key,category⇐category,
                  entitlement⇐entitlement,
                  actual_consumption⇐consumptionResult.coefficient,
                  actual_refunds⇐refundResult.coefficient,
                  ledger_remaining⇐remainingResult.coefficient,
                  open_plan_reserve⇐reserveResult.coefficient,
                  post_plan_headroom⇐headroomResult.coefficient,
                  entitlement_contributors⇐{reference.Posting ⟨budgetFacts,𝕩⟩}¨bi⊑budgetPeriod.accounts.period_contributors,
                  consumption_contributors⇐∾{{reference.Posting ⟨actualFacts,𝕩⟩}¨𝕩⊑actualPeriod.accounts.debit_contributors}¨expenseRows,
                  refund_contributors⇐∾{{reference.Posting ⟨actualFacts,𝕩⟩}¨𝕩⊑actualPeriod.accounts.credit_contributors}¨expenseRows,
                  plan_contributors⇐openMask/joined.rows.plan_reference
                }⟩
              }⍟(headroomResult.state≡"ok") @
            }⍟arithmeticOk @
          }¨envelopeIndices
          # Stage 5: derive aggregate backing and reconciliation coordinates.
          {𝕊:
            entitlementValues ← {𝕩.entitlement}¨candidate
            consumptionValues ← {𝕩.actual_consumption}¨candidate
            refundValues ← {𝕩.actual_refunds}¨candidate
            remainingValues ← {𝕩.ledger_remaining}¨candidate
            reserveValues ← {𝕩.open_plan_reserve}¨candidate
            headroomValues ← {𝕩.post_plan_headroom}¨candidate
            SumValues ← {scale.Sum 𝕩}
            totalsResults ← SumValues¨⟨entitlementValues,consumptionValues,refundValues,remainingValues,reserveValues,headroomValues⟩
            fundingRows ← {IndexOf ⟨𝕩,actualBalance.accounts.account_index⟩}¨fundingIndices
            fundingNormalized ← {𝕊 r:Norm ⟨r⊑actualBalance.accounts.closing,actualBalance.scale⟩}¨fundingRows
            fundingResult ← {state⇐"error",coefficient⇐empty}
            {𝕊:fundingResult↩scale.Sum {𝕩.coefficient}¨fundingNormalized}⍟(∧´1∾{𝕩.state≡"ok"}¨fundingNormalized) @
            backingResult ← scale.Sum {0⌈𝕩}¨remainingValues
            surplusResult ← scale.Sum ⟨fundingResult.coefficient,-backingResult.coefficient⟩
            ui ← IndexOf ⟨⊑unassignedIndices,budgetPeriod.accounts.account_index⟩
            unassignedResult ← Norm ⟨ui⊑budgetPeriod.accounts.closing,budgetPeriod.scale⟩
            unassigned ← unassignedResult.coefficient
            reconciliationResult ← {state⇐"error",coefficient⇐empty}
            {𝕊:reconciliationResult↩scale.Sum ⟨surplusResult.coefficient,-unassigned⟩}⍟((surplusResult.state≡"ok") ∧ unassignedResult.state≡"ok") @
            allOk ← (∧´{𝕩.state≡"ok"}¨totalsResults) ∧ ∧´{𝕩.state≡"ok"}¨⟨fundingResult,backingResult,surplusResult,unassignedResult,reconciliationResult⟩
            diagnostics∾↩AddIf ⟨¬allOk,Diagnostic ⟨"coefficient_sum_failed","Statement totals exceed exact range"⟩⟩
            # Stage 6: publish only after every exact operation has succeeded.
            {𝕊:
              vals ← {𝕩.coefficient}¨totalsResults
              envelopeTable ← {
                count⇐≠candidate,index⇐↕≠candidate,
                account_index⇐{𝕩.account_index}¨candidate,
                account_key⇐{𝕩.account_key}¨candidate,category⇐{𝕩.category}¨candidate,
                entitlement⇐entitlementValues,actual_consumption⇐consumptionValues,
                actual_refunds⇐refundValues,ledger_remaining⇐remainingValues,
                open_plan_reserve⇐reserveValues,post_plan_headroom⇐headroomValues,
                entitlement_contributors⇐{𝕩.entitlement_contributors}¨candidate,
                consumption_contributors⇐{𝕩.consumption_contributors}¨candidate,
                refund_contributors⇐{𝕩.refund_contributors}¨candidate,
                plan_contributors⇐{𝕩.plan_contributors}¨candidate
              }
              statementTotals ← {
                entitlement⇐0⊑vals,actual_consumption⇐1⊑vals,actual_refunds⇐2⊑vals,
                ledger_remaining⇐3⊑vals,open_plan_reserve⇐4⊑vals,post_plan_headroom⇐5⊑vals,
                funding_balance⇐fundingResult.coefficient,signed_envelope_total⇐3⊑vals,
                backing_required⇐backingResult.coefficient,backing_surplus⇐surplusResult.coefficient,
                ledger_unassigned⇐unassigned,reconciliation_delta⇐reconciliationResult.coefficient
              }
              fundingContributors ← ∾{𝕩⊑actualBalance.accounts.contributors}¨fundingRows
              unassignedPostingIndices ← (ui⊑budgetPeriod.accounts.opening_contributors)∾ui⊑budgetPeriod.accounts.period_contributors
              unassignedContributors ← {reference.Posting ⟨budgetFacts,𝕩⟩}¨unassignedPostingIndices
              result↩{
                state⇐"ok",reason⇐"",domain⇐domain,
                start_ordinal⇐start,end_exclusive_ordinal⇐finish,observation_ordinal⇐observation,
                scale⇐targetScale,status⇐(surplusResult.coefficient<0)⊑"backed"‿"under_backed",
                envelopes⇐envelopeTable,totals⇐statementTotals,
                funding_account_indices⇐fundingIndices,funding_contributors⇐fundingContributors,
                unassigned_contributors⇐unassignedContributors,diagnostics⇐empty
              }
            }⍟allOk @
          }⍟(0=≠diagnostics) @
        }⍟(0=≠diagnostics) @
      }⍟fundingValid @
    }⍟(¬ownershipUnavailable) @
  }⍟(0=≠diagnostics) @
  {𝕊:result↩EmptyResult ⟨"error","",domain,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
