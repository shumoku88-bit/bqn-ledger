#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
currentProjection ← •Import "../src/ledger/household_current_policy_projection.bqn"

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

# The ordinary fixture already exercises a multiline Account array.
valid ← householdAdmission.Admit ⟨householdRaw,accounts,budget⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics

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

# Current-policy projection removes only the known historical Envelope section
# family. An unrelated unknown section must survive projection and still fail
# closed in the strict current-policy owner.
historyRaw ← •FChars "../fixtures/canonical-household-envelope-history/household.toml"
projectedHistory ← currentProjection.CurrentPolicy historyRaw
historyPolicy ← householdAdmission.Admit ⟨projectedHistory,accounts,budget⟩
"ok" lib.AssertEq historyPolicy.state
unknownAfterHistory ← currentProjection.CurrentPolicy (historyRaw∾⟨lf⟩∾unknownPrefix)
projectedUnknown ← householdAdmission.Admit ⟨unknownAfterHistory,accounts,budget⟩
"error" lib.AssertEq projectedUnknown.state
⟨"household_section_unsupported","household_key_outside_section"⟩ lib.AssertEq Codes projectedUnknown

•Out "test_ledger_household_policy_structure: ok"
