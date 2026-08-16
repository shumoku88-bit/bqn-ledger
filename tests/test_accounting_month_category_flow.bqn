#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
actualSource ← •Import "../src/application/actual_source_adapter.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
budgetPolicyAdmission ← •Import "../src/ledger/budget_policy_admission.bqn"
householdAdmission ← •Import "current_household_policy_test_admission.bqn"
historyAdmission ← •Import "../src/ledger/envelope_history_admission.bqn"
historyFixture ← •Import "envelope_history_test_fixture.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
byDate ← •Import "../src/accounting/date_category_flow.bqn"
monthly ← •Import "../src/accounting/month_category_flow.bqn"
pivot ← •Import "../src/accounting/sparse_pivot.bqn"

registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
base ← "fixtures/ledger-facts-phase1-proof/"
actualResult ← actualSource.Load ⟨base,registry⟩
"ok" lib.AssertEq actualResult.state
actualFacts ← actualResult.facts
budgetRaw ← •FChars "../"∾base∾"budget.toml"
budgetPolicy ← budgetPolicyAdmission.Admit ⟨budgetRaw,actualFacts.accounts⟩
"ok" lib.AssertEq budgetPolicy.state
householdRaw ← •FChars "../"∾base∾"household.toml"
household ← householdAdmission.Admit ⟨householdRaw,actualFacts.accounts,budgetPolicy⟩
"ok" lib.AssertEq household.state
history ← historyAdmission.Admit householdRaw
"ok" lib.AssertEq history.state
jan ← dates.Ordinal "2026-01-01"
feb ← dates.Ordinal "2026-02-01"
mar ← dates.Ordinal "2026-03-01"
actual ← monthly.Build ⟨actualFacts,household,history,"JPY","actual",jan,feb⟩
"ok" lib.AssertEq actual.state
⟨"2026-01"⟩ lib.AssertEq actual.months.label
⟨"food","other"⟩ lib.AssertEq actual.categories.label
⟨30,5⟩ lib.AssertEq actual.expense_groups.coefficient
⟨⟨2,4⟩,⟨5⟩⟩ lib.AssertEq actual.expense_groups.contributors

tab ← @+9
accountLines ← ⟨
  "assets:cash"∾tab∾"role=asset"∾tab∾"currency=JPY",
  "expenses:food"∾tab∾"role=expense"∾tab∾"currency=JPY",
  "expenses:transport"∾tab∾"role=expense"∾tab∾"currency=JPY",
  "budget:food"∾tab∾"role=budget"∾tab∾"currency=JPY"
⟩
accountResult ← account_admission.Admit ⟨accountLines,registry⟩
"ok" lib.AssertEq accountResult.state
accounts ← accountResult.accounts
planRaw ← ∾{𝕩∾@+10}¨⟨
  "2026-01-10 jan-food","  ; plan-id: p1","  expenses:food 10 JPY","  assets:cash -10 JPY","",
  "2026-01-12 jan-other","  ; plan-id: p2","  expenses:transport 5 JPY","  assets:cash -5 JPY","",
  "2026-02-05 feb-food-whole","  ; plan-id: p3","  expenses:food 20 JPY","  assets:cash -20 JPY","",
  "2026-02-06 feb-food-fraction","  ; plan-id: p4","  expenses:food 2.50 JPY","  assets:cash -2.50 JPY","",
  "2026-02-07 feb-other","  ; plan-id: p5","  expenses:transport 7 JPY","  assets:cash -7 JPY"
⟩
planResult ← canonicalPlan.Build ⟨planRaw,accounts,registry⟩
"ok" lib.AssertEq planResult.state
planFacts ← planResult.facts
planHousehold ← {
  state⇐"ok",source_name⇐"household.toml",
  budget⇐{envelope_id⇐⟨"food"⟩,allocation_account_key⇐⟨"budget:food"⟩}
}
planHistory ← historyFixture.Initial ⟨
  ⟨"food"⟩,
  ⟨"expenses:food","expenses:transport"⟩,
  ⟨"managed","unmanaged"⟩,
  ⟨"food",""⟩
⟩
result ← monthly.Build ⟨planFacts,planHousehold,planHistory,"JPY","plan",jan,mar⟩

"ok" lib.AssertEq result.state
0 lib.AssertEq ≠result.diagnostics
1 lib.AssertEq result.scale
⟨"2026-01","2026-02"⟩ lib.AssertEq result.months.label
⟨"food","other"⟩ lib.AssertEq result.categories.label
4 lib.AssertEq result.expense_groups.count
⟨0,0,1,1⟩ lib.AssertEq result.expense_groups.row_index
⟨0,1,0,1⟩ lib.AssertEq result.expense_groups.column_index
⟨100,50,225,70⟩ lib.AssertEq result.expense_groups.coefficient
⟨⟨0⟩,⟨2⟩,⟨4,6⟩,⟨8⟩⟩ lib.AssertEq result.expense_groups.contributors
matrix ← pivot.Build ⟨result.months.label,result.categories.label,result.scale,result.expense_groups⟩
"ok" lib.AssertEq matrix.state
⟨⟨100,50⟩,⟨225,70⟩⟩ lib.AssertEq matrix.matrix.values
⟨⟨⟨0⟩,⟨2⟩⟩,⟨⟨4,6⟩,⟨8⟩⟩⟩ lib.AssertEq matrix.matrix.contributors

# Every Date-level group remains exact; only their January regrouping exceeds the exact range.
dailyAmount ← 300000000000001
dayOrdinals ← jan+↕31
postingDates ← ∾{⟨𝕩,𝕩⟩}¨dayOrdinals
planDomainIndex ← ⊑planFacts.transactions.domain_index
planLayerIndex ← ⊑planFacts.transactions.layer_index
cashIndex ← 0⊑accounts.index
foodIndex ← 1⊑accounts.index
overflowFacts ← {
  state⇐"ok",domains⇐planFacts.domains,layers⇐planFacts.layers,accounts⇐accounts,
  transactions⇐{
    domain_index⇐31⥊planDomainIndex,layer_index⇐31⥊planLayerIndex,
    date_ordinal⇐dayOrdinals,date_text⇐31⥊⟨"2026-01-01"⟩
  },
  postings⇐{
    index⇐↕62,domain_index⇐62⥊planDomainIndex,layer_index⇐62⥊planLayerIndex,
    date_ordinal⇐postingDates,
    account_index⇐∾{𝕩 ⋄ ⟨foodIndex,cashIndex⟩}¨dayOrdinals,
    coefficient⇐∾{𝕩 ⋄ ⟨dailyAmount,-dailyAmount⟩}¨dayOrdinals,
    scale⇐62⥊0
  }
}
dailyOverflow ← byDate.Build ⟨overflowFacts,planHousehold,planHistory,"JPY","plan",jan,feb⟩
"ok" lib.AssertEq dailyOverflow.state
0 lib.AssertEq ≠dailyOverflow.diagnostics
(31⥊dailyAmount) lib.AssertEq dailyOverflow.expense_groups.coefficient

HasCode ← {𝕊 code‿diagnostics: ∨´0∾code⊸≡¨{𝕩.code}¨diagnostics}
monthlyOverflow ← monthly.Build ⟨overflowFacts,planHousehold,planHistory,"JPY","plan",jan,feb⟩
"error" lib.AssertEq monthlyOverflow.state
1 lib.AssertEq HasCode ⟨"group_sum_failed",monthlyOverflow.diagnostics⟩
0 lib.AssertEq monthlyOverflow.scale
0 lib.AssertEq monthlyOverflow.months.count
0 lib.AssertEq monthlyOverflow.categories.count
0 lib.AssertEq monthlyOverflow.expense_groups.count

CheckRejected ← {𝕊 domain‿layer‿s‿e:
  rejected ← monthly.Build ⟨planFacts,planHousehold,planHistory,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.months.count
  0 lib.AssertEq rejected.categories.count
  0 lib.AssertEq rejected.expense_groups.count
}
CheckRejected ⟨"USD","plan",jan,mar⟩
CheckRejected ⟨"JPY","actual",jan,mar⟩
CheckRejected ⟨"JPY","plan",mar,jan⟩

•Out "test_accounting_month_category_flow: ok"
