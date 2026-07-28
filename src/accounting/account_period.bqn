# Pure selected-domain/layer Account period state from canonical Posting Facts.
# No source parsing, context, Cube/TBDS, report section, formatting, or clock.

scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_account_period",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyTable ← {𝕊:
  {
    count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,
    opening⇐empty,debit_movement⇐empty,credit_movement⇐empty,movement⇐empty,closing⇐empty,
    opening_contributors⇐empty,debit_contributors⇐empty,credit_contributors⇐empty,
    period_contributors⇐empty
  }
}
EmptyTotals ← {𝕊:
  {opening⇐empty,debit_movement⇐empty,credit_movement⇐empty,movement⇐empty,closing⇐empty,balanced⇐0}
}

# Input: facts, domain code, layer name, start ordinal, end-exclusive ordinal.
Build ← {𝕊 factSet‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨factSet.state≢"ok",Diagnostic ⟨"facts_not_ok","canonical facts must be ok"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,factSet.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨layerName,factSet.layers.name⟩,Diagnostic ⟨"layer_unknown","selected layer must occur in Layer facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨startOrdinal≥endOrdinal,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩

  table ← EmptyTable @
  amountScale ← 0
  totals ← EmptyTotals @
  {𝕊:
    domainIndex ← IndexOf ⟨domainCode,factSet.domains.code⟩
    layerIndex ← IndexOf ⟨layerName,factSet.layers.name⟩
    postings ← factSet.postings
    selectedMask ← (domainIndex=postings.domain_index) ∧ layerIndex=postings.layer_index
    selectedFactIndices ← selectedMask/postings.index
    selectedAccountIndices ← selectedMask/postings.account_index
    selectedDates ← selectedMask/postings.date_ordinal
    selectedSides ← selectedMask/postings.side
    selectedCoefficients ← selectedMask/postings.coefficient
    selectedScales ← selectedMask/postings.scale
    {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
    normalizedResults ← {𝕊 i: scale.Normalize ⟨i⊑selectedCoefficients,i⊑selectedScales,amountScale⟩}¨↕≠selectedCoefficients
    normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
    diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected postings cannot normalize exactly to one scale"⟩⟩

    {𝕊:
      normalized ← {𝕩.coefficient}¨normalizedResults
      accountIndices ← (domainCode⊸≡¨factSet.accounts.currency)/factSet.accounts.index
      candidateRows ← empty
      {𝕊 accountIndex:
        accountMask ← accountIndex=selectedAccountIndices
        beforeMask ← accountMask ∧ selectedDates<startOrdinal
        periodMask ← accountMask ∧ (selectedDates≥startOrdinal) ∧ selectedDates<endOrdinal
        debitMask ← periodMask ∧ "debit"⊸≡¨selectedSides
        creditMask ← periodMask ∧ "credit"⊸≡¨selectedSides
        openingResult ← scale.Sum (beforeMask/normalized)
        debitResult ← scale.Sum (debitMask/normalized)
        creditResult ← scale.Sum (creditMask/normalized)
        sumsOk ← (openingResult.state≡"ok") ∧ (debitResult.state≡"ok") ∧ creditResult.state≡"ok"
        diagnostics ∾↩ AddIf ⟨¬sumsOk,Diagnostic ⟨"coefficient_sum_failed","Account period sum exceeds exact range"⟩⟩
        {𝕊:
          movementResult ← scale.Sum ⟨debitResult.coefficient,creditResult.coefficient⟩
          closingResult ← scale.Sum ⟨openingResult.coefficient,movementResult.coefficient⟩
          finalOk ← (movementResult.state≡"ok") ∧ closingResult.state≡"ok"
          diagnostics ∾↩ AddIf ⟨¬finalOk,Diagnostic ⟨"coefficient_sum_failed","Account movement or closing exceeds exact range"⟩⟩
          {𝕊:
            candidateRows∾↩⟨{
              account_index⇐accountIndex,account_key⇐accountIndex⊑factSet.accounts.key,
              opening⇐openingResult.coefficient,debit_movement⇐debitResult.coefficient,
              credit_movement⇐creditResult.coefficient,movement⇐movementResult.coefficient,
              closing⇐closingResult.coefficient,
              opening_contributors⇐beforeMask/selectedFactIndices,
              debit_contributors⇐debitMask/selectedFactIndices,
              credit_contributors⇐creditMask/selectedFactIndices,
              period_contributors⇐periodMask/selectedFactIndices
            }⟩
          }⍟finalOk @
        }⍟sumsOk @
      }¨accountIndices

      {𝕊:
        table↩{
          count⇐≠candidateRows,index⇐↕≠candidateRows,
          account_index⇐{𝕩.account_index}¨candidateRows,account_key⇐{𝕩.account_key}¨candidateRows,
          opening⇐{𝕩.opening}¨candidateRows,debit_movement⇐{𝕩.debit_movement}¨candidateRows,
          credit_movement⇐{𝕩.credit_movement}¨candidateRows,movement⇐{𝕩.movement}¨candidateRows,
          closing⇐{𝕩.closing}¨candidateRows,
          opening_contributors⇐{𝕩.opening_contributors}¨candidateRows,
          debit_contributors⇐{𝕩.debit_contributors}¨candidateRows,
          credit_contributors⇐{𝕩.credit_contributors}¨candidateRows,
          period_contributors⇐{𝕩.period_contributors}¨candidateRows
        }
        openingTotal ← scale.Sum (table.opening)
        debitTotal ← scale.Sum (table.debit_movement)
        creditTotal ← scale.Sum (table.credit_movement)
        movementTotal ← scale.Sum (table.movement)
        closingTotal ← scale.Sum (table.closing)
        totalsOk ← ∧´{𝕩.state≡"ok"}¨⟨openingTotal,debitTotal,creditTotal,movementTotal,closingTotal⟩
        diagnostics ∾↩ AddIf ⟨¬totalsOk,Diagnostic ⟨"coefficient_sum_failed","period totals exceed exact range"⟩⟩
        {𝕊:
          balanced ← (openingTotal.coefficient=0) ∧ (debitTotal.coefficient=-creditTotal.coefficient) ∧ closingTotal.coefficient=0
          totals↩{
            opening⇐openingTotal.coefficient,debit_movement⇐debitTotal.coefficient,
            credit_movement⇐creditTotal.coefficient,movement⇐movementTotal.coefficient,
            closing⇐closingTotal.coefficient,balanced⇐balanced
          }
        }⍟totalsOk @
      }⍟(0=≠diagnostics) @
    }⍟normalizationOk @
  }⍟(0=≠diagnostics) @

  {𝕊: table↩EmptyTable @ ⋄ totals↩EmptyTotals @ ⋄ amountScale↩0}⍟(0<≠diagnostics) @
  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,domain⇐domainCode,layer⇐layerName,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,scale⇐amountScale,accounts⇐table,totals⇐totals,diagnostics⇐diagnostics}
}

{Build⇐Build}
