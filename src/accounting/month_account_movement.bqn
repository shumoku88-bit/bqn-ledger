# Pure dense Month × Account signed Actual movement over an explicit month range.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "fact_reference.bqn"
matrix_result ← •Import "matrix_result.bqn"
sparse_group ← •Import "sparse_group.bqn"
sparse_pivot ← •Import "sparse_pivot.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_month_account_movement",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
IsMonth ← {𝕊 value: (7=≠value) ∧ dates.IsValid value∾"-01"}
MonthNumber ← {𝕊 value: y‿m‿d ← dates.Parts value∾"-01" ⋄ (12×y)+m-1}
MonthLabel ← {𝕊 number:
  y ← ⌊number÷12 ⋄ m ← 1+12|number ⋄ mt←•Fmt m
  (•Fmt y)∾"-"∾((m<10)/"0")∾mt
}
EmptyMatrix ← {𝕊: (matrix_result.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyTotals ← {𝕊: {month⇐empty,account⇐empty,grand⇐empty,balanced⇐0}}
EmptyResult ← {𝕊 domainCode‿firstMonth‿lastMonth‿diagnosticsValue:
  {
    state⇐"error",domain⇐domainCode,first_month⇐firstMonth,last_month_exclusive⇐lastMonth,
    months⇐empty,account_indices⇐empty,account_keys⇐empty,scale⇐0,matrix⇐EmptyMatrix @,
    totals⇐EmptyTotals @,diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 facts‿domainCode‿firstMonth‿lastMonth:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Actual facts must be admitted from actual.journal"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨domainCode,facts.domains.code⟩,Diagnostic ⟨"domain_unknown","selected domain must occur in Domain facts"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬Contains ⟨"actual",facts.layers.name⟩,Diagnostic ⟨"actual_layer_unknown","Actual layer must occur in Layer facts"⟩⟩
  firstValid ← IsMonth firstMonth ⋄ lastValid ← IsMonth lastMonth
  diagnostics ∾↩ AddIf ⟨¬firstValid,Diagnostic ⟨"first_month_invalid","first month must be strict YYYY-MM"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬lastValid,Diagnostic ⟨"last_month_invalid","last exclusive month must be strict YYYY-MM"⟩⟩
  firstNumber ← 0 ⋄ lastNumber ← 0
  {𝕊:
    firstNumber↩MonthNumber firstMonth ⋄ lastNumber↩MonthNumber lastMonth
    diagnostics ∾↩ AddIf ⟨firstNumber≥lastNumber,Diagnostic ⟨"month_range_invalid","first month must precede last exclusive month"⟩⟩
  }⍟(firstValid∧lastValid) @

  result ← EmptyResult ⟨domainCode,firstMonth,lastMonth,diagnostics⟩
  {𝕊:
    months ← MonthLabel¨(firstNumber+↕(lastNumber-firstNumber))
    domainIndex ← IndexOf ⟨domainCode,facts.domains.code⟩
    actualIndex ← IndexOf ⟨"actual",facts.layers.name⟩
    accountIndices ← (domainCode⊸≡¨facts.accounts.currency)/facts.accounts.index
    postings ← facts.postings
    postingMonths ← {7↑𝕩⊑facts.transactions.date_text}¨postings.transaction_index
    postingMonthIndices ← months⊐postingMonths
    selectedMask ← (domainIndex=postings.domain_index) ∧ (actualIndex=postings.layer_index) ∧ (postingMonthIndices<≠months)
    selectedIndices ← selectedMask/postings.index
    selectedAccounts ← selectedMask/postings.account_index
    selectedMonths ← selectedMask/postingMonths
    selectedCoefficients ← selectedMask/postings.coefficient
    selectedScales ← selectedMask/postings.scale
    amountScale ← 0
    {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
    normalizedResults ← selectedCoefficients {scale.Normalize ⟨𝕨,𝕩,amountScale⟩}¨ selectedScales
    normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
    diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected Postings cannot normalize exactly"⟩⟩
    {𝕊:
      normalized ← {𝕩.coefficient}¨normalizedResults
      selectedAccountColumns ← accountIndices⊐selectedAccounts
      selectedContributors ← {⟨reference.Posting ⟨facts,𝕩⟩⟩}¨selectedIndices
      grouped ← sparse_group.Build ⟨
        months,≠accountIndices,selectedMonths,selectedAccountColumns,normalized,selectedContributors
      ⟩
      diagnostics ∾↩ AddIf ⟨grouped.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","month Account movement exceeds exact range"⟩⟩
      {𝕊:
        pivoted ← sparse_pivot.Build ⟨months,accountIndices,amountScale,grouped.groups⟩
        diagnostics ∾↩ pivoted.diagnostics
        {𝕊:
          values ← pivoted.matrix.values
          valueArray ← >values
          monthTotalsResult ← {scale.Sum 𝕩}˘valueArray
          accountTotalsResult ← {scale.Sum 𝕩}˘⍉valueArray
          totalsOk ← (∧´1∾{𝕩.state≡"ok"}¨monthTotalsResult) ∧ ∧´1∾{𝕩.state≡"ok"}¨accountTotalsResult
          diagnostics ∾↩ AddIf ⟨¬totalsOk,Diagnostic ⟨"coefficient_sum_failed","Matrix reconciliation exceeds exact range"⟩⟩
          {𝕊:
            monthTotals ← {𝕩.coefficient}¨monthTotalsResult
            accountTotals ← {𝕩.coefficient}¨accountTotalsResult
            grandResult ← scale.Sum monthTotals
            accountGrandResult ← scale.Sum accountTotals
            grandOk ← (grandResult.state≡"ok") ∧ accountGrandResult.state≡"ok"
            diagnostics ∾↩ AddIf ⟨¬grandOk,Diagnostic ⟨"coefficient_sum_failed","Matrix grand total exceeds exact range"⟩⟩
            {𝕊:
              reconciled ← grandResult.coefficient=accountGrandResult.coefficient
              diagnostics ∾↩ AddIf ⟨¬reconciled,Diagnostic ⟨"matrix_reconciliation_failed","month and Account totals must reconcile"⟩⟩
              {𝕊:
                result↩{
                  state⇐"ok",domain⇐domainCode,first_month⇐firstMonth,last_month_exclusive⇐lastMonth,
                  months⇐months,account_indices⇐accountIndices,account_keys⇐accountIndices⊏facts.accounts.key,
                  scale⇐amountScale,matrix⇐pivoted.matrix,
                  totals⇐{month⇐monthTotals,account⇐accountTotals,grand⇐grandResult.coefficient,balanced⇐(∧´1∾monthTotals=0) ∧ grandResult.coefficient=0},
                  diagnostics⇐empty
                }
              }⍟reconciled @
            }⍟grandOk @
          }⍟totalsOk @
        }⍟(pivoted.state≡"ok") @
      }⍟(grouped.state≡"ok") @
    }⍟normalizationOk @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult ⟨domainCode,firstMonth,lastMonth,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
