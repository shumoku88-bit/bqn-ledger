# Retained Account Balances result and human/compact/JSON renderers.

matrix_result ← •Import "../accounting/matrix_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
json ← •Import "../report/json_text.bqn"
empty ← ⟨⟩
lf ← @+10

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_account_balances",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊: (matrix_result.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyResult ← {𝕊 diagnosticsValue:
  {state⇐"error",domain⇐"",as_of⇐"",account_keys⇐empty,roles⇐empty,types⇐empty,matrix⇐EmptyMatrix @,balanced⇐0,diagnostics⇐diagnosticsValue}
}

Build ← {𝕊 accountBalance‿asOfText:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨accountBalance.state≢"ok",Diagnostic ⟨"account_balance_not_ok","Account balance evidence must be ok"⟩⟩
  asOfValid ← dates.IsValid asOfText
  diagnostics ∾↩ AddIf ⟨¬asOfValid,Diagnostic ⟨"observation_invalid","as-of must be strict Gregorian text"⟩⟩
  {𝕊:
    diagnostics ∾↩ AddIf ⟨(dates.Ordinal asOfText)≠accountBalance.observation_ordinal,Diagnostic ⟨"observation_mismatch","as-of text must match accounting evidence"⟩⟩
  }⍟(asOfValid ∧ accountBalance.state≡"ok") @

  result ← EmptyResult diagnostics
  {𝕊:
    rows ← {⟨𝕩⟩}¨accountBalance.accounts.closing
    contributors ← {⟨𝕩⟩}¨accountBalance.accounts.contributors
    built ← matrix_result.Build ⟨accountBalance.accounts.account_index,⟨"closing"⟩,accountBalance.scale,rows,contributors⟩
    diagnostics ∾↩ built.diagnostics
    {𝕊:
      result↩{
        state⇐"ok",domain⇐accountBalance.domain,as_of⇐asOfText,
        account_keys⇐accountBalance.accounts.account_key,roles⇐accountBalance.accounts.role,types⇐accountBalance.accounts.type,
        matrix⇐built.matrix,balanced⇐accountBalance.balanced,diagnostics⇐empty
      }
    }⍟(built.state≡"ok") @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  labels ← {𝕩∾"/"∾result.domain}¨result.account_keys
  amountTexts ← {text.FormatAmount ⟨⊑𝕩⊑result.matrix.values,result.matrix.scale,style⟩}¨result.matrix.row_index
  valWidth ← ⌈´⟨12⟩∾text.VWidth¨amountTexts
  nameWidth ← ⌈´⟨7⟩∾text.VWidth¨labels
  divider ← (nameWidth⥊'-')∾"-+--"∾(valWidth⥊'-')
  header ← (text.PadRight ⟨nameWidth,"Account"⟩)∾" | "∾(text.PadLeft ⟨valWidth,"Balance"⟩)
  rowLines ← {𝕊 rowIndex:
    (text.PadRight ⟨nameWidth,rowIndex⊑labels⟩)∾" | "∾(text.PadLeft ⟨valWidth,rowIndex⊑amountTexts⟩)
  }¨result.matrix.row_index
  tableLines ← ⟨header,divider⟩∾rowLines∾⟨divider⟩
  prefixLines ← ⟨"== Account Balances ==",("Currency: "∾result.domain),("As of: "∾result.as_of),""⟩
  suffixLines ← ⟨("Balanced: "∾result.balanced⊑"NO"‿"YES"),""⟩
  lines ← prefixLines∾tableLines∾suffixLines
  ∾{𝕩∾lf}¨lines
}

FormatCompact ← {𝕊 result:
  rowLines ← {𝕊 rowIndex:
    value ← ⊑rowIndex⊑result.matrix.values
    "ledger_balance: "∾(rowIndex⊑result.account_keys)∾"/"∾result.domain∾" "∾AmountText ⟨value,result.matrix.scale⟩
  }¨result.matrix.row_index
  lines ← ⟨"--- Ledger Account Balances ---"⟩∾rowLines∾((0=result.matrix.row_count)/⟨"ledger_balance: (none) 0"⟩)
  ∾{𝕩∾lf}¨lines
}

FormatJson ← {𝕊 result:
  AccountObject ← {𝕊 rowIndex:
    value ← ⊑rowIndex⊑result.matrix.values
    json.Object ⟨
      json.Pair ⟨"account",json.String rowIndex⊑result.account_keys⟩,
      json.Pair ⟨"role",json.String rowIndex⊑result.roles⟩,
      json.Pair ⟨"type",json.String rowIndex⊑result.types⟩,
      json.Pair ⟨"balance",json.ExactNumber ⟨value,result.matrix.scale⟩⟩
    ⟩
  }
  accounts ← AccountObject¨result.matrix.row_index
  json.Object ⟨
    json.Pair ⟨"currency",json.String result.domain⟩,
    json.Pair ⟨"as_of",json.String result.as_of⟩,
    json.Pair ⟨"accounts",json.Array accounts⟩,
    json.Pair ⟨"balanced",json.Boolean result.balanced⟩
  ⟩
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact,FormatJson⇐FormatJson}
