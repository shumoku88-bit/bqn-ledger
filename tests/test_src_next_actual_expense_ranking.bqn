#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ranking ← •Import "../src_next/queries/actual_expense_ranking.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds ← •Import "../src_next/tbds.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src/application/source_io.bqn"
context ← •Import "../src_next/context.bqn"
sel ← •Import "../src_next/selected_domain_context.bqn"

Split ← { sep ← 𝕨 ⋄ mask ← sep = 𝕩 ⋄ groups ← (+` mask) ⊔ 𝕩 ⋄ parts ← { (sep ≠ 𝕩) / 𝕩 } ¨ groups ⋄ (0 < ≠¨ parts) / parts }

Pad2 ← { s ← •Fmt 𝕩 ⋄ ((0 ⌈ 2-≠s)⥊'0') ∾ s }
FmtDate ← { "2026-07-" ∾ Pad2 (1 + 𝕩) }

MakeRow12 ← {𝕊 day‿ak_idx‿accountKey‿layerName‿layerIndex‿delta‿postingId‿side‿kind‿status‿domain‿scale:
  {
    source_file           ⇐ "actual.journal",
    source_row            ⇐ day,
    source_id             ⇐ postingId,
    tx_id                  ⇐ "tx-" ∾ postingId,
    posting_id             ⇐ postingId,
    date                   ⇐ FmtDate day,
    day_index              ⇐ day,
    account_key            ⇐ accountKey,
    account_key_index      ⇐ ak_idx,
    layer_name             ⇐ layerName,
    layer_index            ⇐ layerIndex,
    side                   ⇐ side,
    delta                  ⇐ delta,
    kind                   ⇐ kind,
    status                 ⇐ status,
    message                ⇐ "",
    domain                 ⇐ domain,
    calculation_scale      ⇐ scale,
    normalized_coefficient ⇐ delta
  }
}

MakeRow13 ← {𝕊 day‿ak_idx‿accountKey‿layerName‿layerIndex‿delta‿postingId‿side‿kind‿status‿domain‿scale‿role:
  {
    source_file           ⇐ "actual.journal",
    source_row            ⇐ day,
    source_id             ⇐ postingId,
    tx_id                  ⇐ "tx-" ∾ postingId,
    posting_id             ⇐ postingId,
    date                   ⇐ FmtDate day,
    day_index              ⇐ day,
    account_key            ⇐ accountKey,
    account_key_index      ⇐ ak_idx,
    layer_name             ⇐ layerName,
    layer_index            ⇐ layerIndex,
    side                   ⇐ side,
    delta                  ⇐ delta,
    kind                   ⇐ kind,
    status                 ⇐ status,
    message                ⇐ "",
    domain                 ⇐ domain,
    calculation_scale      ⇐ scale,
    normalized_coefficient ⇐ delta,
    role                   ⇐ role,
    account_name           ⇐ ⊑ '/' Split accountKey
  }
}

MakeRow ← { (13 = ≠𝕩) ◶ ⟨ MakeRow12, MakeRow13 ⟩ 𝕩 }

dayCount ← 5
akCount ← 6

expKeys ← ⟨"expenses:food/JPY", "expenses:books/JPY", "expenses:transport/JPY", "expenses:zero/JPY"⟩

rows ← ⟨
  MakeRow ⟨0, 1, "expenses:food/JPY",      "actual", 0,  1200, "p-food-1",     "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨0, 0, "assets:cash/JPY",        "actual", 0, ¯1200, "p-cash-1",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 1, "expenses:food/JPY",      "actual", 0,   800, "p-food-2",     "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 0, "assets:cash/JPY",        "actual", 0,  ¯800, "p-cash-2",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨2, 2, "expenses:books/JPY",     "actual", 0,  2000, "p-books",      "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨2, 0, "assets:cash/JPY",        "actual", 0, ¯2000, "p-cash-3",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨3, 3, "expenses:transport/JPY", "actual", 0,   500, "p-transport",  "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨3, 0, "assets:cash/JPY",        "actual", 0,  ¯500, "p-cash-4",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 1, "expenses:food/JPY",      "plan",   1,   999, "p-plan-food",  "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 0, "assets:cash/JPY",        "plan",   1,  ¯999, "p-plan-cash",  "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨4, 0, "assets:cash/JPY",        "actual", 0,  3000, "p-income-cash","debit",  "income",  "ok",            "JPY", 0⟩,
  MakeRow ⟨4, 4, "income:pension/JPY",     "actual", 0, ¯3000, "p-income",     "credit", "income",  "ok",            "JPY", 0⟩,
  MakeRow ⟨5, 1, "expenses:food/JPY",      "actual", 0,   700, "p-out-period", "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨0, 1, "expenses:food/JPY",      "actual", 0,   100, "p-invalid",    "debit",  "expense", "invalid_amount","JPY", 0⟩
⟩

# 11.1 Real AccountKey format & 11.9 JPY success
result ← ranking.Build ⟨rows, expKeys, dayCount, "JPY", 0⟩
"ok" lib.AssertEq result.state
"JPY" lib.AssertEq result.selected_currency
0 lib.AssertEq result.calculation_scale
4 lib.AssertEq result.selected_count
3 lib.AssertEq result.grouped_count
4500 lib.AssertEq result.selected_total
4500 lib.AssertEq result.grouped_total
1 lib.AssertEq result.conserved

# 11.2 Duplicate expense postings & 11.6 Ranking
# Ranking is amount descending with semantic AccountKey ascending as the tie break.
⟨"expenses:books/JPY", "expenses:food/JPY", "expenses:transport/JPY"⟩ lib.AssertEq result.ranked_keys
2000‿2000‿500 lib.AssertEq result.ranked_values
⟨⟨"p-books"⟩, ⟨"p-food-1", "p-food-2"⟩, ⟨"p-transport"⟩⟩ lib.AssertEq result.ranked_contributor_posting_ids

# ranking_order contract verification on normal success case:
# ranking_order indexes into grouped_keys / grouped_values / contributor_posting_ids
result.ranked_keys lib.AssertEq result.ranking_order ⊏ result.grouped_keys
result.ranked_values lib.AssertEq result.ranking_order ⊏ result.grouped_values
result.ranked_contributor_posting_ids lib.AssertEq result.ranking_order ⊏ result.contributor_posting_ids

# Repeat evaluation is deterministic.
repeat ← ranking.Build ⟨rows, expKeys, dayCount, "JPY", 0⟩
result.ranked_keys lib.AssertEq repeat.ranked_keys
result.ranked_values lib.AssertEq repeat.ranked_values
result.ranked_contributor_posting_ids lib.AssertEq repeat.ranked_contributor_posting_ids

# Empty checked facts produce a successful empty ranking.
emptyResult ← ranking.Build ⟨⟨⟩, expKeys, dayCount, "JPY", 0⟩
"ok" lib.AssertEq emptyResult.state
⟨⟩ lib.AssertEq emptyResult.ranked_keys
⟨⟩ lib.AssertEq emptyResult.ranked_values
0 lib.AssertEq emptyResult.selected_total
1 lib.AssertEq emptyResult.conserved

# 11.3 Non-expense debit inside expense transaction
# Transaction with kind="expense" containing both an expense debit and a non-expense debit (assets:prepaid)
splitTxRows ← ⟨
  MakeRow ⟨0, 1, "expenses:food/JPY",     "actual", 0,  800, "p-split-food",    "debit",  "expense", "ok", "JPY", 0⟩,
  MakeRow ⟨0, 5, "assets:prepaid/JPY",   "actual", 0,  200, "p-split-prepaid", "debit",  "expense", "ok", "JPY", 0⟩,
  MakeRow ⟨0, 0, "assets:cash/JPY",       "actual", 0, ¯1000, "p-split-cash",    "credit", "expense", "ok", "JPY", 0⟩
⟩
splitResult ← ranking.Build ⟨splitTxRows, expKeys, dayCount, "JPY", 0⟩
"ok" lib.AssertEq splitResult.state
1 lib.AssertEq splitResult.selected_count
⟨"expenses:food/JPY"⟩ lib.AssertEq splitResult.ranked_keys
800 lib.AssertEq ⊑ splitResult.ranked_values

# 11.5 Defensive synthetic zero-net expense account test
# Defensive synthetic case only.
# A negative debit is not admitted by the normal Posting IR contract.
# This test characterizes zero-group visibility and ranking-order coordinates,
# not producer admission.
# Characterization target: unexpected but arithmetically valid grouped zero does not enter visible ranking
zeroNetRows ← ⟨
  MakeRow ⟨0, 1, "expenses:food/JPY", "actual", 0,  1000, "p-z-1", "debit", "expense", "ok", "JPY", 0⟩,
  MakeRow ⟨0, 1, "expenses:food/JPY", "actual", 0, ¯1000, "p-z-2", "debit", "expense", "ok", "JPY", 0⟩,
  MakeRow ⟨1, 2, "expenses:books/JPY","actual", 0,  2000, "p-z-3", "debit", "expense", "ok", "JPY", 0⟩
⟩
zeroNetResult ← ranking.Build ⟨zeroNetRows, expKeys, dayCount, "JPY", 0⟩
"ok" lib.AssertEq zeroNetResult.state
2 lib.AssertEq zeroNetResult.grouped_count
1 lib.AssertEq zeroNetResult.conserved
2000 lib.AssertEq zeroNetResult.grouped_total
# Visible ranking excludes the 0-amount group (expenses:food/JPY)
⟨"expenses:books/JPY"⟩ lib.AssertEq zeroNetResult.ranked_keys
2000 lib.AssertEq ⊑ zeroNetResult.ranked_values

# ranking_order contract verification on zero-net defensive case:
# ranking_order indexes into grouped_keys / grouped_values / contributor_posting_ids
zeroNetResult.ranked_keys lib.AssertEq zeroNetResult.ranking_order ⊏ zeroNetResult.grouped_keys
zeroNetResult.ranked_values lib.AssertEq zeroNetResult.ranking_order ⊏ zeroNetResult.grouped_values
zeroNetResult.ranked_contributor_posting_ids lib.AssertEq zeroNetResult.ranking_order ⊏ zeroNetResult.contributor_posting_ids

# 11.7 TBDS relation parity
resolvedSample ← {
  account_keys ⇐ ⟨"assets:cash/JPY", "expenses:food/JPY", "expenses:books/JPY", "expenses:transport/JPY", "income:pension/JPY", "assets:prepaid/JPY"⟩,
  accounts     ⇐ ⟨"assets:cash",     "expenses:food",     "expenses:books",     "expenses:transport",     "income:pension",     "assets:prepaid"⟩,
  currencies   ⇐ ⟨"JPY",             "JPY",               "JPY",                "JPY",                    "JPY",                "JPY"⟩,
  roles        ⇐ ⟨"asset",           "expense",           "expense",            "expense",                "income",             "asset"⟩,
  types        ⇐ ⟨"", "", "", "", "", ""⟩,
  budgets      ⇐ ⟨"", "", "", "", "", ""⟩,
  budget_groups⇐ ⟨"", "", "", "", "", ""⟩,
  spend_classes⇐ ⟨"", "", "", "", "", ""⟩,
  count        ⇐ 6
}
cySample ← {start ⇐ "2026-07-01", end_exclusive ⇐ "2026-07-06", day_count ⇐ 5}
sampleRowsWithRole ← {
  r ← 𝕩
  ak_idx ← ⊑ resolvedSample.account_keys ⊐ ⟨r.account_key⟩
  role ← ak_idx ⊑ resolvedSample.roles
  MakeRow ⟨r.day_index, ak_idx, r.account_key, r.layer_name, r.layer_index, r.delta, r.posting_id, r.side, r.kind, r.status, r.domain, r.calculation_scale, role⟩
}¨ rows

tbdsRows ← tbds.Build ⟨sampleRowsWithRole, cube.Materialize ⟨sampleRowsWithRole, cySample.day_count, resolvedSample.count⟩, resolvedSample, cySample⟩
tbdsBreakdown ← tbds.ActualExpenseBreakdown tbdsRows

tbdsKeys ← { 0 ⊑ 𝕩 }¨ tbdsBreakdown
tbdsAmounts ← { 1 ⊑ 𝕩 }¨ tbdsBreakdown
tbdsOrder ← ⍋ tbdsKeys
tbdsSortedKeys ← tbdsOrder ⊏ tbdsKeys
tbdsSortedAmounts ← tbdsOrder ⊏ tbdsAmounts

rankRes ← ranking.Build ⟨sampleRowsWithRole, ranking.ExpenseAccountKeys resolvedSample, cySample.day_count, "JPY", 0⟩
rankOrder ← ⍋ rankRes.ranked_keys
rankSortedKeys ← rankOrder ⊏ rankRes.ranked_keys
rankSortedAmounts ← rankOrder ⊏ rankRes.ranked_values

tbdsSortedKeys lib.AssertEq rankSortedKeys
tbdsSortedAmounts lib.AssertEq rankSortedAmounts

# 11.8 Production producer integration
baseFixture ← "fixtures/journal-split-purchase-characterization"
rawFixture ← loader.ReadRaw (baseFixture ∾ "/profile.journal")
resolvedFixture ← ak.Resolve (loader.ReadLines (baseFixture ∾ "/accounts.tsv"))
cyFixture ← {start ⇐ "2026-08-01", end_exclusive ⇐ "2026-09-01", day_count ⇐ 31}
sourceFileFixture ← "profile.journal"
snapshotFixture ← context.LoadNonActualPostingSourceSnapshot baseFixture

ctxFixture ← sel.BuildFromPrepared ⟨"JPY", rawFixture, resolvedFixture, cyFixture, sourceFileFixture, snapshotFixture⟩
"ok" lib.AssertEq ctxFixture.state

prodRank ← ranking.Build ⟨ctxFixture.posting_rows, ranking.ExpenseAccountKeys ctxFixture.resolved, ctxFixture.cy.day_count, ctxFixture.selected_currency, ctxFixture.calculation_scale⟩
"ok" lib.AssertEq prodRank.state
⟨
  "expenses:food:daily/JPY",
  "expenses:food:stock/JPY",
  "expenses:tobacco/JPY",
  "expenses:household/JPY",
  "expenses:coffee/JPY"
⟩ lib.AssertEq prodRank.ranked_keys

2800‿1800‿600‿500‿150 lib.AssertEq prodRank.ranked_values

# 11.10 ILS success
ilsAccountKeys ← ⟨"expenses:food-ils/ILS", "assets:cash-ils/ILS"⟩
ilsRows ← ⟨
  MakeRow ⟨0, 0, "expenses:food-ils/ILS", "actual", 0, 2550, "p-ils-1", "debit",  "expense", "ok", "ILS", 2⟩,
  MakeRow ⟨0, 1, "assets:cash-ils/ILS",   "actual", 0,¯2550, "p-ils-2", "credit", "expense", "ok", "ILS", 2⟩
⟩
ilsResult ← ranking.Build ⟨ilsRows, ilsAccountKeys, dayCount, "ILS", 2⟩
"ok" lib.AssertEq ilsResult.state
"ILS" lib.AssertEq ilsResult.selected_currency
2 lib.AssertEq ilsResult.calculation_scale
⟨"expenses:food-ils/ILS"⟩ lib.AssertEq ilsResult.ranked_keys
2550 lib.AssertEq ⊑ ilsResult.ranked_values

# 11.11 Domain and scale fail closed
mixedDomainRows ← rows ∾ ⟨MakeRow ⟨0, 1, "expenses:food-ils/ILS", "actual", 0, 2500, "p-ils", "debit", "expense", "ok", "ILS", 2⟩⟩
mixedDomain ← ranking.Build ⟨mixedDomainRows, expKeys, dayCount, "JPY", 0⟩
"error" lib.AssertEq mixedDomain.state
⟨⟩ lib.AssertEq mixedDomain.ranked_keys
0 lib.AssertEq mixedDomain.grouped_total
"domain_mismatch" lib.AssertEq (⊑ mixedDomain.diagnostics).code

mixedScaleRows ← rows ∾ ⟨MakeRow ⟨0, 1, "expenses:food/JPY", "actual", 0, 2500, "p-scale", "debit", "expense", "ok", "JPY", 2⟩⟩
mixedScale ← ranking.Build ⟨mixedScaleRows, expKeys, dayCount, "JPY", 0⟩
"error" lib.AssertEq mixedScale.state
⟨⟩ lib.AssertEq mixedScale.ranked_values
"calculation_scale_mismatch" lib.AssertEq (⊑ mixedScale.diagnostics).code

•Out "test_src_next_actual_expense_ranking.bqn: OK"
