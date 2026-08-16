#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryCore ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
balanceSheet ← •Import "../src/accounting/balance_sheet.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryCore.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
facts ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
result ← balanceSheet.Build ⟨facts,"JPY",dates.Ordinal "2026-01-12"⟩
"ok" lib.AssertEq result.state
⟨"assets:cash"⟩ lib.AssertEq result.assets.account_key
⟨965⟩ lib.AssertEq result.assets.balance
0 lib.AssertEq result.liabilities.count
0 lib.AssertEq result.equity.count
965 lib.AssertEq result.total_assets
0 lib.AssertEq result.total_liabilities
0 lib.AssertEq result.stated_equity
965 lib.AssertEq result.unclosed_result
965 lib.AssertEq result.total_equity
965 lib.AssertEq result.total_liabilities_and_equity
0 lib.AssertEq result.difference
1 lib.AssertEq result.balanced
4 lib.AssertEq ≠result.unclosed_result_contributors

lf ← @+10
syntheticAccounts ← ∾⟨
  "account assets:cash",lf,"  type: Asset",lf,"  commodity: JPY",lf,lf,
  "account assets:savings",lf,"  type: Asset",lf,"  commodity: JPY",lf,lf,
  "account liabilities:debt",lf,"  type: Liability",lf,"  commodity: JPY",lf,lf,
  "account equity:opening",lf,"  type: Equity",lf,"  commodity: JPY",lf,lf,
  "account income:salary",lf,"  type: Income",lf,"  commodity: JPY",lf,lf,
  "account expenses:food",lf,"  type: Expense",lf,"  commodity: JPY",lf
⟩
syntheticLines ← ⟨
  "commodity JPY","",
  "account assets:cash","    ; role: asset","",
  "account assets:savings","    ; role: asset","",
  "account liabilities:debt","    ; role: liability","",
  "account equity:opening","    ; role: equity","",
  "account income:salary","    ; role: income","",
  "account expenses:food","    ; role: expense","",
  "2026-01-01 * opening","    ; event-id: opening","    ; layer: actual","    ; currency: JPY","    assets:cash 100 JPY","    assets:savings 40 JPY","    equity:opening -140 JPY","",
  "2026-01-02 * food on debt","    ; event-id: food","    ; layer: actual","    ; currency: JPY","    expenses:food 30 JPY","    liabilities:debt -30 JPY","",
  "2026-01-03 * salary","    ; event-id: salary","    ; layer: actual","    ; currency: JPY","    assets:cash 50 JPY","    income:salary -50 JPY"
⟩
syntheticRaw ← ∾{𝕩∾lf}¨syntheticLines
syntheticFacts ← (snapshot.Build ⟨syntheticAccounts,syntheticRaw,registry⟩).facts
synthetic ← balanceSheet.Build ⟨syntheticFacts,"JPY",dates.Ordinal "2026-01-03"⟩
"ok" lib.AssertEq synthetic.state
⟨"assets:cash","assets:savings"⟩ lib.AssertEq synthetic.assets.account_key
⟨150,40⟩ lib.AssertEq synthetic.assets.balance
⟨⟨"opening:0","salary:0"⟩,⟨"opening:1"⟩⟩ lib.AssertEq {{𝕩.posting_id}¨𝕩}¨synthetic.assets.contributors
⟨"liabilities:debt"⟩ lib.AssertEq synthetic.liabilities.account_key
⟨30⟩ lib.AssertEq synthetic.liabilities.balance
⟨⟨"food:1"⟩⟩ lib.AssertEq {{𝕩.posting_id}¨𝕩}¨synthetic.liabilities.contributors
⟨"equity:opening"⟩ lib.AssertEq synthetic.equity.account_key
⟨140⟩ lib.AssertEq synthetic.equity.balance
⟨⟨"opening:2"⟩⟩ lib.AssertEq {{𝕩.posting_id}¨𝕩}¨synthetic.equity.contributors
190 lib.AssertEq synthetic.total_assets
30 lib.AssertEq synthetic.total_liabilities
140 lib.AssertEq synthetic.stated_equity
20 lib.AssertEq synthetic.unclosed_result
160 lib.AssertEq synthetic.total_equity
190 lib.AssertEq synthetic.total_liabilities_and_equity
⟨"salary:1","food:0"⟩ lib.AssertEq {𝕩.posting_id}¨synthetic.unclosed_result_contributors

budgetRaw ← (•FChars "../"∾base∾"actual.journal")∾lf∾∾{𝕩∾lf}¨⟨
  "2026-01-13 * unsupported budget balance",
  "    ; event-id: budget-balance","    ; layer: actual","    ; currency: JPY",
  "    budget:food 10 JPY","    assets:cash -10 JPY"
⟩
budgetFacts ← (snapshot.Build ⟨accountSource,budgetRaw,registry⟩).facts
budgetRejected ← balanceSheet.Build ⟨budgetFacts,"JPY",dates.Ordinal "2026-01-13"⟩
"error" lib.AssertEq budgetRejected.state
"unsupported_role_balance" lib.AssertEq (⊑budgetRejected.diagnostics).code

rejected ← balanceSheet.Build ⟨facts,"USD",dates.Ordinal "2026-01-12"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.assets.count
•Out "test_accounting_balance_sheet: ok"
