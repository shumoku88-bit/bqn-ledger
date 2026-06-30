#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dt ← •Import "../src_next/date.bqn"
proj ← •Import "../src_next/projection.bqn"
validate ← •Import "../src_edit/validate.bqn"

# ── Date text contract ─────────────────────────────────────────

1 lib.AssertEq dt.IsValidDateText "2026-06-30"
1 lib.AssertEq dt.IsValidDateText "2024-02-29"
1 lib.AssertEq dt.IsValidDateText "2000-02-29"
0 lib.AssertEq dt.IsValidDateText "1900-02-29"
0 lib.AssertEq dt.IsValidDateText "2026-02-29"
0 lib.AssertEq dt.IsValidDateText "2026-06-31"
0 lib.AssertEq dt.IsValidDateText "2026-00-01"
0 lib.AssertEq dt.IsValidDateText "2026-13-01"
0 lib.AssertEq dt.IsValidDateText "2026-06-00"
0 lib.AssertEq dt.IsValidDateText "20260630"
0 lib.AssertEq dt.IsValidDateText "2026/06/30"
0 lib.AssertEq dt.IsValidDateText "abcd-ef-gh"

# Projection and edit validation must use the same date contract.
1 lib.AssertEq proj.IsValidDateText "2024-02-29"
0 lib.AssertEq proj.IsValidDateText "2026-02-29"
⟨1, ""⟩ lib.AssertEq validate.ValidateDate "2024-02-29"
0 lib.AssertEq ⊑ validate.ValidateDate "2026-02-29"
0 lib.AssertEq ⊑ validate.ValidateDate "2026/02/29"

# Ordinal conversion contract: FromOrdinal is the inverse and differences are stable.
"2026-06-30" lib.AssertEq dt.FromOrdinal (dt.Ordinal "2026-06-30")
"2024-02-29" lib.AssertEq dt.FromOrdinal (dt.Ordinal "2024-02-29")
1 lib.AssertEq dt.DaysBetween ⟨"2026-06-30", "2026-07-01"⟩
2 lib.AssertEq dt.DaysBetween ⟨"2024-02-28", "2024-03-01"⟩

# Projection epoch conversion contract: projection aliases date.bqn and inverse is stable.
dn_20260630 ← dt.DaysFromEpoch "2026-06-30"
dn_20240229 ← dt.DaysFromEpoch "2024-02-29"
dn_20260630 lib.AssertEq proj.DaysFromEpoch "2026-06-30"
"2026-06-30" lib.AssertEq dt.FromDaysFromEpoch dn_20260630
"2024-02-29" lib.AssertEq dt.FromDaysFromEpoch dn_20240229
"2026-07-01" lib.AssertEq dt.AddDays ⟨"2026-06-30", 1⟩
"2024-03-01" lib.AssertEq dt.AddDays ⟨"2024-02-28", 2⟩
"unavailable" lib.AssertEq dt.AddDays ⟨"unavailable", 2⟩

•Out "test_src_next_date.bqn: OK"
