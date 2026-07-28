#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
companion_snapshot ← •Import "../src/ledger/companion_snapshot.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
flow ← •Import "../src/accounting/date_category_flow.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
cycle ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",facts.accounts⟩
start ← dates.Ordinal cycle.definition.start
end ← dates.Ordinal cycle.definition.end_exclusive
result ← flow.Build ⟨facts,"JPY","actual",start,end⟩

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
⟨1,2,2⟩ lib.AssertEq result.expense_groups.date_index
⟨0,0,1⟩ lib.AssertEq result.expense_groups.category_index
⟨20,10,5⟩ lib.AssertEq result.expense_groups.coefficient
⟨⟨2⟩,⟨4⟩,⟨5⟩⟩ lib.AssertEq result.expense_groups.contributors

late ← flow.Build ⟨facts,"JPY","actual",dates.Ordinal "2026-01-11",end⟩
"ok" lib.AssertEq late.state
⟨"2026-01-12"⟩ lib.AssertEq late.dates.date_text
⟨0⟩ lib.AssertEq late.dates.income
⟨¯15⟩ lib.AssertEq late.dates.net
⟨10,5⟩ lib.AssertEq late.expense_groups.coefficient

scaleAccountLines ← ⟨
  "assets:jpy	role=asset	currency=JPY",
  "expenses:food	role=expense	budget=food	currency=JPY",
  "budget:food	role=budget	kind=envelope	budget=food	currency=JPY"
⟩
scaleAccounts ← (account_admission.Admit ⟨scaleAccountLines,registry⟩).accounts
scalePlanLines ← ⟨
  "2026-01-10	whole	assets:jpy	expenses:food	25	currency=JPY	plan_id=p1",
  "2026-01-10	fraction	assets:jpy	expenses:food	12.30	currency=JPY	plan_id=p2"
⟩
scaleFacts ← (companion_snapshot.Build ⟨scalePlanLines,⟨⟩,scaleAccounts,registry⟩).plan
scaleFlow ← flow.Build ⟨scaleFacts,"JPY","plan",start,end⟩
"ok" lib.AssertEq scaleFlow.state
1 lib.AssertEq scaleFlow.scale
⟨"food","other"⟩ lib.AssertEq scaleFlow.categories.label
⟨¯373⟩ lib.AssertEq scaleFlow.dates.net
⟨373⟩ lib.AssertEq scaleFlow.expense_groups.coefficient
⟨⟨0,2⟩⟩ lib.AssertEq scaleFlow.expense_groups.contributors

CheckRejected ← {𝕊 domain‿layer‿s‿e‿code:
  rejected ← flow.Build ⟨facts,domain,layer,s,e⟩
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
