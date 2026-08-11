#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src/ledger/report_policy_admission.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Pair ← {𝕊 key‿value:key∾" = "∾Q value}

validTail ← ⟨
  "[reports.profit-and-loss]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 5"
⟩

# Physical source ownership is section-segmented. A key before any header is
# outside; an unsupported header resets ownership; keys under it remain outside;
# the next known header starts a new admitted block. Row-local diagnostics stay
# in physical source order.
mixedLines ← ⟨
  Pair ⟨"orphan","value"⟩,
  "[reports.trial-balance]",
  Pair ⟨"as-of","latest"⟩,
  "[unsupported.section]",
  Pair ⟨"ghost","value"⟩,
  "[reports.balance-sheet]",
  "broken row",
  Pair ⟨"as-of","latest"⟩,""
⟩∾validTail
mixed ← admission.Admit Raw mixedLines
"error" lib.AssertEq mixed.state
⟨
  "report_policy_key_outside_section",
  "report_policy_section_unsupported",
  "report_policy_key_outside_section",
  "report_policy_key_shape_invalid"
⟩ lib.AssertEq {𝕩.code}¨mixed.diagnostics
⟨1,4,5,7⟩ lib.AssertEq {𝕩.line}¨mixed.diagnostics

# Ignored rows do not participate in section ownership or key parsing.
ignoredLines ← ⟨
  "# before first section",
  "",
  "[reports.trial-balance]",
  "  # inside trial balance",
  Pair ⟨"as-of","latest"⟩,"",
  "[reports.balance-sheet]",
  Pair ⟨"as-of","latest"⟩,""
⟩∾validTail
ignored ← admission.Admit Raw ignoredLines
"ok" lib.AssertEq ignored.state
0 lib.AssertEq ≠ignored.diagnostics
"latest" lib.AssertEq ignored.reports.trial_balance.as_of
"latest" lib.AssertEq ignored.reports.balance_sheet.as_of

•Out "test_ledger_report_policy_section_relations: ok"
