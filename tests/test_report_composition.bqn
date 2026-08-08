#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
budgetSnapshot ← •Import "../src/ledger/budget_snapshot.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
fixed_resolver ← •Import "../src/accounting/cycle_fixed_resolution.bqn"
cycle_result ← •Import "../src/accounting/cycle_result.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
compose ← •Import "../src/report/compose.bqn"
render ← •Import "../src/report/render.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
actual ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
Raw ← {𝕊 sourceLines: ∾sourceLines∾¨lf}
planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
budget ← (budgetSnapshot.Build ⟨loader.ReadLines base∾"budget_alloc.tsv",accounts,registry⟩).facts
cycle ← fixed_resolver.Resolve cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩

CheckGolden ← {𝕊 composition‿key‿surface‿file:
  "ok" lib.AssertEq composition.state
  key lib.AssertEq composition.key
  rendered ← render.Render ⟨key,surface,composition⟩
  "ok" lib.AssertEq rendered.state
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
planned ← compose.Planned ⟨plan,actual,cycle,"2026-01-12"⟩
CheckGolden ⟨planned,"planned","json","planned_payments.destination.json"⟩
cycleAccounts ← compose.CycleAccounts ⟨actual,"JPY",cycle,"2026-01-10"⟩
CheckGolden ⟨cycleAccounts,"cycle-accounts","human","cycle_accounts.destination.human.txt"⟩

currentCycle ← cycle_result.Success ⟨"fixed","2026-01-10","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
baselineCycle ← cycle_result.Success ⟨"fixed","2025-12-31","2025-12-22","2026-01-22",⟨⟩,⟨⟩⟩
comparison ← compose.CycleComparison ⟨actual,"JPY",currentCycle,"2026-01-10",baselineCycle,"2025-12-31","aligned_elapsed"⟩
CheckGolden ⟨comparison,"cycle-comparison","human","cycle_comparison.destination.human.txt"⟩
monthly ← compose.MonthlyAccounts ⟨actual,"JPY","2026-01","2026-03"⟩
CheckGolden ⟨monthly,"monthly-accounts","human","monthly_accounts.destination.human.txt"⟩
dailyFlow ← compose.DailyFlow ⟨actual,"JPY","2026-01-01","2026-02-01","2026-01-12"⟩
CheckGolden ⟨dailyFlow,"daily-flow","human","daily_flow.destination.human.txt"⟩
envelopes ← compose.Envelopes ⟨budget,actual,plan,"JPY","2026-01-01","2026-02-01","2026-01-12",⟨0⟩⟩
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
