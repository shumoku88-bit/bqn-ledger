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
HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
actualResult ← actualSource.Load ⟨base,registry⟩
"ok" lib.AssertEq actualResult.state
facts ← actualResult.facts
budgetRaw ← •FChars "../"∾base∾"budget.toml"
budgetPolicy ← budgetPolicyAdmission.Admit ⟨budgetRaw,facts.accounts⟩
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
facts.accounts.index lib.AssertEq result.accounts.account_index
facts.accounts.key lib.AssertEq result.accounts.key
facts.accounts.role lib.AssertEq result.accounts.role
⟨"2026-01-02","2026-01-10","2026-01-12"⟩ lib.AssertEq result.dates.date_text
⟨1000,0,0⟩ lib.AssertEq result.dates.income
⟨1000,¯20,¯15⟩ lib.AssertEq result.dates.net
⟨⟨1⟩,⟨⟩,⟨⟩⟩ lib.AssertEq result.dates.income_contributors
3 lib.AssertEq result.expense_groups.count
⟨1,2,2⟩ lib.AssertEq result.expense_groups.row_index
⟨0,0,1⟩ lib.AssertEq result.expense_groups.column_index
⟨20,10,5⟩ lib.AssertEq result.expense_groups.coefficient
⟨⟨2⟩,⟨4⟩,⟨5⟩⟩ lib.AssertEq result.expense_groups.contributors
⟨0,0,1,1,2,2,2⟩ lib.AssertEq result.account_groups.row_index
⟨0,1,0,2,0,2,3⟩ lib.AssertEq result.account_groups.column_index
⟨1000,¯1000,¯20,20,¯15,10,5⟩ lib.AssertEq result.account_groups.coefficient
⟨⟨0⟩,⟨1⟩,⟨3⟩,⟨2⟩,⟨6⟩,⟨4⟩,⟨5⟩⟩ lib.AssertEq result.account_groups.contributors
matrix ← pivot.Build ⟨result.dates.date_ordinal,result.categories.label,result.scale,result.expense_groups⟩
"ok" lib.AssertEq matrix.state
⟨⟨0,0⟩,⟨20,0⟩,⟨10,5⟩⟩ lib.AssertEq matrix.matrix.values
⟨⟨⟨⟩,⟨⟩⟩,⟨⟨2⟩,⟨⟩⟩,⟨⟨4⟩,⟨5⟩⟩⟩ lib.AssertEq matrix.matrix.contributors

# Budget policy Account order is admission evidence, not a reusable numeric axis.
reorderedAccounts ← {
  count⇐facts.accounts.count,index⇐facts.accounts.index,
  key⇐⌽facts.accounts.key,role⇐⌽facts.accounts.role
}
reorderedPolicy ← budgetPolicyAdmission.Admit ⟨budgetRaw,reorderedAccounts⟩
"ok" lib.AssertEq reorderedPolicy.state
reordered ← flow.Build ⟨facts,reorderedPolicy,household,"JPY","actual",start,end⟩
"ok" lib.AssertEq reordered.state
result.categories.label lib.AssertEq reordered.categories.label
result.expense_groups.row_index lib.AssertEq reordered.expense_groups.row_index
result.expense_groups.column_index lib.AssertEq reordered.expense_groups.column_index
result.expense_groups.coefficient lib.AssertEq reordered.expense_groups.coefficient
result.expense_groups.contributors lib.AssertEq reordered.expense_groups.contributors

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
  state⇐"ok",source_name⇐"budget.toml",
  envelopes⇐{count⇐1,id⇐⟨"food"⟩,expense_account_keys⇐⟨⟨"expenses:food"⟩⟩}
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

missingKeyPolicy ← {
  state⇐"ok",source_name⇐"budget.toml",
  envelopes⇐{count⇐1,id⇐⟨"food"⟩,expense_account_keys⇐⟨⟨"expenses:missing"⟩⟩}
}
missingKey ← flow.Build ⟨scaleFacts,missingKeyPolicy,scaleHousehold,"JPY","plan",start,end⟩
"error" lib.AssertEq missingKey.state
lib.Assert HasCode ⟨"budget_policy_expense_account_unknown",missingKey.diagnostics⟩
roleDriftPolicy ← {
  state⇐"ok",source_name⇐"budget.toml",
  envelopes⇐{count⇐1,id⇐⟨"food"⟩,expense_account_keys⇐⟨⟨"assets:jpy"⟩⟩}
}
roleDrift ← flow.Build ⟨scaleFacts,roleDriftPolicy,scaleHousehold,"JPY","plan",start,end⟩
"error" lib.AssertEq roleDrift.state
lib.Assert HasCode ⟨"budget_policy_expense_account_role_invalid",roleDrift.diagnostics⟩

# Household admission proved the allocation Account against its own Account carrier.
# The capability must still reject role drift on the current Facts carrier even when
# Account keys remain aligned.
allocationRoleDriftHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐⟨"food"⟩,allocation_account_index⇐⟨0⟩},
  account_policy⇐{account_key⇐scaleAccounts.key}
}
allocationRoleDrift ← flow.Build ⟨scaleFacts,scaleBudgetPolicy,allocationRoleDriftHousehold,"JPY","plan",start,end⟩
"error" lib.AssertEq allocationRoleDrift.state
lib.Assert HasCode ⟨"envelope_account_role_invalid",allocationRoleDrift.diagnostics⟩

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
0 lib.AssertEq missingCoordinates.accounts.count
0 lib.AssertEq missingCoordinates.account_groups.count
lib.Assert HasCode ⟨"household_envelope_coordinates_missing",missingCoordinates.diagnostics⟩

CheckRejected ← {𝕊 domain‿layer‿s‿e‿code:
  rejected ← flow.Build ⟨facts,budgetPolicy,household,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.dates.count
  0 lib.AssertEq rejected.categories.count
  0 lib.AssertEq rejected.expense_groups.count
  0 lib.AssertEq rejected.accounts.count
  0 lib.AssertEq rejected.account_groups.count
  lib.Assert HasCode ⟨code,rejected.diagnostics⟩
}
CheckRejected ⟨"USD","actual",start,end,"domain_unknown"⟩
CheckRejected ⟨"JPY","plan",start,end,"layer_unknown"⟩
CheckRejected ⟨"JPY","actual",end,start,"period_range_invalid"⟩

•Out "test_accounting_date_category_flow: ok"
