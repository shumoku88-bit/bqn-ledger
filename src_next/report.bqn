# report.bqn — human-readable src_next report
# Usage: bqn src_next/report.bqn <baseDir>
#        bqn src_next/report.bqn <baseDir> --list-sections
#        bqn src_next/report.bqn <baseDir> --section <key>
#        bqn src_next/report.bqn <baseDir> --section balances [--currency CODE]
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
report_sections ← •Import "report_sections.bqn"
report_builder_order ← •Import "report_builder_order.bqn"
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

FindSectionIndex ← { ⊑ ({0⊑𝕩}¨ (0⊑𝕩)) ⊐ ⟨1⊑𝕩⟩ }

# Static descriptor keys own section identity/order. Executable builders remain
# local and must form an exact one-to-one mapping with those keys.
OrderBuilderEntries ← {𝕊 builder_entries:
  result ← report_builder_order.OrderBuilderEntries ⟨report_sections.rows, builder_entries⟩
  {𝕊:
    •Out result.message
    •Exit 1
  }⍟(¬result.valid) @
  result.ordered_entries
}

# FirstLine extracts the first line of text (up to first newline)
FirstLine ← {𝕊 text:
  nl ← @+10
  idx ← (text=nl) ⊐ 1
  idx ↑ text
}

# Per-section entry builders
BuildSnapshotEntry ← { ⟨"snapshot", snapshot.FormatHuman snapshot.Build 𝕩⟩ }
BuildIssuesEntry ← { ⟨"issues", issues.FormatHuman 𝕩⟩ }
BuildYtdEntry ← { ⟨"ytd", ytd_summary.FormatHuman ytd_summary.Build 𝕩⟩ }
# Human balances has one canonical body for direct, full, and cache routes when
# the ledger declares DEFAULT_CURRENCY. Older fixtures without that declaration
# retain the legacy full-report body; any declared-but-invalid selected route
# fails closed rather than silently falling back to a mixed-domain body.
BuildBalancesEntry ← {𝕊 base‿ctx:
  selected ← balances.BuildSelected ⟨base, ""⟩
  missingDefault ← selected.default_code ≡ "missing_default_currency"
  {𝕊:
    •Out "ERROR: " ∾ selected.message
    •Exit 1
  }⍟((selected.state ≢ "ok") ∧ ¬missingDefault) @
  text ← balances.FormatHuman balances.Build ctx
  {𝕊:
    # Normalize the renderer's extra trailing linefeed to the same cached body
    # convention used by the former direct-balances cache adapter.
    text ↩ ¯1 ↓ balances.FormatSelectedHuman selected
  }⍟(selected.state ≡ "ok") @
  ⟨"balances", text⟩
}
BuildCycleEntry ← { ⟨"cycle", cycle_summary.FormatHuman ⟨cycle_summary.Build (0⊑𝕩), (1⊑𝕩).entries⟩⟩ }
BuildTrialBalanceEntry ← { ⟨"trial-balance", trial_balance.FormatHuman (1⊑𝕩)⟩ }
BuildEnvelopesEntry ← {
  vm ← 1⊑𝕩
  txt ← (vm.status ≡ "disabled")◶⟨{
    raw_txt ← envelope_computation.FormatHuman vm
    (0=≠raw_txt)◶⟨{raw_txt},{
      hdr ← L "report.envelope_section_title"
      hdr∾(@+10)∾"status: "∾vm.status∾(@+10)∾(L "report.envelope_guard_note")∾(@+10)
    }⟩ @
  },{""}⟩ @
  ⟨"envelopes", txt⟩
}
BuildPlannedEntry ← { ⟨"planned", planned_payments.FormatHuman 𝕩⟩ }
BuildRecentEntry ← { ⟨"recent", recent_journal.FormatHuman ⟨𝕩, 10⟩⟩ }
BuildCheckEntry ← { ⟨"check", readiness_check.FormatHuman 𝕩⟩ }
BuildOutlookEntry ← { ⟨"outlook", outlook.FormatHuman outlook.BuildAt ⟨0⊑𝕩, 1⊑𝕩⟩⟩ }
BuildDailyTrendEntry ← { ⟨"daily-trend", daily_trend.FormatHuman daily_trend.BuildAt ⟨0⊑𝕩, 1⊑𝕩⟩⟩ }
BuildDailyFlowEntry ← { ⟨"daily-flow", daily_flow.FormatHuman daily_flow.Build 𝕩⟩ }
BuildActualComparisonEntry ← { ⟨"actual-comparison", actual_comparison.FormatHuman actual_comparison.BuildAt ⟨0⊑𝕩, 1⊑𝕩⟩⟩ }
BuildDebugEntry ← {
  ctx ← 𝕩
  hdr ← fmt.Section (L "report.debug_title")
  txt ← hdr∾(@+10)∾"status: partial/src_next"∾(@+10)∾cube.VerifyNumeric ⟨ctx.cube, ctx.resolved.account_keys⟩
  ⟨"debug", txt⟩
}

# BuildSectionEntries returns ⟨⟨key,full_text⟩,...⟩ for all report sections.
# The key is the canonical section name used by UI tools.
# The full_text is what would be printed for that section.
# Outlook O is supplied explicitly and does not redefine other consumers.
BuildSectionEntries ← {
  ctx ← 0 ⊑ 𝕩
  outlook_as_of ← 1 ⊑ 𝕩
  report_today ← 2 ⊑ 𝕩
  base ← 3 ⊑ 𝕩
  exp ← expense_breakdown.Build ctx
  tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩
  vm ← envelope_computation.Build ctx

  builder_entries ← ⟨
    BuildSnapshotEntry ctx
    BuildIssuesEntry ctx
    BuildYtdEntry ctx
    BuildBalancesEntry ⟨base, ctx⟩
    BuildCycleEntry ⟨ctx, exp⟩
    BuildTrialBalanceEntry ⟨ctx, tb⟩
    BuildEnvelopesEntry ⟨ctx, vm⟩
    BuildPlannedEntry ctx
    BuildRecentEntry ctx
    BuildCheckEntry ctx
    BuildOutlookEntry ⟨ctx, outlook_as_of⟩
    BuildDailyTrendEntry ⟨ctx, report_today⟩
    BuildDailyFlowEntry ctx
    BuildActualComparisonEntry ⟨ctx, report_today⟩
    BuildDebugEntry ctx
  ⟩
  OrderBuilderEntries builder_entries
}

# BuildSelectedHumanSection evaluates only the single requested human section
# and its required precomputations. Returns ⟨1, ⟨key, text⟩⟩ if found, or ⟨0, ⟨"", ""⟩⟩ if unknown key.
BuildSelectedHumanSection ← {
  ctx ← 0 ⊑ 𝕩
  section_key ← 1 ⊑ 𝕩
  outlook_as_of ← 2 ⊑ 𝕩
  report_today ← 3 ⊑ 𝕩

  selected_builder_entries ← ⟨
    ⟨"snapshot", { 𝕩: BuildSnapshotEntry ctx }⟩
    ⟨"issues", { 𝕩: BuildIssuesEntry ctx }⟩
    ⟨"ytd", { 𝕩: BuildYtdEntry ctx }⟩
    ⟨"balances", { 𝕩:
      •Out "ERROR: unreachable balances selected handler reached"
      •Exit 1
    }⟩
    ⟨"cycle", { 𝕩: BuildCycleEntry ⟨ctx, expense_breakdown.Build ctx⟩ }⟩
    ⟨"trial-balance", { 𝕩: BuildTrialBalanceEntry ⟨ctx, trial_balance.Build ⟨ctx, cube.layer_actual⟩⟩ }⟩
    ⟨"envelopes", { 𝕩: BuildEnvelopesEntry ⟨ctx, envelope_computation.Build ctx⟩ }⟩
    ⟨"planned", { 𝕩: BuildPlannedEntry ctx }⟩
    ⟨"recent", { 𝕩: BuildRecentEntry ctx }⟩
    ⟨"check", { 𝕩: BuildCheckEntry ctx }⟩
    ⟨"outlook", { 𝕩: BuildOutlookEntry ⟨ctx, outlook_as_of⟩ }⟩
    ⟨"daily-trend", { 𝕩: BuildDailyTrendEntry ⟨ctx, report_today⟩ }⟩
    ⟨"daily-flow", { 𝕩: BuildDailyFlowEntry ctx }⟩
    ⟨"actual-comparison", { 𝕩: BuildActualComparisonEntry ⟨ctx, report_today⟩ }⟩
    ⟨"debug", { 𝕩: BuildDebugEntry ctx }⟩
  ⟩
  ordered_entries ← OrderBuilderEntries selected_builder_entries

  idx ← FindSectionIndex ⟨ordered_entries, section_key⟩
  (idx ≥ ≠ordered_entries) ◶ ⟨
    { 𝕊: ⟨1, (0 ◶ ⟨ 1 ⊑ (idx ⊑ ordered_entries) ⟩) @⟩ },
    { 𝕊: ⟨0, ⟨"", ""⟩⟩ }
  ⟩ @
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
  currency_flag ← HasArg ⟨args, "--currency"⟩
  currency_val ← ArgValue ⟨args, "--currency"⟩
  currency_next_is_option ← "--" ≡ 2 ↑ currency_val
  currency_missing ← currency_flag ∧ ((0 = ≠currency_val) ∨ currency_next_is_option)

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

  {𝕊:
    •Out "ERROR: --currency requires a registry-supported code"
    •Exit 1
  }⍟currency_missing @

  {𝕊:
    •Out "ERROR: --currency is supported only with human --section balances"
    •Exit 1
  }⍟(currency_flag ∧ ((¬section_flag) ∨ list_sections ∨ write_cache_flag ∨ (section_key ≢ "balances") ∨ (format_val ≡ "json"))) @

  # M3 selected balances dispatches before the ordinary mixed-snapshot context.
  # No-override human balances resolves DEFAULT_CURRENCY through the same path.
  {𝕊:
    selected ← balances.BuildSelected ⟨base, currency_val⟩
    {𝕊:
      •Out "ERROR: " ∾ selected.message
      •Exit 1
    }⍟(selected.state ≢ "ok") @
    •Out balances.FormatSelectedHuman selected
    •Exit 0
  }⍟(section_flag ∧ (section_key ≡ "balances") ∧ (format_val ≢ "json")) @

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

  report_today ← date.Today @
  outlook_as_of ← ""
  {𝕊: outlook_as_of ↩ outlook_as_of_val}⍟outlook_as_of_flag @
  {𝕊: outlook_as_of ↩ report_today}⍟(¬ outlook_as_of_flag) @

  {𝕊:
    res ← BuildSelectedHumanSection ⟨ctx, section_key, outlook_as_of, report_today⟩
    found ← 0 ⊑ res
    {𝕊:
      entry ← 1 ⊑ res
      text ← 1 ⊑ entry
      PrintSection text
      •Exit 0
    }⍟found @
    •Out "ERROR: unknown section key: "∾section_key
    •Exit 1
  }⍟(section_flag) @

  entries ← BuildSectionEntries ⟨ctx, outlook_as_of, report_today, base⟩

  {𝕊:
    {𝕊 entry:
      key ← ⊑entry ⋄ text ← 1⊑entry
      (write_cache_dir ∾ "/" ∾ key ∾ ".txt") •FChars text
    }¨ entries
    all_text ← ∾ { (1⊑𝕩) ∾ (@+10) ∾ (@+10) }¨ entries
    (write_cache_dir ∾ "/all.txt") •FChars all_text
    key_manifest ← (∾ { (0⊑𝕩) ∾ (@+10) }¨ entries) ∾ "all" ∾ (@+10)
    (write_cache_dir ∾ "/.section-keys") •FChars key_manifest
    •Exit 0
  }⍟(write_cache_flag) @

  {𝕊:
    {𝕊 entry:
      key ← ⊑entry ⋄ text ← 1⊑entry
      •Out key∾(@+9)∾FirstLine text
    }¨ entries
  }⍟(list_sections) @

  {𝕊:
    {𝕊 entry:
      PrintSection (1⊑entry)
    }¨ entries
  }⍟((¬ list_sections) ∧ (¬ section_flag) ∧ (¬ write_cache_flag)) @
}

Main •args
