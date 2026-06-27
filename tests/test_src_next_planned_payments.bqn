#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
context ← •Import "../src_next/context.bqn"
planned ← •Import "../src_next/planned_payments.bqn"

base ← "fixtures/plan-completion"
ctx ← context.BuildContext base
human ← planned.FormatHuman ctx

# Verify section header and content elements
1 lib.AssertEq ∨´ "== Planned Payments =="⍷human
1 lib.AssertEq ∨´ "[Status]"⍷human
1 lib.AssertEq ∨´ "completed"⍷human
1 lib.AssertEq ∨´ "overdue"⍷human

•Out "test_src_next_planned_payments.bqn: OK"
