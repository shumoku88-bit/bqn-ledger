# summary.bqn — compact src_next summary for machine-readable output
#
# Builds a unified context once, then delegates to each report section.
# Full diagnostic output: tools/report-next
#
# Usage:
#   bqn src_next/summary.bqn data
#   bqn src_next/summary.bqn fixtures/src-next-golden
#   tools/report-next-summary
#   tools/report-next-summary fixtures/src-next-golden
#
# This is the production machine-readable summary surface.
# Human-readable daily report: tools/report (src_next/report.bqn)

ctx_mod ← •Import "context.bqn"
cube ← •Import "cube.bqn"
cycle ← •Import "cycle.bqn"
cycle_summary ← •Import "cycle_summary.bqn"
ytd_summary ← •Import "ytd_summary.bqn"
expense_breakdown ← •Import "expense_breakdown.bqn"
recent_journal ← •Import "recent_journal.bqn"
planned_payments ← •Import "planned_payments.bqn"
balances ← •Import "balances.bqn"
readiness_check ← •Import "readiness_check.bqn"
actual_comparison ← •Import "actual_comparison.bqn"
household_metadata ← •Import "household_metadata.bqn"
plan_journal_overlap ← •Import "plan_journal_overlap.bqn"
envelope_computation ← •Import "envelope_computation.bqn"
snapshot ← •Import "snapshot.bqn"
tbds ← •Import "tbds.bqn"
trial_balance ← •Import "trial_balance.bqn"
outlook ← •Import "outlook.bqn"
daily_trend ← •Import "daily_trend.bqn"

# ── Main ─────────────────────────────────────────────────────

Main ← {𝕊 base:
  ctx ← ctx_mod.BuildContext base

  # Snapshot
  •Out snapshot.Format (snapshot.Build ctx)
  •Out ""
  •Out cycle.FormatCycleInfo ctx.cy
  •Out ""
  •Out cube.FormatMinimalReportSummary ⟨ctx.cube, ctx.resolved.account_keys, ctx.cy.start, ctx.cy.end_exclusive⟩
  •Out ""
  •Out tbds.Format ctx.tbds
  •Out ""
  •Out trial_balance.Format (trial_balance.Build ⟨ctx, cube.layer_actual⟩)
  •Out ""
  •Out cycle_summary.Format (cycle_summary.Build ctx)
  •Out ""
  •Out ytd_summary.Format (ytd_summary.Build ctx)
  •Out ""
  •Out expense_breakdown.Format (expense_breakdown.Build ctx)
  •Out ""
  •Out recent_journal.Format ⟨ctx, 10⟩
  •Out ""
  •Out planned_payments.Format ctx
  •Out ""
  •Out balances.Format (balances.Build ctx)
  •Out ""
  •Out readiness_check.Format (readiness_check.Build ctx)
  •Out ""
  •Out plan_journal_overlap.Format (plan_journal_overlap.Build ctx)
  •Out ""
  •Out envelope_computation.Format (envelope_computation.Build ctx)
  •Out ""
  hm ← household_metadata.Build ctx
  hm_text ← household_metadata.Format hm
  {𝕊: •Out hm_text }⍟(0 < ≠ hm_text) @
  {𝕊: •Out "" }⍟(0 < ≠ hm_text) @
  •Out outlook.Format (outlook.Build ctx)
  •Out ""
  •Out daily_trend.Format (daily_trend.Build ctx)
  •Out ""
  •Out actual_comparison.Format (actual_comparison.Build ctx)
}

Main ⊑•args
