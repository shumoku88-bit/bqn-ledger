#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
proj ← •Import "../src_next/projection.bqn"
cycle ← •Import "../src_next/cycle.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"

BuildRowsForFile ← {𝕊 base‿resolved‿cycleStart‿srcFile:
  lines ← loader.ReadLinesOptional (base ∾ "/" ∾ srcFile)
  args ← {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ lines)
    ⟨srcFile, i, flds, resolved.accounts, resolved.roles, resolved.account_keys, cycleStart⟩
  } ¨ ↕ (≠ lines)
  proj.MakeRowsAuthorized ⟨proof, args⟩
}

base ← "fixtures/src-next-golden"
cy ← cycle.ReadCycle base
resolved ← ak.Resolve (loader.ReadLines (base ∾ "/accounts.tsv"))
proof ← {state⇐"proven", domain⇐"JPY", basis⇐"legacy_compatibility", message⇐""}
rows ← (BuildRowsForFile ⟨base, resolved, cy.start, "journal.tsv"⟩) ∾ (BuildRowsForFile ⟨base, resolved, cy.start, "plan.tsv"⟩) ∾ (BuildRowsForFile ⟨base, resolved, cy.start, "budget_alloc.tsv"⟩)
result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
tbdsRows ← tbds.Build ⟨rows, result, resolved, cy⟩

# One TBDS row per AccountKey × Layer.
(resolved.count × cube.layer_count) lib.AssertEq ≠ tbdsRows

# TBDS preserves the loaded cycle period boundary.
first ← ⊑ tbdsRows
"cycle:2026-06-15..2026-06-22" lib.AssertEq first.period_id
"2026-06-15" lib.AssertEq first.period_start
"2026-06-22" lib.AssertEq first.period_end_exclusive
"2026-06-22" lib.AssertEq first.as_of

# Opening/movement/closing invariants.
# In this fixture there are no pre-period rows, so opening is computed as 0.
closing_ok ← ∧´ ({𝕩.closing = 𝕩.opening + 𝕩.movement}¨ tbdsRows)
movement_ok ← ∧´ ({𝕩.movement = 𝕩.debit_movement + 𝕩.credit_movement}¨ tbdsRows)
1 lib.AssertEq closing_ok
1 lib.AssertEq movement_ok

# Layer totals from TBDS match materialized cube layer totals.
LayerMovement ← {𝕊 l:
  mask ← l = {𝕩.layer_index}¨ tbdsRows
  cube.Sum0 (mask / ({𝕩.movement}¨ tbdsRows))
}
tbdsLayerTotals ← LayerMovement¨ ↕ cube.layer_count
result.layer_totals_vec lib.AssertEq tbdsLayerTotals

# Account-level movement matches known fixture values for actual layer.
actualMask ← (cube.layer_actual = {𝕩.layer_index}¨ tbdsRows)
foodMask ← ("expenses:food/JPY"⊸≡¨ ({𝕩.account_key}¨ tbdsRows))
foodActualRows ← (actualMask ∧ foodMask) / tbdsRows
foodActual ← ⊑ foodActualRows
100 lib.AssertEq foodActual.debit_movement
¯20 lib.AssertEq foodActual.credit_movement
80 lib.AssertEq foodActual.movement
80 lib.AssertEq foodActual.closing
"actual" lib.AssertEq foodActual.layer_name

# Plan layer movement is also available through the same TBDS shape.
planMask ← (cube.layer_plan = {𝕩.layer_index}¨ tbdsRows)
foodPlanRows ← (planMask ∧ foodMask) / tbdsRows
foodPlan ← ⊑ foodPlanRows
30 lib.AssertEq foodPlan.debit_movement
0 lib.AssertEq foodPlan.credit_movement
30 lib.AssertEq foodPlan.movement
"plan" lib.AssertEq foodPlan.layer_name

# TBDS query helpers preserve current report semantics that use gross debit
# movement for expenses and credit movement for income.
0 lib.AssertEq tbds.ActualIncomeAmount tbdsRows
120 lib.AssertEq tbds.ActualExpenseAmount tbdsRows
30 lib.AssertEq tbds.PlanExpenseAmount tbdsRows

•Out "test_src_next_tbds.bqn: OK"
