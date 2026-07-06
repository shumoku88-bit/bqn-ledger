#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"

calendar_base ← "fixtures/src-next-context-as-of-calendar-month"
fixed_base ← "fixtures/src-next-daily-trend-stability-before"

# String-only construction does not preserve the journal-derived cycle-resolution
# date as ctx.as_of. It resolves the cycle, then stores the resolved cycle start.
default_ctx ← ctx_mod.BuildContext calendar_base
"2026-01-15" lib.AssertEq default_ctx.as_of
"calendarMonth" lib.AssertEq default_ctx.cy.mode
"2026-01-15" lib.AssertEq default_ctx.cy.start
"2026-02-15" lib.AssertEq default_ctx.cy.end_exclusive
31 lib.AssertEq default_ctx.cy.day_count

# An explicit caller date is stored verbatim. A date inside the same calendar
# cycle changes ctx.as_of without changing the selected period.
jan_ctx ← ctx_mod.BuildContext ⟨calendar_base, "2026-01-20"⟩
"2026-01-20" lib.AssertEq jan_ctx.as_of
"2026-01-15" lib.AssertEq jan_ctx.cy.start
"2026-02-15" lib.AssertEq jan_ctx.cy.end_exclusive
31 lib.AssertEq jan_ctx.cy.day_count

# A later explicit caller date also acts as calendarMonth period-selection input.
feb_ctx ← ctx_mod.BuildContext ⟨calendar_base, "2026-02-20"⟩
"2026-02-20" lib.AssertEq feb_ctx.as_of
"2026-02-15" lib.AssertEq feb_ctx.cy.start
"2026-03-15" lib.AssertEq feb_ctx.cy.end_exclusive
28 lib.AssertEq feb_ctx.cy.day_count

# BuildAllRows remains ledger-wide across the selected calendarMonth periods.
2 lib.AssertEq ≠jan_ctx.posting_rows
2 lib.AssertEq ≠feb_ctx.posting_rows

# In fixed mode the same explicit-date movement is stored in ctx.as_of, but the
# selected cycle does not move because fixed boundaries ignore that input.
fixed_early ← ctx_mod.BuildContext ⟨fixed_base, "2026-01-03"⟩
fixed_late ← ctx_mod.BuildContext ⟨fixed_base, "2026-01-06"⟩
"2026-01-03" lib.AssertEq fixed_early.as_of
"2026-01-06" lib.AssertEq fixed_late.as_of
"2026-01-01" lib.AssertEq fixed_early.cy.start
"2026-01-01" lib.AssertEq fixed_late.cy.start
"2026-01-11" lib.AssertEq fixed_early.cy.end_exclusive
"2026-01-11" lib.AssertEq fixed_late.cy.end_exclusive

•Out "test_src_next_context_as_of_cycle_semantics.bqn: OK"
