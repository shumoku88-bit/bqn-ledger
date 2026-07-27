#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
context ← •Import "../src_next/context.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
env ← •Import "../src_next/envelope_computation.bqn"
outlook ← •Import "../src_next/outlook.bqn"

# Characterization A: envelope pace currently treats the physically last
# in-cycle journal row as the latest actual date. The fixture source order is:
#   2026-01-10  100
#   2026-01-03  100  (backdated append)
# Therefore current elapsed time is 3 inclusive days, not 10, and
# avg_spend is floor(200 / 3) = 66.
env_base ← "fixtures/src-next-envelope-computation-nonmonotonic-clock"
env_ctx ← context.BuildContext env_base
env_summary ← env.Build env_ctx

1 lib.AssertEq ≠ env_summary.envelopes
food_env ← ⊑ env_summary.envelopes
"食費" lib.AssertEq food_env.label
200 lib.AssertEq food_env.actual_spent
66 lib.AssertEq food_env.avg_spend

# Characterization B: Outlook's prepared frontier policy applies only the lower
# cycle bound. For the historical July cycle, a 2026-08-02 journal row is
# therefore selected even though end_exclusive is 2026-08-01.
out_base ← "fixtures/src-next-outlook-historical-cycle-clock"
out_ctx ← context.BuildContext out_base
out_cy ← out_ctx.cy
frontier ← outlook.RecordedFrontierInfoFromDates ⟨actual_source.DatesFromContext out_ctx, out_cy⟩

"2026-07-01" lib.AssertEq out_cy.start
"2026-08-01" lib.AssertEq out_cy.end_exclusive
1 lib.AssertEq frontier.available
"2026-08-02" lib.AssertEq frontier.date

•Out "test_src_next_temporal_clock_characterization.bqn: OK"
