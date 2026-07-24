# test_journal_canonical_surface_plan.bqn
# Test plan classification for Canonical Journal Surface 001.

assert ← •Import "test_lib.bqn"
plan ← •Import "../src_edit/journal_canonical_surface_plan.bqn"

lf ← @+10

# Synthetic Fixture A: mixed surface
fixtureA ← "commodity JPY" ∾ lf ∾ lf
fixtureA ∾↩ "account assets:cash" ∾ lf ∾ "    ; role: asset" ∾ lf ∾ lf
fixtureA ∾↩ "account expenses:food" ∾ lf ∾ "    ; role: expense" ∾ lf ∾ lf
fixtureA ∾↩ "2026-07-24 * Tx1" ∾ lf
fixtureA ∾↩ "    ; event-id: event-001" ∾ lf
fixtureA ∾↩ "    ; layer: actual" ∾ lf
fixtureA ∾↩ "    ; currency: JPY" ∾ lf
fixtureA ∾↩ "    expenses:food 100 JPY" ∾ lf
fixtureA ∾↩ "    assets:cash -100 JPY" ∾ lf ∾ lf
fixtureA ∾↩ "2026-07-25 * Tx2" ∾ lf
fixtureA ∾↩ "    ; event-id: event-002" ∾ lf
fixtureA ∾↩ "    expenses:food    200 JPY" ∾ lf
fixtureA ∾↩ "    assets:cash    -200 JPY" ∾ lf

resA ← plan.Build fixtureA

"ok" assert.AssertEq resA.state
2 assert.AssertEq resA.transactions
4 assert.AssertEq resA.postings
2 assert.AssertEq resA.single_space_postings
2 assert.AssertEq resA.multi_space_postings
1 assert.AssertEq resA.layer_actual_metadata
1 assert.AssertEq resA.currency_jpy_metadata
1 assert.AssertEq resA.canonical_transactions
1 assert.AssertEq resA.spacing_and_redundant_metadata_transactions

# Synthetic Fixture B: already canonical
fixtureB ← "commodity JPY" ∾ lf ∾ lf
fixtureB ∾↩ "account assets:cash" ∾ lf ∾ "    ; role: asset" ∾ lf ∾ lf
fixtureB ∾↩ "account expenses:food" ∾ lf ∾ "    ; role: expense" ∾ lf ∾ lf
fixtureB ∾↩ "2026-07-24 * Tx1" ∾ lf
fixtureB ∾↩ "    ; event-id: event-001" ∾ lf
fixtureB ∾↩ "    expenses:food    100 JPY" ∾ lf
fixtureB ∾↩ "    assets:cash    -100 JPY" ∾ lf

resB ← plan.Build fixtureB
"ok" assert.AssertEq resB.state
1 assert.AssertEq resB.canonical_transactions
0 assert.AssertEq resB.single_space_postings
0 assert.AssertEq resB.layer_actual_metadata

•Out "PASS: test_journal_canonical_surface_plan"
