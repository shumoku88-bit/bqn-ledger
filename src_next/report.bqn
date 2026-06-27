# report.bqn — human-readable src_next report
# Usage: bqn src_next/report.bqn <baseDir>

ctx_mod ← •Import "context.bqn"
snapshot ← •Import "snapshot.bqn"
ytd_summary ← •Import "ytd_summary.bqn"
balances ← •Import "balances.bqn"
cycle_summary ← •Import "cycle_summary.bqn"
expense_breakdown ← •Import "expense_breakdown.bqn"
envelope_computation ← •Import "envelope_computation.bqn"
planned_payments ← •Import "planned_payments.bqn"
recent_journal ← •Import "recent_journal.bqn"
readiness_check ← •Import "readiness_check.bqn"
outlook ← •Import "outlook.bqn"
daily_trend ← •Import "daily_trend.bqn"
actual_comparison ← •Import "actual_comparison.bqn"
cube ← •Import "cube.bqn"
trial_balance ← •Import "trial_balance.bqn"
fmt ← •Import "format.bqn"

PrintSection ← {𝕊 text: •Out text ⋄ •Out ""}

HasArg ← {𝕊 args‿flag: 0 < +´ flag⊸≡¨ args }

Main ← {𝕊 args:
  base ← ⊑ args
  no_color ← (HasArg ⟨args, "--no-color"⟩) ∨ (HasArg ⟨args, "--color=never"⟩)
  force_color ← HasArg ⟨args, "--color=always"⟩
  fmt.SetColorEnabled force_color ∨ ¬ no_color
  ctx ← ctx_mod.BuildContext base
  exp ← expense_breakdown.Build ctx

  PrintSection snapshot.FormatHuman snapshot.Build ctx
  PrintSection ytd_summary.FormatHuman ytd_summary.Build ctx
  PrintSection balances.FormatHuman balances.Build ctx
  PrintSection cycle_summary.FormatHuman ⟨cycle_summary.Build ctx, exp.entries⟩

  PrintSection trial_balance.FormatHuman (trial_balance.Build ⟨ctx, cube.layer_actual⟩)

  vm ← envelope_computation.Build ctx
  { 𝕊 ⋄
    txt ← envelope_computation.FormatHuman vm
    (0=≠txt)◶⟨{𝕊: PrintSection txt},{𝕊:
      hdr ← "== Envelope & Budget =="
      PrintSection (hdr∾(@+10)∾"status: "∾vm.status∾(@+10)∾"NOTE: src_next envelope production advice is guarded"∾(@+10))
    }⟩ @
  }⍟(vm.status ≢ "disabled") @

  PrintSection planned_payments.FormatHuman ctx
  PrintSection recent_journal.FormatHuman ⟨ctx, 10⟩
  PrintSection readiness_check.FormatHuman ctx
  PrintSection outlook.FormatHuman outlook.Build ctx
  PrintSection daily_trend.FormatHuman daily_trend.Build ctx
  PrintSection actual_comparison.FormatHuman actual_comparison.Build ctx

  hdr ← fmt.Section "12. デバッグ・由来 (Debug & Provenance)"
  PrintSection (hdr∾(@+10)∾"status: partial/src_next"∾(@+10)∾cube.VerifyNumeric ⟨ctx.cube, ctx.resolved.account_keys⟩)
}

Main •args
