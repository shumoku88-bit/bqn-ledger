#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
report_sections ← •Import "../src_next/report_sections.bqn"

rows ← report_sections.rows
keys ← {0⊑𝕩}¨ rows

# Independent exact contract oracle: do not derive these rows from runtime,
# metadata output, or report output.
expected_rows ← ⟨
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
expected_keys ← {0⊑𝕩}¨ expected_rows

15 lib.AssertEq ≠rows
expected_rows lib.AssertEq rows
expected_keys lib.AssertEq keys
lib.Assert ∧´ {6 = ≠𝕩}¨ rows
lib.Assert ∧´ {∧´ 0 < ≠¨𝕩}¨ rows

# Every key occurs exactly once.
lib.Assert ∧´ {1 = +´ 𝕩⊸≡¨ keys}¨ keys

# Preserve the current public metadata values without interpreting their meaning.
lib.Assert ∧´ {"yes" ≡ 4⊑𝕩}¨ rows
lib.Assert ∧´ {"metadata" ≡ 5⊑𝕩}¨ rows

# Debug remains a normal descriptor row owned by report.bqn.
debug_idx ← ⊑ (keys ⊐ ⟨"debug"⟩)
"src_next/report.bqn" lib.AssertEq 3⊑debug_idx⊑rows

•Out "test_src_next_report_sections.bqn: OK"
