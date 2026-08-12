#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
admission ← •Import "../src/ledger/report_policy_admission.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
Pair ← {𝕊 key‿value:key∾" = "∾Q value}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}

RequiredReports ← ⟨
  "[reports.trial-balance]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.balance-sheet]",Pair ⟨"as-of","latest"⟩,"",
  "[reports.profit-and-loss]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.daily-flow]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.monthly-accounts]",Pair ⟨"from","beginning"⟩,Pair ⟨"through","latest"⟩,"",
  "[reports.recent-transactions]",Pair ⟨"through","latest"⟩,"count = 5"
⟩

withoutCalendar ← admission.Admit Raw RequiredReports
"ok" lib.AssertEq withoutCalendar.state
"*" lib.AssertEq withoutCalendar.presentation.calendar.cycle_end_marker
"$" lib.AssertEq withoutCalendar.presentation.calendar.plan_due_marker
"!" lib.AssertEq withoutCalendar.presentation.calendar.issue_due_marker
"+" lib.AssertEq withoutCalendar.presentation.calendar.multiple_marker

custom ← admission.Admit Raw ⟨
  "[presentation.calendar]",
  Pair ⟨"cycle-end-marker","#"⟩,
  Pair ⟨"plan-due-marker","$"⟩,
  Pair ⟨"issue-due-marker","!"⟩,
  Pair ⟨"multiple-marker","+"⟩,
  ""
⟩∾RequiredReports
"ok" lib.AssertEq custom.state
"#" lib.AssertEq custom.presentation.calendar.cycle_end_marker
"$" lib.AssertEq custom.presentation.calendar.plan_due_marker
"!" lib.AssertEq custom.presentation.calendar.issue_due_marker
"+" lib.AssertEq custom.presentation.calendar.multiple_marker

multiCharacter ← admission.Admit Raw ⟨
  "[presentation.calendar]",Pair ⟨"cycle-end-marker","**"⟩,""
⟩∾RequiredReports
"error" lib.AssertEq multiCharacter.state
lib.Assert HasCode ⟨"report_policy_calendar_marker_invalid",multiCharacter.diagnostics⟩

wideCharacter ← admission.Admit Raw ⟨
  "[presentation.calendar]",Pair ⟨"issue-due-marker","◇"⟩,""
⟩∾RequiredReports
"error" lib.AssertEq wideCharacter.state
lib.Assert HasCode ⟨"report_policy_calendar_marker_invalid",wideCharacter.diagnostics⟩

unsupportedKey ← admission.Admit Raw ⟨
  "[presentation.calendar]",Pair ⟨"today-marker","@"⟩,""
⟩∾RequiredReports
"error" lib.AssertEq unsupportedKey.state
lib.Assert HasCode ⟨"report_policy_key_unsupported",unsupportedKey.diagnostics⟩

•Out "test_ledger_report_policy_calendar: ok"
