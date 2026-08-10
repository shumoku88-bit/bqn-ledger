# Retained Account × current/baseline/difference Matrix and human renderer.

matrix_result ← •Import "../accounting/matrix_result.bqn"
amount ← •Import "../ledger/amount_text.bqn"
text ← •Import "../report/text.bqn"
empty ← ⟨⟩
columns ← ⟨"current_movement","baseline_movement","difference"⟩

EmptyMatrix ← {𝕊: (matrix_result.Build ⟨empty,empty,0,empty,empty⟩).matrix}
EmptyResult ← {𝕊 stateValue‿reasonValue‿diagnosticsValue:
  {
    state⇐stateValue,reason⇐reasonValue,policy⇐"",domain⇐"",current_start⇐"",current_observation⇐"",
    baseline_start⇐"",baseline_observation⇐"",current_day_count⇐empty,baseline_day_count⇐empty,
    account_keys⇐empty,account_labels⇐empty,matrix⇐EmptyMatrix @,difference_evidence⇐empty,
    totals⇐{current_movement⇐empty,baseline_movement⇐empty,difference⇐empty,balanced⇐0},diagnostics⇐diagnosticsValue
  }
}

Build ← {𝕊 comparison:
  result ← EmptyResult ⟨comparison.state,comparison.reason,comparison.diagnostics⟩
  {𝕊:
    accounts ← comparison.accounts
    values ← {𝕊 i: ⟨i⊑accounts.current_movement,i⊑accounts.baseline_movement,i⊑accounts.difference⟩}¨accounts.index
    contributors ← {𝕊 i: ⟨i⊑accounts.current_contributors,i⊑accounts.baseline_contributors,i⊑accounts.difference_contributors⟩}¨accounts.index
    built ← matrix_result.Build ⟨accounts.account_index,columns,comparison.scale,values,contributors⟩
    {𝕊:
      result↩{
        state⇐"ok",reason⇐"",policy⇐comparison.policy,domain⇐comparison.domain,
        current_start⇐comparison.current_start,current_observation⇐comparison.current_observation,
        baseline_start⇐comparison.baseline_start,baseline_observation⇐comparison.baseline_observation,
        current_day_count⇐comparison.current_day_count,baseline_day_count⇐comparison.baseline_day_count,
        account_keys⇐accounts.account_key,account_labels⇐{𝕩∾"/"∾comparison.domain}¨accounts.account_key,
        matrix⇐built.matrix,difference_evidence⇐accounts.difference_evidence,
        totals⇐comparison.totals,diagnostics⇐empty
      }
    }⍟(built.state≡"ok") @
    {𝕊: result↩EmptyResult ⟨"error","",built.diagnostics⟩}⍟(built.state≢"ok") @
  }⍟(comparison.state≡"ok") @
  result
}

AmountText ← {𝕊 coefficient‿scaleValue: amount.Format ⟨coefficient,scaleValue⟩}
FormatHuman ← {𝕊 input:
  result ← input ⋄ style ← "minus"
  {𝕊: result↩0⊑input ⋄ style↩(1⊑input).negative_style}⍟((0<≡input) ∧ (2=≠input)) @
  Fmt ← {𝕊 coeff: text.FormatAmount ⟨coeff,result.matrix.scale,style⟩}
  rows ← {𝕊 i:
    values ← i⊑result.matrix.values
    ⟨i⊑result.account_labels⟩∾Fmt¨values
  }¨result.matrix.row_index
  total ← ⟨"Total",
    Fmt result.totals.current_movement,
    Fmt result.totals.baseline_movement,
    Fmt result.totals.difference
  ⟩
  out ← "== Cycle Comparison =="∾(@+10)
  out ∾↩ "Policy: "∾result.policy∾(@+10)
  out ∾↩ "Current : "∾result.current_start∾" through "∾result.current_observation∾" ("∾(•Fmt result.current_day_count)∾" days)"∾(@+10)
  out ∾↩ "Baseline: "∾result.baseline_start∾" through "∾result.baseline_observation∾" ("∾(•Fmt result.baseline_day_count)∾" days)"∾(@+10)∾(@+10)
  out ∾↩ text.RenderTable ⟨⟨"Account","Current movement","Baseline movement","Difference"⟩,rows∾⟨total⟩,⟨1,2,3⟩⟩
  out ∾↩ "Balanced: "∾(result.totals.balanced⊑"NO"‿"YES")∾(@+10)∾(@+10)
  out
}

{Build⇐Build,FormatHuman⇐FormatHuman}
