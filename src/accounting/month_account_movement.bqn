# Pure dense Month × Account signed Actual movement over an explicit month range.

scale ← •Import "../ledger/exact_scale.bqn"
reference ← •Import "fact_reference.bqn"
matrix_result ← •Import "matrix_result.bqn"
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
    selectedMask ← (domainIndex=postings.domain_index) ∧ (actualIndex=postings.layer_index) ∧ {Contains ⟨𝕩,months⟩}¨postingMonths
    selectedIndices ← selectedMask/postings.index
    selectedAccounts ← selectedMask/postings.account_index
    selectedMonths ← selectedMask/postingMonths
    selectedCoefficients ← selectedMask/postings.coefficient
    selectedScales ← selectedMask/postings.scale
    amountScale ← 0
    {𝕊: amountScale↩⌈´selectedScales}⍟(0<≠selectedScales) @
    normalizedResults ← {𝕊 i: scale.Normalize ⟨i⊑selectedCoefficients,i⊑selectedScales,amountScale⟩}¨↕≠selectedCoefficients
    normalizationOk ← ∧´1∾{𝕩.state≡"ok"}¨normalizedResults
    diagnostics ∾↩ AddIf ⟨¬normalizationOk,Diagnostic ⟨"coefficient_normalization_failed","selected Postings cannot normalize exactly"⟩⟩
    {𝕊:
      normalized ← {𝕩.coefficient}¨normalizedResults
      values ← empty ⋄ contributors ← empty
      {𝕊 month:
        valueRow ← empty ⋄ contributorRow ← empty
        {𝕊 accountIndex:
          mask ← (month⊸≡¨selectedMonths) ∧ accountIndex=selectedAccounts
          sum ← scale.Sum mask/normalized
          diagnostics ∾↩ AddIf ⟨sum.state≢"ok",Diagnostic ⟨"coefficient_sum_failed","month Account movement exceeds exact range"⟩⟩
          {𝕊:
            valueRow∾↩sum.coefficient
            contributorRow∾↩⟨{reference.Posting ⟨facts,𝕩⟩}¨mask/selectedIndices⟩
          }⍟(sum.state≡"ok") @
        }¨accountIndices
        values∾↩⟨valueRow⟩ ⋄ contributors∾↩⟨contributorRow⟩
      }¨months
      {𝕊:
        built ← matrix_result.Build ⟨months,accountIndices,amountScale,values,contributors⟩
        diagnostics ∾↩ built.diagnostics
        {𝕊:
          monthTotalsResult ← scale.Sum¨values
          accountTotalsResult ← {𝕊 column: scale.Sum {column⊑𝕩}¨values}¨↕≠accountIndices
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
                  scale⇐amountScale,matrix⇐built.matrix,
                  totals⇐{month⇐monthTotals,account⇐accountTotals,grand⇐grandResult.coefficient,balanced⇐(∧´1∾monthTotals=0) ∧ grandResult.coefficient=0},
                  diagnostics⇐empty
                }
              }⍟reconciled @
            }⍟grandOk @
          }⍟totalsOk @
        }⍟(built.state≡"ok") @
      }⍟(0=≠diagnostics) @
    }⍟normalizationOk @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult ⟨domainCode,firstMonth,lastMonth,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
