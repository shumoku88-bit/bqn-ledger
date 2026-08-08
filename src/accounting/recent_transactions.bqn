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

BuildSelected ← {𝕊 facts‿limit‿eligibleTransactionIndices:
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
        transactions ← facts.transactions
        postings ← facts.postings
        start ← 0⌈(≠eligibleTransactionIndices)-limit
        selected ← ⌽start↓eligibleTransactionIndices
        selectedCount ← ≠selected

        postingCoordinates ← selected⊐postings.transaction_index
        selectedPostingMask ← postingCoordinates<selectedCount
        selectedPostingCoordinates ← selectedPostingMask/postingCoordinates
        selectedPostingIndices ← selectedPostingMask/postings.index
        selectedPostingSides ← selectedPostingMask/postings.side
        selectedPostingScales ← selectedPostingMask/postings.scale
        selectedPostingCoefficients ← selectedPostingMask/postings.coefficient
        selectedPostingAccounts ← selectedPostingMask/postings.account_index

        allCoordinates ← selectedPostingCoordinates∾⟨selectedCount⟩
        postingScaleGroups ← allCoordinates⊔selectedPostingScales

        debitMask ← "debit"⊸≡¨selectedPostingSides
        debitCoordinates ← (debitMask/selectedPostingCoordinates)∾⟨selectedCount⟩
        debitPostingGroups ← debitCoordinates⊔debitMask/selectedPostingIndices
        debitCoefficientGroups ← debitCoordinates⊔debitMask/selectedPostingCoefficients
        debitAccountGroups ← debitCoordinates⊔debitMask/selectedPostingAccounts

        creditMask ← "credit"⊸≡¨selectedPostingSides
        creditCoordinates ← (creditMask/selectedPostingCoordinates)∾⟨selectedCount⟩
        creditPostingGroups ← creditCoordinates⊔creditMask/selectedPostingIndices
        creditAccountGroups ← creditCoordinates⊔creditMask/selectedPostingAccounts

        transactionScales ← selected⊏transactions.calculation_scale
        scalesAligned ← transactionScales {∧´1∾𝕨⊸=¨𝕩}¨ postingScaleGroups
        lanesValid ← (0<≠¨debitPostingGroups) ∧ 0<≠¨creditPostingGroups
        debitTotals ← scale.Sum¨debitCoefficientGroups
        totalsValid ← {𝕩.state≡"ok"}¨debitTotals
        rowValid ← scalesAligned ∧ lanesValid ∧ totalsValid
        diagnostics ∾↩ ∾{𝕊 valid:
          AddIf ⟨¬valid,Diagnostic ⟨"transaction_amount_invalid","selected Transaction requires aligned exact debit and credit evidence"⟩⟩
        }¨rowValid

        {𝕊:
          domainIndices ← selected⊏transactions.domain_index
          rows↩{
            count⇐selectedCount,index⇐↕selectedCount,transaction_index⇐selected,
            date⇐selected⊏transactions.date_text,description⇐selected⊏transactions.description,
            currency⇐domainIndices⊏facts.domains.code,
            coefficient⇐{𝕩.coefficient}¨debitTotals,scale⇐transactionScales,
            credit_accounts⇐{𝕩⊏facts.accounts.key}¨creditAccountGroups,
            debit_accounts⇐{𝕩⊏facts.accounts.key}¨debitAccountGroups,
            transaction_reference⇐{reference.Transaction ⟨facts,𝕩⟩}¨selected,
            debit_contributors⇐{𝕊 indices: {reference.Posting ⟨facts,𝕩⟩}¨indices}¨debitPostingGroups,
            credit_contributors⇐{𝕊 indices: {reference.Posting ⟨facts,𝕩⟩}¨indices}¨creditPostingGroups
          }
        }⍟(0=≠diagnostics) @
      }⍟allActual @
    }⍟actualLayerKnown @
  }⍟(0=≠diagnostics) @
  {𝕊: rows↩EmptyRows @}⍟(0<≠diagnostics) @
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",limit⇐limit,rows⇐rows,diagnostics⇐diagnostics}
}

Build ← {𝕊 facts‿limit:BuildSelected ⟨facts,limit,facts.transactions.index⟩}
BuildThrough ← {𝕊 facts‿throughOrdinal‿limit:
  eligible ← (facts.transactions.date_ordinal≤throughOrdinal)/facts.transactions.index
  BuildSelected ⟨facts,limit,eligible⟩
}

{Build⇐Build,BuildThrough⇐BuildThrough}
