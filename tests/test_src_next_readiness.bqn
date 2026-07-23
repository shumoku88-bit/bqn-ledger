#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
context ← •Import "../src_next/context.bqn"
readiness ← •Import "../src_next/readiness_check.bqn"

base ← "fixtures/src-next-golden"
ctx ← context.BuildContext base
human ← readiness.FormatHuman ctx

# Verify section header and input files info
1 lib.AssertEq ∨´ "== Readiness Check =="⍷human
1 lib.AssertEq ∨´ "journal rows      :"⍷human
1 lib.AssertEq ∨´ "plan rows         :"⍷human
1 lib.AssertEq ∨´ "[Report readiness]"⍷human
1 lib.AssertEq ∨´ "[Data hygiene warnings]"⍷human

•Out "test_src_next_readiness.bqn: OK"
