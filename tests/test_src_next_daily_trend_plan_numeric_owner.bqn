#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
trend_plan ← •Import "../src_next/daily_trend_plan.bqn"
daily_trend ← •Import "../src_next/daily_trend.bqn"

tab ← @+9
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
Snapshot ← {𝕊 plan_lines:
  {
    sources ⇐ ⟨
      {source_file⇐"actual.journal", required⇐1, lines⇐⟨⟩},
      {source_file⇐"plan.tsv", required⇐0, lines⇐plan_lines},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
    ⟩
  }
}

base ← "fixtures/daily-trend-plan-numeric-owner-target"
ctx ← ctx_mod.BuildContext base
trend_dates ← ⟨"2026-02-01", "2026-02-03", "2026-02-06", "2026-02-09"⟩

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

RowsFor ← {𝕊 plan_lines:
  result ← ctx_mod.BuildCheckedPostingProjectionFromSnapshot ⟨Snapshot plan_lines, ctx.resolved, ctx.cy.start⟩
  "ok" lib.AssertEq result.state
  result.posting_rows
}

EvidenceFor ← {𝕊 plan_lines‿journal_lines:
  trend_plan.BuildEvidenceFromLinesForTest ⟨plan_lines, journal_lines⟩
}

# Characterization: D-local reserve membership, same-day completion, completion
# before due date, multiple plans per day, cycle boundaries, and header O isolation.
plan_vm ← trend_plan.BuildAt ⟨ctx, trend_dates⟩
"ok" lib.AssertEq plan_vm.state
"daily_trend_plan_active" lib.AssertEq plan_vm.reason
⟨201, 171, 70, 70⟩ lib.AssertEq plan_vm.reserves

vm ← daily_trend.BuildAt ⟨ctx, "2026-02-09"⟩
"ok" lib.AssertEq vm.state
trend_dates lib.AssertEq {0⊑𝕩}¨ vm.trend_rows
⟨201, 171, 70, 70⟩ lib.AssertEq {2⊑𝕩}¨ vm.trend_rows
# The admitted future inflow contributes 50 at D=2026-02-06, while the
# same-day D=2026-02-01 inflow is not future and end_exclusive is excluded.
15 lib.AssertEq 3⊑ 2⊑ vm.trend_rows

# numeric_owner proof: source evidence says 999, but the admitted Posting IR
# joined at the same source_row says 10. Reserve must use the debit delta 10.
posting_line ← Line ⟨"2026-02-05", "owner-proof", "assets:cash", "expenses:fixed", "10", "plan_id=owner"⟩
evidence_line ← Line ⟨"2026-02-05", "owner-proof", "assets:cash", "expenses:fixed", "999", "plan_id=owner"⟩
owner_rows ← RowsFor ⟨posting_line⟩
owner_evidence ← EvidenceFor ⟨⟨evidence_line⟩, ⟨⟩⟩
owner ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows owner_rows, ⟨"2026-02-03"⟩, owner_evidence⟩
"ok" lib.AssertEq owner.state
⟨10⟩ lib.AssertEq owner.reserves

SingleResult ← {𝕊 posting_line‿evidence_line:
  rows ← RowsFor ⟨posting_line⟩
  evidence ← EvidenceFor ⟨⟨evidence_line⟩, ⟨⟩⟩
  trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows rows, ⟨"2026-02-03"⟩, evidence⟩
}

# Applicable unknown account evidence is rejected rather than treated as zero.
unknown_line ← Line ⟨"2026-02-05", "unknown", "assets:cash", "expenses:missing", "10", "plan_id=unknown"⟩
unknown ← SingleResult ⟨unknown_line, unknown_line⟩
"error" lib.AssertEq unknown.state
"rejected_plan_evidence" lib.AssertEq unknown.reason
"unknown_account" lib.AssertEq (⊑ unknown.diagnostics).status
0 lib.AssertEq ≠ unknown.reserves
error_vm ← {
  state ⇐ unknown.state,
  reason ⇐ unknown.reason,
  diagnostics ⇐ unknown.diagnostics,
  trend_rows ⇐ ⟨⟩,
  top_drops ⇐ ⟨⟩,
  obs_days ⇐ 1,
  as_of ⇐ "2026-02-03",
  header_O ⇐ "2026-02-03",
  cycle_start ⇐ ctx.cy.start,
  cycle_end_exclusive ⇐ ctx.cy.end_exclusive,
  cycle_mode ⇐ ctx.cy.mode
}
error_machine ← daily_trend.Format error_vm
1 lib.AssertEq ∨´ "src_next_daily_trend_status: error"⍷error_machine
1 lib.AssertEq ∨´ "src_next_daily_trend_diagnostic: plan.tsv"⍷error_machine
0 lib.AssertEq ∨´ "src_next_daily_trend: 2026"⍷error_machine

# Invalid dates have unknown applicability and fail closed.
invalid_line ← Line ⟨"2026-02-30", "invalid", "assets:cash", "expenses:fixed", "10", "plan_id=invalid"⟩
invalid ← SingleResult ⟨posting_line, invalid_line⟩
"error" lib.AssertEq invalid.state
"invalid_date" lib.AssertEq (⊑ invalid.diagnostics).status

# Stable join failure is structural, never a local zero.
join_evidence ← EvidenceFor ⟨⟨evidence_line⟩, ⟨⟩⟩
join_failure ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows 1↓owner_rows, ⟨"2026-02-03"⟩, join_evidence⟩
"error" lib.AssertEq join_failure.state
"structural_join" lib.AssertEq (⊑ join_failure.diagnostics).status

# The five-field evidence shape is required even though its amount text is not
# parsed by this helper.
short_line ← "2026-02-05" ∾ tab ∾ "short" ∾ tab ∾ "assets:cash" ∾ tab ∾ "expenses:fixed"
short_evidence ← EvidenceFor ⟨⟨short_line⟩, ⟨⟩⟩
missing ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows owner_rows, ⟨"2026-02-03"⟩, short_evidence⟩
"error" lib.AssertEq missing.state
"missing_required_fields" lib.AssertEq (⊑ missing.diagnostics).status

# Identity compatibility is unchanged. Metadata absence and explicit empty
# plan_id= both use the existing five-field fallback identity.
fallback_fields ← ⟨"2026-02-05", "fallback", "assets:cash", "expenses:fixed", "10"⟩
fallback_id ← ∾ fallback_fields
absent_line ← Line fallback_fields
empty_line ← Line fallback_fields ∾ ⟨"plan_id="⟩
absent_evidence ← EvidenceFor ⟨⟨absent_line⟩, ⟨absent_line⟩⟩
empty_evidence ← EvidenceFor ⟨⟨empty_line⟩, ⟨empty_line⟩⟩
fallback_id lib.AssertEq (⊑ absent_evidence.plans).plan_id
fallback_id lib.AssertEq (⊑ empty_evidence.plans).plan_id
absent ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨absent_line⟩, ⟨"2026-02-03", "2026-02-05"⟩, absent_evidence⟩
empty ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨empty_line⟩, ⟨"2026-02-03", "2026-02-05"⟩, empty_evidence⟩
"ok" lib.AssertEq absent.state
"ok" lib.AssertEq empty.state
⟨10, 0⟩ lib.AssertEq absent.reserves
absent.reserves lib.AssertEq empty.reserves

# Duplicate metadata preserves overlap.PlanId first-match precedence. Duplicate
# plan/completion identities retain prior exact-any-match behavior; this numeric
# owner migration does not promote overlap diagnostics into a new error policy.
dup_meta_plan ← Line ⟨"2026-02-05", "dup-meta", "assets:cash", "expenses:fixed", "10", "plan_id=first", "plan_id=second"⟩
dup_meta_completion ← Line ⟨"2026-02-03", "actual", "assets:cash", "expenses:fixed", "10", "plan_id=first"⟩
dup_meta_evidence ← EvidenceFor ⟨⟨dup_meta_plan⟩, ⟨dup_meta_completion⟩⟩
"first" lib.AssertEq (⊑ dup_meta_evidence.plans).plan_id
dup_meta ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨dup_meta_plan⟩, ⟨"2026-02-03"⟩, dup_meta_evidence⟩
"ok" lib.AssertEq dup_meta.state
⟨0⟩ lib.AssertEq dup_meta.reserves

dup_a ← Line ⟨"2026-02-05", "dup-a", "assets:cash", "expenses:fixed", "10", "plan_id=dup"⟩
dup_b ← Line ⟨"2026-02-06", "dup-b", "assets:cash", "expenses:fixed", "20", "plan_id=dup"⟩
dup_rows ← RowsFor ⟨dup_a, dup_b⟩
dup_evidence ← EvidenceFor ⟨⟨dup_a, dup_b⟩, ⟨⟩⟩
dup ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows dup_rows, ⟨"2026-02-03"⟩, dup_evidence⟩
"ok" lib.AssertEq dup.state
⟨30⟩ lib.AssertEq dup.reserves

outside_dup ← Line ⟨"2026-02-11", "outside-dup", "assets:cash", "expenses:fixed", "99", "plan_id=dup"⟩
outside_rows ← RowsFor ⟨dup_a, outside_dup⟩
outside_evidence ← EvidenceFor ⟨⟨dup_a, outside_dup⟩, ⟨⟩⟩
outside_result ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows outside_rows, ⟨"2026-02-03"⟩, outside_evidence⟩
"ok" lib.AssertEq outside_result.state
⟨10⟩ lib.AssertEq outside_result.reserves

completion_plan ← Line ⟨"2026-02-05", "completion", "assets:cash", "expenses:fixed", "10", "plan_id=complete"⟩
completion_a ← Line ⟨"2026-02-03", "actual-a", "assets:cash", "expenses:fixed", "10", "plan_id=complete"⟩
completion_b ← Line ⟨"2026-02-04", "actual-b", "assets:cash", "expenses:fixed", "10", "plan_id=complete"⟩
completion_evidence ← EvidenceFor ⟨⟨completion_plan⟩, ⟨completion_a, completion_b⟩⟩
completion ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨completion_plan⟩, ⟨"2026-02-02", "2026-02-03"⟩, completion_evidence⟩
"ok" lib.AssertEq completion.state
⟨10, 0⟩ lib.AssertEq completion.reserves

# An applicable plan completed at D is excluded; an unfinished plan remains.
completed_evidence ← EvidenceFor ⟨⟨completion_plan⟩, ⟨completion_a⟩⟩
completed ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨completion_plan⟩, ⟨"2026-02-03", "2026-02-04"⟩, completed_evidence⟩
"ok" lib.AssertEq completed.state
⟨0, 0⟩ lib.AssertEq completed.reserves
unfinished_evidence ← EvidenceFor ⟨⟨completion_plan⟩, ⟨⟩⟩
unfinished ← trend_plan.BuildFromEvidenceForTest ⟨ContextWithRows RowsFor ⟨completion_plan⟩, ⟨"2026-02-03"⟩, unfinished_evidence⟩
⟨10⟩ lib.AssertEq unfinished.reserves

•Out "test_src_next_daily_trend_plan_numeric_owner.bqn: OK"
