#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
outlook ← •Import "../src_next/outlook.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
vm ← outlook.Build ctx

"ok" lib.AssertEq vm.state
"outlook_active" lib.AssertEq vm.reason
0 lib.AssertEq ≠ vm.diagnostics
"2026-06-16" lib.AssertEq vm.as_of
6 lib.AssertEq vm.days_left
0 lib.AssertEq vm.liq_total
0 lib.AssertEq vm.liq_daily
0 lib.AssertEq vm.liq_safe_daily
0 lib.AssertEq vm.next_obligation_total

text ← outlook.Format vm
1 lib.AssertEq ∨´ "--- SrcNext Outlook ---"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_status: ok"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_reason: outlook_active"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_as_of: 2026-06-16"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_days_left: 6"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_liq_safe_daily: 0"⍷text

human ← outlook.FormatHuman vm
1 lib.AssertEq ∨´ "== Outlook Dashboard =="⍷human
1 lib.AssertEq ∨´ "使える可用資金"⍷human
1 lib.AssertEq ∨´ " 〜 "⍷human
1 lib.AssertEq ∨´ "  ─────────────────────────────"⍷human
0 lib.AssertEq ∨´ "可用資金 (安全/保守)"⍷human

# Focused human Outlook purpose split. Existing group settings own membership;
# the overall liquid arithmetic remains independent of these presentation rows.
split_ctx ← ctx_mod.BuildContext ⟨"fixtures/outlook-envelope-purpose-split", "2026-01-04"⟩
split_vm ← outlook.BuildAt ⟨split_ctx, "2026-01-04"⟩
"ok" lib.AssertEq split_vm.state
4695 lib.AssertEq split_vm.liq_total
0 lib.AssertEq split_vm.planned_future_income
0 lib.AssertEq split_vm.fixed_reserve
670 lib.AssertEq split_vm.liq_daily
135 lib.AssertEq split_vm.budget_daily_total
⟨⟨"食費", 630, 90⟩, ⟨"日用品", 315, 45⟩⟩ lib.AssertEq split_vm.budget_breakdown
⟨⟨"米・食料ストック", 1000⟩⟩ lib.AssertEq split_vm.reserve_breakdown
split_human ← outlook.FormatHuman split_vm
1 lib.AssertEq ∨´ "  食費     |       630 |    90"⍷split_human
1 lib.AssertEq ∨´ "  日用品   |       315 |    45"⍷split_human
1 lib.AssertEq ∨´ "  米・食料ストック |      1000"⍷split_human
0 lib.AssertEq ∨´ "米・食料ストック |      1000 |"⍷split_human
0 lib.AssertEq ∨´ "対象外"⍷split_human

mock_vm ← {
  state ⇐ "ok",
  reason ⇐ "outlook_active",
  diagnostics ⇐ ⟨⟩,
  days_left ⇐ 6,
  cycle_start ⇐ "2026-01-01",
  cycle_end_exclusive ⇐ "2026-01-09",
  as_of ⇐ "2026-01-04",
  liq_total ⇐ 1000,
  planned_future_income ⇐ 0,
  fixed_reserve ⇐ 0,
  liq_daily ⇐ 166,
  budget_breakdown ⇐ ⟨⟨"日常食費", 600, 100⟩⟩,
  reserve_breakdown ⇐ ⟨⟨"米・食料ストック", 12000⟩⟩
}
mock_human ← outlook.FormatHuman mock_vm
1 lib.AssertEq ∨´ "サイクル: 2026-01-01 〜 2026-01-09  (残 6 日)"⍷mock_human
1 lib.AssertEq ∨´ "── 日常封筒 ──"⍷mock_human
1 lib.AssertEq ∨´ "  envelope | remaining | /day"⍷mock_human
1 lib.AssertEq ∨´ "  日常食費 |       600 |   100"⍷mock_human
1 lib.AssertEq ∨´ "── まとめ支出の確保 ──"⍷mock_human
1 lib.AssertEq ∨´ "  米・食料ストック |     12000"⍷mock_human
0 lib.AssertEq ∨´ "米・食料ストック |     12000 |"⍷mock_human

# Empty daily and reserve groups are valid independently and omit only their
# respective human table.
reserve_only_vm ← {
  state ⇐ "ok", reason ⇐ "outlook_active", diagnostics ⇐ ⟨⟩,
  days_left ⇐ 6, cycle_start ⇐ "2026-01-01", cycle_end_exclusive ⇐ "2026-01-09",
  as_of ⇐ "2026-01-04", liq_total ⇐ 1000, planned_future_income ⇐ 0,
  fixed_reserve ⇐ 0, liq_daily ⇐ 166, budget_breakdown ⇐ ⟨⟩,
  reserve_breakdown ⇐ ⟨⟨"通院", 9000⟩⟩
}
reserve_only_human ← outlook.FormatHuman reserve_only_vm
0 lib.AssertEq ∨´ "── 日常封筒 ──"⍷reserve_only_human
1 lib.AssertEq ∨´ "── まとめ支出の確保 ──"⍷reserve_only_human
0 lib.AssertEq ∨´ "/day"⍷reserve_only_human

daily_only_vm ← {
  state ⇐ "ok", reason ⇐ "outlook_active", diagnostics ⇐ ⟨⟩,
  days_left ⇐ 6, cycle_start ⇐ "2026-01-01", cycle_end_exclusive ⇐ "2026-01-09",
  as_of ⇐ "2026-01-04", liq_total ⇐ 1000, planned_future_income ⇐ 0,
  fixed_reserve ⇐ 0, liq_daily ⇐ 166, budget_breakdown ⇐ ⟨⟨"書籍以外", 600, 100⟩⟩,
  reserve_breakdown ⇐ ⟨⟩
}
daily_only_human ← outlook.FormatHuman daily_only_vm
1 lib.AssertEq ∨´ "── 日常封筒 ──"⍷daily_only_human
0 lib.AssertEq ∨´ "── まとめ支出の確保 ──"⍷daily_only_human

anchor_ctx ← ctx_mod.BuildContext "fixtures/src-next-anchor-unmet"
anchor_vm ← outlook.Build anchor_ctx
"ok" lib.AssertEq anchor_vm.state
50000 lib.AssertEq anchor_vm.planned_future_income
64000 lib.AssertEq anchor_vm.fixed_reserve
7240 lib.AssertEq anchor_vm.liq_daily
5240 lib.AssertEq anchor_vm.liq_safe_daily
anchor_human ← outlook.FormatHuman anchor_vm
1 lib.AssertEq ∨´ "予定収入(残)          + 50000"⍷anchor_human
1 lib.AssertEq ∨´ "予定支出(残)           -64000"⍷anchor_human
1 lib.AssertEq ∨´ "使える可用資金        181000  ÷ 25日 = 7240 /日"⍷anchor_human
0 lib.AssertEq ∨´ "可用資金 (安全/保守)"⍷anchor_human

•Out "test_src_next_outlook.bqn: OK"
