# report_sections.bqn — pure static report section descriptors
#
# Row shape:
#   key, label_spec, category, owner_path, human_output, structured_output
#
# Row order is the canonical human report section order. This module performs
# no I/O and owns no builders, formatters, ViewModels, CLI, config, or clock.

rows ← ⟨
  ⟨"snapshot", "snapshot.section_title", "overview", "src_next/snapshot.bqn", "yes", "metadata"⟩
  ⟨"issues", "report.issues_title", "operations", "src_next/issues.bqn", "yes", "metadata"⟩
  ⟨"ytd", "ytd.section_title", "accounting", "src_next/ytd_summary.bqn", "yes", "metadata"⟩
  ⟨"balances", "balances.section_title", "accounting", "src_next/balances.bqn", "yes", "metadata"⟩
  ⟨"cycle", "cycle.section_title", "household", "src_next/cycle_summary.bqn", "yes", "metadata"⟩
  ⟨"trial-balance", "trial_balance.actual", "accounting", "src_next/trial_balance.bqn", "yes", "metadata"⟩
  ⟨"envelopes", "report.envelope_section_title", "household", "src_next/envelope_computation.bqn", "yes", "metadata"⟩
  ⟨"planned", "planned.section_title", "operations", "src_next/planned_payments.bqn", "yes", "metadata"⟩
  ⟨"recent", "recent.section_title", "operations", "src_next/recent_journal.bqn", "yes", "metadata"⟩
  ⟨"check", "readiness.section_title", "diagnostics", "src_next/readiness_check.bqn", "yes", "metadata"⟩
  ⟨"outlook", "outlook.section_title", "household", "src_next/outlook.bqn", "yes", "metadata"⟩
  ⟨"daily-trend", "daily.section_title", "household", "src_next/daily_trend.bqn", "yes", "metadata"⟩
  ⟨"daily-flow", "literal:== Daily Flow ==", "household", "src_next/daily_flow.bqn", "yes", "metadata"⟩
  ⟨"actual-comparison", "actual.section_title", "household", "src_next/actual_comparison.bqn", "yes", "metadata"⟩
  ⟨"debug", "report.debug_title", "diagnostics", "src_next/report.bqn", "yes", "metadata"⟩
⟩

{ rows ⇐ rows }
