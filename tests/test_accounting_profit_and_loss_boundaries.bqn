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

# Build 2^53-1 from individually normalizable 15-digit coefficients.
# Every prefix remains inside the contiguous exact-integer interval.
chunks ← (9⥊900000000000000)∾⟨907199254740991⟩
primaryValues ← chunks∾⟨1,2⟩
primaryCount ← ≠primaryValues

# A balanced debit-primary Account axis sums exactly as:
#   chunks -> 2^53-1 -> +1 -> 2^53 -> +2 -> 2^53+2.
# Expense role omits the non-Expense bridge 1, so its subset instead attempts
#   chunks -> 2^53-1 -> +2 = 2^53+1,
# which exact_scale.Sum must reject.
expensePrimaryKeys ← ({𝕊 i: "expenses:chunk-"∾•Fmt i}¨↕≠chunks)∾⟨"assets:bridge","expenses:tail"⟩
expensePrimaryRoles ← ({𝕊 i: "expense"}¨↕≠chunks)∾⟨"asset","expense"⟩
expenseCounterKeys ← {𝕊 i: "liabilities:expense-counter-"∾•Fmt i}¨↕primaryCount
expenseCounterRoles ← {𝕊 i: "liability"}¨↕primaryCount
debitPostingAccounts ← ∾{𝕊 i: ⟨i,primaryCount+i⟩}¨↕primaryCount
pairedSides ← ∾{𝕊 i: ⟨"debit","credit"⟩}¨↕primaryCount
pairedCoefficients ← ∾{𝕊 value: ⟨value,-value⟩}¨primaryValues
expenseSubsetFacts ← MakeFacts ⟨
  expensePrimaryKeys∾expenseCounterKeys,
  expensePrimaryRoles∾expenseCounterRoles,
  debitPostingAccounts,pairedSides,pairedCoefficients
⟩
CheckExactFailure ⟨expenseSubsetFacts,"expense_sum_failed"⟩

# Symmetric credit-primary Account axis: Income sign normalization turns the
# selected credit movement back into the same positive subset 2^53-1 + 2.
incomePrimaryKeys ← ({𝕊 i: "income:chunk-"∾•Fmt i}¨↕≠chunks)∾⟨"liabilities:bridge","income:tail"⟩
incomePrimaryRoles ← ({𝕊 i: "income"}¨↕≠chunks)∾⟨"liability","income"⟩
incomeCounterKeys ← {𝕊 i: "assets:income-counter-"∾•Fmt i}¨↕primaryCount
incomeCounterRoles ← {𝕊 i: "asset"}¨↕primaryCount
creditPostingAccounts ← ∾{𝕊 i: ⟨primaryCount+i,i⟩}¨↕primaryCount
incomeSubsetFacts ← MakeFacts ⟨
  incomePrimaryKeys∾incomeCounterKeys,
  incomePrimaryRoles∾incomeCounterRoles,
  creditPostingAccounts,pairedSides,pairedCoefficients
⟩
CheckExactFailure ⟨incomeSubsetFacts,"income_sum_failed"⟩

# Individually exact Income and Expense totals can still make net income fail.
# Income selects only the chunks (= 2^53-1); bridge 1 is Liability; the final
# Expense Account is an abnormal credit and publishes -2. Net therefore attempts
# 2^53-1 - (-2) = 2^53+1 while the complete credit side remains exact.
netPrimaryKeys ← ({𝕊 i: "income:net-chunk-"∾•Fmt i}¨↕≠chunks)∾⟨"liabilities:net-bridge","expenses:net-tail"⟩
netPrimaryRoles ← ({𝕊 i: "income"}¨↕≠chunks)∾⟨"liability","expense"⟩
netCounterKeys ← {𝕊 i: "assets:net-counter-"∾•Fmt i}¨↕primaryCount
netCounterRoles ← {𝕊 i: "asset"}¨↕primaryCount
netSubsetFacts ← MakeFacts ⟨
  netPrimaryKeys∾netCounterKeys,
  netPrimaryRoles∾netCounterRoles,
  creditPostingAccounts,pairedSides,pairedCoefficients
⟩
CheckExactFailure ⟨netSubsetFacts,"net_income_sum_failed"⟩

•Out "test_accounting_profit_and_loss_boundaries: ok"
