# Pure selected-domain/layer date × Account and dynamic-category accounting flow.
# budget.toml owns Envelope-to-Expense assignment; household.toml owns each
# Envelope's structural Budget Account. Account identity/type stays in Facts.

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
EmptyAccounts ← {𝕊:
  {count⇐0,index⇐empty,account_index⇐empty,key⇐empty,role⇐empty}
}
EmptyGroups ← {𝕊:
  {count⇐0,index⇐empty,row_index⇐empty,column_index⇐empty,coefficient⇐empty,contributors⇐empty}
}

# Input: Facts, admitted Budget policy, admitted Household policy, domain/layer,
# start ordinal, and end-exclusive ordinal.
Build ← {𝕊 factSet‿budgetPolicy‿householdPolicy‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨factSet.state≢"ok",Diagnostic ⟨"facts_not_ok","canonical facts must be ok"⟩⟩
  diagnostics ∾↩ AddIf ⟨(budgetPolicy.state≢"ok") ∨ budgetPolicy.source_name≢"budget.toml",Diagnostic ⟨"budget_policy_invalid","date/category flow requires admitted budget.toml policy"⟩⟩
  diagnostics ∾↩ AddIf ⟨(householdPolicy.state≢"ok") ∨ householdPolicy.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","date/category flow requires admitted household.toml policy"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,factSet.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨layerName,factSet.layers.name⟩,Diagnostic ⟨"layer_unknown","selected layer must occur in Layer facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨startOrdinal≥endOrdinal,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩
  diagnostics ∾↩ AddIf ⟨householdPolicy.account_policy.account_key≢factSet.accounts.key,Diagnostic ⟨"account_axis_mismatch","Household policy and Facts must share one Account axis"⟩⟩

  dateTable ← EmptyDates @
  categoryTable ← EmptyCategories @
  accountTable ← EmptyAccounts @
  groupTable ← EmptyGroups @
  accountGroupTable ← EmptyGroups @
  amountScale ← 0
  {𝕊:
    domainIndex ← IndexOf ⟨domainCode,factSet.domains.code⟩
    layerIndex ← IndexOf ⟨layerName,factSet.layers.name⟩
    accounts ← factSet.accounts
    accountIndices ← (domainCode⊸≡¨accounts.currency)/accounts.index
    accountTable↩{
      count⇐≠accountIndices,index⇐↕≠accountIndices,account_index⇐accountIndices,
      key⇐accountIndices⊏accounts.key,role⇐accountIndices⊏accounts.role
    }

    envelopeLabels ← budgetPolicy.envelopes.id
    diagnostics ∾↩ AddIf ⟨(≠envelopeLabels)≠≠⍷envelopeLabels,Diagnostic ⟨"envelope_category_duplicate","budget.toml Envelope ids must be unique"⟩⟩
    diagnostics ∾↩ AddIf ⟨Contains ⟨"other",envelopeLabels⟩,Diagnostic ⟨"envelope_category_reserved","other is reserved for unmatched expenses"⟩⟩
    householdRows ← {IndexOf ⟨𝕩,householdPolicy.budget.envelope_id⟩}¨envelopeLabels
    householdKnown ← ∧´1∾householdRows<≠householdPolicy.budget.envelope_id
    diagnostics ∾↩ AddIf ⟨¬householdKnown,Diagnostic ⟨"household_envelope_coordinates_missing","Every budget.toml Envelope requires household.toml allocation coordinates"⟩⟩
    envelopeIndices ← empty
    {𝕊:envelopeIndices↩householdRows⊏householdPolicy.budget.allocation_account_index}⍟householdKnown @
    {𝕊:
      envelopeRoles ← envelopeIndices⊏accounts.role
      envelopeCurrencies ← envelopeIndices⊏accounts.currency
      diagnostics ∾↩ AddIf ⟨∨´0∾{𝕩≢"budget"}¨envelopeRoles,Diagnostic ⟨"envelope_account_role_invalid","Household Envelope allocation Accounts require Budget type"⟩⟩
      diagnostics ∾↩ AddIf ⟨∨´0∾{𝕩≢domainCode}¨envelopeCurrencies,Diagnostic ⟨"envelope_account_domain_invalid","Household Envelope allocation Accounts must belong to the selected domain"⟩⟩
    }⍟householdKnown @

    expenseIndices ← budgetPolicy.expense_account_index
    expenseEnvelopeIds ← budgetPolicy.expense_envelope_id
    diagnostics ∾↩ AddIf ⟨(≠expenseIndices)≠≠⍷expenseIndices,Diagnostic ⟨"expense_account_assignment_duplicate","one Expense Account may belong to only one Envelope"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾{¬Contains ⟨𝕩,envelopeLabels⟩}¨expenseEnvelopeIds,Diagnostic ⟨"expense_envelope_unknown","Expense assignment must reference a declared Envelope"⟩⟩

    {𝕊:
      categoryLabels ← envelopeLabels∾⟨"other"⟩
      categoryKinds ← ({𝕩 ⋄ "envelope"}¨envelopeLabels)∾⟨"other"⟩
      categoryEnvelopeIndices ← envelopeIndices∾⟨¯1⟩
      categoryTable↩{
        count⇐≠categoryLabels,index⇐↕≠categoryLabels,label⇐categoryLabels,
        kind⇐categoryKinds,envelope_account_index⇐categoryEnvelopeIndices
      }

      accountCategory ← {𝕊 accountIndex:
        category ← ¯1
        {𝕊:
          matches ← (accountIndex=expenseIndices)/↕≠expenseIndices
          {𝕊:category↩≠envelopeLabels}⍟(0=≠matches) @
          {𝕊:category↩IndexOf ⟨(⊑matches)⊑expenseEnvelopeIds,envelopeLabels⟩}⍟(1=≠matches) @
        }⍟((accountIndex⊑accounts.role)≡"expense") @
        category
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
      postingRoles ← postings.account_index⊏accounts.role
      postingCategories ← postings.account_index⊏accountCategory
      postingMask ← (domainIndex=postings.domain_index) ∧ (layerIndex=postings.layer_index) ∧ (postings.date_ordinal≥startOrdinal) ∧ postings.date_ordinal<endOrdinal
      selectedFactIndices ← postingMask/postings.index
      selectedDates ← postingMask/postings.date_ordinal
      selectedAccounts ← postingMask/postings.account_index
      selectedRoles ← postingMask/postingRoles
      selectedCategories ← postingMask/postingCategories
      selectedCoefficients ← postingMask/postings.coefficient
      selectedScales ← postingMask/postings.scale
      {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
      normalizedResults ← selectedCoefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨ selectedScales
      normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
      diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected flow postings cannot normalize exactly to one scale"⟩⟩

      {𝕊:
        normalized ← {𝕩.coefficient}¨normalizedResults
        incomeMask ← "income"⊸≡¨selectedRoles
        expenseMask ← "expense"⊸≡¨selectedRoles

        incomeDateIndices ← {IndexOf ⟨𝕩,dateOrdinals⟩}¨(incomeMask/selectedDates)
        incomeGroupIndices ← incomeDateIndices∾⟨≠dateOrdinals⟩
        incomeCoefficientGroups ← incomeGroupIndices⊔-(incomeMask/normalized)
        incomeContributorGroups ← incomeGroupIndices⊔{⟨𝕩⟩}¨(incomeMask/selectedFactIndices)
        incomeResults ← scale.Sum¨incomeCoefficientGroups
        incomeContributorRows ← ∾¨incomeContributorGroups

        expenseGrouped ← sparse.Build ⟨
          dateOrdinals,categoryTable.count,
          expenseMask/selectedDates,expenseMask/selectedCategories,expenseMask/normalized,
          {⟨𝕩⟩}¨(expenseMask/selectedFactIndices)
        ⟩
        accountGrouped ← sparse.Build ⟨
          dateOrdinals,accountTable.count,selectedDates,
          accountIndices⊐selectedAccounts,normalized,{⟨𝕩⟩}¨selectedFactIndices
        ⟩
        diagnostics ∾↩ expenseGrouped.diagnostics∾accountGrouped.diagnostics

        expenseGroupIndices ← expenseGrouped.groups.row_index∾⟨≠dateOrdinals⟩
        expenseCoefficientGroups ← expenseGroupIndices⊔expenseGrouped.groups.coefficient
        expenseTotalResults ← scale.Sum¨expenseCoefficientGroups
        netResults ← incomeResults {
          incomeResult ← 𝕨
          expenseResult ← 𝕩
          result ← {state⇐"error",coefficient⇐empty}
          {𝕊:
            result↩scale.Sum ⟨incomeResult.coefficient,-expenseResult.coefficient⟩
          }⍟((incomeResult.state≡"ok") ∧ expenseResult.state≡"ok") @
          result
        }¨ expenseTotalResults
        diagnostics ∾↩ ∾(incomeResults {
          AddIf ⟨𝕨.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily income exceeds exact range"⟩⟩
          ∾ AddIf ⟨𝕩.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily net exceeds exact range"⟩⟩
        }¨ netResults)

        {𝕊:
          dateTable↩{
            count⇐≠dateOrdinals,index⇐↕≠dateOrdinals,
            date_ordinal⇐dateOrdinals,date_text⇐dateTexts,
            income⇐{𝕩.coefficient}¨incomeResults,net⇐{𝕩.coefficient}¨netResults,
            income_contributors⇐incomeContributorRows
          }
          groupTable↩expenseGrouped.groups
          accountGroupTable↩accountGrouped.groups
        }⍟(0=≠diagnostics) @
      }⍟normalizationOk @
    }⍟(0=≠diagnostics) @
  }⍟(0=≠diagnostics) @

  {𝕊:
    dateTable↩EmptyDates @ ⋄ categoryTable↩EmptyCategories @ ⋄ accountTable↩EmptyAccounts @
    groupTable↩EmptyGroups @ ⋄ accountGroupTable↩EmptyGroups @ ⋄ amountScale↩0
  }⍟(0<≠diagnostics) @
  state ← (0=≠diagnostics)⊑"error"‿"ok"
  {
    state⇐state,domain⇐domainCode,layer⇐layerName,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,
    scale⇐amountScale,dates⇐dateTable,categories⇐categoryTable,expense_groups⇐groupTable,
    accounts⇐accountTable,account_groups⇐accountGroupTable,diagnostics⇐diagnostics
  }
}

{Build⇐Build}
