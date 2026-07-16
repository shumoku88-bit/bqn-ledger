#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
remaining_plan ← •Import "../src_next/outlook_remaining_plan.bqn"
outlook ← •Import "../src_next/outlook.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 journal_lines‿plan_lines:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐journal_lines},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plan_lines},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
    ⟩
  }
}

base ← "fixtures/outlook-remaining-plan-numeric-owner-target"
ctx ← ctx_mod.BuildContext base
observation ← "2026-02-05"

ContextWithRows ← {𝕊 rows:
  {
    base ⇐ ctx.base,
    as_of ⇐ ctx.as_of,
    cy ⇐ ctx.cy,
    resolved ⇐ ctx.resolved,
    posting_rows ⇐ rows,
    arithmetic_currency_proof ⇐ ctx.arithmetic_currency_proof,
    cube ⇐ ctx.cube,
    tbds ⇐ ctx.tbds,
    issues ⇐ ctx.issues
  }
}

RowsFor ← {𝕊 journal_lines‿plan_lines:
  result ← ctx_mod.BuildCheckedPostingProjectionFromSnapshot ⟨Snapshot ⟨journal_lines, plan_lines⟩, ctx.resolved, ctx.cy.start⟩
  "ok" lib.AssertEq result.state
  result.posting_rows
}

EvidenceFor ← {𝕊 plan_lines‿journal_lines:
  remaining_plan.BuildEvidenceFromLinesForTest ⟨plan_lines, journal_lines, ctx.cy⟩
}

# Target matrix. Checked plan postings own money, plan-ID evidence owns completion,
# and actual income-credit evidence through O owns anchor activation.
remaining ← remaining_plan.BuildAt ⟨ctx, observation⟩
"ok" lib.AssertEq remaining.state
"remaining_plan_active" lib.AssertEq remaining.reason
0 lib.AssertEq ≠ remaining.diagnostics
30 lib.AssertEq remaining.future_planned_liquid_net
90 lib.AssertEq remaining.planned_future_income
60 lib.AssertEq remaining.fixed_reserve

vm ← outlook.BuildAt ⟨ctx, observation⟩
"ok" lib.AssertEq vm.state
"outlook_active" lib.AssertEq vm.reason
920 lib.AssertEq vm.liq_total
90 lib.AssertEq vm.planned_future_income
60 lib.AssertEq vm.fixed_reserve
158 lib.AssertEq vm.liq_daily
143 lib.AssertEq vm.liq_safe_daily

# Numeric-owner proof: source evidence says 999, while the admitted Posting IR for
# the same stable source row says 10. The result must be 10, not 999.
posting_line ← Line ⟨"2026-02-05", "owner-proof", "assets:cash", "expenses:unanchored", "10"⟩
evidence_line ← Line ⟨"2026-02-05", "owner-proof", "assets:cash", "expenses:unanchored", "999"⟩
owner_rows ← RowsFor ⟨⟨⟩, ⟨posting_line⟩⟩
owner_evidence ← EvidenceFor ⟨⟨evidence_line⟩, ⟨⟩⟩
owner_result ← remaining_plan.BuildFromEvidenceForTest ⟨ContextWithRows owner_rows, observation, owner_evidence⟩
"ok" lib.AssertEq owner_result.state
10 lib.AssertEq owner_result.fixed_reserve
¯10 lib.AssertEq owner_result.future_planned_liquid_net

SinglePlanResult ← {𝕊 posting_line‿evidence_line:
  rows ← RowsFor ⟨⟨⟩, ⟨posting_line⟩⟩
  evidence ← EvidenceFor ⟨⟨evidence_line⟩, ⟨⟩⟩
  remaining_plan.BuildFromEvidenceForTest ⟨ContextWithRows rows, observation, evidence⟩
}

# Invalid anchor metadata and account meaning fail Outlook closed.
unknown_anchor_line ← Line ⟨"2026-02-06", "bad-anchor", "assets:cash", "expenses:unanchored", "10", "anchor=income:missing"⟩
unknown_anchor ← SinglePlanResult ⟨unknown_anchor_line, unknown_anchor_line⟩
"error" lib.AssertEq unknown_anchor.state
"rejected_plan_evidence" lib.AssertEq unknown_anchor.reason
1 lib.AssertEq ≠ unknown_anchor.diagnostics
"unknown_anchor" lib.AssertEq (⊑ unknown_anchor.diagnostics).status
"unavailable" lib.AssertEq unknown_anchor.fixed_reserve

non_income_line ← Line ⟨"2026-02-06", "bad-role", "assets:cash", "expenses:unanchored", "10", "anchor=assets:cash"⟩
non_income ← SinglePlanResult ⟨non_income_line, non_income_line⟩
"error" lib.AssertEq non_income.state
"non_income_anchor" lib.AssertEq (⊑ non_income.diagnostics).status

duplicate_line ← Line ⟨"2026-02-06", "duplicate", "assets:cash", "expenses:unanchored", "10", "anchor=income:salary", "anchor=income:pension"⟩
duplicate ← SinglePlanResult ⟨duplicate_line, duplicate_line⟩
"error" lib.AssertEq duplicate.state
"duplicate_anchor" lib.AssertEq (⊑ duplicate.diagnostics).status

empty_line ← Line ⟨"2026-02-06", "empty", "assets:cash", "expenses:unanchored", "10", "anchor="⟩
empty_anchor ← SinglePlanResult ⟨empty_line, empty_line⟩
"error" lib.AssertEq empty_anchor.state
"empty_anchor" lib.AssertEq (⊑ empty_anchor.diagnostics).status

# Applicable rejected plan evidence produces one source-row diagnostic despite
# the debit/credit posting pair.
unknown_account_line ← Line ⟨"2026-02-06", "unknown-account", "assets:missing", "expenses:unanchored", "10"⟩
unknown_account ← SinglePlanResult ⟨unknown_account_line, unknown_account_line⟩
"error" lib.AssertEq unknown_account.state
1 lib.AssertEq ≠ unknown_account.diagnostics
"unknown_account" lib.AssertEq (⊑ unknown_account.diagnostics).status

# Invalid-date plan evidence has unknown applicability and therefore fails closed.
invalid_date_line ← Line ⟨"2026-02-30", "invalid-date", "assets:cash", "expenses:unanchored", "10"⟩
invalid_date ← SinglePlanResult ⟨invalid_date_line, invalid_date_line⟩
"error" lib.AssertEq invalid_date.state
"invalid_date" lib.AssertEq (⊑ invalid_date.diagnostics).status

# A valid rejected row after the current horizon does not fail this aggregate.
outside_line ← Line ⟨"2026-02-11", "outside", "assets:missing", "expenses:unanchored", "10"⟩
outside ← SinglePlanResult ⟨outside_line, outside_line⟩
"ok" lib.AssertEq outside.state
0 lib.AssertEq outside.fixed_reserve
0 lib.AssertEq outside.future_planned_liquid_net

# Outlook propagates remaining-plan failure and suppresses every monetary field.
error_ctx ← ContextWithRows (RowsFor ⟨⟨⟩, ⟨unknown_anchor_line⟩⟩)
# BuildAt reads source evidence from the fixture, so exercise propagation through
# a context-like fixture seam by calling the helper result and checking ErrorVm
# behavior via the historical invalid-anchor fixture below.
characterization_ctx ← ctx_mod.BuildContext "fixtures/outlook-actual-snapshot-characterization"
characterization_vm ← outlook.BuildAt ⟨characterization_ctx, observation⟩
"error" lib.AssertEq characterization_vm.state
"rejected_plan_evidence" lib.AssertEq characterization_vm.reason
"unknown_anchor" lib.AssertEq (⊑ characterization_vm.diagnostics).status
"unavailable" lib.AssertEq characterization_vm.liq_total
"unavailable" lib.AssertEq characterization_vm.liq_daily

machine ← outlook.Format characterization_vm
1 lib.AssertEq ∨´ "src_next_outlook_status: error"⍷machine
1 lib.AssertEq ∨´ "src_next_outlook_reason: rejected_plan_evidence"⍷machine
1 lib.AssertEq ∨´ "src_next_outlook_diagnostic: plan.tsv"⍷machine

•Out "test_src_next_outlook_remaining_plan_numeric_owner.bqn: OK"
