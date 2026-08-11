#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
profitLoss ← •Import "../src/accounting/profit_and_loss.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← profitLoss.Build ⟨facts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01"⟩
"ok" lib.AssertEq result.state
⟨"income:salary"⟩ lib.AssertEq result.income.account_key
⟨1000⟩ lib.AssertEq result.income.amount
⟨"expenses:food","expenses:transport"⟩ lib.AssertEq result.expenses.account_key
⟨30,5⟩ lib.AssertEq result.expenses.amount
1000 lib.AssertEq result.total_income
35 lib.AssertEq result.total_expenses
965 lib.AssertEq result.net_income
"actual.journal" lib.AssertEq (⊑⊑result.income.contributors).source

late ← profitLoss.Build ⟨facts,"JPY",dates.Ordinal "2026-01-11",dates.Ordinal "2026-02-01"⟩
"ok" lib.AssertEq late.state
0 lib.AssertEq late.total_income
15 lib.AssertEq late.total_expenses
¯15 lib.AssertEq late.net_income

abnormalRaw ← (•FChars "../"∾base∾"actual.journal")∾(@+10)∾∾{𝕩∾(@+10)}¨⟨
  "2026-01-13 * income debit","    ; event-id: income-debit","    ; layer: actual","    ; currency: JPY","    income:salary 10 JPY","    assets:cash -10 JPY","",
  "2026-01-14 * expense credit","    ; event-id: expense-credit","    ; layer: actual","    ; currency: JPY","    assets:cash 3 JPY","    expenses:food -3 JPY"
⟩
abnormalFacts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",abnormalRaw,registry⟩).facts
abnormal ← profitLoss.Build ⟨abnormalFacts,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01"⟩
"ok" lib.AssertEq abnormal.state
⟨990⟩ lib.AssertEq abnormal.income.amount
⟨27,5⟩ lib.AssertEq abnormal.expenses.amount
958 lib.AssertEq abnormal.net_income

rejected ← profitLoss.Build ⟨facts,"USD",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.income.count
•Out "test_accounting_profit_and_loss: ok"
