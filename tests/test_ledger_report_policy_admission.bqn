#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src/ledger/report_policy_admission.bqn"
io ← •Import "../src/application/source_io.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Pair ← {𝕊 key‿value:key∾" = "∾Q value}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}

valid ← admission.Admit io.ReadRaw "fixtures/canonical-household-v1/report.toml"
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
"report.toml" lib.AssertEq valid.source_name
"minus" lib.AssertEq valid.presentation.negative_style
"red" lib.AssertEq valid.presentation.negative_color
5 lib.AssertEq valid.presentation.daily_flow_max_date_columns
"latest" lib.AssertEq valid.reports.trial_balance.as_of
"latest" lib.AssertEq valid.reports.balance_sheet.as_of
"2026-01-01" lib.AssertEq valid.reports.profit_and_loss.from
"latest" lib.AssertEq valid.reports.profit_and_loss.through
"2026-01-01" lib.AssertEq valid.reports.daily_flow.from
"latest" lib.AssertEq valid.reports.daily_flow.through
5 lib.AssertEq valid.reports.daily_flow.max_date_columns
"2026-01-01" lib.AssertEq valid.reports.monthly_accounts.from
"latest" lib.AssertEq valid.reports.monthly_accounts.through
"latest" lib.AssertEq valid.reports.recent_transactions.through
5 lib.AssertEq valid.reports.recent_transactions.count

withoutPresentation ← admission.Admit Raw ⟨
  "[reports.trial-balance]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 7"
⟩
"ok" lib.AssertEq withoutPresentation.state
"parentheses" lib.AssertEq withoutPresentation.presentation.negative_style
"red" lib.AssertEq withoutPresentation.presentation.negative_color
14 lib.AssertEq withoutPresentation.presentation.daily_flow_max_date_columns
7 lib.AssertEq withoutPresentation.reports.recent_transactions.count

sourceFilename ← admission.Admit Raw ⟨
  "[presentation.amounts]",Pair ⟨"negative-style","minus"⟩,"",
  "[reports.trial-balance]",Pair ⟨"as-of","latest"⟩,Pair ⟨"source","actual.journal"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","2026-01-01"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","2026-01-01"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","2026-01-01"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 5"
⟩
"error" lib.AssertEq sourceFilename.state
lib.Assert HasCode ⟨"report_policy_key_unsupported",sourceFilename.diagnostics⟩

invalidDate ← admission.Admit Raw ⟨
  "[reports.trial-balance]",Pair ⟨"as-of","2026-02-30"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 5"
⟩
"error" lib.AssertEq invalidDate.state
lib.Assert HasCode ⟨"report_policy_date_reference_invalid",invalidDate.diagnostics⟩

reversedRange ← admission.Admit Raw ⟨
  "[reports.trial-balance]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","2026-02-01"⟩,Pair ⟨"through","2026-01-01"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 5"
⟩
"error" lib.AssertEq reversedRange.state
lib.Assert HasCode ⟨"report_policy_range_invalid",reversedRange.diagnostics⟩

zeroCount ← admission.Admit Raw ⟨
  "[reports.trial-balance]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"max-date-columns = 0","",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 0"
⟩
"error" lib.AssertEq zeroCount.state
lib.Assert HasCode ⟨"report_policy_positive_integer_invalid",zeroCount.diagnostics⟩

•Out "test_ledger_report_policy_admission: ok"
