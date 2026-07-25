#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ranking ← •Import "../src_next/actual_expense_ranking.bqn"
cube ← •Import "../src_next/cube.bqn"

MakeRow ← {𝕊 day‿ak‿accountKey‿layerName‿layerIndex‿delta‿postingId‿side‿kind‿status‿domain‿scale:
  {
    source_file           ⇐ "actual.journal",
    source_row            ⇐ day,
    source_id             ⇐ postingId,
    tx_id                  ⇐ "tx-" ∾ postingId,
    posting_id             ⇐ postingId,
    date                   ⇐ "2026-07-01",
    day_index              ⇐ day,
    account_key            ⇐ accountKey,
    account_key_index      ⇐ ak,
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

dayCount ← 5
akCount ← 5
rows ← ⟨
  MakeRow ⟨0, 1, "expenses:food|JPY",      "actual", 0,  1200, "p-food-1",     "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨0, 0, "assets:cash|JPY",        "actual", 0, ¯1200, "p-cash-1",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 1, "expenses:food|JPY",      "actual", 0,   800, "p-food-2",     "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 0, "assets:cash|JPY",        "actual", 0,  ¯800, "p-cash-2",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨2, 2, "expenses:books|JPY",     "actual", 0,  2000, "p-books",      "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨2, 0, "assets:cash|JPY",        "actual", 0, ¯2000, "p-cash-3",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨3, 3, "expenses:transport|JPY", "actual", 0,   500, "p-transport",  "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨3, 0, "assets:cash|JPY",        "actual", 0,  ¯500, "p-cash-4",     "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 1, "expenses:food|JPY",      "plan",   1,   999, "p-plan-food",  "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨1, 0, "assets:cash|JPY",        "plan",   1,  ¯999, "p-plan-cash",  "credit", "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨4, 0, "assets:cash|JPY",        "actual", 0,  3000, "p-income-cash","debit",  "income",  "ok",            "JPY", 0⟩,
  MakeRow ⟨4, 4, "income:pension|JPY",     "actual", 0, ¯3000, "p-income",     "credit", "income",  "ok",            "JPY", 0⟩,
  MakeRow ⟨5, 1, "expenses:food|JPY",      "actual", 0,   700, "p-out-period", "debit",  "expense", "ok",            "JPY", 0⟩,
  MakeRow ⟨0, 1, "expenses:food|JPY",      "actual", 0,   100, "p-invalid",    "debit",  "expense", "invalid_amount","JPY", 0⟩
⟩

# One real query runs directly from checked posting facts without Cube ownership.
result ← ranking.Build ⟨rows, dayCount, "JPY", 0⟩
"ok" lib.AssertEq result.state
"JPY" lib.AssertEq result.selected_currency
0 lib.AssertEq result.calculation_scale
4 lib.AssertEq result.selected_count
3 lib.AssertEq result.grouped_count
4500 lib.AssertEq result.selected_total
4500 lib.AssertEq result.grouped_total
1 lib.AssertEq result.conserved

# Ranking is amount descending with semantic AccountKey ascending as the tie break.
⟨"expenses:books|JPY", "expenses:food|JPY", "expenses:transport|JPY"⟩ lib.AssertEq result.ranked_keys
2000‿2000‿500 lib.AssertEq result.ranked_values
⟨⟨"p-books"⟩, ⟨"p-food-1", "p-food-2"⟩, ⟨"p-transport"⟩⟩ lib.AssertEq result.ranked_contributor_posting_ids

# The direct sparse consumer preserves the current Cube expense-total meaning.
current ← cube.Materialize ⟨rows, dayCount, akCount⟩
current.actual_expense_total lib.AssertEq result.grouped_total

# Repeat evaluation is deterministic.
repeat ← ranking.Build ⟨rows, dayCount, "JPY", 0⟩
result.ranked_keys lib.AssertEq repeat.ranked_keys
result.ranked_values lib.AssertEq repeat.ranked_values
result.ranked_contributor_posting_ids lib.AssertEq repeat.ranked_contributor_posting_ids

# Empty checked facts produce a successful empty ranking.
emptyResult ← ranking.Build ⟨⟨⟩, dayCount, "JPY", 0⟩
"ok" lib.AssertEq emptyResult.state
⟨⟩ lib.AssertEq emptyResult.ranked_keys
⟨⟩ lib.AssertEq emptyResult.ranked_values
0 lib.AssertEq emptyResult.selected_total
1 lib.AssertEq emptyResult.conserved

# Arithmetic-domain mismatch fails closed without partial numeric output.
mixedDomainRows ← rows ∾ ⟨MakeRow ⟨0, 1, "expenses:food|ILS", "actual", 0, 2500, "p-ils", "debit", "expense", "ok", "ILS", 2⟩⟩
mixedDomain ← ranking.Build ⟨mixedDomainRows, dayCount, "JPY", 0⟩
"error" lib.AssertEq mixedDomain.state
⟨⟩ lib.AssertEq mixedDomain.ranked_keys
0 lib.AssertEq mixedDomain.grouped_total
"domain_mismatch" lib.AssertEq (⊑ mixedDomain.diagnostics).code

# Exact-scale mismatch also fails closed.
mixedScaleRows ← rows ∾ ⟨MakeRow ⟨0, 1, "expenses:food|JPY", "actual", 0, 2500, "p-scale", "debit", "expense", "ok", "JPY", 2⟩⟩
mixedScale ← ranking.Build ⟨mixedScaleRows, dayCount, "JPY", 0⟩
"error" lib.AssertEq mixedScale.state
⟨⟩ lib.AssertEq mixedScale.ranked_values
"calculation_scale_mismatch" lib.AssertEq (⊑ mixedScale.diagnostics).code

•Out "test_src_next_actual_expense_ranking.bqn: OK"
