# Retained Month × Account movement result with Account × Month human presentation.

matrix_result ← •Import "../accounting/matrix_result.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

EmptyMatrix ← {𝕊: (matrix_result.Build ⟨empty,empty,0,empty,empty⟩).matrix}
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
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  Fmt ← {𝕊 coeff: text.FormatAmount ⟨coeff,result.matrix.scale,style⟩}
  rows ← {𝕊 column:
    values ← {column⊑𝕩}¨result.matrix.values
    ⟨column⊑result.account_labels⟩∾(Fmt¨values)∾⟨Fmt column⊑result.totals.account⟩
  }¨result.matrix.column_index
  totalRow ← ⟨"Month total"⟩∾(Fmt¨result.totals.month)∾⟨Fmt result.totals.grand⟩
  headers ← ⟨"Account"⟩∾result.months∾⟨"Range total"⟩
  right ← 1+↕result.matrix.row_count+1
  out ← "== Monthly Accounts =="∾(@+10)
  out ∾↩ "Range: "∾result.first_month∾".."∾result.last_month_exclusive∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨headers,rows∾⟨totalRow⟩,right⟩
  out ∾↩ "Balanced by month: "∾(result.totals.balanced⊑"NO"‿"YES")∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
