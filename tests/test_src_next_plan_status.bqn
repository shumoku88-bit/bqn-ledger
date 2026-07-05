#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
plan_status ← •Import "../src_next/plan_status.bqn"

as_of ← "2026-07-05"

"overdue" lib.AssertEq plan_status.Classify ⟨0, "2026-07-04", as_of⟩
"due" lib.AssertEq plan_status.Classify ⟨0, "2026-07-05", as_of⟩
"future" lib.AssertEq plan_status.Classify ⟨0, "2026-07-06", as_of⟩

# Completion evidence wins over temporal relation.
"completed" lib.AssertEq plan_status.Classify ⟨1, "2026-07-04", as_of⟩
"completed" lib.AssertEq plan_status.Classify ⟨1, "2026-07-05", as_of⟩
"completed" lib.AssertEq plan_status.Classify ⟨1, "2026-07-06", as_of⟩

•Out "test_src_next_plan_status.bqn: OK"
