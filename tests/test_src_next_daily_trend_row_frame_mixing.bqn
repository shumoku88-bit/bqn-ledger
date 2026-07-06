#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

RowForDate ← {𝕊 rows‿date:
  dates ← {0⊑𝕩}¨ rows
  idx ← ⊑ dates ⊐ ⟨date⟩
  idx ⊑ rows
}

FutureContribution ← {𝕊 row:
  # Daily Trend rows are ⟨date, liquid, reserve, fund, days_left, daily, delta, variable, saving, fixed⟩.
  # Characterize the report-local scalar currently mixed into fund:
  #   future_contribution = fund - liquid + reserve
  (3⊑row) - (1⊑row) + (2⊑row)
}

before_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-before"
after_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-after"

before_vm ← daily_trend.Build before_ctx
after_vm ← daily_trend.Build after_ctx

"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-06" lib.AssertEq after_vm.as_of

before_d1 ← RowForDate ⟨before_vm.trend_rows, "2026-01-02"⟩
before_d2 ← RowForDate ⟨before_vm.trend_rows, "2026-01-03"⟩
after_d1 ← RowForDate ⟨after_vm.trend_rows, "2026-01-02"⟩
after_d2 ← RowForDate ⟨after_vm.trend_rows, "2026-01-03"⟩

# Coordinate-local values stay tied to each row date.
"2026-01-02" lib.AssertEq 0⊑before_d1
"2026-01-03" lib.AssertEq 0⊑before_d2
"2026-01-02" lib.AssertEq 0⊑after_d1
"2026-01-03" lib.AssertEq 0⊑after_d2

9 lib.AssertEq 4⊑before_d1
8 lib.AssertEq 4⊑before_d2
9 lib.AssertEq 4⊑after_d1
8 lib.AssertEq 4⊑after_d2

# The report-local scalar reused across rows is visible as fund - liquid + reserve.
900 lib.AssertEq FutureContribution before_d1
900 lib.AssertEq FutureContribution before_d2
0 lib.AssertEq FutureContribution after_d1
0 lib.AssertEq FutureContribution after_d2

•Out "test_src_next_daily_trend_row_frame_mixing.bqn: OK"
