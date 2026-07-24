# test_journal_canonical_surface_rewrite.bqn
# Test candidate rewrite and semantic equivalence for Canonical Journal Surface 001.

assert ← •Import "test_lib.bqn"
rewrite ← •Import "../src_edit/journal_canonical_surface_rewrite.bqn"
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

resA ← rewrite.BuildCandidate fixtureA

"ok" assert.AssertEq resA.state
0 assert.AssertEq ≠resA.diagnostics

candPlanA ← plan.Build resA.candidate_raw
"ok" assert.AssertEq candPlanA.state
2 assert.AssertEq candPlanA.canonical_transactions
0 assert.AssertEq candPlanA.single_space_postings
0 assert.AssertEq candPlanA.layer_actual_metadata
0 assert.AssertEq candPlanA.currency_jpy_metadata

# Synthetic Fixture B: already canonical
fixtureB ← "commodity JPY" ∾ lf ∾ lf
fixtureB ∾↩ "account assets:cash" ∾ lf ∾ "    ; role: asset" ∾ lf ∾ lf
fixtureB ∾↩ "account expenses:food" ∾ lf ∾ "    ; role: expense" ∾ lf ∾ lf
fixtureB ∾↩ "2026-07-24 * Tx1" ∾ lf
fixtureB ∾↩ "    ; event-id: event-001" ∾ lf
fixtureB ∾↩ "    expenses:food    100 JPY" ∾ lf
fixtureB ∾↩ "    assets:cash    -100 JPY" ∾ lf

resB ← rewrite.BuildCandidate fixtureB
"ok" assert.AssertEq resB.state
fixtureB assert.AssertEq resB.candidate_raw

•Out "PASS: test_journal_canonical_surface_rewrite"
