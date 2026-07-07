#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
outlook ← •Import "../src_next/outlook.bqn"

before_base ← "fixtures/src-next-daily-trend-stability-before"
after_base ← "fixtures/src-next-daily-trend-stability-after"

# Characterization A: move explicit context observation O while holding source
# data, fixed cycle C, and journal-derived local frontier L constant.
early_ctx ← ctx_mod.BuildContext ⟨before_base, "2026-01-03"⟩
late_ctx ← ctx_mod.BuildContext ⟨before_base, "2026-01-06"⟩

"2026-01-03" lib.AssertEq early_ctx.as_of
"2026-01-06" lib.AssertEq late_ctx.as_of
"2026-01-01" lib.AssertEq early_ctx.cy.start
"2026-01-01" lib.AssertEq late_ctx.cy.start
"2026-01-11" lib.AssertEq early_ctx.cy.end_exclusive
"2026-01-11" lib.AssertEq late_ctx.cy.end_exclusive

early_vm ← outlook.Build early_ctx
late_vm ← outlook.Build late_ctx

# Current behavior: Outlook does not consume the differing explicit ctx.as_of as
# its report reference date. It derives local L from journal coordinates.
"2026-01-03" lib.AssertEq early_vm.as_of
"2026-01-03" lib.AssertEq late_vm.as_of
"2026-01-03" lib.AssertEq early_vm.last_journal
"2026-01-03" lib.AssertEq late_vm.last_journal
0 lib.AssertEq early_vm.journal_lag
0 lib.AssertEq late_vm.journal_lag

# O-shaped outputs remain unchanged because the local L frame is unchanged.
8 lib.AssertEq early_vm.days_left
8 lib.AssertEq late_vm.days_left
100 lib.AssertEq early_vm.liq_total
100 lib.AssertEq late_vm.liq_total
900 lib.AssertEq early_vm.planned_future_income
900 lib.AssertEq late_vm.planned_future_income
125 lib.AssertEq early_vm.liq_daily
125 lib.AssertEq late_vm.liq_daily
12 lib.AssertEq early_vm.liq_safe_daily
12 lib.AssertEq late_vm.liq_safe_daily

# Characterization B: hold explicit context observation O and fixed cycle C
# constant while a later unrelated journal Event advances local L.
observation ← "2026-01-03"
before_ctx ← ctx_mod.BuildContext ⟨before_base, observation⟩
after_ctx ← ctx_mod.BuildContext ⟨after_base, observation⟩

observation lib.AssertEq before_ctx.as_of
observation lib.AssertEq after_ctx.as_of
"2026-01-01" lib.AssertEq before_ctx.cy.start
"2026-01-01" lib.AssertEq after_ctx.cy.start
"2026-01-11" lib.AssertEq before_ctx.cy.end_exclusive
"2026-01-11" lib.AssertEq after_ctx.cy.end_exclusive

before_vm ← outlook.Build before_ctx
after_vm ← outlook.Build after_ctx

# Current behavior: local L moves despite fixed explicit ctx.as_of.
"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of
"2026-01-03" lib.AssertEq before_vm.last_journal
"2026-01-06" lib.AssertEq after_vm.last_journal
0 lib.AssertEq before_vm.journal_lag
0 lib.AssertEq after_vm.journal_lag

# The later Event is unrelated to liquid cash, so liq_total itself stays fixed.
# Nevertheless local-L movement changes the denominator and crosses the
# 2026-01-05 future-income cutoff, moving multiple O-shaped outputs.
100 lib.AssertEq before_vm.liq_total
100 lib.AssertEq after_vm.liq_total
8 lib.AssertEq before_vm.days_left
5 lib.AssertEq after_vm.days_left
900 lib.AssertEq before_vm.planned_future_income
0 lib.AssertEq after_vm.planned_future_income
125 lib.AssertEq before_vm.liq_daily
20 lib.AssertEq after_vm.liq_daily
12 lib.AssertEq before_vm.liq_safe_daily
20 lib.AssertEq after_vm.liq_safe_daily

•Out "test_src_next_outlook_observation_sensitivity.bqn: OK"
