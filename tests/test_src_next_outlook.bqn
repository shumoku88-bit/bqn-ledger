#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
outlook ← •Import "../src_next/outlook.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
vm ← outlook.Build ctx

"2026-06-16" lib.AssertEq vm.as_of
6 lib.AssertEq vm.days_left
0 lib.AssertEq vm.liq_total
0 lib.AssertEq vm.liq_daily
0 lib.AssertEq vm.liq_safe_daily
0 lib.AssertEq vm.next_obligation_total

text ← outlook.Format vm
1 lib.AssertEq ∨´ "--- SrcNext Outlook ---"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_as_of: 2026-06-16"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_days_left: 6"⍷text
1 lib.AssertEq ∨´ "src_next_outlook_liq_safe_daily: 0"⍷text

human ← outlook.FormatHuman vm
1 lib.AssertEq ∨´ "== Outlook Dashboard =="⍷human
1 lib.AssertEq ∨´ "使える流動資産"⍷human

•Out "test_src_next_outlook.bqn: OK"
