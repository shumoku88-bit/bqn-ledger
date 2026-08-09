#!/usr/bin/env bqn
# Validate and render one canonical accounts.journal declaration block.
# Args: <baseDir> <name> <role> <legacy-type-or-empty> <currency-or-empty>
# Success protocol: OK\tAPPEND\taccounts.journal, followed by the declaration.

io ← •Import "../src/application/source_io.bqn"
accountSource ← •Import "../src/application/account_source_adapter.bqn"
admission ← •Import "../src/ledger/account_journal_admission.bqn"
canonical ← •Import "../src/application/canonical_household_sources.bqn"
editorCurrency ← •Import "../src/application/editor_currency.bqn"
setup ← editorCurrency.Load @

args ← •args ⋄ tab ← @+9 ⋄ lf ← @+10 ⋄ space ← @+32
roles ← ⟨"asset","liability","equity","income","expense","budget"⟩
types ← ⟨"Asset","Liability","Equity","Income","Expense","Budget"⟩
IndexOf ← {𝕊 item‿items: ⊑items⊐⟨item⟩}
TrimLeft ← {𝕊 xs: (+´∧`((xs=space)∨xs=tab))↓xs}
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs}
Trim ← {TrimRight TrimLeft 𝕩}
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}

{𝕊:Fail "usage: account_add_cmd.bqn <baseDir> <name> <role> <legacy-type-or-empty> <currency-or-empty>"}⍟(5≠≠args) @
base ← 0⊑args ⋄ name ← Trim 1⊑args ⋄ role ← 2⊑args ⋄ legacyType ← 3⊑args ⋄ explicitCurrency ← 4⊑args
{𝕊:Fail "legacy --type Household classification belongs in household.toml; omit --type"}⍟(0<≠legacyType) @
roleIndex ← IndexOf ⟨role,roles⟩
{𝕊:Fail "role must be asset, liability, equity, income, expense, or budget"}⍟(roleIndex≥≠roles) @
{𝕊:Fail "account name must be nonempty"}⍟(0=≠name) @

current ← accountSource.Load base
{𝕊:Fail "canonical accounts.journal failed admission"}⍟(current.state≢"ok") @
{𝕊:Fail "account already exists: "∾name}⍟(∨´0∾name⊸≡¨current.accounts.key) @

currency ← explicitCurrency
{𝕊:
  candidates ← ⍷(0<≠¨current.accounts.currency)/current.accounts.currency
  {𝕊:Fail "--currency is required when canonical Accounts do not determine exactly one Commodity"}⍟(1≠≠candidates) @
  currency↩⊑candidates
}⍟(0=≠currency) @
{𝕊:Fail "unsupported selected currency: "∾currency}⍟(¬setup.IsSupportedCurrency currency) @

canonicalType ← roleIndex⊑types
block ← "account "∾name∾⟨lf⟩∾"  type: "∾canonicalType∾⟨lf⟩∾"  commodity: "∾currency
path ← base∾"/"∾canonical.accounts
raw ← io.ReadRaw path
candidate ← raw
{𝕊:candidate∾↩⟨lf⟩}⍟((0<≠candidate) ∧ lf≠¯1↑candidate) @
candidate∾↩block∾⟨lf⟩
checked ← admission.Admit candidate
{𝕊:Fail "candidate accounts.journal failed complete-source admission"}⍟(checked.state≢"ok") @
{𝕊:Fail "candidate Account cardinality mismatch"}⍟(checked.accounts.count≠current.accounts.count+1) @
i ← checked.accounts.count-1
exact ← (name≡i⊑checked.accounts.key) ∧ (role≡i⊑checked.accounts.role) ∧ (canonicalType≡i⊑checked.accounts.type) ∧ (currency≡i⊑checked.accounts.currency)
{𝕊:Fail "candidate Account declaration did not round-trip exactly"}⍟(¬exact) @

•Out "OK"∾tab∾"APPEND"∾tab∾canonical.accounts
•Out block
