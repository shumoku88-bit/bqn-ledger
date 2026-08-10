#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
plan_status ← •Import "../src/accounting/plan_temporal_status.bqn"

as_of ← "2026-07-05"

"overdue" lib.AssertEq plan_status.Classify ⟨"2026-07-04", as_of⟩
"due" lib.AssertEq plan_status.Classify ⟨"2026-07-05", as_of⟩
"future" lib.AssertEq plan_status.Classify ⟨"2026-07-06", as_of⟩

•Out "test_accounting_plan_temporal_status: ok"
