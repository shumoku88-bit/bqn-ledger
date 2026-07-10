#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
context ← •Import "../src_next/context.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
hh ← •Import "../src_next/household_policy.bqn"

base ← "fixtures/src-next-household-mapping-policy"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base
rows ← context.BuildAllRows ⟨base, resolved, cy.start⟩
result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
summary ← hh.BuildSummary ⟨base, resolved, result.valid_rows⟩
1 lib.AssertEq summary.has_policy_metadata
6 lib.AssertEq summary.expense_account_count
0 lib.AssertEq summary.prefix_fallback_expense_account_count
5 lib.AssertEq summary.expense_account_with_budget_count
2 lib.AssertEq summary.expense_budget_group_daily_count
1 lib.AssertEq summary.expense_budget_group_flex_count
1 lib.AssertEq summary.expense_budget_group_reserve_count
2 lib.AssertEq summary.expense_budget_group_missing_count
0 lib.AssertEq summary.expense_budget_group_other_count
4 lib.AssertEq summary.expense_spend_class_variable_count
0 lib.AssertEq summary.expense_spend_class_fixed_count
2 lib.AssertEq summary.expense_spend_class_missing_count
0 lib.AssertEq summary.expense_spend_class_other_count
100 lib.AssertEq summary.actual_budget_group_daily_total
200 lib.AssertEq summary.actual_budget_group_flex_total
300 lib.AssertEq summary.actual_budget_group_reserve_total
70 lib.AssertEq summary.actual_budget_group_missing_total
0 lib.AssertEq summary.actual_budget_group_other_total
70 lib.AssertEq summary.plan_budget_group_daily_total
80 lib.AssertEq summary.plan_budget_group_flex_total
90 lib.AssertEq summary.plan_budget_group_reserve_total
0 lib.AssertEq summary.plan_budget_group_missing_total
0 lib.AssertEq summary.plan_budget_group_other_total

# A prefix-shaped missing-role expense remains visible diagnostically but must not
# inflate any field that claims classified expense accounts.
negative_base ← "fixtures/src-next-envelope-computation-prefix-negative"
negative_resolved ← ak.Resolve loader.ReadLines (negative_base ∾ "/accounts.tsv")
negative_cy ← cycle.ReadCycle negative_base
negative_rows ← context.BuildAllRows ⟨negative_base, negative_resolved, negative_cy.start⟩
negative_result ← cube.Materialize ⟨negative_rows, negative_cy.day_count, negative_resolved.count⟩
negative ← hh.BuildSummary ⟨negative_base, negative_resolved, negative_result.valid_rows⟩
1 lib.AssertEq negative.prefix_fallback_expense_account_count
0 lib.AssertEq negative.expense_account_count
0 lib.AssertEq negative.expense_account_with_budget_count
0 lib.AssertEq negative.expense_budget_group_daily_count
0 lib.AssertEq negative.expense_budget_group_flex_count
0 lib.AssertEq negative.expense_budget_group_reserve_count
0 lib.AssertEq negative.expense_budget_group_missing_count
0 lib.AssertEq negative.expense_budget_group_other_count
0 lib.AssertEq negative.expense_spend_class_variable_count
0 lib.AssertEq negative.expense_spend_class_fixed_count
0 lib.AssertEq negative.expense_spend_class_missing_count
0 lib.AssertEq negative.expense_spend_class_other_count

•Out "test_src_next_household_policy.bqn: OK"
