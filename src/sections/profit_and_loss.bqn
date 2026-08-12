# Profit and Loss semantic result and human renderer.

amount ← •Import "../ledger/amount_text.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
lf ← @+10

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_profit_and_loss",code⇐codeText,message⇐messageText}
}
EmptyRows ← {𝕊: {count⇐0,index⇐empty,account_key⇐empty,amount⇐empty,contributors⇐empty}}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",period_start⇐"",period_end_exclusive⇐"",scale⇐0,
    income⇐EmptyRows @,expenses⇐EmptyRows @,
    total_income⇐empty,total_expenses⇐empty,net_income⇐empty,diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 accounting‿periodStartText‿periodEndText:
  diagnostics ← accounting.diagnostics
  {𝕊:diagnostics∾↩⟨Diagnostic ⟨"profit_and_loss_not_ok","Profit and Loss accounting evidence must be ok"⟩⟩}⍟((accounting.state≢"ok") ∧ 0=≠diagnostics) @
  startValid ← dates.IsValid periodStartText ⋄ endValid ← dates.IsValid periodEndText
  diagnostics ∾↩ (¬startValid)/⟨Diagnostic ⟨"period_start_invalid","period start must be strict Gregorian text"⟩⟩
  diagnostics ∾↩ (¬endValid)/⟨Diagnostic ⟨"period_end_invalid","period end must be strict Gregorian text"⟩⟩
  {𝕊:
    diagnostics ∾↩ ((dates.Ordinal periodStartText)≠accounting.start_ordinal)/⟨Diagnostic ⟨"period_start_mismatch","period start must match accounting evidence"⟩⟩
    diagnostics ∾↩ ((dates.Ordinal periodEndText)≠accounting.end_exclusive_ordinal)/⟨Diagnostic ⟨"period_end_mismatch","period end must match accounting evidence"⟩⟩
  }⍟(startValid ∧ endValid ∧ accounting.state≡"ok") @
  result ← EmptyResult diagnostics
  {𝕊:
    result↩{
      state⇐"ok",domain⇐accounting.domain,period_start⇐periodStartText,
      period_end_exclusive⇐periodEndText,scale⇐accounting.scale,
      income⇐accounting.income,expenses⇐accounting.expenses,
      total_income⇐accounting.total_income,total_expenses⇐accounting.total_expenses,
      net_income⇐accounting.net_income,diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
StatementTable ← {𝕊 rows‿totalLabel‿totalValue‿scaleValue‿style:
  body ← ({𝕊 rowIndex:
    ⟨rowIndex⊑rows.account_key,text.FormatAmount ⟨rowIndex⊑rows.amount,scaleValue,style⟩⟩
  }¨rows.index)∾⟨⟨totalLabel,text.FormatAmount ⟨totalValue,scaleValue,style⟩⟩⟩
  text.RenderTable ⟨⟨"Account","Amount"⟩,body,⟨1⟩⟩
}
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  headingText ← ∾{𝕩∾lf}¨⟨"== Profit and Loss ==",("Period: "∾result.period_start∾".."∾result.period_end_exclusive∾" ("∾result.domain∾")"),""⟩
  incomeBlock ← "Income"∾lf∾StatementTable ⟨result.income,"Total income",result.total_income,result.scale,style⟩
  expensesBlock ← lf∾"Expenses"∾lf∾StatementTable ⟨result.expenses,"Total expenses",result.total_expenses,result.scale,style⟩
  summaryText ← ∾{𝕩∾lf}¨⟨"",("Net income: "∾text.FormatAmount ⟨result.net_income,result.scale,style⟩),""⟩
  ∾⟨headingText,incomeBlock,expensesBlock,summaryText⟩
}

{Build⇐Build,FormatHuman⇐FormatHuman}
