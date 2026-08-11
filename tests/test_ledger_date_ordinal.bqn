#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

samples ← ⟨"0001-01-01","1900-02-28","2000-02-29","2026-07-30","2400-12-31"⟩
{𝕊 text: text lib.AssertEq dates.FromOrdinal dates.Ordinal text}¨samples

1 lib.AssertEq dates.IsValid "2024-02-29"
0 lib.AssertEq dates.IsValid "1900-02-29"
1 lib.AssertEq dates.IsValid "2000-02-29"
0 lib.AssertEq dates.IsValid "2026-00-01"
0 lib.AssertEq dates.IsValid "2026-13-01"
0 lib.AssertEq dates.IsValid "2026-04-31"
1 lib.AssertEq dates.IsValid "2026-04-30"
0 lib.AssertEq dates.IsValid "2026-02-29"
0 lib.AssertEq dates.IsValid "2026-01-00"
0 lib.AssertEq dates.IsValid "2026-01-32"
0 lib.AssertEq dates.IsValid "2026-1-01"
0 lib.AssertEq dates.IsValid "2026/01/01"

"2026-07-31" lib.AssertEq dates.AddDays ⟨"2026-07-30",1⟩
"2026-03-01" lib.AssertEq dates.AddDays ⟨"2026-02-28",1⟩
"2024-02-29" lib.AssertEq dates.AddDays ⟨"2024-03-01",¯1⟩
"2027-01-01" lib.AssertEq dates.AddDays ⟨"2026-12-31",1⟩
"2000-03-01" lib.AssertEq dates.AddDays ⟨"2000-02-29",1⟩
"1900-03-01" lib.AssertEq dates.AddDays ⟨"1900-02-28",1⟩

1 lib.AssertEq (dates.Ordinal "2026-01-01")-dates.Ordinal "2025-12-31"
60 lib.AssertEq (dates.Ordinal "2024-03-01")-dates.Ordinal "2024-01-01"

•Out "test_ledger_date_ordinal: ok"
