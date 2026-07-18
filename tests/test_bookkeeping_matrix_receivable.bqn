#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

# 1. Load and parse the receivable study journal profile
raw ← •FChars "../fixtures/bookkeeping-matrix-receivable/profile.journal"
result ← parser.Parse raw

# Assert parser state and dimensions
"ok" lib.AssertEq result.state
0 lib.AssertEq ≠ result.diagnostics
3 lib.AssertEq ≠ result.accounts
1 lib.AssertEq ≠ result.commodities
2 lib.AssertEq ≠ result.transactions

# Assert transaction layers are actual and identity is durable
expectedLayers ← ⟨<"actual", <"actual"⟩
actualLayers ← {<𝕩.layer_name}¨ result.transactions
expectedLayers lib.AssertEq actualLayers

"durable" lib.AssertEq (0 ⊑ result.transactions).identity_kind
"durable" lib.AssertEq (1 ⊑ result.transactions).identity_kind

"event-credit-sale-001" lib.AssertEq (0 ⊑ result.transactions).source_event_id
"event-receivable-collection-001" lib.AssertEq (1 ⊑ result.transactions).source_event_id

# Verify postings count and order matches journal
expectedPostingCounts ← 2‿2
expectedPostingCounts lib.AssertEq {≠𝕩.postings}¨ result.transactions

# Credit sale transaction postings
t0_postings ← (0 ⊑ result.transactions).postings
"assets:accounts-receivable" lib.AssertEq (0 ⊑ t0_postings).account_key
3000 lib.AssertEq (0 ⊑ t0_postings).delta
"income:sales" lib.AssertEq (1 ⊑ t0_postings).account_key
¯3000 lib.AssertEq (1 ⊑ t0_postings).delta

# Receivable collection transaction postings
t1_postings ← (1 ⊑ result.transactions).postings
"assets:bank" lib.AssertEq (0 ⊑ t1_postings).account_key
3000 lib.AssertEq (0 ⊑ t1_postings).delta
"assets:accounts-receivable" lib.AssertEq (1 ⊑ t1_postings).account_key
¯3000 lib.AssertEq (1 ⊑ t1_postings).delta


# 2. Event x Account matrix verification
matrixLines ← loader.ReadLines "fixtures/bookkeeping-matrix-receivable/expected-event-account-matrix.tsv"
matrixHeader ← loader.SplitTsvKeepEmpty ⊑ matrixLines
matrixAccountKeys ← <¨ 2 ↓ ¯1 ↓ matrixHeader

expectedMatrix ← {
  fields ← loader.SplitTsvKeepEmpty 𝕩
  util.ToNum¨ 2 ↓ ¯1 ↓ fields
}¨ 1 ↓ matrixLines

actualMatrix ← parser.BuildMatrix ⟨result.transactions, matrixAccountKeys⟩
expectedMatrix lib.AssertEq actualMatrix

# Assert transaction-level zero-sum (balance invariant)
{0 lib.AssertEq +´ 𝕩}¨ actualMatrix

# Resolve column indexes for verification
bankIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"assets:bank" ⟩
salesIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"income:sales" ⟩
receivableIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"assets:accounts-receivable" ⟩

# Verify 0-cells in specific events
0 lib.AssertEq bankIdx ⊑ (0 ⊑ actualMatrix)   # No bank movement during credit sale
0 lib.AssertEq salesIdx ⊑ (1 ⊑ actualMatrix)  # No sales recognized during collection


# 3. Running Balances verification
balanceLines ← loader.ReadLines "fixtures/bookkeeping-matrix-receivable/expected-running-balances.tsv"
balanceHeader ← loader.SplitTsvKeepEmpty ⊑ balanceLines
balanceAccountKeys ← <¨ 1 ↓ balanceHeader

# Ensure columns align between matrix and running balances TSVs
balanceAccountKeys lib.AssertEq matrixAccountKeys

expectedBalances ← {
  fields ← loader.SplitTsvKeepEmpty 𝕩
  util.ToNum¨ 1 ↓ fields
}¨ 1 ↓ balanceLines

# Compute running balances from event matrix using BQN scan
actualBalances ← +` actualMatrix
expectedBalances lib.AssertEq actualBalances


# 4. Final Balances and Accounting Invariants
finalBalance ← ¯1 ⊑ actualBalances
3000 lib.AssertEq bankIdx ⊑ finalBalance
0 lib.AssertEq receivableIdx ⊑ finalBalance
¯3000 lib.AssertEq salesIdx ⊑ finalBalance

# Assert explicit invariants:
# 1. Accounts receivable is 3000 after credit sale, 0 after collection
# 2. Sales remains -3000 after both events
# 3. Bank remains 0 after credit sale, 3000 after collection
balanceAfterSale ← 0 ⊑ actualBalances
3000 lib.AssertEq receivableIdx ⊑ balanceAfterSale
¯3000 lib.AssertEq salesIdx ⊑ balanceAfterSale
0 lib.AssertEq bankIdx ⊑ balanceAfterSale

balanceAfterCollection ← 1 ⊑ actualBalances
0 lib.AssertEq receivableIdx ⊑ balanceAfterCollection
¯3000 lib.AssertEq salesIdx ⊑ balanceAfterCollection
3000 lib.AssertEq bankIdx ⊑ balanceAfterCollection

•Out "test_bookkeeping_matrix_receivable.bqn: OK"
