#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
budgetAdmission ← •Import "../src/ledger/budget_journal_admission.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
HasCode ← {𝕊 code‿diagnostics: ∨´0∾{𝕩.code≡code}¨diagnostics}
Codes ← {𝕊 diagnostics: {𝕩.code}¨diagnostics}

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountRaw ← Raw ⟨
  "account Budget:Unassigned","  type: Budget","  commodity: JPY","",
  "account Budget:Food","  type: Budget","  commodity: JPY","",
  "account Budget:Reserve","  type: Budget","  commodity: JPY","",
  "account Assets:Cash","  type: Asset","  commodity: JPY"
⟩
accountResult ← accountsAdmission.Admit accountRaw
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts

# Source order is semantic from -> to. Different textual scales still represent
# exact opposite resolved amounts and normalize to the canonical JPY scale.
validRaw ← Raw ⟨
  "2026-08-08 Allocate food",
  "  Budget:Unassigned  -20.0 JPY",
  "  Budget:Food          20 JPY","",
  "2026-08-09 Move to reserve",
  "  Budget:Food     -5 JPY",
  "  Budget:Reserve   5 JPY"
⟩
valid ← budgetAdmission.Admit ⟨validRaw,accounts,registry⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
"budget.journal" lib.AssertEq valid.source_name
⟨"budget"⟩ lib.AssertEq valid.declared_layers
2 lib.AssertEq ≠valid.transactions
⟨"2026-08-08","2026-08-09"⟩ lib.AssertEq {𝕩.date}¨valid.transactions
⟨"Allocate food","Move to reserve"⟩ lib.AssertEq {𝕩.description}¨valid.transactions
⟨"budget","budget"⟩ lib.AssertEq {𝕩.layer_name}¨valid.transactions
⟨"physical_fallback","physical_fallback"⟩ lib.AssertEq {𝕩.identity_kind}¨valid.transactions
⟨"budget.journal:line:1","budget.journal:line:5"⟩ lib.AssertEq {𝕩.source_event_id}¨valid.transactions
first ← ⊑valid.transactions
"Budget:Unassigned" lib.AssertEq first.from_account_key
"Budget:Food" lib.AssertEq first.to_account_key
"JPY" lib.AssertEq first.movement_commodity
20 lib.AssertEq first.movement_coefficient
0 lib.AssertEq first.movement_scale
⟨"Budget:Unassigned","Budget:Food"⟩ lib.AssertEq {𝕩.account_key}¨first.postings
⟨0,1⟩ lib.AssertEq {𝕩.posting_index}¨first.postings
⟨¯20,20⟩ lib.AssertEq {𝕩.normalized_coefficient}¨first.postings
⟨2,3⟩ lib.AssertEq {𝕩.source_line}¨first.postings
⟨"budget.journal:line:1:0","budget.journal:line:1:1"⟩ lib.AssertEq {𝕩.posting_id}¨first.postings

threePosting ← budgetAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Split allocation",
  "  Budget:Unassigned  -20 JPY",
  "  Budget:Food          10 JPY",
  "  Budget:Reserve       10 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq threePosting.state
lib.Assert HasCode ⟨"budget_movement_requires_binary_transaction",threePosting.diagnostics⟩

nonBudget ← budgetAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Invalid movement",
  "  Budget:Unassigned  -20 JPY",
  "  Assets:Cash          20 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq nonBudget.state
lib.Assert HasCode ⟨"budget_movement_posting_not_budget",nonBudget.diagnostics⟩

# Exact balance belongs to complete Journal admission. A two-Posting Budget
# transaction that is not exact opposites never reaches Budget-specific relation
# admission, so the historical Budget exact-opposite diagnostic is unreachable.
unbalanced ← budgetAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Unbalanced movement",
  "  Budget:Unassigned  -20 JPY",
  "  Budget:Food          10 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq unbalanced.state
lib.Assert HasCode ⟨"event_unbalanced",unbalanced.diagnostics⟩
0 lib.AssertEq HasCode ⟨"budget_movement_postings_not_exact_opposites",unbalanced.diagnostics⟩

# Budget diagnostics stay transaction-major: each transaction's semantic
# diagnostics appear in source order rather than being regrouped by rule.
mixedInvalid ← budgetAdmission.Admit ⟨Raw ⟨
  "2026-08-08 Non-budget first",
  "  Budget:Unassigned  -20 JPY",
  "  Assets:Cash          20 JPY","",
  "2026-08-09 Non-binary second",
  "  Budget:Unassigned  -20 JPY",
  "  Budget:Food          10 JPY",
  "  Budget:Reserve       10 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq mixedInvalid.state
⟨"budget_movement_posting_not_budget","budget_movement_requires_binary_transaction"⟩ lib.AssertEq Codes mixedInvalid.diagnostics

•Out "test_ledger_budget_journal_admission: ok"
