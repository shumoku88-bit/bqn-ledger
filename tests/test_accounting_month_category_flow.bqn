#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
companion_snapshot ← •Import "../src/ledger/companion_snapshot.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
monthly ← •Import "../src/accounting/month_category_flow.bqn"
pivot ← •Import "../src/accounting/sparse_pivot.bqn"

registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
base ← "fixtures/ledger-facts-phase1-proof/"
actualFacts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
jan ← dates.Ordinal "2026-01-01"
feb ← dates.Ordinal "2026-02-01"
mar ← dates.Ordinal "2026-03-01"
actual ← monthly.Build ⟨actualFacts,"JPY","actual",jan,feb⟩
"ok" lib.AssertEq actual.state
⟨"2026-01"⟩ lib.AssertEq actual.months.label
⟨"food","other"⟩ lib.AssertEq actual.categories.label
⟨30,5⟩ lib.AssertEq actual.expense_groups.coefficient
⟨⟨2,4⟩,⟨5⟩⟩ lib.AssertEq actual.expense_groups.contributors

accountLines ← ⟨
  "assets:cash	role=asset	currency=JPY",
  "expenses:food	role=expense	budget=food	currency=JPY",
  "expenses:transport	role=expense	budget=transport	currency=JPY",
  "budget:food	role=budget	kind=envelope	budget=food	currency=JPY"
⟩
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
planLines ← ⟨
  "2026-01-10	jan-food	assets:cash	expenses:food	10	currency=JPY	plan_id=p1",
  "2026-01-12	jan-other	assets:cash	expenses:transport	5	currency=JPY	plan_id=p2",
  "2026-02-05	feb-food-whole	assets:cash	expenses:food	20	currency=JPY	plan_id=p3",
  "2026-02-06	feb-food-fraction	assets:cash	expenses:food	2.50	currency=JPY	plan_id=p4",
  "2026-02-07	feb-other	assets:cash	expenses:transport	7	currency=JPY	plan_id=p5"
⟩
planFacts ← (companion_snapshot.Build ⟨planLines,⟨⟩,accounts,registry⟩).plan
result ← monthly.Build ⟨planFacts,"JPY","plan",jan,mar⟩

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

CheckRejected ← {𝕊 domain‿layer‿s‿e:
  rejected ← monthly.Build ⟨planFacts,domain,layer,s,e⟩
  "error" lib.AssertEq rejected.state
  0 lib.AssertEq rejected.months.count
  0 lib.AssertEq rejected.categories.count
  0 lib.AssertEq rejected.expense_groups.count
}
CheckRejected ⟨"USD","plan",jan,mar⟩
CheckRejected ⟨"JPY","actual",jan,mar⟩
CheckRejected ⟨"JPY","plan",mar,jan⟩

•Out "test_accounting_month_category_flow: ok"
