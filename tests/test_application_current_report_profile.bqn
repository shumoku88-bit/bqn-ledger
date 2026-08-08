#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
route ← •Import "../src/application/report_route.bqn"
profile ← •Import "../src/application/current_report_profile.bqn"
cycleResult ← •Import "../src/accounting/cycle_result.bqn"

planned ← route.Admit ⟨"planned","human",⟨"2000-01-01","actual.journal","ignored-plan","ignored-cycle"⟩⟩
cycleAccounts ← route.Admit ⟨"cycle-accounts","human",⟨"JPY","2000-01-01","actual.journal","ignored-cycle","ignored-plan"⟩⟩
cycleComparison ← route.Admit ⟨"cycle-comparison","human",⟨"JPY","2000-01-01","1999-12-01","aligned_elapsed","actual.journal","ignored-current","ignored-baseline","ignored-plan"⟩⟩
dailyTarget ← route.Admit ⟨"daily-target","human",⟨"JPY","2000-01-01","2000-01-20","actual.journal","ignored-plan","ignored-scope"⟩⟩
admitted ← ⟨planned,cycleAccounts,cycleComparison,dailyTarget⟩
0 lib.AssertEq ≠∾{𝕩.diagnostics}¨admitted
"aligned_elapsed" lib.AssertEq profile.ComparisonPolicy admitted

current ← cycleResult.Success ⟨"incomeAnchor","2026-03-15","2026-03-01","2026-04-01",⟨⟩,⟨⟩⟩
baseline ← cycleResult.Success ⟨"incomeAnchor","2026-02-28","2026-02-01","2026-03-01",⟨⟩,⟨⟩⟩
resolved ← profile.Build ⟨admitted,"2026-03-15",current,baseline⟩
"ok" lib.AssertEq resolved.state
4 lib.AssertEq ≠resolved.rows
0 lib.AssertEq ≠resolved.diagnostics

FindRow ← {𝕊 key:
  matches ← (key⊸≡¨{𝕩.key}¨resolved.rows)/resolved.rows
  1 lib.AssertEq ≠matches
  ⊑matches
}
⟨"2026-03-15","actual.journal","ignored-plan","ignored-cycle"⟩ lib.AssertEq (FindRow "planned").arguments
⟨"JPY","2026-03-15","actual.journal","ignored-cycle","ignored-plan"⟩ lib.AssertEq (FindRow "cycle-accounts").arguments
⟨"JPY","2026-03-15","2026-02-15","aligned_elapsed","actual.journal","ignored-current","ignored-baseline","ignored-plan"⟩ lib.AssertEq (FindRow "cycle-comparison").arguments
⟨"JPY","2026-03-15","2000-01-20","actual.journal","ignored-plan","ignored-scope"⟩ lib.AssertEq (FindRow "daily-target").arguments

shortBaseline ← cycleResult.Success ⟨"incomeAnchor","2026-03-01","2026-02-20","2026-03-01",⟨⟩,⟨⟩⟩
short ← profile.Build ⟨admitted,"2026-03-15",current,shortBaseline⟩
"error" lib.AssertEq short.state
0 lib.AssertEq ≠short.rows
lib.Assert ∨´"aligned_baseline_unavailable"⊸≡¨{𝕩.code}¨short.diagnostics

•Out "test_application_current_report_profile: ok"
