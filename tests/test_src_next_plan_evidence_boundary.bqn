#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
plan_rows ← •Import "../src_next/plan_rows.bqn"

base ← "fixtures/src-next-plan-evidence-boundary"
cy ← { start ⇐ "2026-01-01", day_count ⇐ 7 }
view ← plan_rows.BuildBase ⟨base, cy⟩

1 lib.AssertEq ≠ view.rows
1 lib.AssertEq 0⊑view.completed_mask
"service" lib.AssertEq 0⊑view.plan_ids

•Out "test_src_next_plan_evidence_boundary.bqn: OK"
