# First section-local destination report proof.
# Accounting formulas stay in account_period; this owner composes MatrixResult and text.

matrixResult ← •Import "../accounting/matrix_result.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩

columnCoordinates ← ⟨"opening","debit_movement","credit_movement","closing"⟩
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_trial_balance",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyMatrix ← {𝕊:
  {row_count⇐0,column_count⇐0,cell_count⇐0,row_index⇐empty,column_index⇐empty,row_coordinates⇐empty,column_coordinates⇐empty,scale⇐0,values⇐empty,contributors⇐empty}
}
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
AmountCell ← {𝕊 coefficient‿scale: text.PadLeft ⟨12,CellText ⟨coefficient,scale⟩⟩}

FormatHuman ← {𝕊 result:
  maxName ← ⌈´⟨7⟩∾text.VWidth¨result.account_labels
  divider ← (maxName⥊'-')∾"-+--------------+--------------+--------------+--------------"
  out ← "== Trial Balance ("∾result.layer∾" layer) =="∾(@+10)
  out ∾↩ "Period: "∾result.period_start∾"〜"∾result.period_end_exclusive∾(@+10)
  out ∾↩ "As of : "∾result.as_of∾(@+10)∾(@+10)
  out ∾↩ (maxName⥊' ')∾" |      Opening |        Debit |       Credit |      Closing "∾(@+10)
  out ∾↩ divider∾(@+10)
  {𝕊 rowIndex:
    values ← rowIndex⊑result.matrix.values
    out ∾↩ (text.PadRight ⟨maxName,rowIndex⊑result.account_labels⟩)∾" | "
    out ∾↩ (AmountCell ⟨0⊑values,result.matrix.scale⟩)∾" | "
    out ∾↩ (AmountCell ⟨1⊑values,result.matrix.scale⟩)∾" | "
    out ∾↩ (AmountCell ⟨2⊑values,result.matrix.scale⟩)∾" | "
    out ∾↩ (AmountCell ⟨3⊑values,result.matrix.scale⟩)∾" "∾(@+10)
  }¨result.matrix.row_index
  out ∾↩ divider∾(@+10)
  out ∾↩ (text.PadRight ⟨maxName,"Total"⟩)∾" | "
  out ∾↩ (AmountCell ⟨result.totals.opening,result.matrix.scale⟩)∾" | "
  out ∾↩ (AmountCell ⟨result.totals.debit_movement,result.matrix.scale⟩)∾" | "
  out ∾↩ (AmountCell ⟨result.totals.credit_movement,result.matrix.scale⟩)∾" | "
  out ∾↩ (AmountCell ⟨result.totals.closing,result.matrix.scale⟩)∾" "∾(@+10)∾(@+10)
  out ∾↩ "Zero-sum check (debit=credit): "∾(result.totals.balanced⊑"FAIL"‿"OK")∾(@+10)∾(@+10)
  out
}

FormatCompact ← {𝕊 result:
  out ← "--- Ledger Trial Balance ---"∾(@+10)
  out ∾↩ "ledger_trial_balance_period: "∾result.period_start∾".."∾result.period_end_exclusive∾(@+10)
  out ∾↩ "ledger_trial_balance_layer: "∾result.layer∾(@+10)
  out ∾↩ "ledger_trial_balance_rows: "∾(•Fmt result.matrix.row_count)∾(@+10)
  {𝕊 rowIndex:
    values ← rowIndex⊑result.matrix.values
    out ∾↩ "ledger_trial_balance_row: "∾(rowIndex⊑result.account_labels)
    out ∾↩ " opening="∾(CellText ⟨0⊑values,result.matrix.scale⟩)
    out ∾↩ " debit="∾(CellText ⟨1⊑values,result.matrix.scale⟩)
    out ∾↩ " credit="∾(CellText ⟨2⊑values,result.matrix.scale⟩)
    out ∾↩ " closing="∾(CellText ⟨3⊑values,result.matrix.scale⟩)∾(@+10)
  }¨result.matrix.row_index
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman,FormatCompact⇐FormatCompact}
