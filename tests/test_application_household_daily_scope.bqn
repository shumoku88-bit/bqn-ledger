#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
accountsAdmission ← •Import "../src/ledger/account_journal_admission.bqn"
planFactsBuilder ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "current_household_policy_test_admission.bqn"
daily ← •Import "../src/application/household_daily_scope.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
empty ← ⟨⟩

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

# Plan-local failures remain source ordered after row-local projection. This law
# deliberately combines duplicate metadata, reservation-without-selection,
# incomplete reservation, invalid amount, and invalid reservation id.
Meta ← {𝕊 key‿value:{key⇐key,value⇐value}}
syntheticHousehold ← {
  state⇐"ok",source_name⇐"household.toml",diagnostics⇐empty,
  daily_target⇐{index⇐empty,scope_id⇐empty,account_key⇐empty}
}
syntheticPlan ← {
  state⇐"ok",sources⇐{name⇐⟨"plan.journal"⟩},
  transactions⇐{
    index⇐⟨0,1,2⟩,
    metadata⇐⟨
      ⟨Meta ⟨"reservation-id","r1"⟩,Meta ⟨"reservation-id","r2"⟩⟩,
      ⟨Meta ⟨"daily-target-id",""⟩,Meta ⟨"reservation-id","r3"⟩,Meta ⟨"reservation-commodity","JPY"⟩⟩,
      ⟨Meta ⟨"daily-target-id","rent"⟩,Meta ⟨"reservation-id",""⟩,Meta ⟨"reservation-amount","bad"⟩,Meta ⟨"reservation-commodity","JPY"⟩⟩
    ⟩,
    plan_id⇐⟨"p0","p1","p2"⟩,
    source_start_line⇐⟨1,2,3⟩,
    transaction_id⇐⟨"plan.journal:plan_id:p0","plan.journal:plan_id:p1","plan.journal:plan_id:p2"⟩
  }
}
failed ← daily.Build ⟨syntheticHousehold,syntheticPlan,registry⟩
"error" lib.AssertEq failed.state
0 lib.AssertEq failed.rows.count
⟨
  "daily_target_metadata_duplicate",
  "daily_reservation_without_selection",
  "daily_target_id_empty",
  "daily_reservation_incomplete",
  "daily_reservation_amount_invalid",
  "daily_reservation_id_invalid"
⟩ lib.AssertEq {𝕩.code}¨failed.diagnostics

•Out "test_application_household_daily_scope: ok"
