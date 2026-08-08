# Pure durable Plan-to-Actual completion Join over explicitly selected Transactions.
# No row parsing, five-field identity fallback, period policy, I/O, formatting, or cross-source summation.

scale ← •Import "../ledger/exact_scale.bqn"
fact_reference ← •Import "fact_reference.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_plan_completion_join",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,status⇐empty,plan_transaction_index⇐empty,plan_id⇐empty,
    plan_reference⇐empty,plan_date⇐empty,currency⇐empty,
    planned_coefficient⇐empty,planned_scale⇐empty,
    planned_from_account⇐empty,planned_to_account⇐empty,
    planned_debit_contributors⇐empty,planned_credit_contributors⇐empty,
    actual_transaction_indices⇐empty,actual_references⇐empty,actual_dates⇐empty,
    actual_currencies⇐empty,actual_coefficients⇐empty,actual_scales⇐empty,
    actual_debit_accounts⇐empty,actual_credit_accounts⇐empty,
    actual_debit_contributors⇐empty,actual_credit_contributors⇐empty,
    currency_matches⇐empty,direction_matches⇐empty
  }
}
EmptyCounts ← {𝕊: {open⇐0,completed⇐0,duplicate⇐0,ambiguous⇐0}}

TransactionEvidence ← {𝕊 facts‿transactionIndex‿requireSingleDirection:
  postingMask ← transactionIndex=facts.postings.transaction_index
  postingIndices ← postingMask/facts.postings.index
  debitMask ← postingMask ∧ "debit"⊸≡¨facts.postings.side
  creditMask ← postingMask ∧ "credit"⊸≡¨facts.postings.side
  debitIndices ← debitMask/facts.postings.index
  creditIndices ← creditMask/facts.postings.index
  txScale ← transactionIndex⊑facts.transactions.calculation_scale
  scalesAligned ← ∧´1∾txScale⊸=¨postingIndices⊏facts.postings.scale
  directionOk ← (0<≠debitIndices) ∧ 0<≠creditIndices
  {𝕊: directionOk ∧↩ (1=≠debitIndices) ∧ 1=≠creditIndices}⍟requireSingleDirection @
  amount ← scale.Sum (debitMask/facts.postings.coefficient)
  ok ← directionOk ∧ scalesAligned ∧ amount.state≡"ok"
  accountKeys ← facts.accounts.key
  debitAccounts ← {𝕩⊑accountKeys}¨debitIndices⊏facts.postings.account_index
  creditAccounts ← {𝕩⊑accountKeys}¨creditIndices⊏facts.postings.account_index
  {
    state⇐ok⊑"error"‿"ok",transaction_index⇐transactionIndex,
    reference⇐fact_reference.Transaction ⟨facts,transactionIndex⟩,
    date⇐transactionIndex⊑facts.transactions.date_text,
    currency⇐(transactionIndex⊑facts.transactions.domain_index)⊑facts.domains.code,
    coefficient⇐ok⊑⟨empty,amount.coefficient⟩,scale⇐ok⊑⟨empty,txScale⟩,
    debit_accounts⇐ok⊑⟨empty,debitAccounts⟩,credit_accounts⇐ok⊑⟨empty,creditAccounts⟩,
    debit_contributors⇐ok⊑⟨empty,{fact_reference.Posting ⟨facts,𝕩⟩}¨debitIndices⟩,
    credit_contributors⇐ok⊑⟨empty,{fact_reference.Posting ⟨facts,𝕩⟩}¨creditIndices⟩
  }
}
Signature ← {𝕊 evidence:
  ⟨evidence.date,evidence.currency,evidence.coefficient,evidence.scale,evidence.debit_accounts,evidence.credit_accounts⟩
}

# Input selection vectors are canonical snapshot-local Transaction indices.
# Selection/period policy stays outside this Join.
Build ← {𝕊 planFacts‿actualFacts‿planTransactionIndices‿actualTransactionIndices:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬fact_reference.SourceIs ⟨planFacts,"plan.journal"⟩,Diagnostic ⟨"plan_facts_invalid","Plan facts must be admitted from plan.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬fact_reference.SourceIs ⟨actualFacts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠planTransactionIndices)≠≠⍷planTransactionIndices,Diagnostic ⟨"plan_selection_duplicate","Plan selection indices must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨(≠actualTransactionIndices)≠≠⍷actualTransactionIndices,Diagnostic ⟨"actual_selection_duplicate","Actual selection indices must be unique"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬∧´1∾{Contains ⟨𝕩,planFacts.transactions.index⟩}¨planTransactionIndices,Diagnostic ⟨"plan_selection_invalid","Plan selection must contain canonical Transaction indices"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬∧´1∾{Contains ⟨𝕩,actualFacts.transactions.index⟩}¨actualTransactionIndices,Diagnostic ⟨"actual_selection_invalid","Actual selection must contain canonical Transaction indices"⟩⟩

  rows ← EmptyRows @
  counts ← EmptyCounts @
  unmatchedActualReferences ← empty
  {𝕊:
    planIds ← planTransactionIndices⊏planFacts.transactions.plan_id
    diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨planIds,Diagnostic ⟨"plan_identity_missing","selected Plan Transactions require durable plan_id"⟩⟩
    diagnostics ∾↩ AddIf ⟨(≠planIds)≠≠⍷planIds,Diagnostic ⟨"plan_identity_duplicate","selected Plan plan_id values must be unique"⟩⟩

    selectedActualPlanIds ← actualTransactionIndices⊏actualFacts.transactions.plan_id
    linkedActualMask ← {0<≠𝕩}¨selectedActualPlanIds
    linkedActualIndices ← linkedActualMask/actualTransactionIndices
    linkedActualPlanIds ← linkedActualMask/selectedActualPlanIds
    unmatchedMask ← {¬Contains ⟨𝕩,planIds⟩}¨linkedActualPlanIds
    unmatchedActualReferences ↩ {fact_reference.Transaction ⟨actualFacts,𝕩⟩}¨unmatchedMask/linkedActualIndices

    candidateRows ← empty
    {𝕊 pi:
      planId ← pi⊑planFacts.transactions.plan_id
      planEvidence ← TransactionEvidence ⟨planFacts,pi,1⟩
      diagnostics ∾↩ AddIf ⟨planEvidence.state≢"ok",Diagnostic ⟨"plan_transaction_invalid","selected Plan transaction must have one exact debit and credit direction"⟩⟩
      matchingMask ← planId⊸≡¨linkedActualPlanIds
      matchingIndices ← matchingMask/linkedActualIndices
      actualEvidence ← {TransactionEvidence ⟨actualFacts,𝕩,0⟩}¨matchingIndices
      actualsOk ← ∧´1∾{𝕩.state≡"ok"}¨actualEvidence
      diagnostics ∾↩ AddIf ⟨¬actualsOk,Diagnostic ⟨"actual_completion_invalid","matching Actual completion must have exact debit and credit evidence"⟩⟩
      {𝕊:
        status ← "open"
        {𝕊: status↩"completed"}⍟(1=≠actualEvidence) @
        {𝕊:
          signatures ← Signature¨actualEvidence
          allSame ← ∧´1∾{𝕩≡⊑signatures}¨signatures
          status↩allSame⊑"ambiguous"‿"duplicate"
        }⍟(1<≠actualEvidence) @
        candidateRows∾↩⟨{
          status⇐status,plan_transaction_index⇐pi,plan_id⇐planId,
          plan_reference⇐planEvidence.reference,plan_date⇐planEvidence.date,currency⇐planEvidence.currency,
          planned_coefficient⇐planEvidence.coefficient,planned_scale⇐planEvidence.scale,
          planned_from_account⇐⊑planEvidence.credit_accounts,planned_to_account⇐⊑planEvidence.debit_accounts,
          planned_debit_contributors⇐planEvidence.debit_contributors,
          planned_credit_contributors⇐planEvidence.credit_contributors,
          actual_transaction_indices⇐matchingIndices,
          actual_references⇐{𝕩.reference}¨actualEvidence,actual_dates⇐{𝕩.date}¨actualEvidence,
          actual_currencies⇐{𝕩.currency}¨actualEvidence,
          actual_coefficients⇐{𝕩.coefficient}¨actualEvidence,actual_scales⇐{𝕩.scale}¨actualEvidence,
          actual_debit_accounts⇐{𝕩.debit_accounts}¨actualEvidence,
          actual_credit_accounts⇐{𝕩.credit_accounts}¨actualEvidence,
          actual_debit_contributors⇐{𝕩.debit_contributors}¨actualEvidence,
          actual_credit_contributors⇐{𝕩.credit_contributors}¨actualEvidence,
          currency_matches⇐{𝕩.currency≡planEvidence.currency}¨actualEvidence,
          direction_matches⇐{(𝕩.debit_accounts≡planEvidence.debit_accounts) ∧ 𝕩.credit_accounts≡planEvidence.credit_accounts}¨actualEvidence
        }⟩
      }⍟((planEvidence.state≡"ok") ∧ actualsOk) @
    }¨planTransactionIndices

    {𝕊:
      rows↩{
        count⇐≠candidateRows,index⇐↕≠candidateRows,status⇐{𝕩.status}¨candidateRows,
        plan_transaction_index⇐{𝕩.plan_transaction_index}¨candidateRows,plan_id⇐{𝕩.plan_id}¨candidateRows,
        plan_reference⇐{𝕩.plan_reference}¨candidateRows,plan_date⇐{𝕩.plan_date}¨candidateRows,
        currency⇐{𝕩.currency}¨candidateRows,planned_coefficient⇐{𝕩.planned_coefficient}¨candidateRows,
        planned_scale⇐{𝕩.planned_scale}¨candidateRows,
        planned_from_account⇐{𝕩.planned_from_account}¨candidateRows,planned_to_account⇐{𝕩.planned_to_account}¨candidateRows,
        planned_debit_contributors⇐{𝕩.planned_debit_contributors}¨candidateRows,
        planned_credit_contributors⇐{𝕩.planned_credit_contributors}¨candidateRows,
        actual_transaction_indices⇐{𝕩.actual_transaction_indices}¨candidateRows,
        actual_references⇐{𝕩.actual_references}¨candidateRows,actual_dates⇐{𝕩.actual_dates}¨candidateRows,
        actual_currencies⇐{𝕩.actual_currencies}¨candidateRows,
        actual_coefficients⇐{𝕩.actual_coefficients}¨candidateRows,actual_scales⇐{𝕩.actual_scales}¨candidateRows,
        actual_debit_accounts⇐{𝕩.actual_debit_accounts}¨candidateRows,
        actual_credit_accounts⇐{𝕩.actual_credit_accounts}¨candidateRows,
        actual_debit_contributors⇐{𝕩.actual_debit_contributors}¨candidateRows,
        actual_credit_contributors⇐{𝕩.actual_credit_contributors}¨candidateRows,
        currency_matches⇐{𝕩.currency_matches}¨candidateRows,direction_matches⇐{𝕩.direction_matches}¨candidateRows
      }
      statuses ← rows.status
      counts↩{
        open⇐+´"open"⊸≡¨statuses,completed⇐+´"completed"⊸≡¨statuses,
        duplicate⇐+´"duplicate"⊸≡¨statuses,ambiguous⇐+´"ambiguous"⊸≡¨statuses
      }
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {𝕊: rows↩EmptyRows @ ⋄ counts↩EmptyCounts @ ⋄ unmatchedActualReferences↩empty}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",rows⇐rows,counts⇐counts,unmatched_actual_references⇐unmatchedActualReferences,diagnostics⇐diagnostics}
}

{Build⇐Build}
