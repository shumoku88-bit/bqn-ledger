#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cube ← •Import "../src_next/cube.bqn"
cs ← •Import "../src_next/cycle_summary.bqn"

MakeRow ← {𝕊 layer‿delta‿side‿kind:
  {
    source_file       ⇐ "journal.tsv",
    source_row        ⇐ 0,
    source_id         ⇐ "T",
    side              ⇐ side,
    day_index         ⇐ 0,
    account_key_index ⇐ 0,
    layer_index       ⇐ layer,
    delta             ⇐ delta,
    kind              ⇐ kind,
    status            ⇐ "ok",
    message           ⇐ ""
  }
}

rows ← ⟨
  MakeRow ⟨cube.layer_actual, 100000, "debit", "income"⟩,
  MakeRow ⟨cube.layer_actual, ¯100000, "credit", "income"⟩,
  MakeRow ⟨cube.layer_actual, 4200, "debit", "expense"⟩,
  MakeRow ⟨cube.layer_actual, ¯4200, "credit", "expense"⟩,
  MakeRow ⟨cube.layer_plan, 2000, "debit", "expense"⟩,
  MakeRow ⟨cube.layer_plan, ¯2000, "credit", "expense"⟩
⟩

result ← cube.Materialize ⟨rows, 1, 1⟩

tbdsRows ← ⟨
  {layer_index ⇐ cube.layer_actual, account_name ⇐ "income:salary", account_key ⇐ "income:salary/JPY", role ⇐ "income", debit_movement ⇐ 0, credit_movement ⇐ ¯100000, movement ⇐ ¯100000},
  {layer_index ⇐ cube.layer_actual, account_name ⇐ "expenses:food", account_key ⇐ "expenses:food/JPY", role ⇐ "expense", debit_movement ⇐ 4200, credit_movement ⇐ 0, movement ⇐ 4200},
  {layer_index ⇐ cube.layer_plan, account_name ⇐ "expenses:food", account_key ⇐ "expenses:food/JPY", role ⇐ "expense", debit_movement ⇐ 2000, credit_movement ⇐ 0, movement ⇐ 2000}
⟩

cy ← { start ⇐ "2026-01-10", end_exclusive ⇐ "2026-03-10", day_count ⇐ 59 }
ctx ← { cy ⇐ cy, tbds ⇐ tbdsRows }
summary ← cs.Build ctx

"2026-01-10" lib.AssertEq summary.start
"2026-03-10" lib.AssertEq summary.end_exclusive
59 lib.AssertEq summary.day_count
100000 lib.AssertEq summary.income_actual
4200 lib.AssertEq summary.expense_actual
95800 lib.AssertEq summary.net_actual
2000 lib.AssertEq summary.plan_expense
2000 lib.AssertEq summary.plan_expense_remaining

text ← cs.Format summary
1 lib.AssertEq ∨´ "src_next_cycle_income_actual: 100000"⍷text
1 lib.AssertEq ∨´ "src_next_cycle_net_actual: 95800"⍷text
1 lib.AssertEq ∨´ "src_next_cycle_plan_expense_remaining: 2000"⍷text

•Out "test_src_next_cycle_summary.bqn: OK"
