#!/usr/bin/env bqn
# src_edit/account_list_cmd.bqn
# Read-only account candidate export for UI shell wrappers.
#
# Args:
#   0: base directory
#   1: role filter, or empty string for all accounts
# Output:
#   one account name per line

loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"

base ← 0⊑•args
role ← 1⊑•args

lines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve lines
accounts ← resolved.accounts
roles ← resolved.roles

mask ← (0 = ≠ role) ◶ ⟨ { 𝕊 ⋄ role ⊸ ≡¨ roles }, { 𝕊 ⋄ 1 + 0 × ↕≠accounts } ⟩ @
selected ← mask / accounts

{ •Out 𝕩 }¨ selected
