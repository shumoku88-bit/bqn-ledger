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
FailureResult ← {𝕊 domainCode‿layerName‿startOrdinal‿endOrdinal‿diagnosticsValue:
  {
    state⇐"error",domain⇐domainCode,layer⇐layerName,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,
    scale⇐0,dates⇐EmptyDates @,categories⇐EmptyCategories @,expense_groups⇐EmptyGroups @,
    accounts⇐EmptyAccounts @,account_groups⇐EmptyGroups @,diagnostics⇐diagnosticsValue
  }
}

# Shallow capability admission: request coordinates and cross-source relations only.
Admit ← {𝕊 factSet‿budgetPolicy‿householdPolicy‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨factSet.state≢"ok",Diagnostic ⟨"facts_not_ok","canonical facts must be ok"⟩⟩
  diagnostics ∾↩ AddIf ⟨(budgetPolicy.state≢"ok") ∨ budgetPolicy.source_name≢"budget.toml",Diagnostic ⟨"budget_policy_invalid","date/category flow requires admitted budget.toml policy"⟩⟩
  diagnostics ∾↩ AddIf ⟨(householdPolicy.state≢"ok") ∨ householdPolicy.source_name≢"household.toml",Diagnostic ⟨"household_policy_invalid","date/category flow requires admitted household.toml policy"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,factSet.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨layerName,factSet.layers.name⟩,Diagnostic ⟨"layer_unknown","selected layer must occur in Layer facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨startOrdinal≥endOrdinal,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩
  diagnostics ∾↩ AddIf ⟨householdPolicy.account_policy.account_key≢factSet.accounts.key,Diagnostic ⟨"account_axis_mismatch","Household policy and Facts must share one Account axis"⟩⟩

  domainIndex ← 0 ⋄ layerIndex ← 0
  accountIndices ← empty ⋄ envelopeLabels ← empty ⋄ envelopeIndices ← empty
  expenseIndices ← empty ⋄ expenseEnvelopeIds ← empty
  {𝕊:
    accounts ← factSet.accounts
    domainIndex↩IndexOf ⟨domainCode,factSet.domains.code⟩
    layerIndex↩IndexOf ⟨layerName,factSet.layers.name⟩
    accountIndices↩(domainCode⊸≡¨accounts.currency)/accounts.index

    envelopeLabels↩budgetPolicy.envelopes.id
    diagnostics ∾↩ AddIf ⟨(≠envelopeLabels)≠≠⍷envelopeLabels,Diagnostic ⟨"envelope_category_duplicate","budget.toml Envelope ids must be unique"⟩⟩
    diagnostics ∾↩ AddIf ⟨Contains ⟨"other",envelopeLabels⟩,Diagnostic ⟨"envelope_category_reserved","other is reserved for unmatched expenses"⟩⟩

    householdRows ← householdPolicy.budget.envelope_id⊐envelopeLabels
    householdKnown ← ∧´1∾householdRows<≠householdPolicy.budget.envelope_id
    diagnostics ∾↩ AddIf ⟨¬householdKnown,Diagnostic ⟨"household_envelope_coordinates_missing","Every budget.toml Envelope requires household.toml allocation coordinates"⟩⟩
    envelopeIndices↩householdRows⊏householdPolicy.budget.allocation_account_index∾⟨¯1⟩
    envelopeRoles ← envelopeIndices⊏accounts.role∾⟨""⟩
    envelopeCurrencies ← envelopeIndices⊏accounts.currency∾⟨""⟩
    diagnostics ∾↩ AddIf ⟨householdKnown ∧ ∨´0∾{𝕩≢"budget"}¨envelopeRoles,Diagnostic ⟨"envelope_account_role_invalid","Household Envelope allocation Accounts require Budget type"⟩⟩
    diagnostics ∾↩ AddIf ⟨householdKnown ∧ ∨´0∾{𝕩≢domainCode}¨envelopeCurrencies,Diagnostic ⟨"envelope_account_domain_invalid","Household Envelope allocation Accounts must belong to the selected domain"⟩⟩

    expenseKeys ← ∾budgetPolicy.envelopes.expense_account_keys
    expenseEnvelopeIds↩∾{𝕊 i:(≠i⊑budgetPolicy.envelopes.expense_account_keys)⥊⟨i⊑envelopeLabels⟩}¨↕≠envelopeLabels
    expenseIndices↩accounts.key⊐expenseKeys
    expenseKnown ← expenseIndices<accounts.count
    expenseRoles ← expenseIndices⊏accounts.role∾⟨""⟩
    diagnostics ∾↩ AddIf ⟨¬∧´1∾expenseKnown,Diagnostic ⟨"budget_policy_expense_account_unknown","budget.toml Expense Accounts must occur on the current Facts Account axis"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾expenseKnown ∧ ¬"expense"⊸≡¨expenseRoles,Diagnostic ⟨"budget_policy_expense_account_role_invalid","budget.toml Expense Accounts must remain Expense Accounts on the current Facts axis"⟩⟩
  }⍟(0=≠diagnostics) @

  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",diagnostics⇐diagnostics,
    domain_index⇐domainIndex,layer_index⇐layerIndex,account_indices⇐accountIndices,
    envelope_labels⇐envelopeLabels,envelope_indices⇐envelopeIndices,
    expense_indices⇐expenseIndices,expense_envelope_ids⇐expenseEnvelopeIds
  }
}

# Bounded successful-path array kernel. Exact normalization and checked reductions
# remain local because those operations can fail only after query selection.
Kernel ← {𝕊 factSet‿admitted‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  accounts ← factSet.accounts
  envelopeLabels ← admitted.envelope_labels
  categoryLabels ← envelopeLabels∾⟨"other"⟩
  categoryTable ← {
    count⇐≠categoryLabels,index⇐↕≠categoryLabels,label⇐categoryLabels,
    kind⇐({𝕩 ⋄ "envelope"}¨envelopeLabels)∾⟨"other"⟩,
    envelope_account_index⇐admitted.envelope_indices∾⟨¯1⟩
  }
  accountTable ← {
    count⇐≠admitted.account_indices,index⇐↕≠admitted.account_indices,
    account_index⇐admitted.account_indices,key⇐admitted.account_indices⊏accounts.key,
    role⇐admitted.account_indices⊏accounts.role
  }

  expenseCoordinates ← envelopeLabels⊐admitted.expense_envelope_ids
  assignmentRows ← admitted.expense_indices⊐accounts.index
  assigned ← assignmentRows<≠admitted.expense_indices
  assignedCategories ← assignmentRows⊏expenseCoordinates∾⟨≠envelopeLabels⟩
  accountExpenseMask ← "expense"⊸≡¨accounts.role
  baseCategories ← ((≠envelopeLabels)×accountExpenseMask)-¬accountExpenseMask
  accountCategory ← (assigned×assignedCategories)+(¬assigned)×baseCategories

  transactions ← factSet.transactions
  transactionMask ← (admitted.domain_index=transactions.domain_index) ∧ (admitted.layer_index=transactions.layer_index) ∧ (transactions.date_ordinal≥startOrdinal) ∧ transactions.date_ordinal<endOrdinal
  transactionDates ← transactionMask/transactions.date_ordinal
  transactionTexts ← transactionMask/transactions.date_text
  dateOrdinals ← ⍷(⍋transactionDates)⊏transactionDates
  dateTexts ← (transactionDates⊐dateOrdinals)⊏transactionTexts

  postings ← factSet.postings
  postingRoles ← postings.account_index⊏accounts.role
  postingCategories ← postings.account_index⊏accountCategory
  postingMask ← (admitted.domain_index=postings.domain_index) ∧ (admitted.layer_index=postings.layer_index) ∧ (postings.date_ordinal≥startOrdinal) ∧ postings.date_ordinal<endOrdinal
  selectedFactIndices ← postingMask/postings.index
  selectedDates ← postingMask/postings.date_ordinal
  selectedAccounts ← postingMask/postings.account_index
  selectedRoles ← postingMask/postingRoles
  selectedCategories ← postingMask/postingCategories
  selectedCoefficients ← postingMask/postings.coefficient
  selectedScales ← postingMask/postings.scale
  amountScale ← ⌈´0∾selectedScales
  normalizedResults ← selectedCoefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨selectedScales
  normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
  diagnostics ← AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected flow postings cannot normalize exactly to one scale"⟩⟩
  result ← FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,diagnostics⟩

  {𝕊:
    normalized ← {𝕩.coefficient}¨normalizedResults
    incomeMask ← "income"⊸≡¨selectedRoles
    expenseMask ← "expense"⊸≡¨selectedRoles

    incomeDateIndices ← dateOrdinals⊐incomeMask/selectedDates
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
      admitted.account_indices⊐selectedAccounts,normalized,{⟨𝕩⟩}¨selectedFactIndices
    ⟩
    diagnostics ∾↩ expenseGrouped.diagnostics∾accountGrouped.diagnostics

    expenseGroupIndices ← expenseGrouped.groups.row_index∾⟨≠dateOrdinals⟩
    expenseCoefficientGroups ← expenseGroupIndices⊔expenseGrouped.groups.coefficient
    expenseTotalResults ← scale.Sum¨expenseCoefficientGroups
    netResults ← incomeResults {
      incomeResult ← 𝕨 ⋄ expenseResult ← 𝕩
      value ← {state⇐"error",coefficient⇐empty}
      {𝕊:value↩scale.Sum ⟨incomeResult.coefficient,-expenseResult.coefficient⟩}⍟((incomeResult.state≡"ok") ∧ expenseResult.state≡"ok") @
      value
    }¨expenseTotalResults
    diagnostics ∾↩ ∾(incomeResults {
      AddIf ⟨𝕨.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily income exceeds exact range"⟩⟩
      ∾ AddIf ⟨𝕩.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","daily net exceeds exact range"⟩⟩
    }¨netResults)

    result↩FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,diagnostics⟩
    {𝕊:result↩{
      state⇐"ok",domain⇐domainCode,layer⇐layerName,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,
      scale⇐amountScale,
      dates⇐{
        count⇐≠dateOrdinals,index⇐↕≠dateOrdinals,date_ordinal⇐dateOrdinals,date_text⇐dateTexts,
        income⇐{𝕩.coefficient}¨incomeResults,net⇐{𝕩.coefficient}¨netResults,
        income_contributors⇐incomeContributorRows
      },
      categories⇐categoryTable,expense_groups⇐expenseGrouped.groups,
      accounts⇐accountTable,account_groups⇐accountGrouped.groups,diagnostics⇐empty
    }}⍟(0=≠diagnostics) @
  }⍟normalizationOk @
  result
}

# Input: Facts, admitted Budget policy, admitted Household policy, domain/layer,
# start ordinal, and end-exclusive ordinal.
Build ← {𝕊 factSet‿budgetPolicy‿householdPolicy‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  admitted ← Admit ⟨factSet,budgetPolicy,householdPolicy,domainCode,layerName,startOrdinal,endOrdinal⟩
  result ← FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,admitted.diagnostics⟩
  {𝕊:result↩Kernel ⟨factSet,admitted,domainCode,layerName,startOrdinal,endOrdinal⟩}⍟(admitted.state≡"ok") @
  result
}

{Build⇐Build}
