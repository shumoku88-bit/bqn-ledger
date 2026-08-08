#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
planFactsBuilder ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
daily ← •Import "../src/application/household_daily_scope.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"

registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry
accountsResult ← accountsAdmission.Admit •FChars "../"∾base∾"accounts.journal"
"ok" lib.AssertEq accountsResult.state
accounts ← accountsResult.accounts
planResult ← planFactsBuilder.Build ⟨•FChars "../"∾base∾"plan.journal",accounts,registry⟩
"ok" lib.AssertEq planResult.state
budgetPolicy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budgetPolicy.state
household ← householdAdmission.Admit ⟨•FChars "../"∾base∾"household.toml",accounts,budgetPolicy⟩
"ok" lib.AssertEq household.state

result ← daily.Build ⟨household,planResult.facts,registry⟩
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
2 lib.AssertEq result.rows.count
⟨"asset","obligation"⟩ lib.AssertEq result.rows.kind
⟨"cash","rent"⟩ lib.AssertEq result.rows.scope_id
⟨"assets:cash",""⟩ lib.AssertEq result.rows.account_key
⟨"","plan-rent-daily-target"⟩ lib.AssertEq result.rows.plan_id
⟨0,50⟩ lib.AssertEq result.rows.excluded_coefficient
⟨0,0⟩ lib.AssertEq result.rows.excluded_scale
⟨"","JPY"⟩ lib.AssertEq result.rows.currency
⟨"","reservation:rent"⟩ lib.AssertEq result.rows.reservation_ref
"plan.journal:plan_id:plan-rent-daily-target" lib.AssertEq 1⊑result.rows.source_ref

•Out "test_application_household_daily_scope: ok"
