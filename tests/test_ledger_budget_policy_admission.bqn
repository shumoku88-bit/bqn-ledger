#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
policyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"

lf ← @+10
quote ← @+34
Raw ← {𝕊 lines: ∾lines∾¨lf}
Q ← {𝕊 text: ⟨quote⟩∾text∾⟨quote⟩}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
LineForCode ← {𝕊 code‿diagnostics:
  matches ← ({𝕩.code≡code}¨diagnostics)/diagnostics
  (⊑matches).line
}
accounts ← {
  count⇐4,index⇐↕4,
  key⇐⟨"Assets:Cash","Assets:Savings","Expenses:Food","Assets:Reserve]One"⟩,
  role⇐⟨"asset","asset","expense","asset"⟩
}

# Current budget.toml owns only Envelope definition/presentation and Backing.
validRaw ← Raw ⟨
  "[[backing-pools]]",
  "id = "∾(Q "cash"),
  "asset-accounts = ["∾(Q "Assets:Cash")∾", "∾(Q "Assets:Savings")∾"]","",
  "[[envelopes]]",
  "id = "∾(Q "food"),
  "label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),
  "backing-pool = "∾(Q "cash"),"",
  "[[envelopes]]",
  "id = "∾(Q "books"),
  "label = "∾(Q "Books"),
  "pacing = "∾(Q "flex"),
  "backing-pool = "∾(Q "cash")
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

# Backing Account arrays retain exact TOML parsing, including multiline source
# shape and punctuation inside quoted Account keys.
multilineRaw ← Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = [",
  "  "∾(Q "Assets:Reserve]One")∾",","  "∾(Q "Assets:Cash"),"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash")
⟩
multiline ← policyAdmission.Admit ⟨multilineRaw,accounts⟩
"ok" lib.AssertEq multiline.state
⟨⟨"Assets:Reserve]One","Assets:Cash"⟩⟩ lib.AssertEq multiline.backing_pools.asset_account_keys

# Retired Expense assignment syntax fails closed. Expense meaning belongs to
# household.toml Envelope history and is never reconstructed from current policy.
retiredExpenseAssignment ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash"),
  "expense-accounts = ["∾(Q "Expenses:Food")∾"]"
⟩,accounts⟩
"error" lib.AssertEq retiredExpenseAssignment.state
lib.Assert HasCode ⟨"budget_policy_key_unsupported",retiredExpenseAssignment.diagnostics⟩

# A multiline logical key/value row owns the first physical source coordinate.
malformedMultiline ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = [",
  "  "∾(Q "Assets:Cash")∾",",
  "  not-quoted",
  "]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash")
⟩,accounts⟩
"error" lib.AssertEq malformedMultiline.state
lib.Assert HasCode ⟨"budget_policy_string_invalid",malformedMultiline.diagnostics⟩
3 lib.AssertEq LineForCode ⟨"budget_policy_string_invalid",malformedMultiline.diagnostics⟩

outsideTable ← policyAdmission.Admit ⟨Raw ⟨
  "id = "∾(Q "orphan"),
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),
  "pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash")
⟩,accounts⟩
"error" lib.AssertEq outsideTable.state
lib.Assert HasCode ⟨"budget_policy_key_outside_table",outsideTable.diagnostics⟩
1 lib.AssertEq LineForCode ⟨"budget_policy_key_outside_table",outsideTable.diagnostics⟩

wrongRole ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Expenses:Food")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "cash")
⟩,accounts⟩
"error" lib.AssertEq wrongRole.state
lib.Assert HasCode ⟨"budget_policy_asset_account_role_invalid",wrongRole.diagnostics⟩

unknownPool ← policyAdmission.Admit ⟨Raw ⟨
  "[[backing-pools]]","id = "∾(Q "cash"),"asset-accounts = ["∾(Q "Assets:Cash")∾"]","",
  "[[envelopes]]","id = "∾(Q "food"),"label = "∾(Q "Food"),"pacing = "∾(Q "daily"),"backing-pool = "∾(Q "missing")
⟩,accounts⟩
"error" lib.AssertEq unknownPool.state
lib.Assert HasCode ⟨"envelope_backing_pool_unknown",unknownPool.diagnostics⟩

•Out "test_ledger_budget_policy_admission: ok"
