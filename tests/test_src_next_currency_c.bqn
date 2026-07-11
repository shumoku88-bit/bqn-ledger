#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"

# Slice C full-context evidence: one all-ILS snapshot reaches the checked
# projection path, cube materialization, and TBDS without conversion.
fixtureContext ← ctx.BuildContext "fixtures/src-next-currency-c-ils-normalized"

# Checked proof carrier
"proven" lib.AssertEq fixtureContext.arithmetic_currency_proof.state
"ILS" lib.AssertEq fixtureContext.arithmetic_currency_proof.domain
"resolved_single_currency" lib.AssertEq fixtureContext.arithmetic_currency_proof.basis
2 lib.AssertEq fixtureContext.arithmetic_currency_proof.amount_scale

# Exact normalized posting rows
allRows ← fixtureContext.posting_rows
debits ← (({𝕩.side}¨ allRows) ≡¨ <"debit") / allRows
credits ← (({𝕩.side}¨ allRows) ≡¨ <"credit") / allRows
120000 lib.AssertEq (0 ⊑ debits).delta
4250 lib.AssertEq (1 ⊑ debits).delta
5 lib.AssertEq (2 ⊑ debits).delta
¯120000 lib.AssertEq (0 ⊑ credits).delta
¯4250 lib.AssertEq (1 ⊑ credits).delta
¯5 lib.AssertEq (2 ⊑ credits).delta
124255 lib.AssertEq (+´ {𝕩.delta}¨ debits)
¯124255 lib.AssertEq (+´ {𝕩.delta}¨ credits)
0 lib.AssertEq (+´ {𝕩.delta}¨ allRows)

# Cube evidence: six valid postings, no skipped rows, balanced actual layer,
# and the exact expense-side movement preserved in normalized integer units.
cubeResult ← fixtureContext.cube
6 lib.AssertEq cubeResult.valid_count
0 lib.AssertEq cubeResult.skipped_count
0 lib.AssertEq cubeResult.valid_total_delta
0 lib.AssertEq (cube.layer_actual ⊑ cubeResult.layer_totals_vec)
124255 lib.AssertEq cubeResult.actual_expense_total
1 lib.AssertEq cubeResult.validation_summary.actual_total_match
1 lib.AssertEq cubeResult.validation_summary.actual_per_account_totals_match

# TBDS downstream exact aggregation
actualTbds ← ({𝕩.layer_index ≡ cube.layer_actual}¨ fixtureContext.tbds) / fixtureContext.tbds
expenseTbds ← ({𝕩.role ≡ "expense"}¨ actualTbds) / actualTbds
assetTbds ← ({𝕩.role ≡ "asset"}¨ actualTbds) / actualTbds
124255 lib.AssertEq (⊑ expenseTbds).debit_movement
0 lib.AssertEq (⊑ expenseTbds).credit_movement
124255 lib.AssertEq (⊑ expenseTbds).movement
0 lib.AssertEq (⊑ assetTbds).debit_movement
¯124255 lib.AssertEq (⊑ assetTbds).credit_movement
¯124255 lib.AssertEq (⊑ assetTbds).movement

•Out "test_src_next_currency_c.bqn: OK"
