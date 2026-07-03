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

lint_ctx ← context.BuildContext "fixtures/src-next-lint-failures"
lint_summary ← readiness.Build lint_ctx
1 lib.AssertEq ≠ lint_summary.unknown_envelope_role_accounts
2 lib.AssertEq ≠ lint_summary.inconsistent_envelope_role_accounts
lint_text ← readiness.Format lint_summary
1 lib.AssertEq ∨´ "src_next_readiness_unknown_envelope_role_accounts_count: 1"⍷lint_text
1 lib.AssertEq ∨´ "src_next_readiness_inconsistent_envelope_role_accounts_count: 2"⍷lint_text
lint_human ← readiness.FormatHuman lint_ctx
1 lib.AssertEq ∨´ "unknown envelope_role accounts  : 1"⍷lint_human
1 lib.AssertEq ∨´ "inconsistent envelope_role      : 2"⍷lint_human

•Out "test_src_next_readiness.bqn: OK"
