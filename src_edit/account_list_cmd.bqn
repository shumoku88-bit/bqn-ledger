#!/usr/bin/env bqn
# Read-only account candidate export for UI shell wrappers.
#
# Args:
#   0: base directory
#   1: role filter, or empty string for all roles
#   2: currency filter, or empty string for all currencies
#   3: preferred role, or empty string to preserve source order
# Output: one account name per line. A preferred role is a stable partition only.

accountSource ← •Import "../src/application/account_source_adapter.bqn"
validate ← •Import "validate.bqn"

tab ← @+9
args ← •args
Fail ← {𝕊 msg: •Out "ERROR" ∾ tab ∾ msg ⋄ •Exit 1 }
{𝕊: Fail "usage: account_list_cmd.bqn <base> <role-or-empty> <currency-or-empty> <preferred-role-or-empty>"}⍟(4 ≠ ≠args) @

base ← 0⊑args
role ← 1⊑args
currency ← 2⊑args
preferredRole ← 3⊑args

{𝕊:
  check ← validate.ValidateCurrency currency
  {𝕊: Fail (1⊑check)}⍟(¬0⊑check) @
}⍟(0 < ≠currency) @

result ← accountSource.Load base
{𝕊: Fail "accounts.journal rejected"}⍟(result.state≢"ok") @
resolved ← result.accounts
accounts ← resolved.key
roles ← resolved.role
currencies ← resolved.currency

roleMask ← (0 = ≠ role) ◶ ⟨ {𝕊: role ⊸ ≡¨ roles}, {𝕊: 1 + 0 × ↕≠accounts} ⟩ @
currencyMask ← (0 = ≠ currency) ◶ ⟨ {𝕊: currency ⊸ ≡¨ currencies}, {𝕊: 1 + 0 × ↕≠accounts} ⟩ @
selectedMask ← roleMask ∧ currencyMask
preferredMask ← preferredRole⊸≡¨roles
selected ← ((selectedMask ∧ preferredMask) / accounts) ∾ ((selectedMask ∧ ¬preferredMask) / accounts)
{𝕊:selected↩selectedMask/accounts}⍟(0=≠preferredRole) @

{ •Out 𝕩 }¨ selected
