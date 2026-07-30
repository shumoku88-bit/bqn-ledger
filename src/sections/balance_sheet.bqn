# Balance Sheet semantic result and human renderer.

amount ← •Import "../ledger/amount_text.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_balance_sheet",code⇐codeText,message⇐messageText}
}
EmptyRows ← {𝕊: {count⇐0,index⇐empty,account_key⇐empty,balance⇐empty,contributors⇐empty}}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",as_of⇐"",scale⇐0,
    assets⇐EmptyRows @,liabilities⇐EmptyRows @,equity⇐EmptyRows @,
    total_assets⇐empty,total_liabilities⇐empty,stated_equity⇐empty,
    unclosed_result⇐empty,total_equity⇐empty,total_liabilities_and_equity⇐empty,
    difference⇐empty,balanced⇐0,unclosed_result_contributors⇐empty,
    diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 accounting‿asOfText:
  diagnostics ← accounting.diagnostics
  {𝕊:diagnostics∾↩⟨Diagnostic ⟨"balance_sheet_not_ok","Balance Sheet accounting evidence must be ok"⟩⟩}⍟((accounting.state≢"ok") ∧ 0=≠diagnostics) @
  asOfValid ← dates.IsValid asOfText
  diagnostics ∾↩ (¬asOfValid)/⟨Diagnostic ⟨"observation_invalid","as-of must be strict Gregorian text"⟩⟩
  {𝕊:
    diagnostics ∾↩ ((dates.Ordinal asOfText)≠accounting.observation_ordinal)/⟨Diagnostic ⟨"observation_mismatch","as-of must match accounting evidence"⟩⟩
  }⍟(asOfValid ∧ accounting.state≡"ok") @
  result ← EmptyResult diagnostics
  {𝕊:
    result↩{
      state⇐"ok",domain⇐accounting.domain,as_of⇐asOfText,scale⇐accounting.scale,
      assets⇐accounting.assets,liabilities⇐accounting.liabilities,equity⇐accounting.equity,
      total_assets⇐accounting.total_assets,total_liabilities⇐accounting.total_liabilities,
      stated_equity⇐accounting.stated_equity,unclosed_result⇐accounting.unclosed_result,
      total_equity⇐accounting.total_equity,
      total_liabilities_and_equity⇐accounting.total_liabilities_and_equity,
      difference⇐accounting.difference,balanced⇐accounting.balanced,
      unclosed_result_contributors⇐accounting.unclosed_result_contributors,
      diagnostics⇐empty
    }
  }⍟(0=≠diagnostics) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
StatementTable ← {𝕊 rows‿totalLabel‿totalValue‿scaleValue:
  body ← {𝕊 rowIndex:
    ⟨rowIndex⊑rows.account_key,AmountText ⟨rowIndex⊑rows.balance,scaleValue⟩⟩
  }¨rows.index
  body ∾↩ ⟨⟨totalLabel,AmountText ⟨totalValue,scaleValue⟩⟩⟩
  text.RenderTable ⟨⟨"Account","Balance"⟩,body,⟨1⟩⟩
}
FormatHuman ← {𝕊 result:
  out ← "== Balance Sheet =="∾(@+10)
  out ∾↩ "As of: "∾result.as_of∾" ("∾result.domain∾")"∾(@+10)∾(@+10)
  out ∾↩ "Assets"∾(@+10)
  out ∾↩ StatementTable ⟨result.assets,"Total assets",result.total_assets,result.scale⟩
  out ∾↩ (@+10)∾"Liabilities"∾(@+10)
  out ∾↩ StatementTable ⟨result.liabilities,"Total liabilities",result.total_liabilities,result.scale⟩
  out ∾↩ (@+10)∾"Equity"∾(@+10)
  out ∾↩ StatementTable ⟨result.equity,"Stated equity",result.stated_equity,result.scale⟩
  out ∾↩ "Unclosed accumulated result: "∾(AmountText ⟨result.unclosed_result,result.scale⟩)∾(@+10)
  out ∾↩ "Total equity: "∾(AmountText ⟨result.total_equity,result.scale⟩)∾(@+10)∾(@+10)
  out ∾↩ "Total liabilities + equity: "∾(AmountText ⟨result.total_liabilities_and_equity,result.scale⟩)∾(@+10)
  out ∾↩ "Difference: "∾(AmountText ⟨result.difference,result.scale⟩)∾(@+10)
  out ∾↩ "Balanced: "∾(result.balanced⊑"NO"‿"YES")∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
