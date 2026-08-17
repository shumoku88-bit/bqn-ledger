# Pure selected-domain/layer date × Account and historically routed category flow.
# Stable Envelope category identity comes directly from household.toml history.
# Expense-to-Envelope meaning is resolved from explicit routing history at each
# Posting day. Current envelope.toml policy is intentionally not an input.

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
  {count⇐0,index⇐empty,label⇐empty,kind⇐empty}
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

Admit ← {𝕊 factSet‿history‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨factSet.state≢"ok",Diagnostic ⟨"facts_not_ok","canonical facts must be ok"⟩⟩
  diagnostics ∾↩ AddIf ⟨history.state≢"ok",Diagnostic ⟨"envelope_history_invalid","date/category flow requires admitted Envelope history"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,factSet.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨layerName,factSet.layers.name⟩,Diagnostic ⟨"layer_unknown","selected layer must occur in Layer facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨startOrdinal≥endOrdinal,Diagnostic ⟨"period_range_invalid","period start must precede end_exclusive"⟩⟩

  domainIndex ← 0 ⋄ layerIndex ← 0
  accountIndices ← empty ⋄ envelopeLabels ← empty
  routing ← history.expense_routing
  {𝕊:
    accounts ← factSet.accounts
    domainIndex↩IndexOf ⟨domainCode,factSet.domains.code⟩
    layerIndex↩IndexOf ⟨layerName,factSet.layers.name⟩
    accountIndices↩(domainCode⊸≡¨accounts.currency)/accounts.index

    envelopeLabels ↩ history.registry.id
    diagnostics ∾↩ AddIf ⟨Contains ⟨"other",envelopeLabels⟩, Diagnostic ⟨"envelope_category_reserved","other is reserved for unmatched expenses"⟩⟩

    routeCoordinates ← accounts.key⊐routing.expense_account_key
    routeKnown ← routeCoordinates<accounts.count
    routeRoles ← routeCoordinates⊏accounts.role∾⟨""⟩
    diagnostics ∾↩ AddIf ⟨¬∧´1∾routeKnown,Diagnostic ⟨"expense_route_account_unknown","historical Expense routing Account must occur on the current Facts Account axis"⟩⟩
    diagnostics ∾↩ AddIf ⟨∨´0∾routeKnown ∧ ¬"expense"⊸≡¨routeRoles,Diagnostic ⟨"expense_route_account_role_invalid","historical Expense routing Account must remain an Expense Account"⟩⟩
    managedTargets ← ("managed"⊸≡¨routing.route)/routing.target_id
    diagnostics ∾↩ AddIf ⟨∨´0∾{¬Contains ⟨𝕩,envelopeLabels⟩}¨managedTargets,Diagnostic ⟨"expense_route_target_unknown","managed historical route must resolve to a stable Household Envelope identity"⟩⟩
  }⍟(0=≠diagnostics) @

  {
    state⇐(0=≠diagnostics)⊑"error"‿"ok",diagnostics⇐diagnostics,
    domain_index⇐domainIndex,layer_index⇐layerIndex,account_indices⇐accountIndices,
    envelope_labels⇐envelopeLabels,routing⇐routing
  }
}

Kernel ← {𝕊 factSet‿admitted‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  accounts ← factSet.accounts
  envelopeLabels ← admitted.envelope_labels
  categoryLabels ← envelopeLabels∾⟨"other"⟩
  categoryTable ← {
    count⇐≠categoryLabels,index⇐↕≠categoryLabels,label⇐categoryLabels,
    kind⇐({𝕩 ⋄ "envelope"}¨envelopeLabels)∾⟨"other"⟩
  }
  accountTable ← {
    count⇐≠admitted.account_indices,index⇐↕≠admitted.account_indices,
    account_index⇐admitted.account_indices,key⇐admitted.account_indices⊏accounts.key,
    role⇐admitted.account_indices⊏accounts.role
  }

  transactions ← factSet.transactions
  transactionMask ← (admitted.domain_index=transactions.domain_index) ∧ (admitted.layer_index=transactions.layer_index) ∧ (transactions.date_ordinal≥startOrdinal) ∧ transactions.date_ordinal<endOrdinal
  transactionDates ← transactionMask/transactions.date_ordinal
  transactionTexts ← transactionMask/transactions.date_text
  dateOrdinals ← ⍷(⍋transactionDates)⊏transactionDates
  dateTexts ← (transactionDates⊐dateOrdinals)⊏transactionTexts

  postings ← factSet.postings
  postingRoles ← postings.account_index⊏accounts.role
  postingMask ← (admitted.domain_index=postings.domain_index) ∧ (admitted.layer_index=postings.layer_index) ∧ (postings.date_ordinal≥startOrdinal) ∧ postings.date_ordinal<endOrdinal
  selectedFactIndices ← postingMask/postings.index
  selectedDates ← postingMask/postings.date_ordinal
  selectedAccounts ← postingMask/postings.account_index
  selectedRoles ← postingMask/postingRoles
  selectedKeys ← selectedAccounts⊏accounts.key
  selectedCoefficients ← postingMask/postings.coefficient
  selectedScales ← postingMask/postings.scale

  routing ← admitted.routing
  RouteCategory ← {𝕊 i:
    role ← i⊑selectedRoles
    category ← ¯1
    {𝕊:
      key ← i⊑selectedKeys ⋄ day ← i⊑selectedDates
      eligibleMask ← (key⊸≡¨routing.expense_account_key) ∧ (routing.initial ∨ routing.effective_ordinal≤day)
      eligibleRows ← eligibleMask/routing.index
      {𝕊:
        ordinals ← eligibleRows⊏routing.effective_ordinal
        latest ← ⌈´ordinals
        latestRows ← (ordinals=latest)/eligibleRows
        {𝕊:
          row ← ⊑latestRows
          managed ← (row⊑routing.route)≡"managed"
          target ← row⊑routing.target_id
          {𝕊:category↩IndexOf ⟨target,envelopeLabels⟩}⍟managed @
          {𝕊:category↩≠envelopeLabels}⍟(¬managed) @
        }⍟(1=≠latestRows) @
        {𝕊:category↩≠envelopeLabels}⍟(1≠≠latestRows) @
      }⍟(0<≠eligibleRows) @
      {𝕊:category↩≠envelopeLabels}⍟(0=≠eligibleRows) @
    }⍟(role≡"expense") @
    category
  }
  selectedCategories ← RouteCategory¨↕≠selectedAccounts

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

Build ← {𝕊 factSet‿history‿domainCode‿layerName‿startOrdinal‿endOrdinal:
  admitted ← Admit ⟨factSet,history,domainCode,layerName,startOrdinal,endOrdinal⟩
  result ← FailureResult ⟨domainCode,layerName,startOrdinal,endOrdinal,admitted.diagnostics⟩
  {𝕊:result↩Kernel ⟨factSet,admitted,domainCode,layerName,startOrdinal,endOrdinal⟩}⍟(admitted.state≡"ok") @
  result
}

{Build⇐Build}