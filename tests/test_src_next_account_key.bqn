#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ak ← •Import "../src_next/account_key.bqn"
proj ← •Import "../src_next/projection.bqn"
ctx ← •Import "../src_next/context.bqn"

tab ← @+9
lines ← ⟨
  "assets:bank" ∾ tab ∾ "role=asset",
  "医療費" ∾ tab ∾ "role=expense" ∾ tab ∾ "budget=医療" ∾ tab ∾ "budget_group=reserve" ∾ tab ∾ "spend_class=fixed",
  "expenses:food" ∾ tab ∾ "role=expense",
  "assets:usd" ∾ tab ∾ "currency=USD",
  "食費" ∾ tab ∾ "role=expense" ∾ tab ∾ "budget=食費" ∾ tab ∾ "budget_group=daily" ∾ tab ∾ "spend_class=variable" ∾ tab ∾ "envelope_role=dynamic" ∾ tab ∾ "currency=USD"
⟩

resolved ← ak.Resolve lines
Line ← {𝕊 fields: ∾ fields ∾¨ tab}
SnapshotForLine ← {𝕊 line:
  {
    sources ⇐ ⟨
      {source_file⇐"journal.tsv", required⇐1, lines⇐⟨line⟩},
      {source_file⇐"plan.tsv", required⇐0, lines⇐⟨⟩},
      {source_file⇐"budget_alloc.tsv", required⇐0, lines⇐⟨⟩}
    ⟩
  }
}
RowsForFields ← {𝕊 rowIdx‿fields:
  snapshot ← SnapshotForLine Line fields
  rows ← (ctx.BuildAuthorizedRowsFromSnapshot ⟨snapshot, resolved, "2026-06-01"⟩).rows
  # Preserve historical rowIdx assertions for this unit test.
  {𝕊 r:
    {
      source_file       ⇐ r.source_file,
      source_row        ⇐ rowIdx,
      source_id         ⇐ r.source_id,
      tx_id             ⇐ r.tx_id,
      posting_id        ⇐ proj.PostingId ⟨r.source_file, rowIdx, r.side⟩,
      date              ⇐ r.date,
      side              ⇐ r.side,
      day_index         ⇐ r.day_index,
      account_key       ⇐ r.account_key,
      account_key_index ⇐ r.account_key_index,
      layer_name        ⇐ r.layer_name,
      layer_index       ⇐ r.layer_index,
      delta             ⇐ r.delta,
      kind              ⇐ r.kind,
      status            ⇐ r.status,
      message           ⇐ r.message
    }
  }¨ rows
}
⟨"asset", "expense", "expense", "", "expense"⟩ lib.AssertEq resolved.roles
⟨"JPY", "JPY", "JPY", "USD", "USD"⟩ lib.AssertEq resolved.currencies
⟨"", "医療", "", "", "食費"⟩ lib.AssertEq resolved.budgets
⟨"", "reserve", "", "", "daily"⟩ lib.AssertEq resolved.budget_groups
⟨"", "fixed", "", "", "variable"⟩ lib.AssertEq resolved.spend_classes
⟨"", "", "", "", "dynamic"⟩ lib.AssertEq resolved.envelope_roles
"expense" lib.AssertEq ak.RoleFromMeta ⟨"role=expense"⟩
"" lib.AssertEq ak.RoleFromMeta ⟨"currency=USD"⟩
"食費" lib.AssertEq ak.BudgetFromMeta ⟨"role=expense", "budget=食費"⟩
"daily" lib.AssertEq ak.BudgetGroupFromMeta ⟨"budget_group=daily"⟩
"variable" lib.AssertEq ak.SpendClassFromMeta ⟨"spend_class=variable"⟩
"execution" lib.AssertEq ak.EnvelopeRoleFromMeta ⟨"envelope_role=execution"⟩
"" lib.AssertEq ak.BudgetFromMeta ⟨"role=expense"⟩
"" lib.AssertEq ak.BudgetGroupFromMeta ⟨"budget=食費"⟩
"" lib.AssertEq ak.SpendClassFromMeta ⟨"fixed=1"⟩
"" lib.AssertEq ak.RoleFromMeta ⟨"budget=食費", "budget_group=daily"⟩
"JPY" lib.AssertEq ak.CurrencyFromMeta ⟨"budget=食費", "budget_group=daily"⟩

# src_next kind inference: explicit roles required.
"expense" lib.AssertEq proj.InferKind ⟨"asset", "expense", "assets:bank", "expenses:food"⟩
"income" lib.AssertEq proj.InferKind ⟨"income", "asset", "income:salary", "assets:bank"⟩
"transfer" lib.AssertEq proj.InferKind ⟨"asset", "asset", "assets:bank", "assets:cash"⟩
"transfer" lib.AssertEq proj.InferKind ⟨"", "", "income:salary", "expenses:food"⟩

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

rows ← RowsForFields ⟨3, ⟨"2026-06-01", "memo", "assets:bank", "医療費", "1200", "txn_id=T-001"⟩⟩
debit ← ⊑ rows
"T-001" lib.AssertEq debit.tx_id
"journal.tsv:3:debit" lib.AssertEq debit.posting_id
"2026-06-01" lib.AssertEq debit.date
"医療費/JPY" lib.AssertEq debit.account_key
"actual" lib.AssertEq debit.layer_name

badAmountRows ← RowsForFields ⟨4, ⟨"2026-06-01", "bad amount", "assets:bank", "医療費", "12x"⟩⟩
badAmountDebit ← ⊑ badAmountRows
"invalid_amount" lib.AssertEq badAmountDebit.status
"invalid amount: 12x" lib.AssertEq badAmountDebit.message
0 lib.AssertEq badAmountDebit.delta

badDateRows ← RowsForFields ⟨5, ⟨"2026-02-31", "bad date", "assets:bank", "医療費", "1200"⟩⟩
badDateDebit ← ⊑ badDateRows
"invalid_date" lib.AssertEq badDateDebit.status
"invalid date: 2026-02-31" lib.AssertEq badDateDebit.message
0 lib.AssertEq badDateDebit.day_index

missingAmountRows ← RowsForFields ⟨6, ⟨"2026-06-01", "missing amount", "assets:bank", "医療費"⟩⟩
"invalid_amount" lib.AssertEq (⊑ missingAmountRows).status

•Out "test_src_next_account_key.bqn: OK"
