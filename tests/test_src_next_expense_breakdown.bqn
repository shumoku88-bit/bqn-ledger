#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds_mod ← •Import "../src_next/tbds.bqn"
eb ← •Import "../src_next/expense_breakdown.bqn"

# ── TBDS query helper: ActualExpenseBreakdown ─────────────────

tbdsRows ← ⟨
  {
    account_key       ⇐ "expenses:food/JPY",
    account_key_index ⇐ 0,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    debit_movement    ⇐ 100,
    credit_movement   ⇐ 0,
    movement          ⇐ 100,
    account_name      ⇐ "expenses:food",
    role              ⇐ "expense"
  },
  {
    account_key       ⇐ "expenses:rent/JPY",
    account_key_index ⇐ 1,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    debit_movement    ⇐ 0,
    credit_movement   ⇐ 0,
    movement          ⇐ 0,
    account_name      ⇐ "expenses:rent",
    role              ⇐ "expense"
  },
  {
    account_key       ⇐ "expenses:food/JPY",
    account_key_index ⇐ 0,
    layer_index       ⇐ cube.layer_plan,
    layer_name        ⇐ "plan",
    debit_movement    ⇐ 50,
    credit_movement   ⇐ 0,
    movement          ⇐ 50,
    account_name      ⇐ "expenses:food",
    role              ⇐ "expense"
  },
  {
    account_key       ⇐ "income:salary/JPY",
    account_key_index ⇐ 2,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    debit_movement    ⇐ 0,
    credit_movement   ⇐ ¯500000,
    movement          ⇐ ¯500000,
    account_name      ⇐ "income:salary",
    role              ⇐ ""
  }
⟩

pairs ← tbds_mod.ActualExpenseBreakdown tbdsRows
1 lib.AssertEq ≠ pairs
"expenses:food/JPY" lib.AssertEq (0 ⊑ (⊑ pairs))
100 lib.AssertEq (1 ⊑ (⊑ pairs))

# ── Build via context ───────────────────────────────────────

ctx ← { tbds ⇐ tbdsRows }
summary ← eb.Build ctx
1 lib.AssertEq ≠ summary.entries
"expenses:food/JPY" lib.AssertEq (0 ⊑ (⊑ summary.entries))
100 lib.AssertEq (1 ⊑ (⊑ summary.entries))
100 lib.AssertEq summary.total

# ── Format ───────────────────────────────────────────────────

text ← eb.Format summary
1 lib.AssertEq ∨´ "SrcNext Cycle Expense Breakdown"⍷text
1 lib.AssertEq ∨´ "src_next_cycle_expense_breakdown_total: 100"⍷text
1 lib.AssertEq ∨´ "expenses:food/JPY 100"⍷text

# ── Empty breakdown ──────────────────────────────────────────

emptyCtx ← { tbds ⇐ ⟨⟩ }
emptySummary ← eb.Build emptyCtx
0 lib.AssertEq ≠ emptySummary.entries
0 lib.AssertEq emptySummary.total
emptyText ← eb.Format emptySummary
1 lib.AssertEq ∨´ "(none)"⍷emptyText

•Out "test_src_next_expense_breakdown.bqn: OK"
