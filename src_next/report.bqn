# report.bqn — human-readable src_next report
# Usage: bqn src_next/report.bqn <baseDir>
#        bqn src_next/report.bqn <baseDir> --list-sections
#
# --list-sections outputs tab-separated section-key and first-line marker
# so UI tools can extract sections without hard-coding header strings.

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

# FirstLine extracts the first line of text (up to first newline)
FirstLine ← {𝕊 text:
  nl ← @+10
  idx ← (text=nl) ⊐ 1
  idx ↑ text
}

# BuildSectionEntries returns ⟨⟨key,full_text⟩,...⟩ for all report sections.
# The key is the canonical section name used by UI tools.
# The full_text is what would be printed for that section.
BuildSectionEntries ← {𝕊 ctx:
  exp ← expense_breakdown.Build ctx
  tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩
  vm ← envelope_computation.Build ctx

  entries ← ⟨
    ⟨"snapshot", snapshot.FormatHuman snapshot.Build ctx⟩
    ⟨"ytd", ytd_summary.FormatHuman ytd_summary.Build ctx⟩
    ⟨"balances", balances.FormatHuman balances.Build ctx⟩
    ⟨"cycle", cycle_summary.FormatHuman ⟨cycle_summary.Build ctx, exp.entries⟩⟩
    ⟨"trial-balance", trial_balance.FormatHuman tb⟩
    ⟨"envelopes", {
      txt ← envelope_computation.FormatHuman vm
      (0=≠txt)◶⟨{𝕊: txt},{
        hdr ← "== Envelope & Budget =="
        hdr∾(@+10)∾"status: "∾vm.status∾(@+10)∾"NOTE: src_next envelope production advice is guarded"∾(@+10)
      }⟩ @
    }⍟(vm.status ≢ "disabled") @⟩
    ⟨"planned", planned_payments.FormatHuman ctx⟩
    ⟨"recent", recent_journal.FormatHuman ⟨ctx, 10⟩⟩
    ⟨"check", readiness_check.FormatHuman ctx⟩
    ⟨"outlook", outlook.FormatHuman outlook.Build ctx⟩
    ⟨"daily-trend", daily_trend.FormatHuman daily_trend.Build ctx⟩
    ⟨"actual-comparison", actual_comparison.FormatHuman actual_comparison.Build ctx⟩
    ⟨"debug", {
      hdr ← fmt.Section "12. デバッグ・由来 (Debug & Provenance)"
      hdr∾(@+10)∾"status: partial/src_next"∾(@+10)∾cube.VerifyNumeric ⟨ctx.cube, ctx.resolved.account_keys⟩
    }⟩
  ⟩
  entries
}

Main ← {𝕊 args:
  base ← ⊑ args
  no_color ← (HasArg ⟨args, "--no-color"⟩) ∨ (HasArg ⟨args, "--color=never"⟩)
  force_color ← HasArg ⟨args, "--color=always"⟩
  fmt.SetColorEnabled force_color ∨ ¬ no_color
  ctx ← ctx_mod.BuildContext base

  list_sections ← HasArg ⟨args, "--list-sections"⟩
  entries ← BuildSectionEntries ctx

  {𝕊 entry:
    key ← ⊑entry ⋄ text ← 1⊑entry
    list_sections◶⟨{𝕊:PrintSection text},{𝕊:•Out key∾"	"∾FirstLine text}⟩ @
  }¨ entries
}

Main •args
