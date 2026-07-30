#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

samples ← ⟨"0001-01-01","1900-02-28","2000-02-29","2026-07-30","2400-12-31"⟩
{𝕊 text: text lib.AssertEq dates.FromOrdinal dates.Ordinal text}¨samples
"2026-07-31" lib.AssertEq dates.AddDays ⟨"2026-07-30",1⟩
"2026-03-01" lib.AssertEq dates.AddDays ⟨"2026-02-28",1⟩
"2024-02-29" lib.AssertEq dates.AddDays ⟨"2024-03-01",¯1⟩
1 lib.AssertEq (dates.Ordinal "2026-01-01")-dates.Ordinal "2025-12-31"
60 lib.AssertEq (dates.Ordinal "2024-03-01")-dates.Ordinal "2024-01-01"
•Out "test_ledger_date_ordinal: ok"
