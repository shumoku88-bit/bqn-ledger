#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
policyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
accounts ← {
  count⇐4,index⇐↕4,
  key⇐⟨"Assets:Cash","Assets:Savings","Expenses:Food","Expenses:Books"⟩,
  role⇐⟨"asset","asset","expense","expense"⟩
}

validRaw ← Raw ⟨
  "[[backing-pools]]",
  "id = \"cash\"",
  "asset-accounts = [\"Assets:Cash\", \"Assets:Savings\"]","",
  "[[envelopes]]",
  "id = \"food\"",
  "label = \"Food\"",
  "pacing = \"daily\"",
  "backing-pool = \"cash\"",
  "expense-accounts = [\"Expenses:Food\"]","",
  "[[envelopes]]",
  "id = \"books\"",
  "label = \"Books\"",
  "pacing = \"flex\"",
  "backing-pool = \"cash\"",
  "expense-accounts = [\"Expenses:Books\"]"
⟩
valid ← policyAdmission.Admit ⟨validRaw,accounts⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
"budget.toml" lib.AssertEq valid.source_name
1 lib.AssertEq valid.backing_pools.count
⟨"cash"⟩ lib.AssertEq valid.backing_pools.id
⟨⟨"Assets:Cash","Assets:Savings"⟩⟩ lib.AssertEq valid.backing_pools.asset_account_keys
2 lib.AssertEq valid.envelopes.count
⟨"food","books"⟩ lib.AssertEq valid.envelopes.id
⟨"Food","Books"⟩ lib.AssertEq valid.envelopes.label
⟨"daily","flex"⟩ lib.AssertEq valid.envelopes.pacing
⟨"cash","cash"⟩ lib.AssertEq valid.envelopes.backing_pool
⟨2,3⟩ lib.AssertEq valid.expense_account_index
⟨"food","books"⟩ lib.AssertEq valid.expense_envelope_id
⟨0,1⟩ lib.AssertEq valid.asset_account_index
⟨"cash","cash"⟩ lib.AssertEq valid.asset_backing_pool_id

duplicateExpense ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = \"cash\"","asset-accounts = [\"Assets:Cash\"]","",
  "[[envelopes]]","id = \"food\"","label = \"Food\"","pacing = \"daily\"","backing-pool = \"cash\"","expense-accounts = [\"Expenses:Food\"]","",
  "[[envelopes]]","id = \"shared\"","label = \"Shared\"","pacing = \"flex\"","backing-pool = \"cash\"","expense-accounts = [\"Expenses:Food\"]"
⟩,accounts⟩
"error" lib.AssertEq duplicateExpense.state
lib.Assert HasCode ⟨"expense_account_assignment_duplicate",duplicateExpense.diagnostics⟩

wrongRole ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = \"cash\"","asset-accounts = [\"Expenses:Food\"]","",
  "[[envelopes]]","id = \"food\"","label = \"Food\"","pacing = \"daily\"","backing-pool = \"cash\"","expense-accounts = [\"Expenses:Food\"]"
⟩,accounts⟩
"error" lib.AssertEq wrongRole.state
lib.Assert HasCode ⟨"budget_policy_asset_account_role_invalid",wrongRole.diagnostics⟩

unknownPool ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = \"cash\"","asset-accounts = [\"Assets:Cash\"]","",
  "[[envelopes]]","id = \"food\"","label = \"Food\"","pacing = \"daily\"","backing-pool = \"missing\"","expense-accounts = [\"Expenses:Food\"]"
⟩,accounts⟩
"error" lib.AssertEq unknownPool.state
lib.Assert HasCode ⟨"envelope_backing_pool_unknown",unknownPool.diagnostics⟩

•Out "test_ledger_budget_policy_admission: ok"
