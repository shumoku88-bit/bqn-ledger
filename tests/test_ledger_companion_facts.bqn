#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
companion_admission ← •Import "../src/ledger/companion_admission.bqn"
companion_snapshot ← •Import "../src/ledger/companion_snapshot.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← (account_admission.Admit ⟨loader.ReadLines base∾"accounts.tsv",registry⟩).accounts
planLines ← loader.ReadLines base∾"plan.tsv"
budgetLines ← loader.ReadLines base∾"budget_alloc.tsv"
result ← companion_snapshot.Build ⟨planLines,budgetLines,accounts,registry⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
1 lib.AssertEq result.plan.transactions.count
2 lib.AssertEq result.plan.postings.count
2 lib.AssertEq result.budget.transactions.count
4 lib.AssertEq result.budget.postings.count
⟨25,¯25⟩ lib.AssertEq result.plan.postings.coefficient
⟨100,¯100,60,¯60⟩ lib.AssertEq result.budget.postings.coefficient
⟨"debit","credit"⟩ lib.AssertEq result.plan.postings.side
⟨"plan.tsv:plan_id:plan-food-2026-01"⟩ lib.AssertEq result.plan.transactions.transaction_id
⟨"durable_relation"⟩ lib.AssertEq result.plan.transactions.identity_kind
⟨"plan-food-2026-01"⟩ lib.AssertEq result.plan.transactions.plan_id
⟨"food-plan"⟩ lib.AssertEq result.plan.transactions.description
⟨1⟩ lib.AssertEq result.plan.transactions.source_start_line
⟨"plan"⟩ lib.AssertEq result.plan.layers.name
⟨"budget"⟩ lib.AssertEq result.budget.layers.name
⟨"JPY"⟩ lib.AssertEq result.plan.domains.code
⟨"JPY"⟩ lib.AssertEq result.budget.domains.code
⟨"25","25"⟩ lib.AssertEq result.plan.postings.amount_text

emptyResult ← companion_snapshot.Build ⟨⟨⟩,⟨⟩,accounts,registry⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.plan.transactions.count
0 lib.AssertEq emptyResult.budget.transactions.count
0 lib.AssertEq emptyResult.plan.domains.count
0 lib.AssertEq emptyResult.budget.domains.count
⟨"plan"⟩ lib.AssertEq emptyResult.plan.layers.name
⟨"budget"⟩ lib.AssertEq emptyResult.budget.layers.name

multiAccountLines ← ⟨
  "assets:jpy	role=asset	currency=JPY",
  "expenses:jpy	role=expense	currency=JPY",
  "assets:usd	role=asset	currency=USD",
  "expenses:usd	role=expense	currency=USD"
⟩
multiAccounts ← (account_admission.Admit ⟨multiAccountLines,registry⟩).accounts
multiPlan ← ⟨
  "2026-01-20	jpy	assets:jpy	expenses:jpy	25	currency=JPY	plan_id=jpy-1",
  "2026-01-21	usd	assets:usd	expenses:usd	12.30	currency=USD	plan_id=usd-1"
⟩
multiResult ← companion_snapshot.Build ⟨multiPlan,⟨⟩,multiAccounts,registry⟩
"ok" lib.AssertEq multiResult.state
⟨"JPY","USD"⟩ lib.AssertEq multiResult.plan.domains.code
⟨0,1⟩ lib.AssertEq multiResult.plan.transactions.calculation_scale
⟨25,¯25,123,¯123⟩ lib.AssertEq multiResult.plan.postings.coefficient
⟨0,0,1,1⟩ lib.AssertEq multiResult.plan.postings.scale

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
CheckRejected ← {𝕊 plan‿budget‿code:
  rejected ← companion_snapshot.Build ⟨plan,budget,accounts,registry⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.plan.transactions.count
  0 lib.AssertEq rejected.plan.postings.count
  0 lib.AssertEq rejected.budget.transactions.count
  0 lib.AssertEq rejected.budget.postings.count
  1 lib.AssertEq HasCode ⟨code,rejected.diagnostics⟩
}

CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	plan_id=p1"⟩,budgetLines,"companion_currency_missing"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	currency=JPY"⟩,budgetLines,"plan_id_missing"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:missing	25	currency=JPY	plan_id=p1"⟩,budgetLines,"companion_to_account_unknown"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	currency=USD	plan_id=p1"⟩,budgetLines,"companion_from_account_currency_mismatch"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	currency=XXX	plan_id=p1"⟩,budgetLines,"companion_currency_unsupported"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	1.234	currency=USD	plan_id=p1"⟩,budgetLines,"companion_amount_precision_exceeded"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	0	currency=JPY	plan_id=p1"⟩,budgetLines,"companion_amount_nonpositive"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	currency=JPY	plan_id=p1	plan_id=p2"⟩,budgetLines,"companion_metadata_duplicate"⟩
CheckRejected ⟨⟨"2026-01-20	food-plan	assets:cash	expenses:food	25	currency=JPY	plan_id=p1	unknown=x"⟩,budgetLines,"companion_metadata_unsupported"⟩
CheckRejected ⟨⟨"2026-99-20	food-plan	assets:cash	expenses:food	25	currency=JPY	plan_id=p1"⟩,budgetLines,"companion_date_invalid"⟩
CheckRejected ⟨planLines,⟨"2026-01-01	seed	budget:opening	budget:unassigned	100"⟩,"companion_currency_missing"⟩

duplicatePlan ← ⟨
  "2026-01-20	one	assets:cash	expenses:food	25	currency=JPY	plan_id=p1",
  "2026-01-21	two	assets:cash	expenses:food	30	currency=JPY	plan_id=p1"
⟩
CheckRejected ⟨duplicatePlan,budgetLines,"companion_identity_duplicate"⟩

•Out "test_ledger_companion_facts: ok"
