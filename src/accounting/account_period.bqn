# Pure selected-domain/layer Account period state from canonical Posting Facts.
# No source parsing, context, Cube/TBDS, report section, formatting, or clock.

scale ← •Import "../ledger/exact_scale.bqn"
sparse_group ← •Import "sparse_group.bqn"
sparse_pivot ← •Import "sparse_pivot.bqn"
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
      beforeMask ← selectedDates<startOrdinal
      periodMask ← (selectedDates≥startOrdinal) ∧ selectedDates<endOrdinal
      debitMask ← periodMask ∧ "debit"⊸≡¨selectedSides
      creditMask ← periodMask ∧ "credit"⊸≡¨selectedSides

      beforeAccounts ← beforeMask/selectedAccountIndices
      debitAccounts ← debitMask/selectedAccountIndices
      creditAccounts ← creditMask/selectedAccountIndices
      periodAccounts ← periodMask/selectedAccountIndices
      evidenceRows ← beforeAccounts∾debitAccounts∾creditAccounts∾periodAccounts
      evidenceColumns ← ((≠beforeAccounts)⥊0)∾((≠debitAccounts)⥊1)∾((≠creditAccounts)⥊2)∾((≠periodAccounts)⥊3)
      evidenceCoefficients ← (beforeMask/normalized)∾(debitMask/normalized)∾(creditMask/normalized)∾((≠periodAccounts)⥊0)
      evidenceFactIndices ← (beforeMask/selectedFactIndices)∾(debitMask/selectedFactIndices)∾(creditMask/selectedFactIndices)∾(periodMask/selectedFactIndices)
      evidenceContributors ← {⟨𝕩⟩}¨evidenceFactIndices

      grouped ← sparse_group.Build ⟨
        accountIndices,4,evidenceRows,evidenceColumns,evidenceCoefficients,evidenceContributors
      ⟩
      diagnostics ∾↩ {𝕊 ignoredDiagnostic: Diagnostic ⟨"coefficient_sum_failed","Account period sum exceeds exact range"⟩}¨grouped.diagnostics
      {𝕊:
        pivoted ← sparse_pivot.Build ⟨accountIndices,↕4,amountScale,grouped.groups⟩
        diagnostics ∾↩ pivoted.diagnostics
        {𝕊:
          values ← pivoted.matrix.values
          contributors ← pivoted.matrix.contributors
          opening ← {0⊑𝕩}¨values
          debitMovement ← {1⊑𝕩}¨values
          creditMovement ← {2⊑𝕩}¨values
          openingContributors ← {0⊑𝕩}¨contributors
          debitContributors ← {1⊑𝕩}¨contributors
          creditContributors ← {2⊑𝕩}¨contributors
          periodContributors ← {3⊑𝕩}¨contributors

          movementResults ← debitMovement {scale.Sum ⟨𝕨,𝕩⟩}¨ creditMovement
          movementOk ← ∧´1∾{𝕩.state≡"ok"}¨movementResults
          diagnostics ∾↩ ∾{𝕊 result:
            AddIf ⟨result.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Account movement or closing exceeds exact range"⟩⟩
          }¨movementResults
          {𝕊:
            movement ← {𝕩.coefficient}¨movementResults
            closingResults ← opening {scale.Sum ⟨𝕨,𝕩⟩}¨ movement
            closingOk ← ∧´1∾{𝕩.state≡"ok"}¨closingResults
            diagnostics ∾↩ ∾{𝕊 result:
              AddIf ⟨result.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","Account movement or closing exceeds exact range"⟩⟩
            }¨closingResults
            {𝕊:
              table↩{
                count⇐≠accountIndices,index⇐↕≠accountIndices,
                account_index⇐accountIndices,account_key⇐accountIndices⊏factSet.accounts.key,
                opening⇐opening,debit_movement⇐debitMovement,
                credit_movement⇐creditMovement,movement⇐movement,
                closing⇐{𝕩.coefficient}¨closingResults,
                opening_contributors⇐openingContributors,debit_contributors⇐debitContributors,
                credit_contributors⇐creditContributors,period_contributors⇐periodContributors
              }
            }⍟closingOk @
          }⍟movementOk @
        }⍟(pivoted.state≡"ok") @
      }⍟(grouped.state≡"ok") @

      {𝕊:
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
