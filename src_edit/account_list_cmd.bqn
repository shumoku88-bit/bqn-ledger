#!/usr/bin/env bqn
# Read-only account candidate export for UI shell wrappers.
#
# Args:
#   0: base directory
#   1: role filter, or empty string for all roles
#   2: currency filter, or empty string for all currencies
# Output: one account name per line.

loader ← •Import "../src_next/loader.bqn"
ak ← •Import "../src_next/account_key.bqn"
validate ← •Import "validate.bqn"

tab ← @+9
args ← •args
Fail ← {𝕊 msg: •Out "ERROR" ∾ tab ∾ msg ⋄ •Exit 1 }
{𝕊: Fail "usage: account_list_cmd.bqn <base> <role-or-empty> <currency-or-empty>"}⍟(3 ≠ ≠args) @

base ← 0⊑args
role ← 1⊑args
currency ← 2⊑args

{𝕊:
  check ← validate.ValidateCurrency currency
  {𝕊: Fail (1⊑check)}⍟(¬0⊑check) @
}⍟(0 < ≠currency) @

lines ← loader.ReadLines (base ∾ "/accounts.tsv")
IsDataLine ← { (0 < ≠𝕩) ? ((⊑𝕩 ≠ '#') ∧ (⊑𝕩 ≠ ⊑"\\")) ; 0 }
dataLines ← (IsDataLine¨ lines) / lines
resolved ← ak.Resolve dataLines
accounts ← resolved.accounts
roles ← resolved.roles
currencies ← resolved.currencies

roleMask ← (0 = ≠ role) ◶ ⟨ {𝕊: role ⊸ ≡¨ roles}, {𝕊: 1 + 0 × ↕≠accounts} ⟩ @
currencyMask ← (0 = ≠ currency) ◶ ⟨ {𝕊: currency ⊸ ≡¨ currencies}, {𝕊: 1 + 0 × ↕≠accounts} ⟩ @
selected ← (roleMask ∧ currencyMask) / accounts

{ •Out 𝕩 }¨ selected
