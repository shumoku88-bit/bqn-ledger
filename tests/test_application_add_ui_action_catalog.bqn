#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
actions ← •Import "../src/application/add_ui_action_catalog.bqn"
production ← actions.catalog

validation ← actions.Validate production
"ok" lib.AssertEq validation.state
1 lib.AssertEq validation.aligned
1 lib.AssertEq validation.unique

rows ← actions.Rows production
12 lib.AssertEq ≠rows
"account-add	アカウント追加	account" lib.AssertEq ⊑rows
"issue-close	Issues & Decisions を閉じる	issue" lib.AssertEq ⊑⌽rows

duplicateCatalog ← {
  key⇐production.key∾⟨"expense"⟩,
  label⇐production.label∾⟨"duplicate expense"⟩,
  family⇐production.family∾⟨"journal"⟩
}
duplicateValidation ← actions.Validate duplicateCatalog
"error" lib.AssertEq duplicateValidation.state
1 lib.AssertEq duplicateValidation.aligned
0 lib.AssertEq duplicateValidation.unique

•Out "test_application_add_ui_action_catalog: ok"
