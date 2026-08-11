#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
io ← •Import "../src/application/source_io.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"

lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry

accountRaw ← Raw ⟨
  "account Assets:Cash","  type: Asset","  commodity: JPY","",
  "account Expenses:Food","  type: Expense","  commodity: JPY"
⟩
accountResult ← accountsAdmission.Admit accountRaw
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts

# The live Snapshot boundary receives already-admitted canonical Account evidence.
valid ← snapshot.BuildFromAccounts ⟨Raw ⟨
  "2026-08-12 Live snapshot",
  "  ; event-id: snapshot-live",
  "  Expenses:Food  100 JPY",
  "  Assets:Cash"
⟩,accounts,registry⟩
"ok" lib.AssertEq valid.state
0 lib.AssertEq ≠valid.diagnostics
1 lib.AssertEq valid.facts.transactions.count
2 lib.AssertEq valid.facts.postings.count
⟨"snapshot-live"⟩ lib.AssertEq valid.facts.transactions.transaction_id
⟨"snapshot-live:0","snapshot-live:1"⟩ lib.AssertEq valid.facts.postings.posting_id

# Journal admission failure remains fail-closed at the Snapshot publication
# boundary; no partial Facts are published.
invalid ← snapshot.BuildFromAccounts ⟨Raw ⟨
  "2026-08-12 Unbalanced snapshot",
  "  ; event-id: snapshot-unbalanced",
  "  Expenses:Food  100 JPY",
  "  Assets:Cash -90 JPY"
⟩,accounts,registry⟩
"error" lib.AssertEq invalid.state
0 lib.AssertEq invalid.facts.transactions.count
0 lib.AssertEq invalid.facts.postings.count
lib.Assert ∨´0∾"event_unbalanced"⊸≡¨{𝕩.code}¨invalid.diagnostics

•Out "test_ledger_snapshot_live_boundary: ok"
