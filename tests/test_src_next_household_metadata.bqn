#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
hm ← •Import "../src_next/household_metadata.bqn"

# ── Fixture: src-next-household-mapping-policy ──────────────────────
# accounts.tsv has:
#   expenses:食費    role=expense budget=食費 budget_group=life_primary spend_class=variable
#   expenses:日用品  role=expense budget=日用品 budget_group=life_primary spend_class=variable
#   expenses:娯楽    role=expense budget=娯楽 budget_group=life_flex    spend_class=variable
#   expenses:予備    role=expense budget=予備 budget_group=reserve_pool  spend_class=variable
#   expenses:未分類  role=expense budget=未分類  (no budget_group, no spend_class)
#   expenses:fallback  (no metadata, prefix fallback expense)
#   assets:bank      role=asset
#   assets:cash      role=asset

base ← "fixtures/src-next-household-mapping-policy"
resolved ← ak.Resolve loader.ReadLines (base ∾ "/accounts.tsv")

diag ← hm.Build { resolved ⇐ resolved }

# Count assertions
1 lib.AssertEq diag.has_any
6 lib.AssertEq diag.expense_accounts_total
1 lib.AssertEq diag.missing_budget_count
2 lib.AssertEq diag.missing_budget_group_count
2 lib.AssertEq diag.missing_spend_class_count

# Value lists (deduplicated, sorted by BQN ∧ order)
"予備,娯楽,日用品,未分類,食費" lib.AssertEq diag.budget_values
"life_flex,life_primary,reserve_pool" lib.AssertEq diag.budget_group_values
"variable" lib.AssertEq diag.spend_class_values

# Missing accounts
"expenses:fallback" lib.AssertEq diag.missing_budget_accounts
"expenses:未分類,expenses:fallback" lib.AssertEq diag.missing_budget_group_accounts
"expenses:未分類,expenses:fallback" lib.AssertEq diag.missing_spend_class_accounts

# ── Format check ─────────────────────────────────────────────────────
text ← hm.Format diag
1 lib.AssertEq (0 < ≠ text)
1 lib.AssertEq (0 ≠ ⊑ "--- SrcNext Household Metadata ---" ≡ (≠ "--- SrcNext Household Metadata ---") ↑ text)
1 lib.AssertEq (1 ≤ +´ ("src_next_household_metadata_expense_accounts_total:" ⍷ text))

# ── Fixture: no expense accounts ─────────────────────────────────────
# src-next-golden has expenses:food and expenses:rent (prefix fallback).
# Use it to test that expense accounts are still detected even without metadata.
base2 ← "fixtures/src-next-golden"
resolved2 ← ak.Resolve loader.ReadLines (base2 ∾ "/accounts.tsv")
diag2 ← hm.Build { resolved ⇐ resolved2 }
# src-next-golden: expenses:food and expenses:rent are prefix-fallback expense accounts
1 lib.AssertEq diag2.has_any
2 lib.AssertEq diag2.expense_accounts_total
2 lib.AssertEq diag2.missing_budget_count
2 lib.AssertEq diag2.missing_budget_group_count
2 lib.AssertEq diag2.missing_spend_class_count
"" lib.AssertEq diag2.budget_values
"" lib.AssertEq diag2.budget_group_values
"" lib.AssertEq diag2.spend_class_values

•Out "test_src_next_household_metadata.bqn: OK"
