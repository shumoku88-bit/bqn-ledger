#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
plan_rows ← •Import "../src_next/plan_rows.bqn"

base ← "fixtures/src-next-plan-evidence-boundary"
cy ← { start ⇐ "2026-01-01", day_count ⇐ 7 }
completion ← ⟨{date⇐"2026-01-03",plan_id⇐"service",amount⇐1,from_account⇐"assets:cash",to_account⇐"expenses:fixed",currency⇐"JPY"}⟩
view ← plan_rows.BuildBaseFromCompletionEvidence ⟨base, cy, completion⟩

1 lib.AssertEq ≠ view.rows
1 lib.AssertEq 0⊑view.completed_mask
"service" lib.AssertEq 0⊑view.plan_ids

•Out "test_src_next_plan_rows_base_boundary.bqn: OK"
