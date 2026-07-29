#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
accountAdmission ← •Import "../src/ledger/account_admission.bqn"
planSnapshot ← •Import "../src/ledger/plan_snapshot.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryBuilder.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← (accountAdmission.Admit ⟨loader.ReadLines base∾"accounts.tsv",registry⟩).accounts
result ← planSnapshot.Build ⟨loader.ReadLines base∾"plan.tsv",accounts,registry⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.facts.transactions.count
"plan.tsv" lib.AssertEq ⊑result.facts.sources.name
"plan" lib.AssertEq ⊑result.facts.layers.name

emptyResult ← planSnapshot.Build ⟨⟨⟩,accounts,registry⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.facts.transactions.count
invalidLine ← "2026-01-20"∾(@+9)∾"bad"∾(@+9)∾"assets:cash"∾(@+9)∾"expenses:food"∾(@+9)∾"25"∾(@+9)∾"currency=JPY"
invalid ← planSnapshot.Build ⟨⟨invalidLine⟩,accounts,registry⟩
"error" lib.AssertEq invalid.state
0 lib.AssertEq invalid.facts.transactions.count
"plan_id_missing" lib.AssertEq (⊑invalid.diagnostics).code
•Out "test_ledger_plan_snapshot: ok"
