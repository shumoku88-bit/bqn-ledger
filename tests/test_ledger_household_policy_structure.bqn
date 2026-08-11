#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
lf ← @+10
accountsResult ← accountsAdmission.Admit •FChars "../"∾base∾"accounts.journal"
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
budget ← budgetAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budget.state
householdRaw ← •FChars "../"∾base∾"household.toml"

Codes ← { {𝕩.code}¨𝕩.diagnostics }
Lines ← { {𝕩.line}¨𝕩.diagnostics }

# The ordinary fixture already contains a multiline Account array. Its first
# physical row remains the logical-row diagnostic owner and the source admits.
valid ← householdAdmission.Admit ⟨householdRaw,accounts,budget⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
⟨"expenses:food","expenses:transport"⟩ lib.AssertEq ({𝕩.account_key}¨accounts.index⊏⟨⟩)⍟0 @

# A key before the first supported section belongs to no policy block.
outsideRaw ← "orphan = "∾⟨@+34⟩∾"x"∾⟨@+34,lf⟩∾householdRaw
outside ← householdAdmission.Admit ⟨outsideRaw,accounts,budget⟩
"error" lib.AssertEq outside.state
⟨"household_key_outside_section"⟩ lib.AssertEq Codes outside
⟨1⟩ lib.AssertEq Lines outside

# An unknown header ends any previous active block but does not establish a new
# block. Its following key is therefore outside a supported section.
unknownPrefix ← "[mystery]"∾⟨lf⟩∾"x = "∾⟨@+34⟩∾"y"∾⟨@+34,lf⟩
unknown ← householdAdmission.Admit ⟨unknownPrefix∾householdRaw,accounts,budget⟩
"error" lib.AssertEq unknown.state
⟨"household_section_unsupported","household_key_outside_section"⟩ lib.AssertEq Codes unknown
⟨1,2⟩ lib.AssertEq Lines unknown

•Out "test_ledger_household_policy_structure: ok"
