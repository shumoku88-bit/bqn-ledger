# Pure durable Plan-to-Actual completion Join over explicitly selected Transactions.
# No row parsing, five-field identity fallback, period policy, I/O, formatting, or cross-source summation.

scale ← •Import "../ledger/exact_scale.bqn"
fact_reference ← •Import "../ledger/fact_reference.bqn"
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
CompletionStatus ← {𝕊 evidence:
  signatures ← Signature¨evidence
  duplicateLike ← (1=≠⍷signatures)⊑"ambiguous"‿"duplicate"
  (2⌊≠evidence)⊑⟨"open","completed",duplicateLike⟩
}

# p: selected Plan Transactions in caller-owned order.
# a: selected Actual Transactions with nonempty plan_id, also in caller-owned order.
# p⊐a.plan_id gives one Plan coordinate per linked Actual; unmatched is the p-axis bound.
# Group turns the matched coordinates into one ragged Actual-index cell per p while preserving a order.
RelationKernel ← {𝕊 planFacts‿actualFacts‿planTransactionIndices‿actualTransactionIndices‿planIds:
  selectedActualPlanIds ← actualTransactionIndices⊏actualFacts.transactions.plan_id
  linkedActualMask ← {0<≠𝕩}¨selectedActualPlanIds
  linkedActualIndices ← linkedActualMask/actualTransactionIndices
  linkedActualPlanIds ← linkedActualMask/selectedActualPlanIds

  planCount ← ≠planIds
  planCoordinates ← planIds⊐linkedActualPlanIds
  matched ← planCoordinates<planCount
  actualIndexCells ← ((matched/planCoordinates)∾planCount)⊔matched/linkedActualIndices
  unmatchedActualReferences ← {fact_reference.Transaction ⟨actualFacts,𝕩⟩}¨(¬matched)/linkedActualIndices

  planEvidence ← {TransactionEvidence ⟨planFacts,𝕩,1⟩}¨planTransactionIndices
  actualEvidenceCells ← {𝕊 indices:
    {TransactionEvidence ⟨actualFacts,𝕩,0⟩}¨indices
  }¨actualIndexCells
  planOk ← {𝕩.state≡"ok"}¨planEvidence
  actualOk ← {∧´1∾{𝕩.state≡"ok"}¨𝕩}¨actualEvidenceCells
  rowDiagnostics ← planOk {𝕊:
    planDiagnostics ← AddIf ⟨¬𝕨,Diagnostic ⟨"plan_transaction_invalid","selected Plan transaction must have one exact debit and credit direction"⟩⟩
    actualDiagnostics ← AddIf ⟨¬𝕩,Diagnostic ⟨"actual_completion_invalid","matching Actual completion must have exact debit and credit evidence"⟩⟩
    planDiagnostics∾actualDiagnostics
  }¨ actualOk
  diagnostics ← ∾⟨empty⟩∾rowDiagnostics

  rows ← EmptyRows @
  counts ← EmptyCounts @
  {𝕊:
    statuses ← CompletionStatus¨actualEvidenceCells
    currencyMatches ← planEvidence {𝕊:
      expected ← 𝕨.currency
      {𝕩.currency≡expected}¨𝕩
    }¨ actualEvidenceCells
    directionMatches ← planEvidence {𝕊:
      expectedDebit ← 𝕨.debit_accounts
      expectedCredit ← 𝕨.credit_accounts
      {(𝕩.debit_accounts≡expectedDebit) ∧ 𝕩.credit_accounts≡expectedCredit}¨𝕩
    }¨ actualEvidenceCells

    rows↩{
      count⇐planCount,index⇐↕planCount,status⇐statuses,
      plan_transaction_index⇐planTransactionIndices,plan_id⇐planIds,
      plan_reference⇐{𝕩.reference}¨planEvidence,plan_date⇐{𝕩.date}¨planEvidence,
      currency⇐{𝕩.currency}¨planEvidence,planned_coefficient⇐{𝕩.coefficient}¨planEvidence,
      planned_scale⇐{𝕩.scale}¨planEvidence,
      planned_from_account⇐{⊑𝕩.credit_accounts}¨planEvidence,
      planned_to_account⇐{⊑𝕩.debit_accounts}¨planEvidence,
      planned_debit_contributors⇐{𝕩.debit_contributors}¨planEvidence,
      planned_credit_contributors⇐{𝕩.credit_contributors}¨planEvidence,
      actual_transaction_indices⇐actualIndexCells,
      actual_references⇐{𝕊 cell: {𝕩.reference}¨cell}¨actualEvidenceCells,
      actual_dates⇐{𝕊 cell: {𝕩.date}¨cell}¨actualEvidenceCells,
      actual_currencies⇐{𝕊 cell: {𝕩.currency}¨cell}¨actualEvidenceCells,
      actual_coefficients⇐{𝕊 cell: {𝕩.coefficient}¨cell}¨actualEvidenceCells,
      actual_scales⇐{𝕊 cell: {𝕩.scale}¨cell}¨actualEvidenceCells,
      actual_debit_accounts⇐{𝕊 cell: {𝕩.debit_accounts}¨cell}¨actualEvidenceCells,
      actual_credit_accounts⇐{𝕊 cell: {𝕩.credit_accounts}¨cell}¨actualEvidenceCells,
      actual_debit_contributors⇐{𝕊 cell: {𝕩.debit_contributors}¨cell}¨actualEvidenceCells,
      actual_credit_contributors⇐{𝕊 cell: {𝕩.credit_contributors}¨cell}¨actualEvidenceCells,
      currency_matches⇐currencyMatches,direction_matches⇐directionMatches
    }
    counts↩{
      open⇐+´"open"⊸≡¨statuses,completed⇐+´"completed"⊸≡¨statuses,
      duplicate⇐+´"duplicate"⊸≡¨statuses,ambiguous⇐+´"ambiguous"⊸≡¨statuses
    }
  }⍟(0=≠diagnostics) @

  {rows⇐rows,counts⇐counts,unmatched_actual_references⇐(0=≠diagnostics)⊑⟨empty,unmatchedActualReferences⟩,diagnostics⇐diagnostics}
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
    {𝕊:
      result ← RelationKernel ⟨planFacts,actualFacts,planTransactionIndices,actualTransactionIndices,planIds⟩
      diagnostics ∾↩ result.diagnostics
      {𝕊:
        rows↩result.rows
        counts↩result.counts
        unmatchedActualReferences↩result.unmatched_actual_references
      }⍟(0=≠result.diagnostics) @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {𝕊: rows↩EmptyRows @ ⋄ counts↩EmptyCounts @ ⋄ unmatchedActualReferences↩empty}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",rows⇐rows,counts⇐counts,unmatched_actual_references⇐unmatchedActualReferences,diagnostics⇐diagnostics}
}

{Build⇐Build}
