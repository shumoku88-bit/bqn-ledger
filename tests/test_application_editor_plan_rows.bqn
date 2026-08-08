#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
projection ← •Import "../src/application/editor_plan_rows.bqn"

result ← projection.Load "fixtures/canonical-household-v1"
{𝕊:
  {𝕊 d: •Out d.code∾" | "∾d.message}¨result.diagnostics
}⍟(result.state≢"ok") @
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
2 lib.AssertEq ≠result.rows

first ← 0⊑result.rows
"2026-01-15" lib.AssertEq first.date
"Planned groceries" lib.AssertEq first.description
"Assets:Bank" lib.AssertEq first.from_account
"Expenses:Groceries" lib.AssertEq first.to_account
"4000" lib.AssertEq first.amount
"JPY" lib.AssertEq first.currency
"plan-groceries" lib.AssertEq first.plan_id
1 lib.AssertEq first.closed
3 lib.AssertEq first.source_start_line

second ← 1⊑result.rows
"2026-02-05" lib.AssertEq second.date
"Planned salary" lib.AssertEq second.description
"Income:Salary" lib.AssertEq second.from_account
"Assets:Bank" lib.AssertEq second.to_account
"50000" lib.AssertEq second.amount
"plan-salary" lib.AssertEq second.plan_id
0 lib.AssertEq second.closed

•Out "test_application_editor_plan_rows: ok"
