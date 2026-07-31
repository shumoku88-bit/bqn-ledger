# Pure comparison of two explicit accounted cycle windows.

scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩
policies ← ⟨"aligned_elapsed","complete_cycles"⟩

Contains ← {∨´ 𝕨⊸≡¨𝕩}
Diagnostic ← {𝕊 c‿m: {severity⇐"error",stage⇐"accounting_cycle_comparison",code⇐c,message⇐m}}
AddIf ← {𝕊 b‿d: b/⟨d⟩}
EmptyAccounts ← {𝕊:
  {count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,
   current_movement⇐empty,baseline_movement⇐empty,difference⇐empty,
   current_contributors⇐empty,baseline_contributors⇐empty,difference_contributors⇐empty,difference_evidence⇐empty}
}
EmptyTotals ← {𝕊: {current_movement⇐empty,baseline_movement⇐empty,difference⇐empty,balanced⇐0}}
EmptyResult ← {𝕊 s‿r‿p‿d:
  {state⇐s,reason⇐r,policy⇐p,domain⇐"",scale⇐0,
   current_start⇐"",current_observation⇐"",current_end_exclusive_ordinal⇐empty,
   baseline_start⇐"",baseline_observation⇐"",baseline_end_exclusive_ordinal⇐empty,
   current_day_count⇐empty,baseline_day_count⇐empty,
   accounts⇐EmptyAccounts @,totals⇐EmptyTotals @,diagnostics⇐d}
}

# Inputs are successful cycle_account_period results plus an explicit comparison policy.
Build ← {𝕊 current‿baseline‿policy:
  inDiag ← current.diagnostics ∾ baseline.diagnostics
  {𝕊: inDiag ∾↩ ⟨Diagnostic ⟨"comparison_input_not_ok","both accounted cycle windows must be ok"⟩⟩}⍟(0=≠inDiag) @
  result ← EmptyResult ⟨"error","",policy,inDiag⟩
  {𝕊: result ↩ EmptyResult ⟨"unavailable","current_window_unavailable:"∾current.reason,policy,empty⟩}⍟(current.state≡"unavailable") @ ⋄
  {𝕊: result ↩ EmptyResult ⟨"unavailable","baseline_window_unavailable:"∾baseline.reason,policy,empty⟩}⍟((current.state≡"ok") ∧ baseline.state≡"unavailable") @ ⋄
  {𝕊:
    diagnostics ← empty
    diagnostics ∾↩ AddIf ⟨¬ policy Contains policies, Diagnostic ⟨"comparison_policy_invalid","policy must be aligned_elapsed or complete_cycles"⟩⟩
    diagnostics ∾↩ AddIf ⟨current.domain ≢ baseline.domain, Diagnostic ⟨"comparison_domain_mismatch","windows must use one currency domain"⟩⟩
    axesMatch ← (current.accounts.account_index ≡ baseline.accounts.account_index) ∧ current.accounts.account_key ≡ baseline.accounts.account_key
    diagnostics ∾↩ AddIf ⟨¬axesMatch, Diagnostic ⟨"comparison_account_axis_mismatch","windows must use the same admitted Account axis"⟩⟩

    ⟨currentDays, baselineDays⟩ ← { 𝕩.observed_end_exclusive_ordinal - dates.Ordinal 𝕩.cycle_start }¨ ⟨current, baseline⟩
    diagnostics ∾↩ AddIf ⟨(policy≡"aligned_elapsed") ∧ currentDays ≠ baselineDays, Diagnostic ⟨"aligned_elapsed_day_count_mismatch","aligned elapsed windows require equal day counts"⟩⟩

    complete ← ∧´ { 𝕩.observed_end_exclusive_ordinal = dates.Ordinal 𝕩.cycle_end_exclusive }¨ ⟨current, baseline⟩
    diagnostics ∾↩ AddIf ⟨(policy≡"complete_cycles") ∧ ¬complete, Diagnostic ⟨"complete_cycle_required","complete_cycles requires two fully observed cycles"⟩⟩

    targetScale ← current.scale ⌈ baseline.scale
    ⟨currentNorm, baselineNorm⟩ ← { w ← 𝕩 ⋄ {scale.Normalize ⟨𝕩, w.scale, targetScale⟩}¨ w.accounts.movement }¨ ⟨current, baseline⟩
    normOk ← ∧´ 1 ∾ {𝕩.state ≡ "ok"}¨ currentNorm ∾ baselineNorm
    diagnostics ∾↩ AddIf ⟨¬normOk, Diagnostic ⟨"coefficient_normalization_failed","window movements cannot normalize exactly"⟩⟩

    {𝕊:
      ⟨currentValues, baselineValues⟩ ← { {𝕩.coefficient}¨ 𝕩 }¨ ⟨currentNorm, baselineNorm⟩
      diffResults ← currentValues {scale.Sum ⟨𝕨,-𝕩⟩}¨ baselineValues
      diffsOk ← ∧´ 1 ∾ {𝕩.state≡"ok"}¨ diffResults
      diagnostics ∾↩ AddIf ⟨¬diffsOk, Diagnostic ⟨"coefficient_sum_failed","Account comparison difference exceeds exact range"⟩⟩

      differences ← {𝕩.coefficient}¨ diffResults
      ⟨currentTotal, baselineTotal, differenceTotal⟩ ← scale.Sum¨ ⟨currentValues, baselineValues, differences⟩
      totalsOk ← ∧´ {𝕩.state≡"ok"}¨ ⟨currentTotal, baselineTotal, differenceTotal⟩
      diagnostics ∾↩ AddIf ⟨¬totalsOk, Diagnostic ⟨"coefficient_sum_failed","comparison totals exceed exact range"⟩⟩

      {𝕊:
        diffContributors ← current.accounts.movement_contributors ∾¨ baseline.accounts.movement_contributors
        diffEvidence ← {
          ⟨c, b, cc, bc⟩ ← 𝕩
          {current_coefficient⇐c, baseline_coefficient⇐b, current_contributors⇐cc, baseline_contributors⇐bc}
        }˘ ⍉ > ⟨currentValues, baselineValues, current.accounts.movement_contributors, baseline.accounts.movement_contributors⟩

        result ↩ {
          state⇐"ok",reason⇐"",policy⇐policy,domain⇐current.domain,scale⇐targetScale,
          current_start⇐current.cycle_start,current_observation⇐current.observation,
          current_end_exclusive_ordinal⇐current.observed_end_exclusive_ordinal,
          baseline_start⇐baseline.cycle_start,baseline_observation⇐baseline.observation,
          baseline_end_exclusive_ordinal⇐baseline.observed_end_exclusive_ordinal,
          current_day_count⇐currentDays,baseline_day_count⇐baselineDays,
          accounts⇐{
            count⇐current.accounts.count,index⇐current.accounts.index,
            account_index⇐current.accounts.account_index,account_key⇐current.accounts.account_key,
            current_movement⇐currentValues,baseline_movement⇐baselineValues,difference⇐differences,
            current_contributors⇐current.accounts.movement_contributors,
            baseline_contributors⇐baseline.accounts.movement_contributors,
            difference_contributors⇐diffContributors,
            difference_evidence⇐diffEvidence
          },
          totals⇐{
            current_movement⇐currentTotal.coefficient,baseline_movement⇐baselineTotal.coefficient,
            difference⇐differenceTotal.coefficient,
            balanced⇐(currentTotal.coefficient=0) ∧ (baselineTotal.coefficient=0) ∧ differenceTotal.coefficient=0
          },diagnostics⇐empty
        }
      }⍟totalsOk @
    }⍟(0=≠diagnostics) @
    {𝕊: result ↩ EmptyResult ⟨"error","",policy,diagnostics⟩}⍟(0<≠diagnostics) @
  }⍟((current.state≡"ok") ∧ baseline.state≡"ok") @
  result
}

{Build⇐Build}
