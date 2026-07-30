# Profit and Loss semantic result and human renderer.

amount ← •Import "../ledger/amount_text.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

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
StatementTable ← {𝕊 rows‿totalLabel‿totalValue‿scaleValue:
  body ← {𝕊 rowIndex:
    ⟨rowIndex⊑rows.account_key,AmountText ⟨rowIndex⊑rows.amount,scaleValue⟩⟩
  }¨rows.index
  body ∾↩ ⟨⟨totalLabel,AmountText ⟨totalValue,scaleValue⟩⟩⟩
  text.RenderTable ⟨⟨"Account","Amount"⟩,body,⟨1⟩⟩
}
FormatHuman ← {𝕊 result:
  out ← "== Profit and Loss =="∾(@+10)
  out ∾↩ "Period: "∾result.period_start∾".."∾result.period_end_exclusive∾" ("∾result.domain∾")"∾(@+10)∾(@+10)
  out ∾↩ "Income"∾(@+10)
  out ∾↩ StatementTable ⟨result.income,"Total income",result.total_income,result.scale⟩
  out ∾↩ (@+10)∾"Expenses"∾(@+10)
  out ∾↩ StatementTable ⟨result.expenses,"Total expenses",result.total_expenses,result.scale⟩
  out ∾↩ (@+10)∾"Net income: "∾(AmountText ⟨result.net_income,result.scale⟩)∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
