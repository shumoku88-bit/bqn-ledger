# Pure comparison of two explicit accounted cycle windows.

scale ← •Import "../ledger/exact_scale.bqn"
dates ← •Import "../ledger/date_ordinal.bqn"
empty ← ⟨⟩
policies ← ⟨"aligned_elapsed","complete_cycles"⟩

Contains ← {𝕊 item‿items: ∨´0∾item⊸≡¨items}
Diagnostic ← {𝕊 codeText‿messageText:
  {severity⇐"error",stage⇐"accounting_cycle_comparison",code⇐codeText,message⇐messageText}
}
AddIf ← {𝕊 invalid‿diagnostic: invalid/⟨diagnostic⟩}
EmptyAccounts ← {𝕊:
  {
    count⇐0,index⇐empty,account_index⇐empty,account_key⇐empty,
    current_movement⇐empty,baseline_movement⇐empty,difference⇐empty,
    current_contributors⇐empty,baseline_contributors⇐empty,difference_contributors⇐empty,
    difference_evidence⇐empty
  }
}
EmptyTotals ← {𝕊: {current_movement⇐empty,baseline_movement⇐empty,difference⇐empty,balanced⇐0}}
EmptyResult ← {𝕊 stateValue‿reasonValue‿policyValue‿diagnosticsValue:
  {
    state⇐stateValue,reason⇐reasonValue,policy⇐policyValue,domain⇐"",scale⇐0,
    current_start⇐"",current_observation⇐"",current_end_exclusive_ordinal⇐empty,
    baseline_start⇐"",baseline_observation⇐"",baseline_end_exclusive_ordinal⇐empty,
    current_day_count⇐empty,baseline_day_count⇐empty,
    accounts⇐EmptyAccounts @,totals⇐EmptyTotals @,diagnostics⇐diagnosticsValue
  }
}

# Inputs are successful cycle_account_period results plus an explicit comparison policy.
Build ← {𝕊 current‿baseline‿policy:
  inputDiagnostics ← current.diagnostics∾baseline.diagnostics
  {𝕊: inputDiagnostics∾↩⟨Diagnostic ⟨"comparison_input_not_ok","both accounted cycle windows must be ok"⟩⟩}⍟(0=≠inputDiagnostics) @
  result ← EmptyResult ⟨"error","",policy,inputDiagnostics⟩
  {𝕊: result↩EmptyResult ⟨"unavailable","current_window_unavailable:"∾current.reason,policy,empty⟩}⍟(current.state≡"unavailable") @
  {𝕊: result↩EmptyResult ⟨"unavailable","baseline_window_unavailable:"∾baseline.reason,policy,empty⟩}⍟((current.state≡"ok") ∧ baseline.state≡"unavailable") @
  {𝕊:
    diagnostics ← empty
    diagnostics ∾↩ AddIf ⟨¬Contains ⟨policy,policies⟩,Diagnostic ⟨"comparison_policy_invalid","policy must be aligned_elapsed or complete_cycles"⟩⟩
    diagnostics ∾↩ AddIf ⟨current.domain≢baseline.domain,Diagnostic ⟨"comparison_domain_mismatch","windows must use one currency domain"⟩⟩
    axesMatch ← (current.accounts.account_index≡baseline.accounts.account_index) ∧ current.accounts.account_key≡baseline.accounts.account_key
    diagnostics ∾↩ AddIf ⟨¬axesMatch,Diagnostic ⟨"comparison_account_axis_mismatch","windows must use the same admitted Account axis"⟩⟩
    currentStart ← dates.Ordinal current.cycle_start
    baselineStart ← dates.Ordinal baseline.cycle_start
    currentDays ← current.observed_end_exclusive_ordinal-currentStart
    baselineDays ← baseline.observed_end_exclusive_ordinal-baselineStart
    {𝕊:
      diagnostics ∾↩ AddIf ⟨currentDays≠baselineDays,Diagnostic ⟨"aligned_elapsed_day_count_mismatch","aligned elapsed windows require equal day counts"⟩⟩
    }⍟(policy≡"aligned_elapsed") @
    {𝕊:
      currentComplete ← current.observed_end_exclusive_ordinal=dates.Ordinal current.cycle_end_exclusive
      baselineComplete ← baseline.observed_end_exclusive_ordinal=dates.Ordinal baseline.cycle_end_exclusive
      diagnostics ∾↩ AddIf ⟨¬(currentComplete∧baselineComplete),Diagnostic ⟨"complete_cycle_required","complete_cycles requires two fully observed cycles"⟩⟩
    }⍟(policy≡"complete_cycles") @
    {𝕊:
      targetScale ← current.scale⌈baseline.scale
      currentNormalized ← {scale.Normalize ⟨𝕩,current.scale,targetScale⟩}¨current.accounts.movement
      baselineNormalized ← {scale.Normalize ⟨𝕩,baseline.scale,targetScale⟩}¨baseline.accounts.movement
      normalizedOk ← (∧´1∾{𝕩.state≡"ok"}¨currentNormalized) ∧ ∧´1∾{𝕩.state≡"ok"}¨baselineNormalized
      diagnostics ∾↩ AddIf ⟨¬normalizedOk,Diagnostic ⟨"coefficient_normalization_failed","window movements cannot normalize exactly"⟩⟩
      {𝕊:
        currentValues ← {𝕩.coefficient}¨currentNormalized
        baselineValues ← {𝕩.coefficient}¨baselineNormalized
        differenceResults ← {𝕊 i: scale.Sum ⟨i⊑currentValues,-(i⊑baselineValues)⟩}¨current.accounts.index
        differencesOk ← ∧´1∾{𝕩.state≡"ok"}¨differenceResults
        diagnostics ∾↩ AddIf ⟨¬differencesOk,Diagnostic ⟨"coefficient_sum_failed","Account comparison difference exceeds exact range"⟩⟩
        {𝕊:
          differences ← {𝕩.coefficient}¨differenceResults
          currentTotal ← scale.Sum currentValues ⋄ baselineTotal ← scale.Sum baselineValues ⋄ differenceTotal ← scale.Sum differences
          totalsOk ← ∧´{𝕩.state≡"ok"}¨⟨currentTotal,baselineTotal,differenceTotal⟩
          diagnostics ∾↩ AddIf ⟨¬totalsOk,Diagnostic ⟨"coefficient_sum_failed","comparison totals exceed exact range"⟩⟩
          {𝕊:
            result↩{
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
                difference_contributors⇐{𝕊 i: (i⊑current.accounts.movement_contributors)∾(i⊑baseline.accounts.movement_contributors)}¨current.accounts.index,
                difference_evidence⇐{𝕊 i:
                  {
                    current_coefficient⇐i⊑currentValues,baseline_coefficient⇐i⊑baselineValues,
                    current_contributors⇐i⊑current.accounts.movement_contributors,
                    baseline_contributors⇐i⊑baseline.accounts.movement_contributors
                  }
                }¨current.accounts.index
              },
              totals⇐{
                current_movement⇐currentTotal.coefficient,baseline_movement⇐baselineTotal.coefficient,
                difference⇐differenceTotal.coefficient,
                balanced⇐(currentTotal.coefficient=0) ∧ (baselineTotal.coefficient=0) ∧ differenceTotal.coefficient=0
              },diagnostics⇐empty
            }
          }⍟totalsOk @
        }⍟differencesOk @
      }⍟normalizedOk @
    }⍟(0=≠diagnostics) @
    {𝕊: result↩EmptyResult ⟨"error","",policy,diagnostics⟩}⍟(0<≠diagnostics) @
  }⍟((current.state≡"ok") ∧ baseline.state≡"ok") @
  result
}

{Build⇐Build}
