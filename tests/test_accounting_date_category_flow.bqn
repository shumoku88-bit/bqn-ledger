#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
actualSource ← •Import "../src/application/actual_source_adapter.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
historyAdmission ← •Import "../src/ledger/envelope_history_admission.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
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
householdRaw ← •FChars "../"∾base∾"household.toml"
history ← historyAdmission.Admit householdRaw
"ok" lib.AssertEq history.state
start ← dates.Ordinal "2026-01-01"
end ← dates.Ordinal "2026-02-01"
result ← flow.Build ⟨facts,history,"JPY","actual",start,end⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
0 lib.AssertEq result.scale
⟨"food","other"⟩ lib.AssertEq result.categories.label
⟨"envelope","other"⟩ lib.AssertEq result.categories.kind
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

late ← flow.Build ⟨facts,history,"JPY","actual",dates.Ordinal "2026-01-11",end⟩
"ok" lib.AssertEq late.state
⟨"2026-01-12"⟩ lib.AssertEq late.dates.date_text
⟨0⟩ lib.AssertEq late.dates.income
⟨¯15⟩ lib.AssertEq late.dates.net
⟨10,5⟩ lib.AssertEq late.expense_groups.coefficient

tab ← @+9
scaleAccountLines ← ⟨
  "assets:jpy"∾tab∾"role=asset"∾tab∾"currency=JPY",
  "expenses:food"∾tab∾"role=expense"∾tab∾"currency=JPY"
⟩
scaleAccountResult ← account_admission.Admit ⟨scaleAccountLines,registry⟩
"ok" lib.AssertEq scaleAccountResult.state
scaleAccounts ← scaleAccountResult.accounts
scalePlanRaw ← ∾{𝕩∾@+10}¨⟨
  "2026-01-10 whole","  ; plan-id: p1","  expenses:food 25 JPY","  assets:jpy -25 JPY","",
  "2026-01-10 fraction","  ; plan-id: p2","  expenses:food 12.30 JPY","  assets:jpy -12.30 JPY"
⟩
scalePlanResult ← canonicalPlan.Build ⟨scalePlanRaw,scaleAccounts,registry⟩
"ok" lib.AssertEq scalePlanResult.state
scaleFacts ← scalePlanResult.facts
scaleHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"food"⟩⟩
scaleFlow ← flow.Build ⟨scaleFacts,scaleHistory,"JPY","plan",start,end⟩
"ok" lib.AssertEq scaleFlow.state
1 lib.AssertEq scaleFlow.scale
⟨"food","other"⟩ lib.AssertEq scaleFlow.categories.label
⟨¯373⟩ lib.AssertEq scaleFlow.dates.net
⟨373⟩ lib.AssertEq scaleFlow.expense_groups.coefficient
⟨⟨0,2⟩⟩ lib.AssertEq scaleFlow.expense_groups.contributors

missingHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:missing"⟩,⟨"food"⟩⟩
missingKey ← flow.Build ⟨scaleFacts,missingHistory,"JPY","plan",start,end⟩
"error" lib.AssertEq missingKey.state
lib.Assert HasCode ⟨"expense_route_account_unknown",missingKey.diagnostics⟩
roleDriftHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"assets:jpy"⟩,⟨"food"⟩⟩
roleDrift ← flow.Build ⟨scaleFacts,roleDriftHistory,"JPY","plan",start,end⟩
"error" lib.AssertEq roleDrift.state
lib.Assert HasCode ⟨"expense_route_account_role_invalid",roleDrift.diagnostics⟩

unknownTargetHistory ← historyFixture.Managed ⟨⟨"food"⟩,⟨"expenses:food"⟩,⟨"unknown_target"⟩⟩
unknownTarget ← flow.Build ⟨scaleFacts,unknownTargetHistory,"JPY","plan",start,end⟩
"error" lib.AssertEq unknownTarget.state
lib.Assert HasCode ⟨"expense_route_target_unknown",unknownTarget.diagnostics⟩

CheckRejected ← {𝕊 domain‿layer‿s‿e‿code:
  rejected ← flow.Build ⟨facts,history,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.dates.count
  lib.Assert HasCode ⟨code,rejected.diagnostics⟩
}
CheckRejected ⟨"USD","actual",start,end,"domain_unknown"⟩
CheckRejected ⟨"JPY","plan",start,end,"layer_unknown"⟩
CheckRejected ⟨"JPY","actual",end,start,"period_range_invalid"⟩

•Out "test_accounting_date_category_flow: ok"
