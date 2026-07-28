# Retained Month × Account movement Matrix and human-only renderer.

amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

EmptyMatrix ← {𝕊:
  {row_count⇐0,column_count⇐0,cell_count⇐0,row_index⇐empty,column_index⇐empty,row_coordinates⇐empty,column_coordinates⇐empty,scale⇐0,values⇐empty,contributors⇐empty}
}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",first_month⇐"",last_month_exclusive⇐"",months⇐empty,
    account_keys⇐empty,account_labels⇐empty,matrix⇐EmptyMatrix @,
    totals⇐{month⇐empty,account⇐empty,grand⇐empty,balanced⇐0},diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 monthlyMovement:
  result ← EmptyResult monthlyMovement.diagnostics
  {𝕊:
    result↩{
      state⇐"ok",domain⇐monthlyMovement.domain,first_month⇐monthlyMovement.first_month,
      last_month_exclusive⇐monthlyMovement.last_month_exclusive,months⇐monthlyMovement.months,
      account_keys⇐monthlyMovement.account_keys,
      account_labels⇐{𝕩∾"/"∾monthlyMovement.domain}¨monthlyMovement.account_keys,
      matrix⇐monthlyMovement.matrix,totals⇐monthlyMovement.totals,diagnostics⇐empty
    }
  }⍟(monthlyMovement.state≡"ok") @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 result:
  rows ← {𝕊 row:
    values ← row⊑result.matrix.values
    ⟨row⊑result.months⟩∾({AmountText ⟨𝕩,result.matrix.scale⟩}¨values)∾⟨AmountText ⟨row⊑result.totals.month,result.matrix.scale⟩⟩
  }¨result.matrix.row_index
  totalRow ← ⟨"Range total"⟩∾({AmountText ⟨𝕩,result.matrix.scale⟩}¨result.totals.account)∾⟨AmountText ⟨result.totals.grand,result.matrix.scale⟩⟩
  headers ← ⟨"Month"⟩∾result.account_labels∾⟨"Total"⟩
  right ← 1+↕result.matrix.column_count+1
  out ← "== Monthly Accounts =="∾(@+10)
  out ∾↩ "Range: "∾result.first_month∾".."∾result.last_month_exclusive∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨headers,rows∾⟨totalRow⟩,right⟩
  out ∾↩ "Balanced by month: "∾(result.totals.balanced⊑"NO"‿"YES")∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
