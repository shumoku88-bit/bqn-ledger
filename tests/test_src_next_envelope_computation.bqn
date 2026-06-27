#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
proj ← •Import "../src_next/projection.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
env ← •Import "../src_next/envelope_computation.bqn"

base ← "fixtures/src-next-envelope-computation"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")
cy ← cycle.ReadCycle base

BuildRowsForFile ← {𝕊 srcFile:
  lines ← loader.ReadLinesOptional (base ∾ "/" ∾ srcFile)
  args ← {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ lines)
    ⟨srcFile, i, flds, resolved.accounts, resolved.roles, resolved.account_keys, cy.start⟩
  } ¨ ↕ ≠ lines
  ∾ (proj.MakeRow ¨ args)
}

rows ← (BuildRowsForFile "journal.tsv") ∾ (BuildRowsForFile "plan.tsv") ∾ BuildRowsForFile "budget_alloc.tsv"
result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
summary ← env.Build { base ⇐ base, resolved ⇐ resolved, cy ⇐ cy, cube ⇐ result }

"fixture_food_like" lib.AssertEq summary.target_id
"食費" lib.AssertEq summary.label
"budget=食費" lib.AssertEq summary.selector
"computed" lib.AssertEq summary.status
1 lib.AssertEq summary.selected_expense_account_count
1 lib.AssertEq summary.allocation_row_count
1000 lib.AssertEq summary.allocated
350 lib.AssertEq summary.actual_spent
650 lib.AssertEq summary.remaining

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
