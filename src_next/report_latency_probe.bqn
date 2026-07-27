# report_latency_probe.bqn — timing probe for latency characterization
# Usage: bqn src_next/report_latency_probe.bqn <baseDir>

t_start ← •MonoTime @

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

t_imports ← •MonoTime @

Main ← {𝕊 args:
  base ← ⊑ args
  fmt.SetColorEnabled 0

  t_ctx0 ← •MonoTime @
  ctx ← ctx_mod.BuildContext base
  t_ctx1 ← •MonoTime @

  report_today ← date.Today @
  outlook_as_of ← report_today

  # Shared precomputations
  t_exp0 ← •MonoTime @
  exp ← expense_breakdown.Build ctx
  t_exp1 ← •MonoTime @

  t_tb0 ← •MonoTime @
  tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩
  t_tb1 ← •MonoTime @

  t_vm0 ← •MonoTime @
  vm ← envelope_computation.Build ctx
  t_vm1 ← •MonoTime @

  # Helper to time a section builder
  _TimeFn ← {
    t0 ← •MonoTime @
    res ← 𝔽 @
    t1 ← •MonoTime @
    ⟨res, t1 - t0⟩
  }

  t_builders0 ← •MonoTime @
  res_snapshot ← ({𝕩 ⋄ snapshot.FormatHuman snapshot.Build ctx} _TimeFn @)
  res_issues ← ({𝕩 ⋄ issues.FormatHuman ctx} _TimeFn @)
  res_ytd ← ({𝕩 ⋄ ytd_summary.FormatHuman ytd_summary.Build ctx} _TimeFn @)
  res_balances ← ({𝕩 ⋄ balances.FormatHuman balances.Build ctx} _TimeFn @)
  res_cycle ← ({𝕩 ⋄ cycle_summary.FormatHuman ⟨cycle_summary.Build ctx, exp.entries⟩} _TimeFn @)
  res_tb ← ({𝕩 ⋄ trial_balance.FormatHuman tb} _TimeFn @)
  res_envelopes ← ({
    txt ← envelope_computation.FormatHuman vm
    (0=≠txt) ◶ ⟨{txt}, { (L "report.envelope_section_title") ∾ (@+10) ∾ "status: " ∾ vm.status ∾ (@+10) ∾ (L "report.envelope_guard_note") ∾ (@+10) }⟩ @
  }⍟(vm.status ≢ "disabled") _TimeFn @)
  res_planned ← ({𝕩 ⋄ planned_payments.FormatHuman ctx} _TimeFn @)
  res_recent ← ({𝕩 ⋄ recent_journal.FormatHuman ⟨ctx, 10⟩} _TimeFn @)
  res_check ← ({𝕩 ⋄ readiness_check.FormatHuman ctx} _TimeFn @)
  res_outlook ← ({𝕩 ⋄ outlook.FormatHuman outlook.BuildAt ⟨ctx, outlook_as_of⟩} _TimeFn @)
  res_daily_trend ← ({𝕩 ⋄ daily_trend.FormatHuman daily_trend.BuildAt ⟨ctx, report_today⟩} _TimeFn @)
  res_daily_flow ← ({𝕩 ⋄ daily_flow.FormatHuman daily_flow.Build ctx} _TimeFn @)
  res_actual_comp ← ({𝕩 ⋄ actual_comparison.FormatHuman actual_comparison.BuildAt ⟨ctx, report_today⟩} _TimeFn @)
  res_debug ← fmt.Section (L "report.debug_title") ∾ (@+10) ∾ "status: partial/src_next" ∾ (@+10) ∾ cube.VerifyNumeric ⟨ctx.cube, ctx.resolved.account_keys⟩
  t_builders1 ← •MonoTime @

  sec_list ← ⟨
    ⟨"snapshot", 0⊑res_snapshot, 1⊑res_snapshot⟩
    ⟨"issues", 0⊑res_issues, 1⊑res_issues⟩
    ⟨"ytd", 0⊑res_ytd, 1⊑res_ytd⟩
    ⟨"balances", 0⊑res_balances, 1⊑res_balances⟩
    ⟨"cycle", 0⊑res_cycle, 1⊑res_cycle⟩
    ⟨"trial-balance", 0⊑res_tb, 1⊑res_tb⟩
    ⟨"envelopes", 0⊑res_envelopes, 1⊑res_envelopes⟩
    ⟨"planned", 0⊑res_planned, 1⊑res_planned⟩
    ⟨"recent", 0⊑res_recent, 1⊑res_recent⟩
    ⟨"check", 0⊑res_check, 1⊑res_check⟩
    ⟨"outlook", 0⊑res_outlook, 1⊑res_outlook⟩
    ⟨"daily-trend", 0⊑res_daily_trend, 1⊑res_daily_trend⟩
    ⟨"daily-flow", 0⊑res_daily_flow, 1⊑res_daily_flow⟩
    ⟨"actual-comparison", 0⊑res_actual_comp, 1⊑res_actual_comp⟩
    ⟨"debug", res_debug, 0⟩
  ⟩

  # Time cache writes
  tmp_dir ← "/tmp/probe_cache_test"
  t_w0 ← •MonoTime @
  {𝕊 item:
    key ← 0⊑item ⋄ text ← 1⊑item
    (tmp_dir ∾ "_" ∾ key ∾ ".txt") •FChars text
  }¨ sec_list
  t_w1 ← •MonoTime @

  t_end ← •MonoTime @

  # Format report output of timings (in milliseconds, rounded to 3 decimal places)
  Ms ← {𝕊 sec: •Fmt (⌊ 0.5 + 1000000 × sec) ÷ 1000 }

  •Out "--- TIMING PROBE REPORT ---"
  •Out "Import_ms: " ∾ Ms (t_imports - t_start)
  •Out "BuildContext_ms: " ∾ Ms (t_ctx1 - t_ctx0)
  •Out "Precompute_expense_breakdown_ms: " ∾ Ms (t_exp1 - t_exp0)
  •Out "Precompute_trial_balance_ms: " ∾ Ms (t_tb1 - t_tb0)
  •Out "Precompute_envelope_computation_ms: " ∾ Ms (t_vm1 - t_vm0)
  •Out "All_section_builders_total_ms: " ∾ Ms (t_builders1 - t_builders0)
  •Out "Section_write_cache_ms: " ∾ Ms (t_w1 - t_w0)
  •Out "Total_probe_ms: " ∾ Ms (t_end - t_start)
  •Out "--- SECTION BUILDER TIMINGS (ms) ---"
  {𝕊 item:
    key ← 0⊑item ⋄ ms ← Ms (2⊑item)
    •Out key ∾ ": " ∾ ms
  }¨ sec_list

  # Count statistics
  •Out "--- DATA SCALE STATISTICS ---"
  •Out "Posting_rows_count: " ∾ •Fmt ≠ctx.posting_rows
  •Out "Actual_transactions_count: " ∾ •Fmt ≠ctx.actual_transactions
  •Out "Account_keys_count: " ∾ •Fmt ≠ctx.resolved.account_keys
}

Main •args
