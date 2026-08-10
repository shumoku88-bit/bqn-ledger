#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
period ← •Import "../src/accounting/account_period.bqn"
profitLoss ← •Import "../src/accounting/profit_and_loss.bqn"

empty ← ⟨⟩
start ← dates.Ordinal "2026-01-01"
end ← dates.Ordinal "2026-02-01"

# Pure accounting boundary fixtures deliberately start at the admitted Facts contract.
# Journal amount admission is a separate ledger-owner boundary and must not decide
# whether an already-admitted Account subset can still overflow a downstream exact sum.
MakeFacts ← {𝕊 accountKeys‿roles‿postingAccounts‿postingSides‿postingCoefficients:
  accountCount ← ≠accountKeys
  postingCount ← ≠postingAccounts
  currencies ← {𝕊 i: "JPY"}¨↕accountCount
  postingIds ← {𝕊 i: "pnl-boundary-"∾•Fmt i}¨↕postingCount
  {
    state⇐"ok",
    sources⇐{name⇐⟨"actual.journal"⟩},
    domains⇐{code⇐⟨"JPY"⟩},
    layers⇐{name⇐⟨"actual"⟩},
    accounts⇐{
      count⇐accountCount,index⇐↕accountCount,key⇐accountKeys,role⇐roles,currency⇐currencies
    },
    postings⇐{
      count⇐postingCount,index⇐↕postingCount,posting_id⇐postingIds,
      account_index⇐postingAccounts,domain_index⇐0×↕postingCount,layer_index⇐0×↕postingCount,
      date_ordinal⇐start+0×↕postingCount,side⇐postingSides,
      coefficient⇐postingCoefficients,scale⇐0×↕postingCount
    },
    diagnostics⇐empty
  }
}

CheckExactFailure ← {𝕊 boundaryFacts‿code:
  upstream ← period.Build ⟨boundaryFacts,"JPY","actual",start,end⟩
  "ok" lib.AssertEq upstream.state
  failed ← profitLoss.Build ⟨boundaryFacts,"JPY",start,end⟩
  "error" lib.AssertEq failed.state
  0 lib.AssertEq failed.income.count
  0 lib.AssertEq failed.expenses.count
  1 lib.AssertEq ∨´0∾code⊸≡¨{𝕩.code}¨failed.diagnostics
}

# Dense statement rows retain zero-movement Income/Expense Accounts in canonical Account order.
zeroFacts ← MakeFacts ⟨
  ⟨"assets:zero","income:z","expenses:z","income:a","expenses:a"⟩,
  ⟨"asset","income","expense","income","expense"⟩,
  empty,empty,empty
⟩
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

# The complete Account axis can sum exactly while the Expense-role subset cannot.
# Account movements in canonical order are:
#   9007199254740991, 1, 2, -9007199254740991, -1, -2
# The whole sequence and its one-sided totals are exact, but Expense selects the
# first and third movements: 9007199254740991 + 2 = 9007199254740993, which is
# not exactly representable at the current Number spacing.
expenseSubsetFacts ← MakeFacts ⟨
  ⟨"expenses:subset-a","assets:subset-bridge","expenses:subset-b","liabilities:subset-a","liabilities:subset-bridge","liabilities:subset-b"⟩,
  ⟨"expense","asset","expense","liability","liability","liability"⟩,
  ⟨0,3,1,4,2,5⟩,
  ⟨"debit","credit","debit","credit","debit","credit"⟩,
  ⟨9007199254740991,¯9007199254740991,1,¯1,2,¯2⟩
⟩
CheckExactFailure ⟨expenseSubsetFacts,"expense_sum_failed"⟩

# Symmetric credit-side construction keeps Account Period exact while Income
# statement sign normalization exposes the same non-exact subset 9007199254740991 + 2.
incomeSubsetFacts ← MakeFacts ⟨
  ⟨"income:subset-a","liabilities:subset-bridge","income:subset-b","assets:subset-a","assets:subset-bridge","assets:subset-b"⟩,
  ⟨"income","liability","income","asset","asset","asset"⟩,
  ⟨3,0,4,1,5,2⟩,
  ⟨"debit","credit","debit","credit","debit","credit"⟩,
  ⟨9007199254740991,¯9007199254740991,1,¯1,2,¯2⟩
⟩
CheckExactFailure ⟨incomeSubsetFacts,"income_sum_failed"⟩

# Income and Expense totals can each be exact while their final net combination is not.
# Income publishes +9007199254740991; abnormal Expense credit publishes -2;
# net income therefore requires 9007199254740991 - (-2) = 9007199254740993.
netSubsetFacts ← MakeFacts ⟨
  ⟨"income:net-a","liabilities:net-bridge","expenses:net-b","assets:net-a","assets:net-bridge","assets:net-b"⟩,
  ⟨"income","liability","expense","asset","asset","asset"⟩,
  ⟨3,0,4,1,5,2⟩,
  ⟨"debit","credit","debit","credit","debit","credit"⟩,
  ⟨9007199254740991,¯9007199254740991,1,¯1,2,¯2⟩
⟩
CheckExactFailure ⟨netSubsetFacts,"net_income_sum_failed"⟩

•Out "test_accounting_profit_and_loss_boundaries: ok"
