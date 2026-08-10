#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
period ← •Import "../src/accounting/account_period.bqn"
profitLoss ← •Import "../src/accounting/profit_and_loss.bqn"

registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
start ← dates.Ordinal "2026-01-01"
end ← dates.Ordinal "2026-02-01"
lf ← @+10
Raw ← {𝕊 lines: ∾{𝕩∾lf}¨lines}

CheckFacts ← {𝕊 label‿facts:
  •Out "boundary facts: "∾label∾" = "∾facts.state
  {𝕊: •Out •Fmt facts.diagnostics}⍟(facts.state≢"ok") @
  "ok" lib.AssertEq facts.state
}
CheckExactFailure ← {𝕊 label‿boundaryFacts‿code:
  upstream ← period.Build ⟨boundaryFacts,"JPY","actual",start,end⟩
  •Out "boundary period: "∾label∾" = "∾upstream.state
  {𝕊: •Out •Fmt upstream.diagnostics}⍟(upstream.state≢"ok") @
  "ok" lib.AssertEq upstream.state
  failed ← profitLoss.Build ⟨boundaryFacts,"JPY",start,end⟩
  "error" lib.AssertEq failed.state
  0 lib.AssertEq failed.income.count
  0 lib.AssertEq failed.expenses.count
  1 lib.AssertEq ∨´0∾code⊸≡¨{𝕩.code}¨failed.diagnostics
}

# Dense statement rows retain zero-movement Income/Expense Accounts in canonical Account order.
zeroAccountLines ← ⟨
  "assets:zero	role=asset	currency=JPY",
  "income:z	role=income	currency=JPY",
  "expenses:z	role=expense	currency=JPY",
  "income:a	role=income	currency=JPY",
  "expenses:a	role=expense	currency=JPY"
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
CheckFacts ⟨"zero",zeroFacts⟩
zero ← profitLoss.Build ⟨zeroFacts,"JPY",start,end⟩
•Out "boundary pnl: zero = "∾zero.state
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
maxConsecutive ← "9007199254740991"

expenseSubsetAccounts ← ⟨
  "expenses:subset-a	role=expense	currency=JPY",
  "assets:subset-bridge	role=asset	currency=JPY",
  "expenses:subset-b	role=expense	currency=JPY",
  "liabilities:subset-a	role=liability	currency=JPY",
  "liabilities:subset-bridge	role=liability	currency=JPY",
  "liabilities:subset-b	role=liability	currency=JPY"
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
CheckFacts ⟨"expense subset",expenseSubsetFacts⟩
CheckExactFailure ⟨"expense subset",expenseSubsetFacts,"expense_sum_failed"⟩

incomeSubsetAccounts ← ⟨
  "income:subset-a	role=income	currency=JPY",
  "liabilities:subset-bridge	role=liability	currency=JPY",
  "income:subset-b	role=income	currency=JPY",
  "assets:subset-a	role=asset	currency=JPY",
  "assets:subset-bridge	role=asset	currency=JPY",
  "assets:subset-b	role=asset	currency=JPY"
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
CheckFacts ⟨"income subset",incomeSubsetFacts⟩
CheckExactFailure ⟨"income subset",incomeSubsetFacts,"income_sum_failed"⟩

# Income and Expense totals can each be exact while their final net combination is not.
netSubsetAccounts ← ⟨
  "income:net-a	role=income	currency=JPY",
  "liabilities:net-bridge	role=liability	currency=JPY",
  "expenses:net-b	role=expense	currency=JPY",
  "assets:net-a	role=asset	currency=JPY",
  "assets:net-bridge	role=asset	currency=JPY",
  "assets:net-b	role=asset	currency=JPY"
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
CheckFacts ⟨"net subset",netSubsetFacts⟩
CheckExactFailure ⟨"net subset",netSubsetFacts,"net_income_sum_failed"⟩

•Out "test_accounting_profit_and_loss_boundaries: ok"
