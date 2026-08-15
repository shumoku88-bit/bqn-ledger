#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
currentProjection ← •Import "../src/ledger/household_current_policy_projection.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
accountsResult ← accountsAdmission.Admit •FChars "../"∾base∾"accounts.journal"
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
budget ← budgetAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budget.state
householdRaw ← currentProjection.CurrentPolicy (•FChars "../"∾base∾"household.toml")

foodIndex ← ⊑accounts.key⊐⟨"expenses:food"⟩
transportIndex ← ⊑accounts.key⊐⟨"expenses:transport"⟩

# Keep the Account carrier shape fixed while making the first expense relation a
# known wrong role and the second an unknown key. Diagnostic order must follow
# the Household policy key axis, not diagnostic kind.
badKeys ← {𝕊 i: (i=transportIndex)⊑⟨i⊑accounts.key,"expenses:renamed"⟩}¨accounts.index
badRoles ← {𝕊 i: (i=foodIndex)⊑⟨i⊑accounts.role,"asset"⟩}¨accounts.index
badAccounts ← {
  count⇐accounts.count,index⇐accounts.index,key⇐badKeys,
  currency⇐accounts.currency,default_commodity⇐accounts.default_commodity,
  role⇐badRoles,type⇐accounts.type,metadata⇐accounts.metadata,source_row⇐accounts.source_row
}

bad ← householdAdmission.Admit ⟨householdRaw,badAccounts,budget⟩
"error" lib.AssertEq bad.state
⟨"household_account_role_invalid","household_account_unknown"⟩ lib.AssertEq {𝕩.code}¨bad.diagnostics
2 lib.AssertEq ≠bad.diagnostics

# Fail-closed publication keeps the dense Account axis but publishes no policy
# classifications from the rejected source.
badAccounts.key lib.AssertEq bad.account_policy.account_key
(accounts.count⥊⟨""⟩) lib.AssertEq bad.account_policy.spend_class

•Out "test_ledger_household_policy_account_relations: ok"
