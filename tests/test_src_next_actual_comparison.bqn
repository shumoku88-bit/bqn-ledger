#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_comparison ← •Import "../src_next/actual_comparison.bqn"

# Normal current source-parser characterization. The supplied context observation
# is intentionally earlier than the maximum journal date: the report rereads the
# source and owns its local maximum-date cutoff today.
ctx ← ctx_mod.BuildContext ⟨"fixtures/actual-comparison-projection-normal", "2026-03-05"⟩
vm ← actual_comparison.Build ctx

"ok" lib.AssertEq vm.observation_status
"2026-03-01" lib.AssertEq vm.current_start
"2026-03-07" lib.AssertEq vm.as_of
"2026-03-08" lib.AssertEq vm.current_end_exclusive
"2026-02-01" lib.AssertEq vm.baseline_start
"2026-02-08" lib.AssertEq vm.baseline_end_exclusive
7 lib.AssertEq vm.elapsed_days
5 lib.AssertEq ≠ vm.table

RowFor ← {𝕊 unit:
  matches ← (unit⊸≡¨ {3⊑𝕩}¨ vm.table) / vm.table
  1 lib.AssertEq ≠ matches
  ⊑ matches
}

AssertRow ← {
  row ← RowFor 𝕩
  𝕨 lib.AssertEq 8↓row
}

# amount, count, diff, ratio, and status for all three lanes, including
# baseline-zero/new and current-zero/stopped behavior.
⟨120, 100, 20, 1, 1, 0, "120%", "increased", "ok"⟩ AssertRow "salary"
⟨120, 100, 20, 1, 1, 0, "120%", "increased", "ok"⟩ AssertRow "rent"
⟨88, 50, 38, 4, 1, 3, "176%", "increased", "ok"⟩ AssertRow "food"
⟨30, 0, 30, 1, 0, 1, "n/a", "new", "ok"⟩ AssertRow "new"
⟨0, 40, ¯40, 0, 1, ¯1, "0%", "stopped", "ok"⟩ AssertRow "stopped"

"income" lib.AssertEq 1⊑RowFor "salary"
"recurring_fixed" lib.AssertEq 1⊑RowFor "rent"
"variable" lib.AssertEq 1⊑RowFor "food"
0 lib.AssertEq +´ "savings"⊸≡¨ {3⊑𝕩}¨ vm.table
0 lib.AssertEq +´ "card"⊸≡¨ {3⊑𝕩}¨ vm.table

# The checked projection rejects the unknown-account transaction, while the
# current raw parser nevertheless includes its +7 known expense side in food.
rejected ← ("unknown_account"⊸≡¨ {𝕩.status}¨ ctx.posting_rows) / ctx.posting_rows
2 lib.AssertEq ≠ rejected
88 lib.AssertEq 8⊑RowFor "food"
# Current behavior does not honor ctx.as_of as a hard observation cutoff.
"2026-03-05" lib.AssertEq ctx.as_of
"2026-03-07" lib.AssertEq vm.as_of

text ← actual_comparison.Format vm
1 lib.AssertEq ∨´ "src_next_actual_comparison_status: ok"⍷text
1 lib.AssertEq ∨´ "src_next_actual_comparison_row: food lane=variable cur=88 base=50 diff=38 ratio=176% status=increased"⍷text

# Separate history-boundary fixture: no previous anchor means unavailable.
history_ctx ← ctx_mod.BuildContext "fixtures/actual-comparison-history-boundary"
history_vm ← actual_comparison.Build history_ctx
"unavailable" lib.AssertEq history_vm.observation_status
"unavailable" lib.AssertEq history_vm.baseline_start
"unavailable" lib.AssertEq history_vm.baseline_end_exclusive
0 lib.AssertEq ≠ history_vm.table

history_human ← actual_comparison.FormatHuman history_vm
1 lib.AssertEq ∨´ "status: unavailable"⍷history_human
1 lib.AssertEq ∨´ "Actual比較は表示しません"⍷history_human

•Out "test_src_next_actual_comparison.bqn: OK"
