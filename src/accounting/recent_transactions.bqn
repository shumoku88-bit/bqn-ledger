# Pure newest-first bounded Actual Transaction List from canonical Facts.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "fact_reference.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_recent_transactions",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {
    count⇐0,index⇐empty,transaction_index⇐empty,date⇐empty,description⇐empty,currency⇐empty,
    coefficient⇐empty,scale⇐empty,credit_accounts⇐empty,debit_accounts⇐empty,
    transaction_reference⇐empty,debit_contributors⇐empty,credit_contributors⇐empty
  }
}

Build ← {𝕊 facts‿limit:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  limitInvalid ← (limit≤0) ∨ limit≠⌊limit
  diagnostics ∾↩ AddIf ⟨limitInvalid,Diagnostic ⟨"limit_invalid","Recent Transaction limit must be a positive integer"⟩⟩
  rows ← EmptyRows @
  {𝕊:
    actualLayerKnown ← Contains ⟨"actual",facts.layers.name⟩
    diagnostics ∾↩ AddIf ⟨¬actualLayerKnown,Diagnostic ⟨"actual_layer_unknown","Actual layer must occur in Layer facts"⟩⟩
    {𝕊:
      actualLayerIndex ← IndexOf ⟨"actual",facts.layers.name⟩
      allActual ← ∧´1∾actualLayerIndex⊸=¨facts.transactions.layer_index
      diagnostics ∾↩ AddIf ⟨¬allActual,Diagnostic ⟨"transaction_layer_invalid","Actual source Transactions must all use Actual layer"⟩⟩
      {𝕊:
        start ← 0⌈facts.transactions.count-limit
        selected ← ⌽start↓facts.transactions.index
        candidateRows ← empty
        {𝕊 transactionIndex:
          postingMask ← transactionIndex=facts.postings.transaction_index
          postingIndices ← postingMask/facts.postings.index
          debitMask ← postingMask ∧ "debit"⊸≡¨facts.postings.side
          creditMask ← postingMask ∧ "credit"⊸≡¨facts.postings.side
          debitIndices ← debitMask/facts.postings.index
          creditIndices ← creditMask/facts.postings.index
          transactionScale ← transactionIndex⊑facts.transactions.calculation_scale
          scalesAligned ← ∧´1∾transactionScale⊸=¨postingIndices⊏facts.postings.scale
          lanesValid ← (0<≠debitIndices) ∧ 0<≠creditIndices
          debitTotal ← scale.Sum (debitMask/facts.postings.coefficient)
          rowValid ← scalesAligned ∧ lanesValid ∧ debitTotal.state≡"ok"
          diagnostics ∾↩ AddIf ⟨¬rowValid,Diagnostic ⟨"transaction_amount_invalid","selected Transaction requires aligned exact debit and credit evidence"⟩⟩
          {𝕊:
            debitAccountIndices ← debitIndices⊏facts.postings.account_index
            creditAccountIndices ← creditIndices⊏facts.postings.account_index
            domainIndex ← transactionIndex⊑facts.transactions.domain_index
            candidateRows∾↩⟨{
              transaction_index⇐transactionIndex,date⇐transactionIndex⊑facts.transactions.date_text,
              description⇐transactionIndex⊑facts.transactions.description,
              currency⇐domainIndex⊑facts.domains.code,
              coefficient⇐debitTotal.coefficient,scale⇐transactionScale,
              debit_accounts⇐{𝕩⊑facts.accounts.key}¨debitAccountIndices,
              credit_accounts⇐{𝕩⊑facts.accounts.key}¨creditAccountIndices,
              transaction_reference⇐reference.Transaction ⟨facts,transactionIndex⟩,
              debit_contributors⇐{reference.Posting ⟨facts,𝕩⟩}¨debitIndices,
              credit_contributors⇐{reference.Posting ⟨facts,𝕩⟩}¨creditIndices
            }⟩
          }⍟rowValid @
        }¨selected
        {𝕊:
          rows↩{
            count⇐≠candidateRows,index⇐↕≠candidateRows,
            transaction_index⇐{𝕩.transaction_index}¨candidateRows,date⇐{𝕩.date}¨candidateRows,
            description⇐{𝕩.description}¨candidateRows,currency⇐{𝕩.currency}¨candidateRows,
            coefficient⇐{𝕩.coefficient}¨candidateRows,scale⇐{𝕩.scale}¨candidateRows,
            credit_accounts⇐{𝕩.credit_accounts}¨candidateRows,debit_accounts⇐{𝕩.debit_accounts}¨candidateRows,
            transaction_reference⇐{𝕩.transaction_reference}¨candidateRows,
            debit_contributors⇐{𝕩.debit_contributors}¨candidateRows,
            credit_contributors⇐{𝕩.credit_contributors}¨candidateRows
          }
        }⍟(0=≠diagnostics) @
      }⍟allActual @
    }⍟actualLayerKnown @
  }⍟(0=≠diagnostics) @
  {𝕊: rows↩EmptyRows @}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",limit⇐limit,rows⇐rows,diagnostics⇐diagnostics}
}

{Build⇐Build}
