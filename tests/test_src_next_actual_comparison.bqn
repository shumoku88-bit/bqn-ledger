#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_comparison ← •Import "../src_next/actual_comparison.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
vm ← actual_comparison.Build ctx

"unavailable" lib.AssertEq vm.observation_status
0 lib.AssertEq ≠ vm.table

text ← actual_comparison.Format vm
1 lib.AssertEq ∨´ "--- SrcNext Actual Comparison ---"⍷text
1 lib.AssertEq ∨´ "src_next_actual_comparison_status: unavailable"⍷text
1 lib.AssertEq ∨´ "src_next_actual_comparison_reason: status:unavailable"⍷text
0 lib.AssertEq +´ "production.ready"⍷text
0 lib.AssertEq +´ "parity"⍷text

human ← actual_comparison.FormatHuman vm
1 lib.AssertEq ∨´ "== Actual Comparison =="⍷human
1 lib.AssertEq ∨´ "status: unavailable"⍷human
1 lib.AssertEq ∨´ "Actual比較は表示しません"⍷human

•Out "test_src_next_actual_comparison.bqn: OK"
