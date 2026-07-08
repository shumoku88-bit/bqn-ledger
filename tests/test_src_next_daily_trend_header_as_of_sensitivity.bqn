#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"
proj ← •Import "../src_next/projection.bqn"

# 1. Build VM from stability-before fixture
before_ctx ← ctx_mod.BuildContext "fixtures/src-next-daily-trend-stability-before"
before_vm ← daily_trend.Build before_ctx

# 2. Assert initial conditions: vm.as_of is "2026-01-03", days_left is 8
"2026-01-03" lib.AssertEq before_vm.as_of
"2026-01-01" lib.AssertEq before_vm.cycle_start
"2026-01-11" lib.AssertEq before_vm.cycle_end_exclusive

before_days_left ← 0 ⌈ (proj.DaysFromEpoch before_vm.cycle_end_exclusive) - proj.DaysFromEpoch before_vm.as_of
8 lib.AssertEq before_days_left

# 3. Construct after_vm changing only as_of to "2026-01-06"
after_vm ← {
  trend_rows ⇐ before_vm.trend_rows,
  top_drops ⇐ before_vm.top_drops,
  obs_days ⇐ before_vm.obs_days,
  as_of ⇐ "2026-01-06",
  cycle_start ⇐ before_vm.cycle_start,
  cycle_end_exclusive ⇐ before_vm.cycle_end_exclusive,
  cycle_mode ⇐ before_vm.cycle_mode
}

after_days_left ← 0 ⌈ (proj.DaysFromEpoch after_vm.cycle_end_exclusive) - proj.DaysFromEpoch after_vm.as_of
5 lib.AssertEq after_days_left

# 4. Format both and check header sensitivity
before_human ← daily_trend.FormatHuman before_vm
after_human ← daily_trend.FormatHuman after_vm

# Find the start of the table
header_prefix ← "date       | liquid"
before_table_idx ← ⊑ (header_prefix ⍷ before_human) / ↕ 1 + (≠before_human) - (≠header_prefix)
after_table_idx ← ⊑ (header_prefix ⍷ after_human) / ↕ 1 + (≠after_human) - (≠header_prefix)

before_table ← before_table_idx ↓ before_human
after_table  ← after_table_idx ↓ after_human

# The table part must be byte-for-byte identical
before_table lib.AssertEq after_table

# The human header itself must be different
1 lib.AssertEq before_human ≢ after_human

# The trend rows inside the VM must be identical
before_vm.trend_rows lib.AssertEq after_vm.trend_rows

# Row-local days_left values must remain unchanged in the VM rows
before_row_days_left ← {4⊑𝕩}¨ before_vm.trend_rows
after_row_days_left  ← {4⊑𝕩}¨ after_vm.trend_rows
before_row_days_left lib.AssertEq after_row_days_left

# Output success message
•Out "test_src_next_daily_trend_header_as_of_sensitivity.bqn: OK"
