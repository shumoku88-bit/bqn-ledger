#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
snapshot ← •Import "../src_next/snapshot.bqn"

# Verify BuildFromTBDS uses TBDS account entries for account_totals display.
# We construct minimal TBDS rows and check that FormatAccountTotals renders
# the correct TBDS-derived entries.

tbdsRows ← ⟨
  {
    account_key       ⇐ "equity:opening/JPY",
    account_key_index ⇐ 0,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    opening           ⇐ 0,
    movement          ⇐ ¯100,
    closing           ⇐ ¯100,
    debit_movement    ⇐ 0,
    credit_movement   ⇐ ¯100,
    account_name      ⇐ "equity:opening",
    role              ⇐ ""
  },
  {
    account_key       ⇐ "expenses:food/JPY",
    account_key_index ⇐ 1,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    opening           ⇐ 1000,
    movement          ⇐ 80,
    closing           ⇐ 1080,
    debit_movement    ⇐ 100,
    credit_movement   ⇐ ¯20,
    account_name      ⇐ "expenses:food",
    role              ⇐ "expense"
  },
  # zero-movement account (should not appear)
  {
    account_key       ⇐ "expenses:rent/JPY",
    account_key_index ⇐ 2,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    opening           ⇐ 0,
    movement          ⇐ 0,
    closing           ⇐ 0,
    debit_movement    ⇐ 0,
    credit_movement   ⇐ 0,
    account_name      ⇐ "expenses:rent",
    role              ⇐ "expense"
  }
⟩

nz ← tbds.NonzeroActualBalances tbdsRows
2 lib.AssertEq ≠ nz

# FormatAccountTotals uses TBDS closing entries
entries ← {⟨𝕩.account_key, 𝕩.closing⟩}¨ nz
2 lib.AssertEq ≠ entries
"equity:opening/JPY" lib.AssertEq (0 ⊑ (⊑ entries))
¯100 lib.AssertEq (1 ⊑ (⊑ entries))

text ← snapshot.FormatAccountTotalsFromEntries entries
1 lib.AssertEq ∨´ "equity:opening/JPY ¯100"⍷text
1 lib.AssertEq ∨´ "expenses:food/JPY 1080"⍷text

# Empty entries
emptyText ← snapshot.FormatAccountTotalsFromEntries ⟨⟩
1 lib.AssertEq ∨´ "(none)"⍷emptyText

•Out "test_src_next_snapshot_tbds.bqn: OK"
