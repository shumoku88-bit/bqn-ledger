#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
cs ← •Import "../src_next/cycle_summary.bqn"
tbds ← •Import "../src_next/tbds.bqn"
proj ← •Import "../src_next/projection.bqn"

# 1. Root Context & Normal Case
root_ctx ← ctx_mod.BuildContext "fixtures/cycle-remaining-plan-characterization"
summary ← cs.Build root_ctx

# Assert O derivation: C.end_exclusive is 2026-03-01. O is 2026-02-15.
# end_dn (2026-03-01) - as_dn (2026-02-15) = 14 days
14 lib.AssertEq summary.days_remaining

# plan_expense_remaining should be 500 (today-expense 200 + future-expense 300)
# (past-expense 100, future-income 1000, outside-expense 400 are excluded)
500 lib.AssertEq summary.plan_expense_remaining


# Helper to build custom context pointing to subfixture base
MakeCustomCtx ← {𝕊 sub_dir:
  {
    base ⇐ sub_dir,
    cy ⇐ root_ctx.cy,
    resolved ⇐ root_ctx.resolved,
    posting_rows ⇐ root_ctx.posting_rows,
    arithmetic_currency_proof ⇐ root_ctx.arithmetic_currency_proof,
    cube ⇐ root_ctx.cube,
    tbds ⇐ root_ctx.tbds,
    issues ⇐ root_ctx.issues
  }
}

MakeCustomCtxWithRows ← {𝕊 sub_dir‿rows:
  {
    base ⇐ sub_dir,
    cy ⇐ root_ctx.cy,
    resolved ⇐ root_ctx.resolved,
    posting_rows ⇐ rows,
    arithmetic_currency_proof ⇐ root_ctx.arithmetic_currency_proof,
    cube ⇐ root_ctx.cube,
    tbds ⇐ root_ctx.tbds,
    issues ⇐ root_ctx.issues
  }
}

# 2. Subfixture: sub_reverse_journal
# Tests that O derivation is independent of journal source order.
rev_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_reverse_journal"
rev_sum ← cs.Build rev_ctx
14 lib.AssertEq rev_sum.days_remaining
500 lib.AssertEq rev_sum.plan_expense_remaining

# 3. Subfixture: sub_completion
# Tests that completed plans (plan_id with actual completion in journal)
# are STILL included in plan_expense_remaining by the current local parser.
comp_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_completion"
comp_sum ← cs.Build comp_ctx
300 lib.AssertEq comp_sum.plan_expense_remaining

# 4. Subfixture: sub_invalid_amount
# Tests zero-substitution for non-integer amounts.
# abc -> 0, 100.5 -> 0, 200 -> 200. Total = 200.
inv_amt_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_invalid_amount"
inv_amt_sum ← cs.Build inv_amt_ctx
200 lib.AssertEq inv_amt_sum.plan_expense_remaining

# 5. Subfixture: sub_unknown_account
# Tests unknown account exclusion (IsExpenseTo role fallback to empty).
# unknown-acc (300) is excluded, valid-acc (200) is included. Total = 200.
unk_acc_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_unknown_account"
unk_acc_sum ← cs.Build unk_acc_ctx
200 lib.AssertEq unk_acc_sum.plan_expense_remaining

# Checked Posting IR side validation for unknown-account
# Read files for sub_unknown_account
loader ← •Import "../src_next/loader.bqn"
unk_plan_lines ← loader.ReadLinesOptional "fixtures/cycle-remaining-plan-characterization/sub_unknown_account/plan.tsv"
shared_journal_lines ← loader.ReadLinesOptional "fixtures/cycle-remaining-plan-characterization/journal.tsv"
unk_snap ← {
  sources ⇐ ⟨
    {source_file⇐"journal.tsv", required⇐1, lines⇐shared_journal_lines},
    {source_file⇐"plan.tsv", required⇐0, lines⇐unk_plan_lines},
    {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
  ⟩
}
unk_proj ← ctx_mod.BuildCheckedPostingProjectionFromSnapshot ⟨unk_snap, root_ctx.resolved, root_ctx.cy.start⟩
target_rows ← (("plan.tsv"⊸≡¨ {𝕩.source_file}¨ unk_proj.posting_rows) ∧ (0 = {𝕩.source_row}¨ unk_proj.posting_rows)) / unk_proj.posting_rows
2 lib.AssertEq ≠ target_rows # Should return debit/credit pair
debit_row ← ⊑ ("debit"⊸≡¨ {𝕩.side}¨ target_rows) / target_rows
"debit" lib.AssertEq debit_row.side
"unknown_account" lib.AssertEq debit_row.status
"plan.tsv" lib.AssertEq debit_row.source_file
0 lib.AssertEq debit_row.source_row

credit_row ← ⊑ ("credit"⊸≡¨ {𝕩.side}¨ target_rows) / target_rows
"credit" lib.AssertEq credit_row.side
"unknown_account" lib.AssertEq credit_row.status
"plan.tsv" lib.AssertEq credit_row.source_file
0 lib.AssertEq credit_row.source_row

# 5b. Structurally unjoinable checked Posting IR evidence
# We create unjoinable rows by dropping the credit row of the future-expense pair (source_row 2).
future_rows ← (("plan.tsv"⊸≡¨ {𝕩.source_file}¨ root_ctx.posting_rows) ∧ (2 = {𝕩.source_row}¨ root_ctx.posting_rows)) / root_ctx.posting_rows
2 lib.AssertEq ≠ future_rows # Normal checks yield 1 debit and 1 credit row
IsTargetCredit ← { ("plan.tsv" ≡ 𝕩.source_file) ∧ (2 = 𝕩.source_row) ∧ ("credit" ≡ 𝕩.side) }
unjoinable_rows ← (¬ IsTargetCredit¨ root_ctx.posting_rows) / root_ctx.posting_rows

# Current cycle_summary local parser ignores join boundaries and sums all direct source amount texts
unjoinable_ctx ← MakeCustomCtxWithRows ⟨"fixtures/cycle-remaining-plan-characterization", unjoinable_rows⟩
unjoinable_sum ← cs.Build unjoinable_ctx
500 lib.AssertEq unjoinable_sum.plan_expense_remaining

# But the checked rows for source_row 2 do not form exactly one pair (missing credit row)
unjoined_pair ← (("plan.tsv"⊸≡¨ {𝕩.source_file}¨ unjoinable_rows) ∧ (2 = {𝕩.source_row}¨ unjoinable_rows)) / unjoinable_rows
1 lib.AssertEq ≠ unjoined_pair # Only 1 row (debit) exists, showing structural unjoinability

# 6. Subfixture: sub_invalid_date
# Tests that invalid date format (like "abc") crashes the BQN execution.
# We catch the error and assert it fails.
inv_date_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_invalid_date"
HasError ← {𝕊:
  # Try to build, if it throws an error return 1, else 0
  ({𝕊 ⋄ cs.Build inv_date_ctx ⋄ 0}⎊{𝕊 ⋄ 1}) @
}
1 lib.AssertEq HasError @

# 7. Subfixture: sub_empty_plan
# Empty plan.tsv returns 0.
empty_plan_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_empty_plan"
empty_plan_sum ← cs.Build empty_plan_ctx
0 lib.AssertEq empty_plan_sum.plan_expense_remaining

# 8. Subfixture: sub_no_actual
# No actual journal rows inside cycle: O falls back to cy.start (2026-02-01).
# days_remaining = 2026-03-01 - 2026-02-01 = 28 days.
# future-expense (300) on 2026-02-10 is included. Total = 300.
no_act_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_no_actual"
no_act_sum ← cs.Build no_act_ctx
28 lib.AssertEq no_act_sum.days_remaining
300 lib.AssertEq no_act_sum.plan_expense_remaining

# 9. Subfixture: sub_outside_actual
# Actual rows only outside cycle: O remains cy.start (2026-02-01).
# Total = 300.
out_act_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_outside_actual"
out_act_sum ← cs.Build out_act_ctx
28 lib.AssertEq out_act_sum.days_remaining
300 lib.AssertEq out_act_sum.plan_expense_remaining

# 10. Fallback: context without base
# Uses fallback_total which is tbds.PlanExpenseAmount (from root_ctx.tbds).
no_base_ctx ← {
  cy ⇐ root_ctx.cy,
  resolved ⇐ root_ctx.resolved,
  posting_rows ⇐ root_ctx.posting_rows,
  arithmetic_currency_proof ⇐ root_ctx.arithmetic_currency_proof,
  cube ⇐ root_ctx.cube,
  tbds ⇐ root_ctx.tbds,
  issues ⇐ root_ctx.issues
}
no_base_sum ← cs.Build no_base_ctx
no_base_sum.plan_expense lib.AssertEq no_base_sum.plan_expense_remaining

# 11. Exact-decimal plan input vs local parser
# Reuse "fixtures/currency-usd-single" context.
usd_ctx ← ctx_mod.BuildContext "fixtures/currency-usd-single"
usd_sum ← cs.Build usd_ctx
# USD scale is 2, so 49.99 becomes 4999 in TBDS.
# Local parser in PlanExpenseRemaining fails IsIntegerText("49.99"), returning 0.
4999 lib.AssertEq usd_sum.plan_expense
0 lib.AssertEq usd_sum.plan_expense_remaining

# 12. Subfixture: sub_duplicate_plan_id & sub_duplicate_plan_id_rev
# Tests that duplicate plan_id is not treated as an error by current local parser.
# It simply sums up both rows (300 + 200 = 500) and is order-independent.
dup_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_duplicate_plan_id"
dup_sum ← cs.Build dup_ctx
500 lib.AssertEq dup_sum.plan_expense_remaining

dup_rev_ctx ← MakeCustomCtx "fixtures/cycle-remaining-plan-characterization/sub_duplicate_plan_id_rev"
dup_rev_sum ← cs.Build dup_rev_ctx
500 lib.AssertEq dup_rev_sum.plan_expense_remaining

# 13. Admitted Source Identities Characterization
# Assert that root_ctx.posting_rows contains the checked Posting IR evidence
# for the normal contributing plan source rows (source_row 1 and 2 of plan.tsv).
normal_rows ← root_ctx.posting_rows

# Row 1 (today-expense, amount 200)
row1_pair ← (("plan.tsv"⊸≡¨ {𝕩.source_file}¨ normal_rows) ∧ (1 = {𝕩.source_row}¨ normal_rows)) / normal_rows
2 lib.AssertEq ≠ row1_pair
row1_debit ← ⊑ ("debit"⊸≡¨ {𝕩.side}¨ row1_pair) / row1_pair
"ok" lib.AssertEq row1_debit.status
200 lib.AssertEq row1_debit.delta

# Row 2 (future-expense, amount 300)
row2_pair ← (("plan.tsv"⊸≡¨ {𝕩.source_file}¨ normal_rows) ∧ (2 = {𝕩.source_row}¨ normal_rows)) / normal_rows
2 lib.AssertEq ≠ row2_pair
row2_debit ← ⊑ ("debit"⊸≡¨ {𝕩.side}¨ row2_pair) / row2_pair
"ok" lib.AssertEq row2_debit.status
300 lib.AssertEq row2_debit.delta

# Total matches current local parser result
(row1_debit.delta + row2_debit.delta) lib.AssertEq summary.plan_expense_remaining

•Out "test_src_next_cycle_remaining_plan_characterization.bqn: OK"
