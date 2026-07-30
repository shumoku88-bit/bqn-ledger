# Pure selected-domain/layer date × dynamic category accounting flow.
# Category identity comes only from admitted Account role/budget/kind metadata.

scale ← •Import "../ledger/exact_scale.bqn"
sparse ← •Import "sparse_group.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_date_category_flow",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyDates ← {𝕊:
  {count⇐0,index⇐empty,date_ordinal⇐empty,date_text⇐empty,income⇐empty,net⇐empty,income_contributors⇐empty}
}
EmptyCategories ← {𝕊:
  {count⇐0,index⇐empty,label⇐empty,kind⇐empty,envelope_account_index⇐empty}
}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

# Input: facts, domain code, layer name, start ordinal, end-exclusive ordinal.
Build ← {𝕊 factSet‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨factSet.state≢"ok",Diagnostic ⟨"facts_not_ok","canonical facts must be ok"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,factSet.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨layerName,factSet.layers.name⟩,Diagnostic ⟨"layer_unknown","selected layer must occur in Layer facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨startOrdinal≥endOrdinal,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩

  dateTable ← EmptyDates @
  categoryTable ← EmptyCategories @
  groupTable ← EmptyGroups @
  amountScale ← 0
  {𝕊:
    domainIndex ← IndexOf ⟨domainCode,factSet.domains.code⟩
    layerIndex ← IndexOf ⟨layerName,factSet.layers.name⟩
    accounts ← factSet.accounts

    envelopeMask ← (domainCode⊸≡¨accounts.currency) ∧ ("envelope"⊸≡¨accounts.kind)
    envelopeIndices ← envelopeMask/accounts.index
    envelopeLabels ← envelopeMask/accounts.budget
    envelopeRoles ← envelopeMask/accounts.role
    diagnostics ∾↩ AddIf ⟨∨´0∾{𝕩≢"budget"}¨envelopeRoles,Diagnostic ⟨"envelope_account_role_invalid","envelope Accounts require explicit budget role"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾{0=≠𝕩}¨envelopeLabels,Diagnostic ⟨"envelope_category_missing","envelope Accounts require explicit budget category metadata"⟩⟩
    # Deduplicate compares category-label major cells and preserves Account-derived order.
    diagnostics ∾↩ AddIf ⟨(≠envelopeLabels)≠≠⍷envelopeLabels,Diagnostic ⟨"envelope_category_duplicate","envelope budget categories must be unique in one domain"⟩⟩
    diagnostics ∾↩ AddIf ⟨Contains ⟨"other",envelopeLabels⟩,Diagnostic ⟨"envelope_category_reserved","other is reserved for unmatched expenses"⟩⟩

    {𝕊:
      categoryLabels ← envelopeLabels∾⟨"other"⟩
      categoryKinds ← ({𝕩 ⋄ "envelope"}¨envelopeLabels)∾⟨"other"⟩
      categoryEnvelopeIndices ← envelopeIndices∾⟨¯1⟩
      categoryTable↩{
        count⇐≠categoryLabels,index⇐↕≠categoryLabels,label⇐categoryLabels,
        kind⇐categoryKinds,envelope_account_index⇐categoryEnvelopeIndices
      }

      accountCategory ← {𝕊 accountIndex:
        result ← ¯1
        role ← accountIndex⊑accounts.role
        {𝕊:
          budget ← accountIndex⊑accounts.budget
          result↩≠envelopeLabels
          {𝕊: result↩IndexOf ⟨budget,envelopeLabels⟩}⍟(Contains ⟨budget,envelopeLabels⟩) @
        }⍟(role≡"expense") @
        result
      }¨accounts.index

      transactions ← factSet.transactions
      transactionMask ← (domainIndex=transactions.domain_index) ∧ (layerIndex=transactions.layer_index) ∧ (transactions.date_ordinal≥startOrdinal) ∧ transactions.date_ordinal<endOrdinal
      transactionDates ← transactionMask/transactions.date_ordinal
      transactionTexts ← transactionMask/transactions.date_text
      order ← ⍋transactionDates
      sortedDates ← order⊏transactionDates
      sortedTexts ← order⊏transactionTexts
      keep ← (sortedDates⊐sortedDates)=↕≠sortedDates
      dateOrdinals ← keep/sortedDates
      dateTexts ← keep/sortedTexts

      postings ← factSet.postings
      postingRoles ← {𝕩⊑accounts.role}¨postings.account_index
      postingCategories ← {𝕩⊑accountCategory}¨postings.account_index
      accountingRole ← ("income"⊸≡¨postingRoles) ∨ "expense"⊸≡¨postingRoles
      postingMask ← (domainIndex=postings.domain_index) ∧ (layerIndex=postings.layer_index) ∧ (postings.date_ordinal≥startOrdinal) ∧ (postings.date_ordinal<endOrdinal) ∧ accountingRole
      selectedFactIndices ← postingMask/postings.index
      selectedDates ← postingMask/postings.date_ordinal
      selectedRoles ← postingMask/postingRoles
      selectedCategories ← postingMask/postingCategories
      selectedCoefficients ← postingMask/postings.coefficient
      selectedScales ← postingMask/postings.scale
      {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
      normalizedResults ← {𝕊 i: scale.Normalize ⟨i⊑selectedCoefficients,i⊑selectedScales,amountScale⟩}¨↕≠selectedCoefficients
      normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
      diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected flow postings cannot normalize exactly to one scale"⟩⟩

      {𝕊:
        normalized ← {𝕩.coefficient}¨normalizedResults
        expenseMask ← "expense"⊸≡¨selectedRoles
        grouped ← sparse.Build ⟨
          dateOrdinals,categoryTable.count,
          expenseMask/selectedDates,expenseMask/selectedCategories,expenseMask/normalized,
          {⟨𝕩⟩}¨(expenseMask/selectedFactIndices)
        ⟩
        diagnostics ∾↩ grouped.diagnostics
        candidateDates ← empty
        {𝕊 dateIndex:
          ordinal ← dateIndex⊑dateOrdinals
          dateMask ← ordinal=selectedDates
          incomeMask ← dateMask ∧ "income"⊸≡¨selectedRoles
          incomeResult ← scale.Sum (-(incomeMask/normalized))
          diagnostics ∾↩ AddIf ⟨incomeResult.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily income exceeds exact range"⟩⟩
          dateGroupMask ← dateIndex=grouped.groups.row_index
          expenseTotal ← scale.Sum (dateGroupMask/grouped.groups.coefficient)
          netResult ← {state⇐"error",coefficient⇐empty}
          {𝕊: netResult↩scale.Sum ⟨incomeResult.coefficient,-expenseTotal.coefficient⟩}⍟((incomeResult.state≡"ok") ∧ expenseTotal.state≡"ok") @
          diagnostics ∾↩ AddIf ⟨netResult.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily net exceeds exact range"⟩⟩
          {𝕊:
            candidateDates∾↩⟨{
              date_ordinal⇐ordinal,date_text⇐dateIndex⊑dateTexts,
              income⇐incomeResult.coefficient,net⇐netResult.coefficient,
              income_contributors⇐incomeMask/selectedFactIndices
            }⟩
          }⍟(netResult.state≡"ok") @
        }¨↕≠dateOrdinals

        {𝕊:
          dateTable↩{
            count⇐≠candidateDates,index⇐↕≠candidateDates,
            date_ordinal⇐{𝕩.date_ordinal}¨candidateDates,date_text⇐{𝕩.date_text}¨candidateDates,
            income⇐{𝕩.income}¨candidateDates,net⇐{𝕩.net}¨candidateDates,
            income_contributors⇐{𝕩.income_contributors}¨candidateDates
          }
          groupTable↩grouped.groups
        }⍟(0=≠diagnostics) @
      }⍟normalizationOk @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {𝕊: dateTable↩EmptyDates @ ⋄ categoryTable↩EmptyCategories @ ⋄ groupTable↩EmptyGroups @ ⋄ amountScale↩0}⍟(0<≠diagnostics) @
  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {state⇐state,domain⇐domainCode,layer⇐layerName,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,scale⇐amountScale,dates⇐dateTable,categories⇐categoryTable,expense_groups⇐groupTable,diagnostics⇐diagnostics}
}

{Build⇐Build}
