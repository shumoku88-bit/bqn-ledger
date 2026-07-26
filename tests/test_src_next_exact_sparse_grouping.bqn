#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
sparse ← •Import "../src_next/queries/exact_sparse_grouping.bqn"
cube ← •Import "../src_next/cube.bqn"

# Empty input is a successful empty grouped relation.
emptyResult ← sparse.Group ⟨⟨⟩, ⟨⟩⟩
"ok" lib.AssertEq emptyResult.state
⟨⟩ lib.AssertEq emptyResult.keys
⟨⟩ lib.AssertEq emptyResult.values
0 lib.AssertEq emptyResult.input_count
0 lib.AssertEq emptyResult.grouped_count
0 lib.AssertEq emptyResult.input_total
0 lib.AssertEq emptyResult.grouped_total
1 lib.AssertEq emptyResult.conserved
"first_occurrence" lib.AssertEq emptyResult.order

# Duplicate exact keys add exactly, negative values are retained, totals conserve,
# and first occurrence determines deterministic group order.
keys ← ⟨"day0/account1/actual", "day0/account0/actual", "day0/account1/actual", "day1/account1/actual"⟩
values ← 10‿¯10‿5‿¯5
result ← sparse.Group ⟨keys, values⟩
expectedKeys ← ⟨"day0/account1/actual", "day0/account0/actual", "day1/account1/actual"⟩
expectedValues ← 15‿¯10‿¯5
"ok" lib.AssertEq result.state
expectedKeys lib.AssertEq result.keys
expectedValues lib.AssertEq result.values
4 lib.AssertEq result.input_count
3 lib.AssertEq result.grouped_count
0 lib.AssertEq result.input_total
0 lib.AssertEq result.grouped_total
1 lib.AssertEq result.conserved

repeat ← sparse.Group ⟨keys, values⟩
result.keys lib.AssertEq repeat.keys
result.values lib.AssertEq repeat.values

# Provenance remains a separate sidecar. Numeric grouped facts do not own posting IDs.
contributors ← sparse.ContributorIndices ⟨keys, result.keys⟩
0‿2 lib.AssertEq (0 ⊑ contributors)
⟨1⟩ lib.AssertEq (1 ⊑ contributors)
⟨3⟩ lib.AssertEq (2 ⊑ contributors)
postingIds ← ⟨"p0", "p1", "p2", "p3"⟩
⟨"p0", "p2"⟩ lib.AssertEq ((0 ⊑ contributors) ⊏ postingIds)

# Current cube.Materialize can be reconstructed from the same sparse grouped facts
# without changing cube production code.
MakeRow ← {𝕊 day‿ak‿layer‿delta‿srcId‿side‿kind:
  {
    source_file       ⇐ "actual.journal",
    source_row        ⇐ 0,
    source_id         ⇐ srcId,
    side              ⇐ side,
    day_index         ⇐ day,
    account_key_index ⇐ ak,
    layer_index       ⇐ layer,
    delta             ⇐ delta,
    kind              ⇐ kind,
    status            ⇐ "ok",
    message           ⇐ ""
  }
}

rows ← ⟨
  MakeRow ⟨0, 1, cube.layer_actual, 10, "A", "debit", "expense"⟩,
  MakeRow ⟨0, 0, cube.layer_actual, ¯10, "A", "credit", "expense"⟩,
  MakeRow ⟨0, 1, cube.layer_actual, 5, "B", "debit", "expense"⟩,
  MakeRow ⟨0, 0, cube.layer_actual, ¯5, "B", "credit", "expense"⟩,
  MakeRow ⟨1, 1, cube.layer_plan, 20, "P", "debit", "expense"⟩,
  MakeRow ⟨1, 0, cube.layer_plan, ¯20, "P", "credit", "expense"⟩
⟩

dayCount ← 2
akCount ← 2
flatSize ← dayCount × akCount × cube.layer_count
alSize ← akCount × cube.layer_count
current ← cube.Materialize ⟨rows, dayCount, akCount⟩
indices ← { (𝕩.day_index × alSize) + (𝕩.account_key_index × cube.layer_count) + 𝕩.layer_index }¨ current.valid_rows
deltas ← {𝕩.delta}¨ current.valid_rows
groupedCube ← sparse.Group ⟨indices, deltas⟩
denseFlat ← {𝕊 index: sparse.Sum0 ((groupedCube.keys = index) / groupedCube.values) }¨ ↕ flatSize
(flatSize ⥊ current.cube) lib.AssertEq denseFlat
current.valid_total_delta lib.AssertEq groupedCube.input_total
1 lib.AssertEq groupedCube.conserved

# A genuinely different TBDS-like consumer can group layer/account/side movement
# with the same primitive while owning its own period and accounting semantics.
movementKeys ← ⟨"actual/account0/debit", "actual/account0/credit", "actual/account0/debit", "plan/account1/debit"⟩
movementValues ← 30‿¯10‿5‿20
movement ← sparse.Group ⟨movementKeys, movementValues⟩
⟨"actual/account0/debit", "actual/account0/credit", "plan/account1/debit"⟩ lib.AssertEq movement.keys
35‿¯10‿20 lib.AssertEq movement.values

# Commodity is not implicit in the numeric kernel. A whole-Journal consumer must
# partition first or include domain in the key so incompatible quantities stay apart.
commodityKeys ← ⟨"JPY/assets:cash", "ILS/assets:cash", "JPY/assets:cash"⟩
commodityValues ← 100‿2500‿¯40
commodity ← sparse.Group ⟨commodityKeys, commodityValues⟩
⟨"JPY/assets:cash", "ILS/assets:cash"⟩ lib.AssertEq commodity.keys
60‿2500 lib.AssertEq commodity.values

# Structural mismatch fails without partial numeric output.
bad ← sparse.Group ⟨⟨"a"⟩, ⟨⟩⟩
"error" lib.AssertEq bad.state
⟨⟩ lib.AssertEq bad.keys
⟨⟩ lib.AssertEq bad.values

•Out "test_src_next_exact_sparse_grouping.bqn: OK"
