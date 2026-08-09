# Retained Current-cycle Accounts Matrix and human-only renderer.

matrix_result ← •Import "../accounting/matrix_result.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
columns ← ⟨"opening","debit","credit","movement","closing"⟩

Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"section_cycle_accounts",code⇐codeText,message⇐messageText}
}
EmptyMatrix ← {𝕊:
  {row_count⇐0,column_count⇐0,cell_count⇐0,row_index⇐empty,column_index⇐empty,row_coordinates⇐empty,column_coordinates⇐empty,scale⇐0,values⇐empty,contributors⇐empty}
}
EmptyTotals ← {𝕊:
  {opening⇐empty,debit⇐empty,credit⇐empty,movement⇐empty,closing⇐empty,balanced⇐0}
}
EmptyResult ← {𝕊 stateValue‿reasonValue‿diagnosticsValue:
  {
    state⇐stateValue,reason⇐reasonValue,domain⇐"",observation⇐"",cycle_mode⇐"",
    cycle_start⇐"",cycle_end_exclusive⇐"",account_keys⇐empty,account_labels⇐empty,
    matrix⇐EmptyMatrix @,totals⇐EmptyTotals @,
    cycle_start_contributors⇐empty,cycle_end_contributors⇐empty,diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 cycleAccountPeriod:
  stateValue ← cycleAccountPeriod.state
  reasonValue ← ""
  {𝕊: reasonValue↩cycleAccountPeriod.reason}⍟(stateValue≡"unavailable") @
  result ← EmptyResult ⟨stateValue,reasonValue,cycleAccountPeriod.diagnostics⟩
  {𝕊:
    accounts ← cycleAccountPeriod.accounts
    values ← {𝕊 i:
      ⟨i⊑accounts.opening,i⊑accounts.debit_movement,i⊑accounts.credit_movement,i⊑accounts.movement,i⊑accounts.closing⟩
    }¨accounts.index
    contributors ← {𝕊 i:
      ⟨i⊑accounts.opening_contributors,i⊑accounts.debit_contributors,i⊑accounts.credit_contributors,i⊑accounts.movement_contributors,i⊑accounts.closing_contributors⟩
    }¨accounts.index
    built ← matrix_result.Build ⟨accounts.account_index,columns,cycleAccountPeriod.scale,values,contributors⟩
    {𝕊:
      result↩{
        state⇐"ok",reason⇐"",domain⇐cycleAccountPeriod.domain,observation⇐cycleAccountPeriod.observation,
        cycle_mode⇐cycleAccountPeriod.cycle_mode,cycle_start⇐cycleAccountPeriod.cycle_start,
        cycle_end_exclusive⇐cycleAccountPeriod.cycle_end_exclusive,
        account_keys⇐accounts.account_key,
        account_labels⇐{𝕩∾"/"∾cycleAccountPeriod.domain}¨accounts.account_key,
        matrix⇐built.matrix,
        totals⇐{
          opening⇐cycleAccountPeriod.totals.opening,debit⇐cycleAccountPeriod.totals.debit_movement,
          credit⇐cycleAccountPeriod.totals.credit_movement,movement⇐cycleAccountPeriod.totals.movement,
          closing⇐cycleAccountPeriod.totals.closing,balanced⇐cycleAccountPeriod.totals.balanced
        },
        cycle_start_contributors⇐cycleAccountPeriod.cycle_start_contributors,
        cycle_end_contributors⇐cycleAccountPeriod.cycle_end_contributors,diagnostics⇐empty
      }
    }⍟(built.state≡"ok") @
    {𝕊: result↩EmptyResult ⟨"error","",built.diagnostics⟩}⍟(built.state≢"ok") @
  }⍟(stateValue≡"ok") @
  {𝕊:
    result↩EmptyResult ⟨"error","",⟨Diagnostic ⟨"cycle_account_period_not_ok","Cycle Account-period evidence must be ok"⟩⟩⟩
  }⍟(¬∨´stateValue⊸≡¨⟨"ok","error","unavailable"⟩) @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  Fmt ← {𝕊 coeff: text.FormatAmount ⟨coeff,result.matrix.scale,style⟩}
  rows ← {𝕊 i:
    values ← i⊑result.matrix.values
    ⟨
      i⊑result.account_labels,
      Fmt 0⊑values,
      Fmt 1⊑values,
      Fmt 2⊑values,
      Fmt 3⊑values,
      Fmt 4⊑values
    ⟩
  }¨result.matrix.row_index
  total ← ⟨
    "Total",Fmt result.totals.opening,
    Fmt result.totals.debit,
    Fmt result.totals.credit,
    Fmt result.totals.movement,
    Fmt result.totals.closing
  ⟩
  out ← "== Current-cycle Accounts =="∾(@+10)
  out ∾↩ "Cycle: "∾result.cycle_start∾".."∾result.cycle_end_exclusive∾" ("∾result.cycle_mode∾")"∾(@+10)
  out ∾↩ "Observed through: "∾result.observation∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨⟨"Account","Opening","Debit","Credit (signed)","Movement","Closing"⟩,rows∾⟨total⟩,⟨1,2,3,4,5⟩⟩
  out ∾↩ "Balanced: "∾(result.totals.balanced⊑"NO"‿"YES")∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
