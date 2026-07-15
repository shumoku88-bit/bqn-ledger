#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
report_sections ← •Import "../src_next/report_sections.bqn"

rows ← report_sections.rows
keys ← {0⊑𝕩}¨ rows
expected_keys ← ⟨
  "snapshot", "issues", "ytd", "balances", "cycle", "trial-balance",
  "envelopes", "planned", "recent", "check", "outlook", "daily-trend",
  "daily-flow", "actual-comparison", "debug"
⟩

15 lib.AssertEq ≠rows
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
