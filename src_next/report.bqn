# report.bqn — human-readable src_next report
# Usage: bqn src_next/report.bqn <baseDir>
#        bqn src_next/report.bqn <baseDir> --list-sections
#        bqn src_next/report.bqn <baseDir> --section <key>
#        bqn src_next/report.bqn <baseDir> --outlook-as-of YYYY-MM-DD
#
# --list-sections outputs tab-separated section-key and first-line marker
# so UI tools can extract sections without hard-coding header strings.
# --section prints one canonical section body by its stable key.
# --outlook-as-of selects observation O for the Outlook consumer only.

ctx_mod ← •Import "context.bqn"
date ← •Import "date.bqn"
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
labels ← •Import "report_labels.bqn"
issues ← •Import "issues.bqn"
daily_flow ← •Import "daily_flow.bqn"
L ← labels.Text

PrintSection ← {𝕊 text: •Out text ⋄ •Out ""}

HasArg ← {𝕊 args‿flag: 0 < +´ flag⊸≡¨ args }

ArgValue ← {𝕊 args‿flag:
  idx ← ⊑ ((flag⊸≡¨ args) ⊐ ⟨1⟩)
  next_idx ← 1 + idx
  (next_idx < ≠args) ? (next_idx ⊑ args) ; ""
}

FindSectionIndex ← {𝕊 entries‿key: ({⊑𝕩}¨ entries) ⊐ ⟨key⟩ }

# FirstLine extracts the first line of text (up to first newline)
FirstLine ← {𝕊 text:
  nl ← @+10
  idx ← (text=nl) ⊐ 1
  idx ↑ text
}

# BuildSectionEntries returns ⟨⟨key,full_text⟩,...⟩ for all report sections.
# The key is the canonical section name used by UI tools.
# The full_text is what would be printed for that section.
# Outlook O is supplied explicitly and does not redefine other consumers.
BuildSectionEntries ← {𝕊 ctx‿outlook_as_of:
  exp ← expense_breakdown.Build ctx
  tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩
  vm ← envelope_computation.Build ctx

  entries ← ⟨
    ⟨"snapshot", snapshot.FormatHuman snapshot.Build ctx⟩
    ⟨"issues", issues.FormatHuman ctx⟩
    ⟨"ytd", ytd_summary.FormatHuman ytd_summary.Build ctx⟩
    ⟨"balances", balances.FormatHuman balances.Build ctx⟩
    ⟨"cycle", cycle_summary.FormatHuman ⟨cycle_summary.Build ctx, exp.entries⟩⟩
    ⟨"trial-balance", trial_balance.FormatHuman tb⟩
    ⟨"envelopes", {
      txt ← envelope_computation.FormatHuman vm
      (0=≠txt)◶⟨{𝕊: txt},{
        hdr ← L "report.envelope_section_title"
        hdr∾(@+10)∾"status: "∾vm.status∾(@+10)∾(L "report.envelope_guard_note")∾(@+10)
      }⟩ @
    }⍟(vm.status ≢ "disabled") @⟩
    ⟨"planned", planned_payments.FormatHuman ctx⟩
    ⟨"recent", recent_journal.FormatHuman ⟨ctx, 10⟩⟩
    ⟨"check", readiness_check.FormatHuman ctx⟩
    ⟨"outlook", outlook.FormatHuman outlook.BuildAt ⟨ctx, outlook_as_of⟩⟩
    ⟨"daily-trend", daily_trend.FormatHuman daily_trend.Build ctx⟩
    ⟨"daily-flow", daily_flow.FormatHuman daily_flow.Build ctx⟩
    ⟨"actual-comparison", actual_comparison.FormatHuman actual_comparison.Build ctx⟩
    ⟨"debug", {
      hdr ← fmt.Section (L "report.debug_title")
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

  list_sections ← HasArg ⟨args, "--list-sections"⟩
  section_flag ← HasArg ⟨args, "--section"⟩
  section_key ← ArgValue ⟨args, "--section"⟩
  format_flag ← HasArg ⟨args, "--format"⟩
  format_val ← ArgValue ⟨args, "--format"⟩
  write_cache_flag ← HasArg ⟨args, "--write-section-cache"⟩
  write_cache_dir ← ArgValue ⟨args, "--write-section-cache"⟩
  outlook_as_of_flag ← HasArg ⟨args, "--outlook-as-of"⟩
  outlook_as_of_val ← ArgValue ⟨args, "--outlook-as-of"⟩
  outlook_as_of_next_is_option ← "--" ≡ 2 ↑ outlook_as_of_val
  outlook_as_of_missing ← outlook_as_of_flag ∧ ((0 = ≠outlook_as_of_val) ∨ outlook_as_of_next_is_option)

  {𝕊:
    •Out "ERROR: --section requires a section key"
    •Exit 1
  }⍟(section_flag ∧ (0 = ≠section_key)) @

  {𝕊:
    •Out "ERROR: --format requires a format"
    •Exit 1
  }⍟(format_flag ∧ (0 = ≠format_val)) @

  {𝕊:
    •Out "ERROR: unsupported format: "∾format_val
    •Exit 1
  }⍟((0 < ≠format_val) ∧ (format_val ≢ "json")) @

  {𝕊:
    •Out "ERROR: --format json requires --section <key>"
    •Exit 1
  }⍟((format_val ≡ "json") ∧ ¬ section_flag) @

  {𝕊:
    •Out "ERROR: --write-section-cache requires a directory path"
    •Exit 1
  }⍟(write_cache_flag ∧ (0 = ≠write_cache_dir)) @

  {𝕊:
    •Out "ERROR: --list-sections cannot be combined with --section"
    •Exit 1
  }⍟(list_sections ∧ section_flag) @

  {𝕊:
    •Out "ERROR: --write-section-cache cannot be combined with other major flags"
    •Exit 1
  }⍟(write_cache_flag ∧ (list_sections ∨ section_flag)) @

  {𝕊:
    •Out "ERROR: --outlook-as-of requires YYYY-MM-DD"
    •Exit 1
  }⍟outlook_as_of_missing @

  {𝕊:
    •Out "ERROR: invalid --outlook-as-of date: "∾outlook_as_of_val
    •Exit 1
  }⍟(outlook_as_of_flag ∧ (¬ outlook_as_of_missing) ∧ ¬ date.IsValidDateText outlook_as_of_val) @

  ctx ← ctx_mod.BuildContext base

  # Structured section requests dispatch before any human section rendering.
  # This keeps JSON output independent from unrelated FormatHuman failures and
  # from the human Outlook system-today default.
  {𝕊:
    (section_key ≡ "planned") ?
      {𝕊:
        •Out planned_payments.FormatJson ctx
        •Exit 0
      } @ ;
    (section_key ≡ "balances") ?
      {𝕊:
        •Out balances.FormatJson ctx
        •Exit 0
      } @ ;
    (section_key ≡ "snapshot") ?
      {𝕊:
        •Out snapshot.FormatJson ctx
        •Exit 0
      } @ ;
    (section_key ≡ "envelopes") ?
      {𝕊:
        •Out envelope_computation.FormatJson ctx
        •Exit 0
      } @
    ; {𝕊:
      •Out "ERROR: JSON format not supported for section: "∾section_key
      •Exit 1
    } @
  }⍟(format_val ≡ "json") @

  outlook_as_of ← ""
  {𝕊: outlook_as_of ↩ outlook_as_of_val}⍟outlook_as_of_flag @
  {𝕊: outlook_as_of ↩ date.Today @}⍟(¬ outlook_as_of_flag) @

  entries ← BuildSectionEntries ⟨ctx, outlook_as_of⟩

  {𝕊:
    {𝕊 entry:
      key ← ⊑entry ⋄ text ← 1⊑entry
      (write_cache_dir ∾ "/" ∾ key ∾ ".txt") •FChars text
    }¨ entries
    all_text ← ∾ { (1⊑𝕩) ∾ "\n\n" }¨ entries
    (write_cache_dir ∾ "/all.txt") •FChars all_text
    •Exit 0
  }⍟(write_cache_flag) @

  {𝕊:
    {𝕊 entry:
      key ← ⊑entry ⋄ text ← 1⊑entry
      •Out key∾(@+9)∾FirstLine text
    }¨ entries
  }⍟(list_sections) @

  {𝕊:
    idx ← FindSectionIndex ⟨entries, section_key⟩
    {𝕊: PrintSection (1⊑ idx ⊑ entries)}⍟(idx < ≠entries) @
    {𝕊:
      •Out "ERROR: unknown section key: "∾section_key
      •Exit 1
    }⍟(idx ≥ ≠entries) @
  }⍟(section_flag) @

  {𝕊:
    {𝕊 entry:
      PrintSection (1⊑entry)
    }¨ entries
  }⍟((¬ list_sections) ∧ (¬ section_flag)) @
}

Main •args
