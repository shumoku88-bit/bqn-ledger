#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
resolution ← •Import "../src/application/report_policy_resolution.bqn"

policy ← {
  state⇐"ok",
  presentation⇐{negative_style⇐"minus",negative_color⇐"red",daily_flow_max_date_columns⇐5},
  reports⇐{
    trial_balance⇐{as_of⇐"latest"},
    balance_sheet⇐{as_of⇐"2026-01-12"},
    profit_and_loss⇐{range_kind⇐"explicit",from⇐"beginning",through⇐"latest"},
    daily_flow⇐{range_kind⇐"explicit",from⇐"2026-01-01",through⇐"latest",max_date_columns⇐5},
    monthly_accounts⇐{from⇐"beginning",through⇐"2026-01-12"},
    recent_transactions⇐{through⇐"latest",count⇐5}
  }
}
Codes ← {𝕊 diagnostics:{𝕩.code}¨diagnostics}
Messages ← {𝕊 diagnostics:{𝕩.message}¨diagnostics}

resolved ← resolution.Resolve ⟨policy,"2026-01-13",⟨"2026-01-10","2026-01-02","2026-02-01"⟩⟩
"ok" lib.AssertEq resolved.state
0 lib.AssertEq ≠resolved.diagnostics
"2026-01-13" lib.AssertEq resolved.trial_balance.as_of
"2026-01-12" lib.AssertEq resolved.balance_sheet.as_of
"2026-01-02" lib.AssertEq resolved.profit_and_loss.from
"2026-01-13" lib.AssertEq resolved.profit_and_loss.through
"2026-01-01" lib.AssertEq resolved.daily_flow.from
"2026-01-13" lib.AssertEq resolved.daily_flow.through
5 lib.AssertEq resolved.daily_flow.max_date_columns
"2026-01-02" lib.AssertEq resolved.monthly_accounts.from
"2026-01-12" lib.AssertEq resolved.monthly_accounts.through
"2026-01-13" lib.AssertEq resolved.recent_transactions.through
5 lib.AssertEq resolved.recent_transactions.count
"minus" lib.AssertEq resolved.presentation.negative_style
0 lib.AssertEq resolution.NeedsCurrentCycle policy

symbolicPolicy ← {
  state⇐"ok",presentation⇐policy.presentation,
  reports⇐{
    trial_balance⇐policy.reports.trial_balance,
    balance_sheet⇐policy.reports.balance_sheet,
    profit_and_loss⇐{range_kind⇐"current-cycle-to-date",from⇐"",through⇐""},
    daily_flow⇐{range_kind⇐"current-cycle-to-date",from⇐"",through⇐"",max_date_columns⇐5},
    monthly_accounts⇐policy.reports.monthly_accounts,
    recent_transactions⇐policy.reports.recent_transactions
  }
}
currentCycle ← {state⇐"ok",start⇐"2026-01-05",end_exclusive⇐"2026-01-20"}
1 lib.AssertEq resolution.NeedsCurrentCycle symbolicPolicy
missingCycle ← resolution.Resolve ⟨symbolicPolicy,"2026-01-13",⟨"2026-01-02"⟩⟩
"error" lib.AssertEq missingCycle.state
⟨"report_current_cycle_context_required"⟩ lib.AssertEq Codes missingCycle.diagnostics
symbolicResolved ← resolution.ResolveWithCurrentCycle ⟨symbolicPolicy,"2026-01-13",⟨"2026-01-02"⟩,currentCycle⟩
"ok" lib.AssertEq symbolicResolved.state
"2026-01-05" lib.AssertEq symbolicResolved.profit_and_loss.from
"2026-01-13" lib.AssertEq symbolicResolved.profit_and_loss.through
"2026-01-05" lib.AssertEq symbolicResolved.daily_flow.from
"2026-01-13" lib.AssertEq symbolicResolved.daily_flow.through
outsideCycle ← resolution.ResolveWithCurrentCycle ⟨symbolicPolicy,"2026-01-20",⟨"2026-01-02"⟩,currentCycle⟩
"error" lib.AssertEq outsideCycle.state
⟨"report_current_cycle_observation_outside_period"⟩ lib.AssertEq Codes outsideCycle.diagnostics

emptyBeginning ← resolution.Resolve ⟨policy,"2026-01-13",⟨"2026-02-01"⟩⟩
"ok" lib.AssertEq emptyBeginning.state
"2026-01-13" lib.AssertEq emptyBeginning.profit_and_loss.from
"2026-01-12" lib.AssertEq emptyBeginning.monthly_accounts.from

badLatest ← resolution.Resolve ⟨policy,"2026-02-30",⟨"2026-01-02"⟩⟩
"error" lib.AssertEq badLatest.state

badPolicy ← {state⇐"error",presentation⇐policy.presentation,reports⇐policy.reports}
inputErrors ← resolution.Resolve ⟨badPolicy,"2026-02-30",⟨"2026-13-01","2026-01-02","bad"⟩⟩
"error" lib.AssertEq inputErrors.state
⟨"report_policy_not_ok","report_latest_invalid","report_journal_date_invalid","report_journal_date_invalid"⟩ lib.AssertEq Codes inputErrors.diagnostics
"" lib.AssertEq inputErrors.trial_balance.as_of
"" lib.AssertEq inputErrors.balance_sheet.as_of
"" lib.AssertEq inputErrors.profit_and_loss.from
"" lib.AssertEq inputErrors.profit_and_loss.through
"" lib.AssertEq inputErrors.daily_flow.from
"" lib.AssertEq inputErrors.daily_flow.through
"" lib.AssertEq inputErrors.monthly_accounts.from
"" lib.AssertEq inputErrors.monthly_accounts.through
"" lib.AssertEq inputErrors.recent_transactions.through
0 lib.AssertEq inputErrors.recent_transactions.count
5 lib.AssertEq inputErrors.daily_flow.max_date_columns

reversedPolicy ← {
  state⇐"ok",presentation⇐policy.presentation,
  reports⇐{
    trial_balance⇐policy.reports.trial_balance,
    balance_sheet⇐policy.reports.balance_sheet,
    profit_and_loss⇐{range_kind⇐"explicit",from⇐"2026-02-01",through⇐"latest"},
    daily_flow⇐{range_kind⇐"explicit",from⇐"2026-02-02",through⇐"latest",max_date_columns⇐5},
    monthly_accounts⇐{from⇐"2026-02-03",through⇐"latest"},
    recent_transactions⇐policy.reports.recent_transactions
  }
}
reversed ← resolution.Resolve ⟨reversedPolicy,"2026-01-13",⟨"2026-01-02"⟩⟩
"error" lib.AssertEq reversed.state
3 lib.AssertEq ≠reversed.diagnostics
⟨"report_range_invalid","report_range_invalid","report_range_invalid"⟩ lib.AssertEq Codes reversed.diagnostics
⟨
  "profit-and-loss start must not be after its through date",
  "daily-flow start must not be after its through date",
  "monthly-accounts start must not be after its through date"
⟩ lib.AssertEq Messages reversed.diagnostics
"2026-02-01" lib.AssertEq reversed.profit_and_loss.from
"2026-01-13" lib.AssertEq reversed.profit_and_loss.through
"2026-02-02" lib.AssertEq reversed.daily_flow.from
"2026-01-13" lib.AssertEq reversed.daily_flow.through
"2026-02-03" lib.AssertEq reversed.monthly_accounts.from
"2026-01-13" lib.AssertEq reversed.monthly_accounts.through

•Out "test_application_report_policy_resolution: ok"
