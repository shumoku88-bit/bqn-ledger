#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_comparison ← •Import "../src_next/actual_comparison.bqn"

# Clean target contract: explicit O, Posting IR/TBDS amounts, and per-key counts.
ctx ← ctx_mod.BuildContext ⟨"fixtures/actual-comparison-numeric-owner-target", "2026-03-05"⟩
vm ← actual_comparison.BuildAt ⟨ctx,"2026-03-05"⟩

"ok" lib.AssertEq vm.observation_status
"comparison_active" lib.AssertEq vm.reason
"2026-03-05" lib.AssertEq vm.as_of
"2026-03-01" lib.AssertEq vm.current_start
"2026-03-06" lib.AssertEq vm.current_end_exclusive
"2026-02-01" lib.AssertEq vm.baseline_start
"2026-02-06" lib.AssertEq vm.baseline_end_exclusive
5 lib.AssertEq vm.elapsed_days
0 lib.AssertEq ≠vm.diagnostics
5 lib.AssertEq ≠vm.table

RowFor ← {𝕊 unit:
  matches ← (unit⊸≡¨ {3⊑𝕩}¨vm.table) / vm.table
  1 lib.AssertEq ≠matches
  ⊑matches
}
AssertRow ← {row←RowFor 𝕩 ⋄ 𝕨 lib.AssertEq 8↓row}

# The dual income-from/expense-to source row contributes once to each distinct
# output key. Transfers and post-O rows do not contribute.
⟨125,100,25,2,1,1,"125%","increased","ok"⟩ AssertRow "salary"
⟨120,100,20,1,1,0,"120%","increased","ok"⟩ AssertRow "rent"
⟨75,50,25,3,1,2,"150%","increased","ok"⟩ AssertRow "food"
⟨30,0,30,1,0,1,"n/a","new","ok"⟩ AssertRow "new"
⟨0,40,¯40,0,1,¯1,"0%","stopped","ok"⟩ AssertRow "stopped"
0 lib.AssertEq +´"savings"⊸≡¨{3⊑𝕩}¨vm.table
0 lib.AssertEq +´"loan"⊸≡¨{3⊑𝕩}¨vm.table

text ← actual_comparison.Format vm
1 lib.AssertEq ∨´"src_next_actual_comparison_status: ok"⍷text
1 lib.AssertEq ∨´"src_next_actual_comparison_row: food lane=variable cur=75 base=50 diff=25 ratio=150% status=increased"⍷text

# No previous anchor is normal unavailability, not an error or old
# insufficient_history state.
history_ctx ← ctx_mod.BuildContext "fixtures/actual-comparison-history-boundary"
history_vm ← actual_comparison.BuildAt ⟨history_ctx,"2026-03-05"⟩
"unavailable" lib.AssertEq history_vm.observation_status
"previous_comparable_anchor_unavailable" lib.AssertEq history_vm.reason
0 lib.AssertEq ≠history_vm.table
0 lib.AssertEq ≠history_vm.diagnostics
history_human ← actual_comparison.FormatHuman history_vm
1 lib.AssertEq ∨´"status: unavailable"⍷history_human
1 lib.AssertEq ∨´"Actual比較は表示しません"⍷history_human

# Explicit observation boundaries never read the real clock.
before_vm ← actual_comparison.BuildAt ⟨ctx,"2026-02-28"⟩
"unavailable" lib.AssertEq before_vm.observation_status
"empty_current_window" lib.AssertEq before_vm.reason
0 lib.AssertEq before_vm.elapsed_days

start_vm ← actual_comparison.BuildAt ⟨ctx,"2026-03-01"⟩
"ok" lib.AssertEq start_vm.observation_status
"2026-03-02" lib.AssertEq start_vm.current_end_exclusive
1 lib.AssertEq start_vm.elapsed_days

after_vm ← actual_comparison.BuildAt ⟨ctx,"2026-04-10"⟩
"ok" lib.AssertEq after_vm.observation_status
"2026-04-01" lib.AssertEq after_vm.current_end_exclusive
31 lib.AssertEq after_vm.elapsed_days

bad_o_vm ← actual_comparison.BuildAt ⟨ctx,"2026-02-30"⟩
"error" lib.AssertEq bad_o_vm.observation_status
"invalid_observation" lib.AssertEq bad_o_vm.reason
0 lib.AssertEq ≠bad_o_vm.table

bad_cycle ← {mode⇐"fixed",start⇐"bad",end_exclusive⇐"2026-04-01",day_count⇐31}
bad_ctx ← {base⇐ctx.base,as_of⇐ctx.as_of,cy⇐bad_cycle,resolved⇐ctx.resolved,
  posting_rows⇐ctx.posting_rows,arithmetic_currency_proof⇐ctx.arithmetic_currency_proof,
  cube⇐ctx.cube,tbds⇐ctx.tbds,issues⇐ctx.issues}
bad_cycle_vm ← actual_comparison.BuildAt ⟨bad_ctx,"2026-03-05"⟩
"error" lib.AssertEq bad_cycle_vm.observation_status
"invalid_or_unresolvable_cycle" lib.AssertEq bad_cycle_vm.reason
0 lib.AssertEq ≠bad_cycle_vm.table

•Out "test_src_next_actual_comparison.bqn: OK"
