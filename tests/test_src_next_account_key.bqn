#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
proj ← •Import "../src_next/projection.bqn"

tab ← @+9
lines ← ⟨
  "assets:bank" ∾ tab ∾ "role=asset",
  "医療費" ∾ tab ∾ "role=expense" ∾ tab ∾ "budget=医療" ∾ tab ∾ "budget_group=reserve" ∾ tab ∾ "spend_class=fixed",
  "expenses:food" ∾ tab ∾ "role=expense",
  "assets:usd" ∾ tab ∾ "currency=USD",
  "食費" ∾ tab ∾ "role=expense" ∾ tab ∾ "budget=食費" ∾ tab ∾ "budget_group=daily" ∾ tab ∾ "spend_class=variable" ∾ tab ∾ "currency=USD"
⟩

resolved ← ak.Resolve lines
⟨"asset", "expense", "expense", "", "expense"⟩ lib.AssertEq resolved.roles
⟨"JPY", "JPY", "JPY", "USD", "USD"⟩ lib.AssertEq resolved.currencies
⟨"", "医療", "", "", "食費"⟩ lib.AssertEq resolved.budgets
⟨"", "reserve", "", "", "daily"⟩ lib.AssertEq resolved.budget_groups
⟨"", "fixed", "", "", "variable"⟩ lib.AssertEq resolved.spend_classes
"expense" lib.AssertEq ak.RoleFromMeta ⟨"role=expense"⟩
"" lib.AssertEq ak.RoleFromMeta ⟨"currency=USD"⟩
"食費" lib.AssertEq ak.BudgetFromMeta ⟨"role=expense", "budget=食費"⟩
"daily" lib.AssertEq ak.BudgetGroupFromMeta ⟨"budget_group=daily"⟩
"variable" lib.AssertEq ak.SpendClassFromMeta ⟨"spend_class=variable"⟩
"" lib.AssertEq ak.BudgetFromMeta ⟨"role=expense"⟩
"" lib.AssertEq ak.BudgetGroupFromMeta ⟨"budget=食費"⟩
"" lib.AssertEq ak.SpendClassFromMeta ⟨"fixed=1"⟩
"" lib.AssertEq ak.RoleFromMeta ⟨"budget=食費", "budget_group=daily"⟩
"JPY" lib.AssertEq ak.CurrencyFromMeta ⟨"budget=食費", "budget_group=daily"⟩

# src_next kind inference: explicit roles preferred, legacy prefixes retained as fallback.
"expense" lib.AssertEq proj.InferKind ⟨"asset", "expense", "assets:bank", "expenses:food"⟩
"income" lib.AssertEq proj.InferKind ⟨"income", "asset", "income:salary", "assets:bank"⟩
"transfer" lib.AssertEq proj.InferKind ⟨"asset", "asset", "assets:bank", "assets:cash"⟩

# Posting IR identity helpers.
"T-001" lib.AssertEq proj.TxIdFromMeta ⟨"fallback-id", ⟨"2026-06-01", "memo", "assets:bank", "医療費", "1200", "txn_id=T-001"⟩⟩
"fallback-id" lib.AssertEq proj.TxIdFromMeta ⟨"fallback-id", ⟨"2026-06-01", "memo", "assets:bank", "医療費", "1200"⟩⟩
"actual" lib.AssertEq proj.LayerName proj.layer_actual
"journal.tsv:3:debit" lib.AssertEq proj.PostingId ⟨"journal.tsv", 3, "debit"⟩
1 lib.AssertEq proj.IsIntegerText "1200"
0 lib.AssertEq proj.IsIntegerText "12x"
1 lib.AssertEq proj.IsValidDateText "2026-06-01"
0 lib.AssertEq proj.IsValidDateText "2026-02-31"
0 lib.AssertEq proj.IsValidDateText "20260601"

rows ← proj.MakeRow ⟨"journal.tsv", 3, ⟨"2026-06-01", "memo", "assets:bank", "医療費", "1200", "txn_id=T-001"⟩, resolved.accounts, resolved.roles, resolved.account_keys, "2026-06-01"⟩
debit ← ⊑ rows
"T-001" lib.AssertEq debit.tx_id
"journal.tsv:3:debit" lib.AssertEq debit.posting_id
"2026-06-01" lib.AssertEq debit.date
"医療費/JPY" lib.AssertEq debit.account_key
"actual" lib.AssertEq debit.layer_name

badAmountRows ← proj.MakeRow ⟨"journal.tsv", 4, ⟨"2026-06-01", "bad amount", "assets:bank", "医療費", "12x"⟩, resolved.accounts, resolved.roles, resolved.account_keys, "2026-06-01"⟩
badAmountDebit ← ⊑ badAmountRows
"invalid_amount" lib.AssertEq badAmountDebit.status
"invalid amount: 12x" lib.AssertEq badAmountDebit.message
0 lib.AssertEq badAmountDebit.delta

badDateRows ← proj.MakeRow ⟨"journal.tsv", 5, ⟨"2026-02-31", "bad date", "assets:bank", "医療費", "1200"⟩, resolved.accounts, resolved.roles, resolved.account_keys, "2026-06-01"⟩
badDateDebit ← ⊑ badDateRows
"invalid_date" lib.AssertEq badDateDebit.status
"invalid date: 2026-02-31" lib.AssertEq badDateDebit.message
0 lib.AssertEq badDateDebit.day_index

missingAmountRows ← proj.MakeRow ⟨"journal.tsv", 6, ⟨"2026-06-01", "missing amount", "assets:bank", "医療費"⟩, resolved.accounts, resolved.roles, resolved.account_keys, "2026-06-01"⟩
"invalid_amount" lib.AssertEq (⊑ missingAmountRows).status

•Out "test_src_next_account_key.bqn: OK"
