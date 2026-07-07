#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
outlook ← •Import "../src_next/outlook.bqn"

before_base ← "fixtures/src-next-daily-trend-stability-before"
after_base ← "fixtures/src-next-daily-trend-stability-after"

# A. Move explicit Outlook observation O while recorded frontier L stays fixed.
ctx ← ctx_mod.BuildContext before_base
early_vm ← outlook.BuildAt ⟨ctx, "2026-01-03"⟩
late_vm ← outlook.BuildAt ⟨ctx, "2026-01-06"⟩

"2026-01-03" lib.AssertEq early_vm.as_of
"2026-01-06" lib.AssertEq late_vm.as_of
"2026-01-03" lib.AssertEq early_vm.last_recorded_on
"2026-01-03" lib.AssertEq late_vm.last_recorded_on
"2026-01-03" lib.AssertEq early_vm.last_journal
"2026-01-03" lib.AssertEq late_vm.last_journal

"at_observation" lib.AssertEq early_vm.record_frontier_relation
0 lib.AssertEq early_vm.record_frontier_distance_days
0 lib.AssertEq early_vm.journal_lag

"before_observation" lib.AssertEq late_vm.record_frontier_relation
3 lib.AssertEq late_vm.record_frontier_distance_days
3 lib.AssertEq late_vm.journal_lag

# O-relative terms follow explicit O.
8 lib.AssertEq early_vm.days_left
5 lib.AssertEq late_vm.days_left
100 lib.AssertEq early_vm.liq_total
100 lib.AssertEq late_vm.liq_total
900 lib.AssertEq early_vm.planned_future_income
0 lib.AssertEq late_vm.planned_future_income
125 lib.AssertEq early_vm.liq_daily
20 lib.AssertEq late_vm.liq_daily
12 lib.AssertEq early_vm.liq_safe_daily
20 lib.AssertEq late_vm.liq_safe_daily

# B. Hold explicit O fixed while a later unrelated Event advances L.
observation ← "2026-01-03"
before_ctx ← ctx_mod.BuildContext before_base
after_ctx ← ctx_mod.BuildContext after_base
before_vm ← outlook.BuildAt ⟨before_ctx, observation⟩
after_vm ← outlook.BuildAt ⟨after_ctx, observation⟩

observation lib.AssertEq before_vm.as_of
observation lib.AssertEq after_vm.as_of
"2026-01-03" lib.AssertEq before_vm.last_recorded_on
"2026-01-06" lib.AssertEq after_vm.last_recorded_on

"at_observation" lib.AssertEq before_vm.record_frontier_relation
0 lib.AssertEq before_vm.record_frontier_distance_days
0 lib.AssertEq before_vm.journal_lag

"after_observation" lib.AssertEq after_vm.record_frontier_relation
3 lib.AssertEq after_vm.record_frontier_distance_days
0 lib.AssertEq after_vm.journal_lag

# The later Event is unrelated to liquid cash and lies after explicit O. O-shaped
# results therefore stay tied to O instead of following moved local L.
8 lib.AssertEq before_vm.days_left
8 lib.AssertEq after_vm.days_left
100 lib.AssertEq before_vm.liq_total
100 lib.AssertEq after_vm.liq_total
900 lib.AssertEq before_vm.planned_future_income
900 lib.AssertEq after_vm.planned_future_income
125 lib.AssertEq before_vm.liq_daily
125 lib.AssertEq after_vm.liq_daily
12 lib.AssertEq before_vm.liq_safe_daily
12 lib.AssertEq after_vm.liq_safe_daily

# C. No recorded actual frontier is explicit unavailable evidence on BuildAt.
empty_ctx ← ctx_mod.BuildContext "fixtures/src-next-empty-projection"
empty_vm ← outlook.BuildAt ⟨empty_ctx, "2026-06-18"⟩

"2026-06-18" lib.AssertEq empty_vm.as_of
"unavailable" lib.AssertEq empty_vm.last_recorded_on
"unavailable" lib.AssertEq empty_vm.last_journal
"unavailable" lib.AssertEq empty_vm.record_frontier_relation
"unavailable" lib.AssertEq empty_vm.record_frontier_distance_days
"unavailable" lib.AssertEq empty_vm.journal_lag

# Legacy Build keeps its established fallback while the new relation remains
# honest about missing frontier evidence.
legacy_empty_vm ← outlook.Build empty_ctx
"2026-06-15" lib.AssertEq legacy_empty_vm.as_of
"2026-06-15" lib.AssertEq legacy_empty_vm.last_journal
0 lib.AssertEq legacy_empty_vm.journal_lag
"unavailable" lib.AssertEq legacy_empty_vm.last_recorded_on
"unavailable" lib.AssertEq legacy_empty_vm.record_frontier_relation
"unavailable" lib.AssertEq legacy_empty_vm.record_frontier_distance_days

•Out "test_src_next_outlook_explicit_observation_path.bqn: OK"
