#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
policyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
Codes ← {𝕊 diagnostics: {𝕩.code}¨diagnostics}
Lines ← {𝕊 diagnostics: {𝕩.line}¨diagnostics}
LineForCode ← {𝕊 code‿diagnostics:
  matches ← ({𝕩.code≡code}¨diagnostics)/diagnostics
  (⊑matches).line
}
accounts ← {
  count⇐6,index⇐↕6,
  key⇐⟨"Assets:Cash","Assets:Savings","Expenses:Food","Expenses:Books","Assets:Reserve]One","Expenses:Food,Shared"⟩,
  role⇐⟨"asset","asset","expense","expense","asset","expense"⟩
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

# A closing bracket or comma inside a quoted Account key is data, not source
# structure. Multiline logical-row assembly and item splitting must agree on the
# same quote boundary.
quotedPunctuationRaw ← Raw ⟨
  "[[backing-pools]]","id = "∾(Q "punct"),"asset-accounts = [",
  "  "∾(Q "Assets:Reserve]One")∾",",
  "  "∾(Q "Assets:Cash"),
  "]","",
  "[[envelopes]]","id = "∾(Q "shared"),"label = "∾(Q "Shared"),
  "pacing = "∾(Q "flex"),"backing-pool = "∾(Q "punct"),
  "expense-accounts = ["∾(Q "Expenses:Food,Shared")∾"]"
⟩
quotedPunctuation ← policyAdmission.Admit ⟨quotedPunctuationRaw,accounts⟩
"ok" lib.AssertEq quotedPunctuation.state
⟨⟨"Assets:Reserve]One","Assets:Cash"⟩⟩ lib.AssertEq quotedPunctuation.backing_pools.asset_account_keys
⟨⟨"Expenses:Food,Shared"⟩⟩ lib.AssertEq quotedPunctuation.envelopes.expense_account_keys

# A multiline logical key/value row owns the first physical source coordinate.
# Literal diagnostics from later physical continuation lines are remapped to
# that first line rather than losing source provenance during row assembly.
malformedMultiline ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = [",
  "  "∾(Q "Assets:Cash")∾",",
  "  not-quoted",
  "]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq malformedMultiline.state
lib.Assert HasCode ⟨"budget_policy_string_invalid",malformedMultiline.diagnostics⟩
3 lib.AssertEq LineForCode ⟨"budget_policy_string_invalid",malformedMultiline.diagnostics⟩

# Before the first canonical table header, a key/value row is not silently
# attached to the first later block. Its own physical coordinate is retained.
outsideTable ← policyAdmission.Admit ⟨Raw ⟨
  "id = "∾(Q "orphan"),
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq outsideTable.state
lib.Assert HasCode ⟨"budget_policy_key_outside_table",outsideTable.diagnostics⟩
1 lib.AssertEq LineForCode ⟨"budget_policy_key_outside_table",outsideTable.diagnostics⟩

# Current admission is fail-fast across semantic blocks: once one block emits a
# semantic diagnostic, later structurally valid blocks are not semantically
# parsed. Preserve this diagnostic frontier unless a separate review deliberately
# changes diagnostic publication semantics.
semanticFrontier ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "bad-pacing"),"label = "∾(Q "Bad pacing"),
  "pacing = "∾(Q "weekly"),"backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Food")∾"]","",
  "[[envelopes]]","id = "∾(Q "later"),"label = "∾(Q "Later"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "missing"),
  "expense-accounts = ["∾(Q "Expenses:Books")∾"]"
⟩,accounts⟩
"error" lib.AssertEq semanticFrontier.state
⟨"envelope_pacing_invalid","budget_policy_envelopes_missing"⟩ lib.AssertEq Codes semanticFrontier.diagnostics
0 lib.AssertEq HasCode ⟨"envelope_backing_pool_unknown",semanticFrontier.diagnostics⟩

# Account relation diagnostics are policy-key-major. Expense memberships are
# resolved before backing Asset memberships, and each diagnostic keeps the line
# of the owning Envelope or backing-pool block.
relationOrder ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),
  "asset-accounts = ["∾(Q "Missing:Asset")∾", "∾(Q "Expenses:Books")∾"]","",
  "[[envelopes]]","id = "∾(Q "mixed"),"label = "∾(Q "Mixed"),
  "pacing = "∾(Q "flex"),"backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Missing:Expense")∾", "∾(Q "Assets:Savings")∾"]"
⟩,accounts⟩
"error" lib.AssertEq relationOrder.state
⟨
  "budget_policy_expense_account_unknown",
  "budget_policy_expense_account_role_invalid",
  "budget_policy_asset_account_unknown",
  "budget_policy_asset_account_role_invalid"
⟩ lib.AssertEq Codes relationOrder.diagnostics
⟨5,5,1,1⟩ lib.AssertEq Lines relationOrder.diagnostics

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
0 lib.AssertEq wrongRole.backing_pools.count
0 lib.AssertEq wrongRole.envelopes.count

unknownPool ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "missing"),"expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq unknownPool.state
lib.Assert HasCode ⟨"envelope_backing_pool_unknown",unknownPool.diagnostics⟩

•Out "test_ledger_budget_policy_admission: ok"
