#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
actual ← •Import "../src/application/editor_actual.bqn"

rows ← actual.LoadTransactionRows "fixtures/plan-completion"
2 lib.AssertEq ≠rows
"" lib.AssertEq (0⊑rows).plan_id
"plan-2026-01-15-rent" lib.AssertEq (1⊑rows).plan_id

evidence ← actual.CompletionEvidenceFromRows rows
1 lib.AssertEq ≠evidence
completed ← ⊑evidence
"plan-2026-01-15-rent" lib.AssertEq completed.plan_id
"2026-01-15" lib.AssertEq completed.date
"assets:bank" lib.AssertEq completed.from_account
"expenses:rent" lib.AssertEq completed.to_account
64000 lib.AssertEq completed.amount
"JPY" lib.AssertEq completed.currency

•Out "test_application_editor_actual: ok"
