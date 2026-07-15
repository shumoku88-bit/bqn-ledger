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

# Anchor identity is independent of amount sign. The appended configured
# income-credit event with amount 0 is the previous anchor for this local cycle.
zero_anchor_cycle ← {mode⇐"fixed",start⇐"2026-02-01",end_exclusive⇐"2026-03-01",day_count⇐28}
zero_anchor_ctx ← {base⇐ctx.base,as_of⇐ctx.as_of,cy⇐zero_anchor_cycle,resolved⇐ctx.resolved,
  posting_rows⇐ctx.posting_rows,arithmetic_currency_proof⇐ctx.arithmetic_currency_proof,
  cube⇐ctx.cube,tbds⇐ctx.tbds,issues⇐ctx.issues}
zero_anchor_vm ← actual_comparison.BuildAt ⟨zero_anchor_ctx,"2026-02-05"⟩
"ok" lib.AssertEq zero_anchor_vm.observation_status
"2026-01-01" lib.AssertEq zero_anchor_vm.baseline_start
"2026-01-06" lib.AssertEq zero_anchor_vm.baseline_end_exclusive

text ← actual_comparison.Format vm
1 lib.AssertEq ∨´"src_next_actual_comparison_status: ok"⍷text
1 lib.AssertEq ∨´"src_next_actual_comparison_row: food lane=variable cur=75 base=50 diff=25 ratio=150% status=increased"⍷text

# PR #261 normal evidence intentionally changes: one in-window checked rejection
# fails closed, the numeric table is empty, and explicit O owns vm.as_of.
normal_ctx ← ctx_mod.BuildContext ⟨"fixtures/actual-comparison-projection-normal","2026-03-05"⟩
normal_vm ← actual_comparison.BuildAt ⟨normal_ctx,"2026-03-05"⟩
"error" lib.AssertEq normal_vm.observation_status
"rejected_actual_evidence" lib.AssertEq normal_vm.reason
"2026-03-05" lib.AssertEq normal_vm.as_of
"2026-03-06" lib.AssertEq normal_vm.current_end_exclusive
0 lib.AssertEq ≠normal_vm.table
1 lib.AssertEq ≠normal_vm.diagnostics
"journal.tsv" lib.AssertEq (⊑normal_vm.diagnostics).source_file
15 lib.AssertEq (⊑normal_vm.diagnostics).source_row
"unknown_account" lib.AssertEq (⊑normal_vm.diagnostics).status
normal_text ← actual_comparison.Format normal_vm
1 lib.AssertEq ∨´"src_next_actual_comparison_status: error"⍷normal_text
1 lib.AssertEq ∨´"src_next_actual_comparison_diagnostic: journal.tsv row=15 status=unknown_account"⍷normal_text
0 lib.AssertEq ∨´"src_next_actual_comparison_row:"⍷normal_text
normal_human ← actual_comparison.FormatHuman normal_vm
1 lib.AssertEq ∨´"数字を表示できません"⍷normal_human
0 lib.AssertEq ∨´"比較可能な前サイクル履歴"⍷normal_human

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

# Invalid-date rejected evidence is applicability-unknown and diagnostic identity
# is source-row based rather than debit/credit posting based.
invalid_ctx ← ctx_mod.BuildContext "fixtures/actual-comparison-invalid-date-rejected"
invalid_vm ← actual_comparison.BuildAt ⟨invalid_ctx,"2026-03-05"⟩
"error" lib.AssertEq invalid_vm.observation_status
"rejected_actual_evidence" lib.AssertEq invalid_vm.reason
0 lib.AssertEq ≠invalid_vm.table
1 lib.AssertEq ≠invalid_vm.diagnostics
"invalid_date" lib.AssertEq (⊑invalid_vm.diagnostics).status

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
