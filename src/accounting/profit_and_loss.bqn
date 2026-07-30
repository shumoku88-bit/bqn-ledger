# Pure Actual income and expense statement over one explicit half-open period.

period ← •Import "account_period.bqn"
reference ← •Import "fact_reference.bqn"
scale ← •Import "../ledger/exact_scale.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_profit_and_loss",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyRows ← {𝕊:
  {count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,amount⇐empty,contributors⇐empty}
}
EmptyResult ← {𝕊 domainCode‿diagnosticsValue:
  {
    state⇐"error",domain⇐domainCode,start_ordinal⇐0,end_exclusive_ordinal⇐0,scale⇐0,
    income⇐EmptyRows @,expenses⇐EmptyRows @,
    total_income⇐empty,total_expenses⇐empty,net_income⇐empty,diagnostics⇐diagnosticsValue
  }
}
Rows ← {𝕊 source‿rowIndices‿amounts‿facts:
  {
    count⇐≠rowIndices,index⇐↕≠rowIndices,
    account_index⇐rowIndices⊏source.account_index,account_key⇐rowIndices⊏source.account_key,
    amount⇐amounts,
    contributors⇐{𝕊 rowIndex:
      {reference.Posting ⟨facts,𝕩⟩}¨rowIndex⊑source.period_contributors
    }¨rowIndices
  }
}

Build ← {𝕊 facts‿domainCode‿startOrdinal‿endOrdinal:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨¬reference.SourceIs ⟨facts,"actual.journal"⟩,Diagnostic ⟨"actual_facts_invalid","Profit and Loss requires admitted Actual facts"⟩⟩
  accountPeriod ← period.Build ⟨facts,domainCode,"actual",startOrdinal,endOrdinal⟩
  diagnostics ∾↩ accountPeriod.diagnostics
  result ← EmptyResult ⟨domainCode,diagnostics⟩
  {𝕊:
    source ← accountPeriod.accounts
    roles ← source.account_index⊏facts.accounts.role
    incomeIndices ← ("income"⊸≡¨roles)/source.index
    expenseIndices ← ("expense"⊸≡¨roles)/source.index
    incomeAmounts ← -(incomeIndices⊏source.movement)
    expenseAmounts ← expenseIndices⊏source.movement
    incomeTotal ← scale.Sum incomeAmounts
    expenseTotal ← scale.Sum expenseAmounts
    diagnostics ∾↩ AddIf ⟨incomeTotal.state≢"ok",Diagnostic ⟨"income_sum_failed","income total exceeds exact range"⟩⟩
    diagnostics ∾↩ AddIf ⟨expenseTotal.state≢"ok",Diagnostic ⟨"expense_sum_failed","expense total exceeds exact range"⟩⟩
    {𝕊:
      net ← scale.Sum ⟨incomeTotal.coefficient,-expenseTotal.coefficient⟩
      diagnostics ∾↩ AddIf ⟨net.state≢"ok",Diagnostic ⟨"net_income_sum_failed","net income exceeds exact range"⟩⟩
      {𝕊:
        result↩{
          state⇐"ok",domain⇐domainCode,start_ordinal⇐startOrdinal,end_exclusive_ordinal⇐endOrdinal,
          scale⇐accountPeriod.scale,
          income⇐Rows ⟨source,incomeIndices,incomeAmounts,facts⟩,
          expenses⇐Rows ⟨source,expenseIndices,expenseAmounts,facts⟩,
          total_income⇐incomeTotal.coefficient,total_expenses⇐expenseTotal.coefficient,
          net_income⇐net.coefficient,diagnostics⇐empty
        }
      }⍟(net.state≡"ok") @
    }⍟((incomeTotal.state≡"ok") ∧ expenseTotal.state≡"ok") @
  }⍟(accountPeriod.state≡"ok") @
  {𝕊: result↩EmptyResult ⟨domainCode,diagnostics⟩}⍟(0<≠diagnostics) @
  result
}

{Build⇐Build}
