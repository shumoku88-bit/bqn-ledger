#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
currentProjection ← •Import "../src/ledger/household_current_policy_projection.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
lf ← @+10
quote ← @+34
Rows ← {𝕊 xs:∾{𝕩∾⟨lf⟩}¨xs}
Quoted ← {𝕊 text:⟨quote⟩∾text∾⟨quote⟩}
accountsResult ← accountsAdmission.Admit •FChars "../"∾base∾"accounts.journal"
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
householdRaw ← •FChars "../"∾base∾"household.toml"
currentRaw ← currentProjection.CurrentPolicy householdRaw

Codes ← { {𝕩.code}¨𝕩.diagnostics }
Lines ← { {𝕩.line}¨𝕩.diagnostics }

# The ordinary canonical source is shared physically; this strict owner receives
# only its current-policy projection.
valid ← householdAdmission.Admit ⟨currentRaw,accounts⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics

# A key before the first supported section belongs to no policy block.
outsideRaw ← "orphan = "∾(Quoted "x")∾⟨lf⟩∾currentRaw
outside ← householdAdmission.Admit ⟨outsideRaw,accounts⟩
"error" lib.AssertEq outside.state
⟨"household_key_outside_section"⟩ lib.AssertEq Codes outside
⟨1⟩ lib.AssertEq Lines outside

# An unknown header ends any previous active block but does not establish a new
# block. Its following key is therefore outside a supported section.
unknownPrefix ← Rows ⟨"[mystery]","x = "∾(Quoted "y")⟩
unknown ← householdAdmission.Admit ⟨unknownPrefix∾currentRaw,accounts⟩
"error" lib.AssertEq unknown.state
⟨"household_section_unsupported","household_key_outside_section"⟩ lib.AssertEq Codes unknown
⟨1,2⟩ lib.AssertEq Lines unknown

# Current-policy projection removes only the known historical Envelope section
# family. An unrelated unknown section must survive projection and still fail
# closed in the strict current-policy owner.
historySuffix ← Rows ⟨"[envelope-history]","identities = ["∾(Quoted "food")∾"]","","[[envelope-history.expense-routing]]","effective-from = "∾(Quoted "initial"),"expense-account = "∾(Quoted "expenses:food"),"route = "∾(Quoted "managed"),"target = "∾(Quoted "food"),"note = "∾(Quoted "synthetic")⟩
projectedHistory ← currentProjection.CurrentPolicy (currentRaw∾⟨lf⟩∾historySuffix)
historyPolicy ← householdAdmission.Admit ⟨projectedHistory,accounts⟩
"ok" lib.AssertEq historyPolicy.state
unknownAfterHistory ← currentProjection.CurrentPolicy (currentRaw∾⟨lf⟩∾historySuffix∾unknownPrefix)
projectedUnknown ← householdAdmission.Admit ⟨unknownAfterHistory,accounts⟩
"error" lib.AssertEq projectedUnknown.state
⟨"household_section_unsupported","household_key_outside_section"⟩ lib.AssertEq Codes projectedUnknown

•Out "test_ledger_household_policy_structure: ok"
