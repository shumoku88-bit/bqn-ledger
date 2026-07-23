#!/usr/bin/env bqn

# Runtime target contract over the public characterization fixtures.

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
cs ← •Import "../src_next/cycle_summary.bqn"
loader ← •Import "../src_next/loader.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
labels ← •Import "../src_next/report_labels.bqn"
fmt ← •Import "../src_next/format.bqn"

fmt.SetColorEnabled 0
L ← labels.Text
Contains ← {𝕊 haystack‿needle: ∨´ needle ⍷ haystack }

root_base ← "fixtures/cycle-remaining-plan-characterization"
root_ctx ← ctx_mod.BuildContext root_base

PostingRowsForBase ← {𝕊 base:
  snapshot ← ctx_mod.LoadNonActualPostingSourceSnapshot base
  projection ← ctx_mod.BuildCheckedPostingProjectionFromSnapshot ⟨snapshot,root_ctx.resolved,root_ctx.cy.start⟩
  txs ← actual_source.LoadTransactions base
  actual ← adapter.BuildForSource ⟨txs,root_ctx.resolved,root_ctx.cy.start,(actual_source.Resolve base).file⟩
  actual.posting_rows∾projection.posting_rows
}

MakeCustomCtxWithRows ← {𝕊 base‿rows:
  {
    base ⇐ base,
    cy ⇐ root_ctx.cy,
    resolved ⇐ root_ctx.resolved,
    posting_rows ⇐ rows,
    arithmetic_currency_proof ⇐ root_ctx.arithmetic_currency_proof,
    cube ⇐ root_ctx.cube,
    tbds ⇐ root_ctx.tbds,
    issues ⇐ root_ctx.issues
  }
}

MakeCustomCtx ← {𝕊 base:
  MakeCustomCtxWithRows ⟨base, PostingRowsForBase base⟩
}

# 1. Normal case keeps the current temporal boundary and checked amount.
summary ← cs.Build root_ctx
"ok" lib.AssertEq summary.state
"remaining_plan_active" lib.AssertEq summary.reason
0 lib.AssertEq ≠ summary.diagnostics
14 lib.AssertEq summary.days_remaining
500 lib.AssertEq summary.plan_expense_remaining

normal_machine ← cs.Format summary
lib.Assert Contains ⟨normal_machine, "src_next_cycle_state: ok"⟩
lib.Assert Contains ⟨normal_machine, "src_next_cycle_plan_expense_remaining: 500"⟩

# 2. Journal source order does not change O or the remaining amount.
rev_ctx ← MakeCustomCtx (root_base ∾ "/sub_reverse_journal")
rev_sum ← cs.Build rev_ctx
"ok" lib.AssertEq rev_sum.state
14 lib.AssertEq rev_sum.days_remaining
500 lib.AssertEq rev_sum.plan_expense_remaining

# 3. Completed plan identity is excluded from remaining expense.
comp_ctx ← MakeCustomCtx (root_base ∾ "/sub_completion")
comp_sum ← cs.Build comp_ctx
"ok" lib.AssertEq comp_sum.state
0 lib.AssertEq comp_sum.plan_expense_remaining

# 4. Applicable unknown-account evidence stops the whole Cycle Summary.
unk_ctx ← MakeCustomCtx (root_base ∾ "/sub_unknown_account")
unk_sum ← cs.Build unk_ctx
"error" lib.AssertEq unk_sum.state
"rejected_plan_evidence" lib.AssertEq unk_sum.reason
"unavailable" lib.AssertEq unk_sum.plan_expense_remaining
1 lib.AssertEq ≠ unk_sum.diagnostics
unk_diag ← ⊑ unk_sum.diagnostics
"plan.tsv" lib.AssertEq unk_diag.source_file
0 lib.AssertEq unk_diag.source_row
"unknown_account" lib.AssertEq unk_diag.status

unk_machine ← cs.Format unk_sum
lib.Assert Contains ⟨unk_machine, "src_next_cycle_state: error"⟩
lib.Assert Contains ⟨unk_machine, "src_next_cycle_diagnostic_1_status: unknown_account"⟩
0 lib.AssertEq Contains ⟨unk_machine, "src_next_cycle_income_actual:"⟩
0 lib.AssertEq Contains ⟨unk_machine, "src_next_cycle_plan_expense_remaining:"⟩

unk_human ← cs.FormatHuman ⟨unk_sum, ⟨⟩⟩
lib.Assert Contains ⟨unk_human, "ERROR: Cycle Summary stopped"⟩
lib.Assert Contains ⟨unk_human, "unknown_account"⟩
0 lib.AssertEq Contains ⟨unk_human, L "cycle.income_total_label"⟩
0 lib.AssertEq Contains ⟨unk_human, L "cycle.planned_remaining_label"⟩

# 5. Missing half of an applicable Posting IR pair stops the section.
IsTargetCredit ← { ("plan.tsv" ≡ 𝕩.source_file) ∧ (2 = 𝕩.source_row) ∧ ("credit" ≡ 𝕩.side) }
unjoinable_rows ← (¬ IsTargetCredit¨ root_ctx.posting_rows) / root_ctx.posting_rows
unjoinable_ctx ← MakeCustomCtxWithRows ⟨root_base, unjoinable_rows⟩
unjoinable_sum ← cs.Build unjoinable_ctx
"error" lib.AssertEq unjoinable_sum.state
1 lib.AssertEq ≠ unjoinable_sum.diagnostics
unjoinable_diag ← ⊑ unjoinable_sum.diagnostics
"structural_join" lib.AssertEq unjoinable_diag.status
"unavailable" lib.AssertEq unjoinable_sum.income_actual

# 6. Each invalid plan date becomes one controlled source-row diagnostic.
inv_date_ctx ← MakeCustomCtx (root_base ∾ "/sub_invalid_date")
inv_date_sum ← cs.Build inv_date_ctx
"error" lib.AssertEq inv_date_sum.state
2 lib.AssertEq ≠ inv_date_sum.diagnostics
inv_date_diag1 ← 0⊑inv_date_sum.diagnostics
inv_date_diag2 ← 1⊑inv_date_sum.diagnostics
"invalid_date" lib.AssertEq inv_date_diag1.status
"invalid_date" lib.AssertEq inv_date_diag2.status
0 lib.AssertEq inv_date_diag1.source_row
1 lib.AssertEq inv_date_diag2.source_row

# 7. Empty plan input is valid and returns a real zero.
empty_ctx ← MakeCustomCtx (root_base ∾ "/sub_empty_plan")
empty_sum ← cs.Build empty_ctx
"ok" lib.AssertEq empty_sum.state
0 lib.AssertEq empty_sum.plan_expense_remaining

# 8. No actual row in the cycle keeps O = C.start.
no_actual_ctx ← MakeCustomCtx (root_base ∾ "/sub_no_actual")
no_actual_sum ← cs.Build no_actual_ctx
"ok" lib.AssertEq no_actual_sum.state
28 lib.AssertEq no_actual_sum.days_remaining
300 lib.AssertEq no_actual_sum.plan_expense_remaining

# 9. Actual rows outside the cycle do not move O.
outside_actual_ctx ← MakeCustomCtx (root_base ∾ "/sub_outside_actual")
outside_actual_sum ← cs.Build outside_actual_ctx
"ok" lib.AssertEq outside_actual_sum.state
28 lib.AssertEq outside_actual_sum.days_remaining
300 lib.AssertEq outside_actual_sum.plan_expense_remaining

# 10. Context without base retains the narrow direct-call compatibility fallback.
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
"ok" lib.AssertEq no_base_sum.state
"no_base_compatibility" lib.AssertEq no_base_sum.reason
no_base_sum.plan_expense lib.AssertEq no_base_sum.plan_expense_remaining

# 11. Duplicate plan identity remains exact-any-match compatible and order-independent.
dup_ctx ← MakeCustomCtx (root_base ∾ "/sub_duplicate_plan_id")
dup_sum ← cs.Build dup_ctx
"ok" lib.AssertEq dup_sum.state
500 lib.AssertEq dup_sum.plan_expense_remaining

dup_rev_ctx ← MakeCustomCtx (root_base ∾ "/sub_duplicate_plan_id_rev")
dup_rev_sum ← cs.Build dup_rev_ctx
"ok" lib.AssertEq dup_rev_sum.state
500 lib.AssertEq dup_rev_sum.plan_expense_remaining

•Out "test_src_next_cycle_remaining_plan_characterization.bqn: OK"
