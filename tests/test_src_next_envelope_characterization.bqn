#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
context ← •Import "../src_next/context.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
env ← •Import "../src_next/envelope_computation.bqn"
plan_rows ← •Import "../src_next/plan_rows.bqn"

# ── 1. Load Main Context ──
base ← "fixtures/envelope-characterization"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base
posting_snapshot ← context.LoadPostingSourceSnapshot base

# Build normally
built_rows ← context.BuildAuthorizedRowsFromSnapshot ⟨posting_snapshot, resolved, cy.start⟩
rows ← built_rows.rows
result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
tbds_rows ← tbds.Build ⟨rows, result, resolved, cy⟩

summary ← env.Build { base ⇐ base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ result, tbds ⇐ tbds_rows }

# ── Case 1: Normal Allocation and Spending ──
# food envelope: allocated = 500, spent - drawn = 300, remaining = 200
# rent envelope: allocated = 1200, spent - drawn = 1000, remaining = 200
# total active envelope remaining = 400
# unassigned remaining = -1700, OVER_ALLOCATED status
500 lib.AssertEq (⊑ (("food"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).allocated
300 lib.AssertEq (⊑ (("food"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).actual_spent
200 lib.AssertEq (⊑ (("food"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).remaining

1200 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).allocated
1000 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).actual_spent
200 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).remaining

# ── Case 10 & Case 11: Root unassigned OVER_ALLOCATED and backing MISMATCH ──
¯1700 lib.AssertEq summary.unassigned_remaining
"OVER_ALLOCATED" lib.AssertEq summary.unassigned_status
"MISMATCH" lib.AssertEq summary.backing_status


# ── Case 4 & Case 3: Planned payments completed vs unfinished ──
# Configured execution envelope is 'rent' (rent label)
# Planned payments in plan.tsv:
#   rent_p1 (1000): completed (exists in journal)
#   rent_p2 (200): unfinished (does not exist in journal)
# execution_planned.envelope_remaining should be rent's remaining (200)
# planned_open_total should be unfinished rent_p2 (200)
# delta = 200 - 200 = 0
# status = OK
ep ← summary.execution_planned
"rent" lib.AssertEq ep.envelope_label
200 lib.AssertEq ep.envelope_remaining
200 lib.AssertEq ep.planned_open_total
0 lib.AssertEq ep.delta
"OK" lib.AssertEq ep.status
1 lib.AssertEq ≠ ep.rows
"rent_p2" lib.AssertEq (⊑ ep.rows).plan_id

# Verify that future_planned_spent includes completed plan if plan date > as_of
# Latest actual date in cycle is 2026-01-15 (rent_paid).
# rent_p1 is on 2026-01-15, which is NOT > 2026-01-15, so not in future_planned_spent.
# If we check rent_p2 (on 2026-01-20), it is > 2026-01-15, so it is in future_planned_spent.
0 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ summary.envelopes) / summary.envelopes)).days_until_empty  # Avg spend is 66, b is 0, so days_until_empty is 0

# ── Case 5: Unknown Account in Allocation ──
# sub_unknown_account_alloc has 'budget:unknown_env' which is unknown.
# We build checked projection from its snapshot.
unk_base ← "fixtures/envelope-characterization/sub_unknown_account_alloc"
unk_snapshot ← context.LoadPostingSourceSnapshot unk_base
unk_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨unk_snapshot, resolved, cy.start⟩
"ok" lib.AssertEq unk_proj.state # Unknown account does NOT fail the projection state

# But it is skipped in cube materialization
unk_cube ← cube.Materialize ⟨unk_proj.posting_rows, cy.day_count, resolved.count⟩
2 lib.AssertEq unk_cube.skipped_count
"status: unknown_account" lib.AssertEq ⊑ (⊑ unk_cube.skipped_info)

# ── Case 6: Rejected or Invalid Amount ──
# sub_invalid_amount has amount 'abc'.
# Build checked projection from its snapshot.
inv_base ← "fixtures/envelope-characterization/sub_invalid_amount"
inv_snapshot ← context.LoadPostingSourceSnapshot inv_base
inv_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨inv_snapshot, resolved, cy.start⟩
"error" lib.AssertEq inv_proj.state # Invalid amount fails projection state

# ── Case 7: Invalid Budget Date ──
# sub_invalid_budget_date has date '2026-99-99' in budget_alloc.tsv.
# Build checked projection.
miss_base ← "fixtures/envelope-characterization/sub_invalid_budget_date"
miss_snapshot ← context.LoadPostingSourceSnapshot miss_base
miss_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨miss_snapshot, resolved, cy.start⟩
"ok" lib.AssertEq miss_proj.state # Invalid date does NOT fail projection state (it projects as invalid_date row status)
miss_rows ← miss_proj.posting_rows
miss_cube ← cube.Materialize ⟨miss_rows, cy.day_count, resolved.count⟩
miss_tbds ← tbds.Build ⟨miss_rows, miss_cube, resolved, cy⟩
HasInvalidBudgetDateError ← {𝕊:
  ({𝕊 ⋄ env.Build { base ⇐ miss_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ miss_cube, tbds ⇐ miss_tbds } ⋄ 0}⎊{𝕊 ⋄ 1}) @
}
1 lib.AssertEq HasInvalidBudgetDateError @ # But building the report crashes BQN when parsing the budget allocation date in CalcAllocated



# ── Case 2: Empty Allocation Source ──
# sub_empty_alloc has empty budget_alloc.tsv.
emp_base ← "fixtures/envelope-characterization/sub_empty_alloc"
emp_snapshot ← context.LoadPostingSourceSnapshot emp_base
emp_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨emp_snapshot, resolved, cy.start⟩
emp_rows ← emp_proj.posting_rows
emp_cube ← cube.Materialize ⟨emp_rows, cy.day_count, resolved.count⟩
emp_tbds ← tbds.Build ⟨emp_rows, emp_cube, resolved, cy⟩
emp_summary ← env.Build { base ⇐ emp_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ emp_cube, tbds ⇐ emp_tbds }

# Envelopes allocations are 0
0 lib.AssertEq (⊑ (("food"⊸≡¨ {𝕩.label}¨ emp_summary.envelopes) / emp_summary.envelopes)).allocated
¯300 lib.AssertEq (⊑ (("food"⊸≡¨ {𝕩.label}¨ emp_summary.envelopes) / emp_summary.envelopes)).remaining
0 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ emp_summary.envelopes) / emp_summary.envelopes)).allocated
¯1000 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ emp_summary.envelopes) / emp_summary.envelopes)).remaining

# unassigned remaining is 0
0 lib.AssertEq emp_summary.unassigned_remaining
"OK" lib.AssertEq emp_summary.unassigned_status

# ── Case 8: Execution envelope with no matching planned payment ──
# If we have no planned payments, execution_planned.status = MISMATCH
# Let's verify by building execution planned coverage with empty plan rows.
no_plan_base ← "fixtures/envelope-characterization/sub_no_planned_payment"
no_plan_snapshot ← context.LoadPostingSourceSnapshot no_plan_base
no_plan_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨no_plan_snapshot, resolved, cy.start⟩
no_plan_rows ← no_plan_proj.posting_rows
no_plan_cube ← cube.Materialize ⟨no_plan_rows, cy.day_count, resolved.count⟩
no_plan_tbds ← tbds.Build ⟨no_plan_rows, no_plan_cube, resolved, cy⟩
no_plan_summary ← env.Build { base ⇐ no_plan_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ no_plan_cube, tbds ⇐ no_plan_tbds }

empty_plan_coverage ← no_plan_summary.execution_planned
200 lib.AssertEq empty_plan_coverage.envelope_remaining
0 lib.AssertEq empty_plan_coverage.planned_open_total
200 lib.AssertEq empty_plan_coverage.delta
"MISMATCH" lib.AssertEq empty_plan_coverage.status

# ── Case 9: Planned payment with no configured execution envelope ──
dis_base ← "fixtures/envelope-characterization/sub_disabled_execution"
dis_snapshot ← context.LoadPostingSourceSnapshot dis_base
dis_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨dis_snapshot, resolved, cy.start⟩
dis_rows ← dis_proj.posting_rows
dis_cube ← cube.Materialize ⟨dis_rows, cy.day_count, resolved.count⟩
dis_tbds ← tbds.Build ⟨dis_rows, dis_cube, resolved, cy⟩
dis_summary ← env.Build { base ⇐ dis_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ dis_cube, tbds ⇐ dis_tbds }
"disabled" lib.AssertEq dis_summary.execution_planned.status

miss_env_base ← "fixtures/envelope-characterization/sub_missing_execution"
miss_env_snapshot ← context.LoadPostingSourceSnapshot miss_env_base
miss_env_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨miss_env_snapshot, resolved, cy.start⟩
miss_env_rows ← miss_env_proj.posting_rows
miss_env_cube ← cube.Materialize ⟨miss_env_rows, cy.day_count, resolved.count⟩
miss_env_tbds ← tbds.Build ⟨miss_env_rows, miss_env_cube, resolved, cy⟩
miss_env_summary ← env.Build { base ⇐ miss_env_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ miss_env_cube, tbds ⇐ miss_env_tbds }
"unavailable/missing_execution_envelope" lib.AssertEq miss_env_summary.execution_planned.status

# ── Case 12: Duplicate/repeated plan identity ──
# sub_duplicate_plan has two rent_p2 plans.
# Both are open, so both are included in execution planned coverage open list.
dup_base ← "fixtures/envelope-characterization/sub_duplicate_plan"
dup_snapshot ← context.LoadPostingSourceSnapshot dup_base
dup_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨dup_snapshot, resolved, cy.start⟩
dup_rows ← dup_proj.posting_rows
dup_cube ← cube.Materialize ⟨dup_rows, cy.day_count, resolved.count⟩
dup_tbds ← tbds.Build ⟨dup_rows, dup_cube, resolved, cy⟩
dup_summary ← env.Build { base ⇐ dup_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ dup_cube, tbds ⇐ dup_tbds }

# execution planned coverage should have 2 rent_p2 rows
dup_ep ← dup_summary.execution_planned
400 lib.AssertEq dup_ep.planned_open_total
2 lib.AssertEq ≠ dup_ep.rows
"rent_p2" lib.AssertEq (0⊑dup_ep.rows).plan_id
"rent_p2" lib.AssertEq (1⊑dup_ep.rows).plan_id

# ── Executable Evidence for Completed Future Plan Hazard ──
# sub_completed_future_plan has a plan rent_p1 on 2026-01-15 (future relative to as_of=2026-01-10)
# which is already completed in journal on 2026-01-10.
comp_base ← "fixtures/envelope-characterization/sub_completed_future_plan"
comp_snapshot ← context.LoadPostingSourceSnapshot comp_base
comp_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨comp_snapshot, resolved, cy.start⟩
comp_rows ← comp_proj.posting_rows
comp_cube ← cube.Materialize ⟨comp_rows, cy.day_count, resolved.count⟩
comp_tbds ← tbds.Build ⟨comp_rows, comp_cube, resolved, cy⟩
comp_summary ← env.Build { base ⇐ comp_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ comp_cube, tbds ⇐ comp_tbds }

# 1. execution planned coverage correctly excludes it because of completion evidence (plan_id matched)
comp_ep ← comp_summary.execution_planned
0 lib.AssertEq comp_ep.planned_open_total
"MISMATCH" lib.AssertEq comp_ep.status

# 2. Cube-derived future_planned_spent STILL counts it, double-counting and reducing days_until_empty to 0 (instead of 2)
0 lib.AssertEq (⊑ (("rent"⊸≡¨ {𝕩.label}¨ comp_summary.envelopes) / comp_summary.envelopes)).days_until_empty

# ── Executable Evidence for Missing execution-envelope linkage filter ──
# sub_unrelated_unfinished_plan has an unfinished food plan food_p1.
# Current BuildExecutionPlannedCoverage does not filter plans, so food_p1 is incorrectly summed.
unrelated_base ← "fixtures/envelope-characterization/sub_unrelated_unfinished_plan"
unrelated_snapshot ← context.LoadPostingSourceSnapshot unrelated_base
unrelated_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨unrelated_snapshot, resolved, cy.start⟩
unrelated_rows ← unrelated_proj.posting_rows
unrelated_cube ← cube.Materialize ⟨unrelated_rows, cy.day_count, resolved.count⟩
unrelated_tbds ← tbds.Build ⟨unrelated_rows, unrelated_cube, resolved, cy⟩
unrelated_summary ← env.Build { base ⇐ unrelated_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ unrelated_cube, tbds ⇐ unrelated_tbds }

unrelated_ep ← unrelated_summary.execution_planned
350 lib.AssertEq unrelated_ep.planned_open_total  # rent_p2 (200) + food_p1 (150)
¯150 lib.AssertEq unrelated_ep.delta
2 lib.AssertEq ≠ unrelated_ep.rows

# ── Executable Evidence for Insufficient Funding Backing OVER_ALLOCATED status ──
# sub_insufficient_backing has actual cash closing balance = -1300, leading to backing status OVER_ALLOCATED.
backing_base ← "fixtures/envelope-characterization/sub_insufficient_backing"
backing_snapshot ← context.LoadPostingSourceSnapshot backing_base
backing_proj ← context.BuildCheckedPostingProjectionFromSnapshot ⟨backing_snapshot, resolved, cy.start⟩
backing_rows ← backing_proj.posting_rows
backing_cube ← cube.Materialize ⟨backing_rows, cy.day_count, resolved.count⟩
backing_tbds ← tbds.Build ⟨backing_rows, backing_cube, resolved, cy⟩
backing_summary ← env.Build { base ⇐ backing_base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ backing_cube, tbds ⇐ backing_tbds }

¯1300 lib.AssertEq backing_summary.funding_base
400 lib.AssertEq backing_summary.allocated_total
¯1700 lib.AssertEq backing_summary.cash_backed_unassigned
"OVER_ALLOCATED" lib.AssertEq backing_summary.backing_status

•Out "test_src_next_envelope_characterization.bqn: OK"
