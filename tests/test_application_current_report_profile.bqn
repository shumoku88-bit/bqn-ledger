#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
cycleResult ← •Import "../src/accounting/cycle_result.bqn"
profile ← •Import "../src/application/current_report_profile.bqn"

lines ← io.ReadLines "fixtures/ledger-facts-phase1-proof/report_all_human.destination.tsv"
fields ← io.SplitTsv¨1↓lines
rows ← {𝕊 row: {key⇐0⊑row,surface⇐1⊑row,arguments⇐2↓row}}¨fields
current ← cycleResult.Success ⟨"fixed","2026-01-12","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
baseline ← cycleResult.Success ⟨"fixed","2025-12-31","2025-12-22","2026-01-22",⟨⟩,⟨⟩⟩
result ← profile.Build ⟨rows,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq result.state
12 lib.AssertEq ≠result.rows
Find ← {𝕊 key: (⊑(key⊸≡¨{𝕩.key}¨result.rows)⊐1)⊑result.rows}
⟨"JPY","2026-01-12","actual.journal"⟩ lib.AssertEq (Find "balance-sheet").arguments
⟨"JPY","2026-01-01","2026-01-13","actual.journal"⟩ lib.AssertEq (Find "profit-and-loss").arguments
⟨"JPY","2026-01-12","2026-01-02","aligned_elapsed","actual.journal","cycle.tsv","cycle_baseline.destination.tsv"⟩ lib.AssertEq (Find "cycle-comparison").arguments
⟨"JPY","2026-01","2026-02","actual.journal"⟩ lib.AssertEq (Find "monthly-accounts").arguments
⟨"JPY","2026-01-12","2026-01-22","actual.journal","daily_target_plan.destination.tsv","daily_target_scope.destination.tsv"⟩ lib.AssertEq (Find "daily-target").arguments

yearEndCurrent ← cycleResult.Success ⟨"fixed","2026-12-31","2026-12-01","2027-01-15",⟨⟩,⟨⟩⟩
yearEndBaseline ← cycleResult.Success ⟨"fixed","2026-10-31","2026-10-01","2026-11-15",⟨⟩,⟨⟩⟩
yearEnd ← profile.Build ⟨rows,"2026-12-31",yearEndCurrent,yearEndBaseline⟩
"ok" lib.AssertEq yearEnd.state
yearEndMonthly ← (⊑("monthly-accounts"⊸≡¨{𝕩.key}¨yearEnd.rows)⊐1)⊑yearEnd.rows
⟨"JPY","2026-01","2027-01","actual.journal"⟩ lib.AssertEq yearEndMonthly.arguments

shortBaseline ← cycleResult.Success ⟨"fixed","2025-12-31","2025-12-30","2026-01-02",⟨⟩,⟨⟩⟩
rejected ← profile.Build ⟨rows,"2026-01-12",current,shortBaseline⟩
"error" lib.AssertEq rejected.state
"aligned_baseline_unavailable" lib.AssertEq (⊑rejected.diagnostics).code
•Out "test_application_current_report_profile: ok"
