#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
period ← •Import "../src/accounting/account_period.bqn"
profitLoss ← •Import "../src/accounting/profit_and_loss.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
facts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",•FChars "../"∾base∾"actual.journal",registry⟩).facts
start ← dates.Ordinal "2026-01-01"
end ← dates.Ordinal "2026-02-01"
result ← profitLoss.Build ⟨facts,"JPY",start,end⟩
"ok" lib.AssertEq result.state
⟨"income:salary"⟩ lib.AssertEq result.income.account_key
⟨1000⟩ lib.AssertEq result.income.amount
⟨"expenses:food","expenses:transport"⟩ lib.AssertEq result.expenses.account_key
⟨30,5⟩ lib.AssertEq result.expenses.amount
1000 lib.AssertEq result.total_income
35 lib.AssertEq result.total_expenses
965 lib.AssertEq result.net_income
"actual.journal" lib.AssertEq (⊑⊑result.income.contributors).source

late ← profitLoss.Build ⟨facts,"JPY",dates.Ordinal "2026-01-11",end⟩
"ok" lib.AssertEq late.state
0 lib.AssertEq late.total_income
15 lib.AssertEq late.total_expenses
¯15 lib.AssertEq late.net_income

abnormalRaw ← (•FChars "../"∾base∾"actual.journal")∾(@+10)∾∾{𝕩∾(@+10)}¨⟨
  "2026-01-13 * income debit","    ; event-id: income-debit","    ; layer: actual","    ; currency: JPY","    income:salary 10 JPY","    assets:cash -10 JPY","",
  "2026-01-14 * expense credit","    ; event-id: expense-credit","    ; layer: actual","    ; currency: JPY","    assets:cash 3 JPY","    expenses:food -3 JPY"
⟩
abnormalFacts ← (snapshot.Build ⟨loader.ReadLines base∾"accounts.tsv",abnormalRaw,registry⟩).facts
abnormal ← profitLoss.Build ⟨abnormalFacts,"JPY",start,end⟩
"ok" lib.AssertEq abnormal.state
⟨990⟩ lib.AssertEq abnormal.income.amount
⟨27,5⟩ lib.AssertEq abnormal.expenses.amount
958 lib.AssertEq abnormal.net_income

# Dense statement rows retain zero-movement Income/Expense Accounts in canonical Account order.
lf ← @+10
Raw ← {𝕊 lines: ∾{𝕩∾lf}¨lines}
zeroAccountLines ← ⟨
  "assets:zero\trole=asset\tcurrency=JPY",
  "income:z\trole=income\tcurrency=JPY",
  "expenses:z\trole=expense\tcurrency=JPY",
  "income:a\trole=income\tcurrency=JPY",
  "expenses:a\trole=expense\tcurrency=JPY"
⟩
zeroRaw ← Raw ⟨
  "commodity JPY","",
  "account assets:zero","    ; role: asset","",
  "account income:z","    ; role: income","",
  "account expenses:z","    ; role: expense","",
  "account income:a","    ; role: income","",
  "account expenses:a","    ; role: expense"
⟩
zeroFacts ← (snapshot.Build ⟨zeroAccountLines,zeroRaw,registry⟩).facts
"ok" lib.AssertEq zeroFacts.state
zero ← profitLoss.Build ⟨zeroFacts,"JPY",start,end⟩
"ok" lib.AssertEq zero.state
⟨"income:z","income:a"⟩ lib.AssertEq zero.income.account_key
⟨0,0⟩ lib.AssertEq zero.income.amount
⟨⟨⟩,⟨⟩⟩ lib.AssertEq zero.income.contributors
⟨"expenses:z","expenses:a"⟩ lib.AssertEq zero.expenses.account_key
⟨0,0⟩ lib.AssertEq zero.expenses.amount
⟨⟨⟩,⟨⟩⟩ lib.AssertEq zero.expenses.contributors
0 lib.AssertEq zero.total_income
0 lib.AssertEq zero.total_expenses
0 lib.AssertEq zero.net_income

# A full one-sided Account sum can be exact while a role-selected subset is not.
# 9007199254740991 + 1 + 2 is exact in sequence; selecting the first and third
# produces the non-exact integer 9007199254740993 at the current Number spacing.
maxConsecutive ← "9007199254740991"
CheckExactFailure ← {𝕊 boundaryFacts‿code:
  upstream ← period.Build ⟨boundaryFacts,"JPY","actual",start,end⟩
  "ok" lib.AssertEq upstream.state
  failed ← profitLoss.Build ⟨boundaryFacts,"JPY",start,end⟩
  "error" lib.AssertEq failed.state
  0 lib.AssertEq failed.income.count
  0 lib.AssertEq failed.expenses.count
  1 lib.AssertEq ∨´0∾code⊸≡¨{𝕩.code}¨failed.diagnostics
}

expenseSubsetAccounts ← ⟨
  "expenses:subset-a\trole=expense\tcurrency=JPY",
  "assets:subset-bridge\trole=asset\tcurrency=JPY",
  "expenses:subset-b\trole=expense\tcurrency=JPY",
  "liabilities:subset-a\trole=liability\tcurrency=JPY",
  "liabilities:subset-bridge\trole=liability\tcurrency=JPY",
  "liabilities:subset-b\trole=liability\tcurrency=JPY"
⟩
expenseSubsetRaw ← Raw ⟨
  "commodity JPY","",
  "account expenses:subset-a","    ; role: expense","",
  "account assets:subset-bridge","    ; role: asset","",
  "account expenses:subset-b","    ; role: expense","",
  "account liabilities:subset-a","    ; role: liability","",
  "account liabilities:subset-bridge","    ; role: liability","",
  "account liabilities:subset-b","    ; role: liability","",
  "2026-01-10 * subset A","    ; event-id: pnl-expense-subset-a","    ; layer: actual",
  "    expenses:subset-a "∾maxConsecutive∾" JPY","    liabilities:subset-a -"∾maxConsecutive∾" JPY","",
  "2026-01-11 * subset bridge","    ; event-id: pnl-expense-subset-bridge","    ; layer: actual",
  "    assets:subset-bridge 1 JPY","    liabilities:subset-bridge -1 JPY","",
  "2026-01-12 * subset B","    ; event-id: pnl-expense-subset-b","    ; layer: actual",
  "    expenses:subset-b 2 JPY","    liabilities:subset-b -2 JPY"
⟩
expenseSubsetFacts ← (snapshot.Build ⟨expenseSubsetAccounts,expenseSubsetRaw,registry⟩).facts
"ok" lib.AssertEq expenseSubsetFacts.state
CheckExactFailure ⟨expenseSubsetFacts,"expense_sum_failed"⟩

incomeSubsetAccounts ← ⟨
  "income:subset-a\trole=income\tcurrency=JPY",
  "liabilities:subset-bridge\trole=liability\tcurrency=JPY",
  "income:subset-b\trole=income\tcurrency=JPY",
  "assets:subset-a\trole=asset\tcurrency=JPY",
  "assets:subset-bridge\trole=asset\tcurrency=JPY",
  "assets:subset-b\trole=asset\tcurrency=JPY"
⟩
incomeSubsetRaw ← Raw ⟨
  "commodity JPY","",
  "account income:subset-a","    ; role: income","",
  "account liabilities:subset-bridge","    ; role: liability","",
  "account income:subset-b","    ; role: income","",
  "account assets:subset-a","    ; role: asset","",
  "account assets:subset-bridge","    ; role: asset","",
  "account assets:subset-b","    ; role: asset","",
  "2026-01-10 * income subset A","    ; event-id: pnl-income-subset-a","    ; layer: actual",
  "    assets:subset-a "∾maxConsecutive∾" JPY","    income:subset-a -"∾maxConsecutive∾" JPY","",
  "2026-01-11 * income subset bridge","    ; event-id: pnl-income-subset-bridge","    ; layer: actual",
  "    assets:subset-bridge 1 JPY","    liabilities:subset-bridge -1 JPY","",
  "2026-01-12 * income subset B","    ; event-id: pnl-income-subset-b","    ; layer: actual",
  "    assets:subset-b 2 JPY","    income:subset-b -2 JPY"
⟩
incomeSubsetFacts ← (snapshot.Build ⟨incomeSubsetAccounts,incomeSubsetRaw,registry⟩).facts
"ok" lib.AssertEq incomeSubsetFacts.state
CheckExactFailure ⟨incomeSubsetFacts,"income_sum_failed"⟩

# Income and Expense totals can each be exact while their final net combination is not.
netSubsetAccounts ← ⟨
  "income:net-a\trole=income\tcurrency=JPY",
  "liabilities:net-bridge\trole=liability\tcurrency=JPY",
  "expenses:net-b\trole=expense\tcurrency=JPY",
  "assets:net-a\trole=asset\tcurrency=JPY",
  "assets:net-bridge\trole=asset\tcurrency=JPY",
  "assets:net-b\trole=asset\tcurrency=JPY"
⟩
netSubsetRaw ← Raw ⟨
  "commodity JPY","",
  "account income:net-a","    ; role: income","",
  "account liabilities:net-bridge","    ; role: liability","",
  "account expenses:net-b","    ; role: expense","",
  "account assets:net-a","    ; role: asset","",
  "account assets:net-bridge","    ; role: asset","",
  "account assets:net-b","    ; role: asset","",
  "2026-01-10 * net subset income","    ; event-id: pnl-net-income","    ; layer: actual",
  "    assets:net-a "∾maxConsecutive∾" JPY","    income:net-a -"∾maxConsecutive∾" JPY","",
  "2026-01-11 * net subset bridge","    ; event-id: pnl-net-bridge","    ; layer: actual",
  "    assets:net-bridge 1 JPY","    liabilities:net-bridge -1 JPY","",
  "2026-01-12 * net subset expense credit","    ; event-id: pnl-net-expense","    ; layer: actual",
  "    assets:net-b 2 JPY","    expenses:net-b -2 JPY"
⟩
netSubsetFacts ← (snapshot.Build ⟨netSubsetAccounts,netSubsetRaw,registry⟩).facts
"ok" lib.AssertEq netSubsetFacts.state
CheckExactFailure ⟨netSubsetFacts,"net_income_sum_failed"⟩

rejected ← profitLoss.Build ⟨facts,"USD",start,end⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.income.count
•Out "test_accounting_profit_and_loss: ok"
