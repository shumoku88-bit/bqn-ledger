#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
proj ← •Import "../src_next/projection.bqn"

# 1. Build context from stability-before fixture
ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-before"

# 2. Build VMs using BuildAt with different header_O values
before_vm ← daily_trend.BuildAt ⟨ctx, "2026-01-03"⟩
after_vm  ← daily_trend.BuildAt ⟨ctx, "2026-01-06"⟩

# A. Header O sensitivity
# Assert human header days-remaining changes 8 -> 5
before_human ← daily_trend.FormatHuman before_vm
after_human ← daily_trend.FormatHuman after_vm

1 lib.AssertEq ∨´ "(現在 8 日残)" ⍷ before_human
1 lib.AssertEq ∨´ "(現在 5 日残)" ⍷ after_human
0 lib.AssertEq ∨´ "(現在 5 日残)" ⍷ before_human
0 lib.AssertEq ∨´ "(現在 8 日残)" ⍷ after_human

# Assert rendered table portion remains byte-for-byte identical
header_prefix ← "Date       | Liquid"
before_table_idx ← ⊑ (header_prefix ⍷ before_human) / ↕ 1 + (≠before_human) - (≠header_prefix)
after_table_idx ← ⊑ (header_prefix ⍷ after_human) / ↕ 1 + (≠after_human) - (≠header_prefix)

before_table ← before_table_idx ↓ before_human
after_table  ← after_table_idx ↓ after_human
before_table lib.AssertEq after_table

# Assert full trend_rows remain identical
before_vm.trend_rows lib.AssertEq after_vm.trend_rows

# Assert row-local days_left values remain identical
before_row_days_left ← {4⊑𝕩}¨ before_vm.trend_rows
after_row_days_left  ← {4⊑𝕩}¨ after_vm.trend_rows
before_row_days_left lib.AssertEq after_row_days_left

# B. Internal L preservation
# Prove vm.as_of is identical across both calls and remains "2026-01-03"
"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-03" lib.AssertEq after_vm.as_of
before_vm.as_of lib.AssertEq after_vm.as_of

# C. Reserve preservation
# Prove reserve values remain identical across the two BuildAt calls
# We compare the complete reserve column: index 2 of trend_rows
before_reserves ← {2⊑𝕩}¨ before_vm.trend_rows
after_reserves  ← {2⊑𝕩}¨ after_vm.trend_rows
before_reserves lib.AssertEq after_reserves

# Print success
•Out "test_src_next_daily_trend_header_as_of_sensitivity.bqn: OK"
