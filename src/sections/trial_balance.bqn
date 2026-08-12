# First section-local destination report proof.
# Accounting formulas stay in account_period; this owner composes MatrixResult and text.

matrixResult ← •Import "../accounting/matrix_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
lf ← @+10

columnCoordinates ← ⟨"opening","debit_movement","credit_movement","closing"⟩
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_trial_balance",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊: (matrixResult.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyResult ← {𝕊 diagnosticsValue:
  {
    state⇐"error",domain⇐"",layer⇐"",period_start⇐"",period_end_exclusive⇐"",as_of⇐"",
    account_keys⇐empty,account_labels⇐empty,matrix⇐EmptyMatrix @,
    totals⇐{opening⇐empty,debit_movement⇐empty,credit_movement⇐empty,closing⇐empty,balanced⇐0},
    diagnostics⇐diagnosticsValue
  }
}

# Input: successful Account-period result plus exact display date coordinates.
Build ← {𝕊 accountPeriod‿periodStartText‿periodEndText:
  diagnostics ← empty
  diagnostics ∾↩ AddIf ⟨accountPeriod.state≢"ok",Diagnostic ⟨"account_period_not_ok","Account-period result must be ok"⟩⟩
  startValid ← dates.IsValid periodStartText
  endValid ← dates.IsValid periodEndText
  diagnostics ∾↩ AddIf ⟨¬startValid,Diagnostic ⟨"period_start_invalid","period start text must be strict Gregorian text"⟩⟩
  diagnostics ∾↩ AddIf ⟨¬endValid,Diagnostic ⟨"period_end_invalid","period end text must be strict Gregorian text"⟩⟩
  {𝕊:
    diagnostics ∾↩ AddIf ⟨(dates.Ordinal periodStartText)≠accountPeriod.start_ordinal,Diagnostic ⟨"period_start_mismatch","period start text must match accounting coordinate"⟩⟩
    diagnostics ∾↩ AddIf ⟨(dates.Ordinal periodEndText)≠accountPeriod.end_exclusive_ordinal,Diagnostic ⟨"period_end_mismatch","period end text must match accounting coordinate"⟩⟩
  }⍟(startValid ∧ endValid ∧ accountPeriod.state≡"ok") @

  result ← EmptyResult empty
  {𝕊:
    accounts ← accountPeriod.accounts
    values ← {𝕊 rowIndex:
      ⟨rowIndex⊑accounts.opening,rowIndex⊑accounts.debit_movement,rowIndex⊑accounts.credit_movement,rowIndex⊑accounts.closing⟩
    }¨accounts.index
    contributors ← {𝕊 rowIndex:
      openingContributors ← rowIndex⊑accounts.opening_contributors
      periodContributors ← rowIndex⊑accounts.period_contributors
      ⟨
        openingContributors,
        rowIndex⊑accounts.debit_contributors,
        rowIndex⊑accounts.credit_contributors,
        openingContributors∾periodContributors
      ⟩
    }¨accounts.index
    builtMatrix ← matrixResult.Build ⟨accounts.account_index,columnCoordinates,accountPeriod.scale,values,contributors⟩
    diagnostics ∾↩ builtMatrix.diagnostics
    {𝕊:
      result↩{
        state⇐"ok",domain⇐accountPeriod.domain,layer⇐accountPeriod.layer,
        period_start⇐periodStartText,period_end_exclusive⇐periodEndText,as_of⇐periodEndText,
        account_keys⇐accounts.account_key,
        account_labels⇐{𝕩∾"/"∾accountPeriod.domain}¨accounts.account_key,
        matrix⇐builtMatrix.matrix,
        totals⇐{
          opening⇐accountPeriod.totals.opening,
          debit_movement⇐accountPeriod.totals.debit_movement,
          credit_movement⇐accountPeriod.totals.credit_movement,
          closing⇐accountPeriod.totals.closing,
          balanced⇐accountPeriod.totals.balanced
        },
        diagnostics⇐empty
      }
    }⍟(builtMatrix.state≡"ok") @
  }⍟(0=≠diagnostics) @
  {𝕊: result↩EmptyResult diagnostics}⍟(0<≠diagnostics) @
  result
}

CellText ← {𝕊 coefficient‿scale: amount.Format ⟨coefficient,scale⟩}
AmountCell ← {𝕊 coefficient‿scale‿style: text.PadLeft ⟨12,text.FormatAmount ⟨coefficient,scale,style⟩⟩}

FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  maxName ← ⌈´⟨7⟩∾text.VWidth¨result.account_labels
  divider ← (maxName⥊'-')∾"-+--------------+--------------+--------------+--------------"
  tableHeader ← (maxName⥊' ')∾" |      Opening |        Debit |       Credit |      Closing "
  rowLines ← {𝕊 rowIndex:
    values ← rowIndex⊑result.matrix.values
    (text.PadRight ⟨maxName,rowIndex⊑result.account_labels⟩)∾" | "∾
    (AmountCell ⟨0⊑values,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨1⊑values,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨2⊑values,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨3⊑values,result.matrix.scale,style⟩)∾" "
  }¨result.matrix.row_index
  totalLine ← (text.PadRight ⟨maxName,"Total"⟩)∾" | "∾
    (AmountCell ⟨result.totals.opening,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨result.totals.debit_movement,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨result.totals.credit_movement,result.matrix.scale,style⟩)∾" | "∾
    (AmountCell ⟨result.totals.closing,result.matrix.scale,style⟩)∾" "
  lines ← ⟨
    ("== Trial Balance ("∾result.layer∾" layer) =="),
    ("Period: "∾result.period_start∾"〜"∾result.period_end_exclusive),
    ("As of : "∾result.as_of),"",tableHeader,divider
  ⟩∾rowLines∾⟨
    divider,totalLine,"",
    ("Zero-sum check (debit=credit): "∾result.totals.balanced⊑"FAIL"‿"OK"),""
  ⟩
  ∾{𝕩∾lf}¨lines
}

FormatCompact ← {𝕊 result:
  rowLines ← {𝕊 rowIndex:
    values ← rowIndex⊑result.matrix.values
    "ledger_trial_balance_row: "∾(rowIndex⊑result.account_labels)∾
    " opening="∾(CellText ⟨0⊑values,result.matrix.scale⟩)∾
    " debit="∾(CellText ⟨1⊑values,result.matrix.scale⟩)∾
    " credit="∾(CellText ⟨2⊑values,result.matrix.scale⟩)∾
    " closing="∾CellText ⟨3⊑values,result.matrix.scale⟩
  }¨result.matrix.row_index
  lines ← ⟨
    "--- Ledger Trial Balance ---",
    ("ledger_trial_balance_period: "∾result.period_start∾".."∾result.period_end_exclusive),
    ("ledger_trial_balance_layer: "∾result.layer),
    ("ledger_trial_balance_rows: "∾•Fmt result.matrix.row_count)
  ⟩∾rowLines
  ∾{𝕩∾lf}¨lines
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact}
