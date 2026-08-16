#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
canonicalBudget ← •Import "canonical_budget_test_facts.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "current_household_policy_test_admission.bqn"
envelopeHistoryAdmission ← •Import "../src/ledger/envelope_history_admission.bqn"
account_admission ← •Import "../src/ledger/account_journal_admission.bqn"
cycleResolution ← •Import "../src/application/cycle_resolution.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
compose ← •Import "../src/report/compose.bqn"
render ← •Import "../src/report/render.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
accounts ← (account_admission.Admit accountSource).accounts
actual ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
planRaw ← •FChars "../"∾base∾"plan.journal"
planResult ← canonicalPlan.Build ⟨planRaw,accounts,registry⟩
plan ← planResult.facts ⋄ planRetirements ← planResult.retirements
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
budgetRaw ← Raw ⟨
  "2026-01-01 seed","  budget:opening     -100 JPY","  budget:unassigned   100 JPY","",
  "2026-01-01 allocate-food","  budget:unassigned  -60 JPY","  budget:food         60 JPY"
⟩
budget ← (canonicalBudget.Build ⟨budgetRaw,accounts,registry⟩).movements
budgetPolicy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",accounts⟩
"ok" lib.AssertEq budgetPolicy.state
householdRaw ← •FChars "../"∾base∾"household.toml"
household ← householdAdmission.Admit ⟨householdRaw,accounts,budgetPolicy⟩
"ok" lib.AssertEq household.state
envelopeHistory ← envelopeHistoryAdmission.Admit householdRaw
"ok" lib.AssertEq envelopeHistory.state
cycle10 ← cycleResolution.WithPlan ⟨household.cycle,"2026-01-10",actual,plan⟩
"ok" lib.AssertEq cycle10.state
cycle12 ← cycleResolution.WithPlan ⟨household.cycle,"2026-01-12",actual,plan⟩
"ok" lib.AssertEq cycle12.state

CheckGolden ← {𝕊 composition‿key‿surface‿file:
  "ok" lib.AssertEq composition.state ⋄ key lib.AssertEq composition.key
  rendered ← render.Render ⟨key,surface,composition⟩ ⋄ "ok" lib.AssertEq rendered.state
  (•FChars "../"∾base∾file) lib.AssertEq rendered.text
}

balances ← compose.Balances ⟨actual,"JPY","2026-01-12"⟩
CheckGolden ⟨balances,"balances","human","account_balances.destination.human.txt"⟩
balanceSheet ← compose.BalanceSheet ⟨actual,"JPY","2026-01-12"⟩
CheckGolden ⟨balanceSheet,"balance-sheet","human","balance_sheet.destination.human.txt"⟩
profitLoss ← compose.ProfitAndLoss ⟨actual,"JPY","2026-01-01","2026-02-01"⟩
CheckGolden ⟨profitLoss,"profit-and-loss","human","profit_and_loss.destination.human.txt"⟩
recent ← compose.Recent ⟨actual,10⟩
CheckGolden ⟨recent,"recent","compact","recent_journal.destination.compact.txt"⟩
planned ← compose.Planned ⟨plan,actual,cycle12,"2026-01-12"⟩
CheckGolden ⟨planned,"planned","json","planned_payments.destination.json"⟩
cycleAccounts ← compose.CycleAccounts ⟨actual,"JPY",cycle10,"2026-01-10"⟩
CheckGolden ⟨cycleAccounts,"cycle-accounts","human","cycle_accounts.destination.human.txt"⟩
comparison ← compose.CycleComparison ⟨actual,"JPY",cycle10,"2026-01-10",cycle10,"2026-01-10","aligned_elapsed"⟩
CheckGolden ⟨comparison,"cycle-comparison","human","cycle_comparison.destination.human.txt"⟩
monthly ← compose.MonthlyAccounts ⟨actual,"JPY","2026-01","2026-03"⟩
CheckGolden ⟨monthly,"monthly-accounts","human","monthly_accounts.destination.human.txt"⟩
dailyFlow ← compose.DailyFlow ⟨actual,household,envelopeHistory,"JPY","2026-01-01","2026-02-01","2026-01-12"⟩
CheckGolden ⟨dailyFlow,"daily-flow","human","daily_flow.destination.human.txt"⟩
envelopes ← compose.Envelopes ⟨budget,budgetPolicy,household,envelopeHistory,actual,plan,planRetirements,"JPY","2026-01-01","2026-02-01","2026-01-12"⟩
CheckGolden ⟨envelopes,"envelopes","compact","envelope_backing.destination.compact.txt"⟩

Ref ← {𝕊 id:{source⇐"synthetic",transaction_id⇐id,posting_id⇐id}}
asset ← {asset_id⇐"cash",currency⇐"JPY",coefficient⇐1000,scale⇐0,decision⇐"include",reference⇐Ref "cash",contributors⇐⟨Ref "cash"⟩}
obligation ← {obligation_id⇐"rent",due_ordinal⇐dates.Ordinal "2026-01-15",currency⇐"JPY",coefficient⇐200,scale⇐0,settlement_state⇐"open",decision⇐"include",excluded_coefficient⇐50,excluded_scale⇐0,reservation_state⇐"proven",reservation_ref⇐"reservation:rent",reference⇐Ref "rent",contributors⇐⟨Ref "rent"⟩}
assetScope ← {state⇐"resolved",scope_id⇐"assets",basis_kind⇐"account_balance",rows⇐⟨asset⟩}
obligationScope ← {state⇐"resolved",scope_id⇐"obligations",rows⇐⟨obligation⟩}
dailyTarget ← compose.DailyTarget ⟨"2026-01-10","2026-01-20","JPY",assetScope,obligationScope⟩
CheckGolden ⟨dailyTarget,"daily-target","human","daily_target.destination.human.txt"⟩
issues ← compose.Issues ⟨loader.ReadLines base∾"issues.destination.tsv",registry⟩
CheckGolden ⟨issues,"issues","human","issues.destination.human.txt"⟩

deficitAsset ← {asset_id⇐"cash",currency⇐"JPY",coefficient⇐100,scale⇐0,decision⇐"include",reference⇐Ref "cash",contributors⇐⟨Ref "cash"⟩}
deficitAssetScope ← {state⇐"resolved",scope_id⇐"assets",basis_kind⇐"account_balance",rows⇐⟨deficitAsset⟩}
deficitTarget ← compose.DailyTarget ⟨"2026-01-10","2026-01-20","JPY",deficitAssetScope,obligationScope⟩
"ok" lib.AssertEq deficitTarget.state
"deficit" lib.AssertEq deficitTarget.result.state

unavailableAssets ← {state⇐"unavailable",scope_id⇐"missing",basis_kind⇐"account_balance",rows⇐⟨⟩}
unavailableTarget ← compose.DailyTarget ⟨"2026-01-10","2026-01-20","JPY",unavailableAssets,obligationScope⟩
"unavailable" lib.AssertEq unavailableTarget.state
"asset_scope_unavailable" lib.AssertEq unavailableTarget.reason
"error" lib.AssertEq (compose.Balances ⟨actual,"JPY","2026-01-40"⟩).state
"error" lib.AssertEq (compose.Recent ⟨actual,0⟩).state
"error" lib.AssertEq (render.Render ⟨"issues","json",issues⟩).state
"error" lib.AssertEq (render.Render ⟨"balances","human",recent⟩).state
"error" lib.AssertEq (compose.ValidateSingle ⟨"all","human"⟩).state
•Out "test_report_composition: ok"
