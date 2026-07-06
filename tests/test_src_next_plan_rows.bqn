#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cycle ← •Import "../src_next/cycle.bqn"
plan_rows ← •Import "../src_next/plan_rows.bqn"

base ← "fixtures/src-next-execution-plan-coverage"
cy ← cycle.ReadCycle base

shared ← plan_rows.BuildBase ⟨base, cy⟩

3 lib.AssertEq ≠ shared.rows
"paid-fixed" lib.AssertEq 0⊑shared.plan_ids
"wifi" lib.AssertEq 1⊑shared.plan_ids
"povo" lib.AssertEq 2⊑shared.plan_ids

1 lib.AssertEq 0⊑shared.completed_mask
0 lib.AssertEq 1⊑shared.completed_mask
0 lib.AssertEq 2⊑shared.completed_mask

100 lib.AssertEq 0⊑shared.actuals
0 lib.AssertEq 1⊑shared.actuals
0 lib.AssertEq 2⊑shared.actuals

# Temporal meaning is attached from one explicit caller-owned as_of.
temporal ← plan_rows.WithTemporal ⟨shared, "2026-01-05"⟩
"completed" lib.AssertEq 0⊑temporal.temporal_statuses
"due" lib.AssertEq 1⊑temporal.temporal_statuses
"future" lib.AssertEq 2⊑temporal.temporal_statuses

# Preserve legacy five-field fallback identity when plan_id metadata is absent.
tab ← @+9
legacy_line ← "2026-01-05" ∾ tab ∾ "wifi" ∾ tab ∾ "assets:cash" ∾ tab ∾ "expenses:fixed" ∾ tab ∾ "3000"
"2026-01-05wifiassets:cashexpenses:fixed3000" lib.AssertEq plan_rows.PlanId legacy_line

•Out "test_src_next_plan_rows.bqn: OK"
