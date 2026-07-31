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
    amountScale↩⌈´0∾selectedScales
    normalizedResults ← selectedCoefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨ selectedScales
    normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
    diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected postings cannot normalize exactly to one scale"⟩⟩

    {𝕊:
      normalized ← {𝕩.coefficient}¨normalizedResults
      accountIndices ← (domainCode⊸≡¨factSet.accounts.currency)/factSet.accounts.index
      accountCount ← ≠accountIndices
      beforeMask ← selectedDates<startOrdinal
      periodMask ← (selectedDates≥startOrdinal) ∧ selectedDates<endOrdinal
      debitMask ← periodMask ∧ "debit"⊸≡¨selectedSides
      creditMask ← periodMask ∧ "credit"⊸≡¨selectedSides
      laneMasks ← ⟨beforeMask,debitMask,creditMask,periodMask⟩
      laneCount ← ≠laneMasks
      laneCoefficients ← ⟨normalized,normalized,normalized,0×normalized⟩

      # p: selected Posting cells in source order; a: domain Accounts in canonical order.
      # k: opening / debit / credit / all-period contributor lanes.
      # p→a×k Group preserves source order; the trailing cell bound retains every empty lane.
      evidenceAccounts ← ∾{𝕩/selectedAccountIndices}¨laneMasks
      evidenceLanes ← ∾(↕laneCount) {(+´𝕩)⥊𝕨}¨ laneMasks
      evidenceCoefficients ← ∾laneMasks {𝕨/𝕩}¨ laneCoefficients
      evidenceFactIndices ← ∾{𝕩/selectedFactIndices}¨laneMasks
      accountCoordinates ← accountIndices⊐evidenceAccounts
      evidenceKnown ← ∧´1∾accountCoordinates<accountCount
      diagnostics ∾↩ AddIf ⟨¬evidenceKnown,Diagnostic ⟨"coefficient_sum_failed","Account period sum exceeds exact range"⟩⟩

      {𝕊:
        cellCount ← accountCount×laneCount
        cellCoordinates ← (laneCount×accountCoordinates)+evidenceLanes
        groupCoordinates ← cellCoordinates∾cellCount
        coefficientGroups ← groupCoordinates⊔evidenceCoefficients
        postingGroups ← groupCoordinates⊔evidenceFactIndices
        sumResults ← scale.Sum¨coefficientGroups
        sumOk ← {𝕩.state≡"ok"}¨sumResults
        diagnostics ∾↩ ∾{𝕊 ok:
          AddIf ⟨¬ok,Diagnostic ⟨"coefficient_sum_failed","Account period sum exceeds exact range"⟩⟩
        }¨sumOk

        {𝕊:
          amountCells ← (accountCount‿laneCount)⥊{𝕩.coefficient}¨sumResults
          contributorCells ← (accountCount‿laneCount)⥊postingGroups
          amountLanes ← ⍉amountCells
          contributorLanes ← ⍉contributorCells
          opening ← 0⊏amountLanes
          debitMovement ← 1⊏amountLanes
          creditMovement ← 2⊏amountLanes
          openingContributors ← 0⊏contributorLanes
          debitContributors ← 1⊏contributorLanes
          creditContributors ← 2⊏contributorLanes
          periodContributors ← 3⊏contributorLanes

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
                count⇐accountCount,index⇐↕accountCount,
                account_index⇐accountIndices,account_key⇐accountIndices⊏factSet.accounts.key,
                opening⇐opening,debit_movement⇐debitMovement,
                credit_movement⇐creditMovement,movement⇐movement,
                closing⇐{𝕩.coefficient}¨closingResults,
                opening_contributors⇐openingContributors,debit_contributors⇐debitContributors,
                credit_contributors⇐creditContributors,period_contributors⇐periodContributors
              }
            }⍟closingOk @
          }⍟movementOk @
        }⍟(∧´1∾sumOk) @
      }⍟evidenceKnown @

      {𝕊:
        openingTotal ← scale.Sum table.opening
        debitTotal ← scale.Sum table.debit_movement
        creditTotal ← scale.Sum table.credit_movement
        movementTotal ← scale.Sum table.movement
        closingTotal ← scale.Sum table.closing
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
