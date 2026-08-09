#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
actualSource ← •Import "../src/application/actual_source_adapter.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "../src/ledger/household_policy_admission.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
flow ← •Import "../src/accounting/date_category_flow.bqn"
pivot ← •Import "../src/accounting/sparse_pivot.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
actualResult ← actualSource.Load ⟨base,registry⟩
"ok" lib.AssertEq actualResult.state
facts ← actualResult.facts
budgetPolicy ← budgetPolicyAdmission.Admit ⟨•FChars "../"∾base∾"budget.toml",facts.accounts⟩
"ok" lib.AssertEq budgetPolicy.state
household ← householdAdmission.Admit ⟨•FChars "../"∾base∾"household.toml",facts.accounts,budgetPolicy⟩
"ok" lib.AssertEq household.state
start ← dates.Ordinal "2026-01-01"
end ← dates.Ordinal "2026-02-01"
result ← flow.Build ⟨facts,budgetPolicy,household,"JPY","actual",start,end⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
0 lib.AssertEq result.scale
⟨"food","other"⟩ lib.AssertEq result.categories.label
⟨"envelope","other"⟩ lib.AssertEq result.categories.kind
⟨6,¯1⟩ lib.AssertEq result.categories.envelope_account_index
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.dates.date_text
⟨1000,0,0⟩ lib.AssertEq result.dates.income
⟨1000,¯20,¯15⟩ lib.AssertEq result.dates.net
⟨⟨1⟩,⟨⟩,⟨⟩⟩ lib.AssertEq result.dates.income_contributors
3 lib.AssertEq result.expense_groups.count
⟨1,2,2⟩ lib.AssertEq result.expense_groups.row_index
⟨0,0,1⟩ lib.AssertEq result.expense_groups.column_index
⟨20,10,5⟩ lib.AssertEq result.expense_groups.coefficient
⟨⟨2⟩,⟨4⟩,⟨5⟩⟩ lib.AssertEq result.expense_groups.contributors
matrix ← pivot.Build ⟨result.dates.date_ordinal,result.categories.label,result.scale,result.expense_groups⟩
"ok" lib.AssertEq matrix.state
⟨⟨0,0⟩,⟨20,0⟩,⟨10,5⟩⟩ lib.AssertEq matrix.matrix.values
⟨⟨⟨⟩,⟨⟩⟩,⟨⟨2⟩,⟨⟩⟩,⟨⟨4⟩,⟨5⟩⟩⟩ lib.AssertEq matrix.matrix.contributors

late ← flow.Build ⟨facts,budgetPolicy,household,"JPY","actual",dates.Ordinal "2026-01-11",end⟩
"ok" lib.AssertEq late.state
⟨"2026-01-12"⟩ lib.AssertEq late.dates.date_text
⟨0⟩ lib.AssertEq late.dates.income
⟨¯15⟩ lib.AssertEq late.dates.net
⟨10,5⟩ lib.AssertEq late.expense_groups.coefficient

scaleAccountLines ← ⟨
  "assets:jpy	role=asset	currency=JPY",
  "expenses:food	role=expense	currency=JPY",
  "budget:food	role=budget	currency=JPY"
⟩
scaleAccounts ← (account_admission.Admit ⟨scaleAccountLines,registry⟩).accounts
scalePlanRaw ← ∾{𝕩∾@+10}¨⟨
  "2026-01-10 whole","  ; plan-id: p1","  expenses:food 25 JPY","  assets:jpy -25 JPY","",
  "2026-01-10 fraction","  ; plan-id: p2","  expenses:food 12.30 JPY","  assets:jpy -12.30 JPY"
⟩
scaleFacts ← (canonicalPlan.Build ⟨scalePlanRaw,scaleAccounts,registry⟩).facts
scaleBudgetPolicy ← {
  state⇐"ok",source_name⇐"budget.toml",envelopes⇐{count⇐1,id⇐⟨"food"⟩},
  expense_account_index⇐⟨1⟩,expense_envelope_id⇐⟨"food"⟩
}
scaleHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐⟨"food"⟩,allocation_account_index⇐⟨2⟩},
  account_policy⇐{account_key⇐scaleAccounts.key}
}
scaleFlow ← flow.Build ⟨scaleFacts,scaleBudgetPolicy,scaleHousehold,"JPY","plan",start,end⟩
"ok" lib.AssertEq scaleFlow.state
1 lib.AssertEq scaleFlow.scale
⟨"food","other"⟩ lib.AssertEq scaleFlow.categories.label
⟨¯373⟩ lib.AssertEq scaleFlow.dates.net
⟨373⟩ lib.AssertEq scaleFlow.expense_groups.coefficient
⟨⟨0,2⟩⟩ lib.AssertEq scaleFlow.expense_groups.contributors

missingHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐⟨⟩,allocation_account_index⇐⟨⟩},
  account_policy⇐{account_key⇐facts.accounts.key}
}
missingCoordinates ← flow.Build ⟨facts,budgetPolicy,missingHousehold,"JPY","actual",start,end⟩
"error" lib.AssertEq missingCoordinates.state
0 lib.AssertEq missingCoordinates.dates.count
0 lib.AssertEq missingCoordinates.categories.count
0 lib.AssertEq missingCoordinates.expense_groups.count
1 lib.AssertEq ∨´0∾"household_envelope_coordinates_missing"⊸≡¨{𝕩.code}¨missingCoordinates.diagnostics

CheckRejected ← {𝕊 domain‿layer‿s‿e‿code:
  rejected ← flow.Build ⟨facts,budgetPolicy,household,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.dates.count
  0 lib.AssertEq rejected.categories.count
  0 lib.AssertEq rejected.expense_groups.count
  1 lib.AssertEq ∨´0∾code⊸≡¨{𝕩.code}¨rejected.diagnostics
}
CheckRejected ⟨"USD","actual",start,end,"domain_unknown"⟩
CheckRejected ⟨"JPY","plan",start,end,"layer_unknown"⟩
CheckRejected ⟨"JPY","actual",end,start,"period_range_invalid"⟩

•Out "test_accounting_date_category_flow: ok"
