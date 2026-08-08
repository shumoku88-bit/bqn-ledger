#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
source ← •Import "../src/application/report_policy_source_adapter.bqn"

policy ← source.Load "fixtures/canonical-household-v1"
"ok" lib.AssertEq policy.state
"report.toml" lib.AssertEq policy.source_name
"minus" lib.AssertEq policy.presentation.negative_style
5 lib.AssertEq policy.reports.daily_flow.max_date_columns
5 lib.AssertEq policy.reports.recent_transactions.count
0 lib.AssertEq ≠policy.diagnostics

•Out "test_application_report_policy_source: ok"
