#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
policyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
accounts ← {
  count⇐4,index⇐↕4,
  key⇐⟨"Assets:Cash","Assets:Savings","Expenses:Food","Expenses:Books"⟩,
  role⇐⟨"asset","asset","expense","expense"⟩
}

validRaw ← Raw ⟨
  "[[backing-pools]]",
  "id = "∾(Q "cash"),
  "asset-accounts = ["∾(Q "Assets:Cash")∾", "∾(Q "Assets:Savings")∾"]","",
  "[[envelopes]]",
  "id = "∾(Q "food"),
  "label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),
  "backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Food")∾"]","",
  "[[envelopes]]",
  "id = "∾(Q "books"),
  "label = "∾(Q "Books"),
  "pacing = "∾(Q "flex"),
  "backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Books")∾"]"
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
⟨⟨"Expenses:Food"⟩,⟨"Expenses:Books"⟩⟩ lib.AssertEq valid.envelopes.expense_account_keys

multilineRaw ← Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = [",
  "  "∾(Q "Assets:Cash")∾",","  "∾(Q "Assets:Savings"),"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),"expense-accounts = [",
  "  "∾(Q "Expenses:Food")∾",",
  "]"
⟩
multiline ← policyAdmission.Admit ⟨multilineRaw,accounts⟩
"ok" lib.AssertEq multiline.state
⟨⟨"Assets:Cash","Assets:Savings"⟩⟩ lib.AssertEq multiline.backing_pools.asset_account_keys
⟨⟨"Expenses:Food"⟩⟩ lib.AssertEq multiline.envelopes.expense_account_keys

duplicateExpense ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),"expense-accounts = ["∾(Q "Expenses:Food")∾"]","",
  "[[envelopes]]","id = "∾(Q "shared"),"label = "∾(Q "Shared"),"pacing = "∾(Q "flex"),"backing-pool = "∾(Q "cash"),"expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq duplicateExpense.state
lib.Assert HasCode ⟨"expense_account_assignment_duplicate",duplicateExpense.diagnostics⟩

wrongRole ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Expenses:Food")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),"expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq wrongRole.state
lib.Assert HasCode ⟨"budget_policy_asset_account_role_invalid",wrongRole.diagnostics⟩

unknownPool ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "missing"),"expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq unknownPool.state
lib.Assert HasCode ⟨"envelope_backing_pool_unknown",unknownPool.diagnostics⟩

•Out "test_ledger_budget_policy_admission: ok"
