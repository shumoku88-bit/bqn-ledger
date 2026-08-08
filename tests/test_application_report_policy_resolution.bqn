#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
resolution ← •Import "../src/application/report_policy_resolution.bqn"

policy ← {
  state⇐"ok",
  presentation⇐{negative_style⇐"minus",negative_color⇐"red",daily_flow_max_date_columns⇐5},
  reports⇐{
    trial_balance⇐{as_of⇐"latest"},
    balance_sheet⇐{as_of⇐"2026-01-12"},
    profit_and_loss⇐{from⇐"beginning",through⇐"latest"},
    daily_flow⇐{from⇐"2026-01-01",through⇐"latest",max_date_columns⇐5},
    monthly_accounts⇐{from⇐"beginning",through⇐"2026-01-12"},
    recent_transactions⇐{through⇐"latest",count⇐5}
  }
}

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

emptyBeginning ← resolution.Resolve ⟨policy,"2026-01-13",⟨"2026-02-01"⟩⟩
"ok" lib.AssertEq emptyBeginning.state
"2026-01-13" lib.AssertEq emptyBeginning.profit_and_loss.from
"2026-01-12" lib.AssertEq emptyBeginning.monthly_accounts.from

badLatest ← resolution.Resolve ⟨policy,"2026-02-30",⟨"2026-01-02"⟩⟩
"error" lib.AssertEq badLatest.state

•Out "test_application_report_policy_resolution: ok"
