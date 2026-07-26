#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
dt ← •Import "../src_next/date.bqn"
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

# Edit validation must use the same direct date contract.
⟨1, ""⟩ lib.AssertEq validate.ValidateDate "2024-02-29"
0 lib.AssertEq ⊑ validate.ValidateDate "2026-02-29"
0 lib.AssertEq ⊑ validate.ValidateDate "2026/02/29"

# Ordinal conversion contract: inverse functions and differences are stable.
"2026-06-30" lib.AssertEq dt.FromOrdinal (dt.Ordinal "2026-06-30")
"2024-02-29" lib.AssertEq dt.FromOrdinal (dt.Ordinal "2024-02-29")
1 lib.AssertEq dt.DaysBetween ⟨"2026-06-30", "2026-07-01"⟩
2 lib.AssertEq dt.DaysBetween ⟨"2024-02-28", "2024-03-01"⟩

# Legacy epoch coordinates must retain their existing invalid-month failure
# boundary rather than silently normalizing malformed source dates.
InvalidEpochMonthErrors ← {𝕊:
  ({𝕊 ⋄ dt.DaysFromEpoch "2026-99-99" ⋄ 0}⎊{𝕊 ⋄ 1}) @
}
1 lib.AssertEq InvalidEpochMonthErrors @

# Legacy epoch coordinates must remain a one-day lattice across leap, year,
# and Gregorian century boundaries.
1 lib.AssertEq (dt.DaysFromEpoch "2024-01-01") - (dt.DaysFromEpoch "2023-12-31")
1 lib.AssertEq (dt.DaysFromEpoch "2025-01-01") - (dt.DaysFromEpoch "2024-12-31")
1 lib.AssertEq (dt.DaysFromEpoch "2024-02-29") - (dt.DaysFromEpoch "2024-02-28")
1 lib.AssertEq (dt.DaysFromEpoch "2024-03-01") - (dt.DaysFromEpoch "2024-02-29")
1 lib.AssertEq (dt.DaysFromEpoch "1900-01-01") - (dt.DaysFromEpoch "1899-12-31")
1 lib.AssertEq (dt.DaysFromEpoch "2000-01-01") - (dt.DaysFromEpoch "1999-12-31")
1 lib.AssertEq (dt.DaysFromEpoch "2001-01-01") - (dt.DaysFromEpoch "2000-12-31")

# The legacy coordinate inverse must be unique at the corrected boundaries.
"2023-12-31" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "2023-12-31")
"2024-01-01" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "2024-01-01")
"2024-12-31" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "2024-12-31")
"2025-01-01" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "2025-01-01")
"1900-01-01" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "1900-01-01")
"2000-01-01" lib.AssertEq dt.FromDaysFromEpoch (dt.DaysFromEpoch "2000-01-01")

# Existing non-boundary round trips and AddDays behavior remain stable.
dn_20260630 ← dt.DaysFromEpoch "2026-06-30"
dn_20240229 ← dt.DaysFromEpoch "2024-02-29"
"2026-06-30" lib.AssertEq dt.FromDaysFromEpoch dn_20260630
"2024-02-29" lib.AssertEq dt.FromDaysFromEpoch dn_20240229
"2026-07-01" lib.AssertEq dt.AddDays ⟨"2026-06-30", 1⟩
"2024-03-01" lib.AssertEq dt.AddDays ⟨"2024-02-28", 2⟩
"2024-01-01" lib.AssertEq dt.AddDays ⟨"2023-12-31", 1⟩
"2025-01-01" lib.AssertEq dt.AddDays ⟨"2024-12-31", 1⟩
"unavailable" lib.AssertEq dt.AddDays ⟨"unavailable", 2⟩

•Out "test_src_next_date.bqn: OK"
