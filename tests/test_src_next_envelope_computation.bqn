#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
context ← •Import "../src_next/context.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
env ← •Import "../src_next/envelope_computation.bqn"
hm ← •Import "../src_next/household_metadata.bqn"
readiness ← •Import "../src_next/readiness_check.bqn"

base ← "fixtures/src-next-envelope-computation"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base
ledger ← context.BuildContext base
rows ← ledger.posting_rows
result ← ledger.cube
tbds_rows ← ledger.tbds
summary ← env.Build { base ⇐ base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ result, tbds ⇐ tbds_rows }

"fixture_food_like" lib.AssertEq summary.target_id
"食費" lib.AssertEq summary.label
"budget=食費" lib.AssertEq summary.selector
"computed" lib.AssertEq summary.status
1 lib.AssertEq summary.selected_expense_account_count
1 lib.AssertEq summary.allocation_row_count
1000 lib.AssertEq summary.allocated
350 lib.AssertEq summary.actual_spent
650 lib.AssertEq summary.remaining
¯1800 lib.AssertEq summary.unassigned_remaining
"OVER_ALLOCATED" lib.AssertEq summary.unassigned_status
1 lib.AssertEq summary.unassigned_account_count
0 lib.AssertEq summary.funding_base
1070 lib.AssertEq summary.allocated_total
¯1070 lib.AssertEq summary.cash_backed_unassigned
730 lib.AssertEq summary.ledger_cash_delta
"OVER_ALLOCATED" lib.AssertEq summary.backing_status
roles ← {𝕩.envelope_role}¨ summary.envelopes
1 lib.AssertEq ∨´ "dynamic"⊸≡¨ roles
1 lib.AssertEq ∨´ "execution"⊸≡¨ roles
1 lib.AssertEq ∨´ "unknown"⊸≡¨ roles
"HELD" lib.AssertEq env.ExecutionStatus ⟨500, 420, 80⟩
"DONE" lib.AssertEq env.ExecutionStatus ⟨500, 0, 500⟩
"DRAWN" lib.AssertEq env.ExecutionStatus ⟨500, ¯100, 600⟩

# Planned spending is present (200) but the prototype remaining does not subtract it.
200 lib.AssertEq result.plan_expense_total
650 lib.AssertEq summary.remaining

# Missing budget metadata must not be silently assigned to the target.
# Fixture has 90 of actual spending on expenses:missing; actual_spent remains 350.
520 lib.AssertEq result.actual_expense_total
350 lib.AssertEq summary.actual_spent

text ← env.Format summary
0 lib.AssertEq +´ ("safe_remaining" ⍷ text)
0 lib.AssertEq +´ ("daily_amount" ⍷ text)
0 lib.AssertEq +´ ("src_next_envelope_active_remaining_source: 謎" ⍷ text)
0 lib.AssertEq +´ ("src_next_envelope_active_movement: 2026-01-01\t2\tbudget:謎" ⍷ text)

human ← env.FormatHuman summary
1 lib.AssertEq ∨´ "[Dynamic envelopes]"⍷human
1 lib.AssertEq ∨´ "[Execution envelopes]"⍷human
1 lib.AssertEq ∨´ "[Unknown role envelopes]"⍷human
1 lib.AssertEq ∨´ "[Unassigned]"⍷human
1 lib.AssertEq ∨´ "Group        | Envelope | Allocated"⍷human
1 lib.AssertEq ∨´ "life_primary | 食費     |      1000 |   350 |     650"⍷human
1 lib.AssertEq ∨´ "life_primary | 日用品   |  500 |       80 |       420 | HELD"⍷human
1 lib.AssertEq ∨´ "life_primary | 謎       |       300 |     0 |     300 | unknown_role"⍷human
1 lib.AssertEq ∨´ "unknown envelope_role は active envelope total に含めず"⍷human
1 lib.AssertEq ∨´ "[Backing check]"⍷human
1 lib.AssertEq ∨´ "封筒対象資金(暫定:type=liquid): 0"⍷human
1 lib.AssertEq ∨´ "active封筒残高合計:              1070"⍷human
1 lib.AssertEq ∨´ "現金裏付け未割当:                -1070"⍷human
1 lib.AssertEq ∨´ "[Budget ledger]"⍷human
1 lib.AssertEq ∨´ "予算台帳未割当:                   -1800"⍷human
1 lib.AssertEq ∨´ "現金裏付け未割当 - 予算台帳未割当: 730"⍷human
1 lib.AssertEq ∨´ "status: OVER_ALLOCATED"⍷human
1 lib.AssertEq ∨´ "[Backing provenance]"⍷human
1 lib.AssertEq ∨´ "funding_base sources:"⍷human
1 lib.AssertEq ∨´ "(none)"⍷human
1 lib.AssertEq ∨´ "active envelope remaining:"⍷human
1 lib.AssertEq ∨´ "食費   |    650"⍷human
1 lib.AssertEq ∨´ "日用品 |    420"⍷human
1 lib.AssertEq ∨´ "ledger unassigned source:"⍷human
1 lib.AssertEq ∨´ "budget:unassigned |  -1800"⍷human
1 lib.AssertEq ∨´ "[Budget movement provenance]"⍷human
1 lib.AssertEq ∨´ "ledger unassigned movements:"⍷human
1 lib.AssertEq ∨´ "2026-01-01 |  #0 | budget:unassigned | credit | -1000 | alloc_food"⍷human
1 lib.AssertEq ∨´ "2026-01-01 |  #1 | budget:unassigned | credit |  -500 | alloc_goods"⍷human
1 lib.AssertEq ∨´ "2026-01-01 |  #2 | budget:unassigned | credit |  -300 | alloc_unknown"⍷human
1 lib.AssertEq ∨´ "active envelope movements:"⍷human
1 lib.AssertEq ∨´ "2026-01-01 |  #0 | budget:食費   | debit |  1000 | alloc_food"⍷human
1 lib.AssertEq ∨´ "2026-01-01 |  #1 | budget:日用品 | debit |   500 | alloc_goods"⍷human

# Prefix-shaped accounts with missing roles remain diagnostic-only even when their
# budget/kind metadata would otherwise make them selectable.
negative_base ← "fixtures/src-next-envelope-computation-prefix-negative"
negative_ctx ← context.BuildContext negative_base
negative_resolved ← negative_ctx.resolved
negative_tgt ← env.FixtureFoodLikeTarget @
0 lib.AssertEq ≠ env.SelectedExpenseIndices ⟨negative_tgt, negative_resolved⟩
0 lib.AssertEq ≠ env.TargetBudgetAccountIndices ⟨negative_tgt, negative_resolved⟩
0 lib.AssertEq ≠ env.UnassignedBudgetAccountIndices negative_resolved
negative_summary ← env.Build negative_ctx
0 lib.AssertEq ≠ negative_summary.envelopes
0 lib.AssertEq negative_summary.selected_expense_account_count
0 lib.AssertEq negative_summary.target_budget_account_count
0 lib.AssertEq negative_summary.unassigned_account_count
negative_diag ← hm.Build negative_ctx
1 lib.AssertEq negative_diag.prefix_fallback_expense_count
2 lib.AssertEq negative_diag.prefix_fallback_budget_count
0 lib.AssertEq negative_diag.expense_accounts_total
negative_readiness ← readiness.Build negative_ctx
3 lib.AssertEq ≠ negative_readiness.missing_role_accounts

# No allocation: target exists and actual can be observed, but status is unavailable
# and formatted amounts are not polished remaining values.
tgt ← env.FixtureFoodLikeTarget @
no_alloc ← env.BuildFromInputs ⟨tgt, resolved, cy, result.valid_rows, ⟨⟩⟩
"unavailable/no_policy" lib.AssertEq no_alloc.status
0 lib.AssertEq no_alloc.allocation_row_count
no_alloc_text ← env.Format no_alloc
1 lib.AssertEq (1 ≤ +´ ("src_next_envelope_remaining: unavailable/no_policy" ⍷ no_alloc_text))

# No fixture policy source: production-like bases must not compute.
no_policy ← env.BuildFromInputs ⟨env.NoPolicyTarget @, resolved, cy, result.valid_rows, loader.ReadLines (base ∾ "/budget_alloc.tsv")⟩
"unavailable/no_policy" lib.AssertEq no_policy.status
"unavailable/no_policy" lib.AssertEq no_policy.target_id

•Out "test_src_next_envelope_computation.bqn: OK"
