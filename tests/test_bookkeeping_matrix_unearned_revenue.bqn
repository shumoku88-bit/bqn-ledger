#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

# 1. Load and parse the unearned revenue study journal profile
raw ← •FChars "../fixtures/bookkeeping-matrix-unearned-revenue/profile.journal"
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

"event-maintenance-advance-001" lib.AssertEq (0 ⊑ result.transactions).source_event_id
"event-maintenance-recognition-001" lib.AssertEq (1 ⊑ result.transactions).source_event_id

# Verify posting counts, order, account keys, and signed deltas match the journal
expectedPostingCounts ← 2‿2
expectedPostingCounts lib.AssertEq {≠𝕩.postings}¨ result.transactions

advancePostings ← (0 ⊑ result.transactions).postings
"assets:bank" lib.AssertEq (0 ⊑ advancePostings).account_key
12000 lib.AssertEq (0 ⊑ advancePostings).delta
"liabilities:unearned-revenue" lib.AssertEq (1 ⊑ advancePostings).account_key
¯12000 lib.AssertEq (1 ⊑ advancePostings).delta

recognitionPostings ← (1 ⊑ result.transactions).postings
"liabilities:unearned-revenue" lib.AssertEq (0 ⊑ recognitionPostings).account_key
1000 lib.AssertEq (0 ⊑ recognitionPostings).delta
"income:maintenance" lib.AssertEq (1 ⊑ recognitionPostings).account_key
¯1000 lib.AssertEq (1 ⊑ recognitionPostings).delta


# 2. Event x Account matrix verification
matrixLines ← loader.ReadLines "fixtures/bookkeeping-matrix-unearned-revenue/expected-event-account-matrix.tsv"
matrixHeader ← loader.SplitTsvKeepEmpty ⊑ matrixLines
matrixAccountKeys ← <¨ 2 ↓ ¯1 ↓ matrixHeader

expectedMatrix ← {
  fields ← loader.SplitTsvKeepEmpty 𝕩
  util.ToNum¨ 2 ↓ ¯1 ↓ fields
}¨ 1 ↓ matrixLines

actualMatrix ← parser.BuildMatrix ⟨result.transactions, matrixAccountKeys⟩
expectedMatrix lib.AssertEq actualMatrix

# Every event is zero-sum
{0 lib.AssertEq +´ 𝕩}¨ actualMatrix

# Resolve account column indexes
bankIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"assets:bank" ⟩
unearnedIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"liabilities:unearned-revenue" ⟩
maintenanceIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"income:maintenance" ⟩

advanceRow ← 0 ⊑ actualMatrix
recognitionRow ← 1 ⊑ actualMatrix

# Advance receipt increases bank and unearned liability without recognizing revenue
12000 lib.AssertEq bankIdx ⊑ advanceRow
¯12000 lib.AssertEq unearnedIdx ⊑ advanceRow
0 lib.AssertEq maintenanceIdx ⊑ advanceRow

# Revenue recognition reduces the liability and recognizes revenue without moving bank
0 lib.AssertEq bankIdx ⊑ recognitionRow
1000 lib.AssertEq unearnedIdx ⊑ recognitionRow
¯1000 lib.AssertEq maintenanceIdx ⊑ recognitionRow


# 3. Running balances verification
balanceLines ← loader.ReadLines "fixtures/bookkeeping-matrix-unearned-revenue/expected-running-balances.tsv"
balanceHeader ← loader.SplitTsvKeepEmpty ⊑ balanceLines
balanceAccountKeys ← <¨ 1 ↓ balanceHeader
balanceAccountKeys lib.AssertEq matrixAccountKeys

expectedBalances ← {
  fields ← loader.SplitTsvKeepEmpty 𝕩
  util.ToNum¨ 1 ↓ fields
}¨ 1 ↓ balanceLines

# Derive running balances from the event matrix using BQN scan
actualBalances ← +` actualMatrix
expectedBalances lib.AssertEq actualBalances

# Each running-balance row remains zero-sum
{0 lib.AssertEq +´ 𝕩}¨ actualBalances


# 4. Explicit balances and accounting preservation relations
balanceAfterAdvance ← 0 ⊑ actualBalances
12000 lib.AssertEq bankIdx ⊑ balanceAfterAdvance
¯12000 lib.AssertEq unearnedIdx ⊑ balanceAfterAdvance
0 lib.AssertEq maintenanceIdx ⊑ balanceAfterAdvance

finalBalance ← ¯1 ⊑ actualBalances
12000 lib.AssertEq bankIdx ⊑ finalBalance
¯11000 lib.AssertEq unearnedIdx ⊑ finalBalance
¯1000 lib.AssertEq maintenanceIdx ⊑ finalBalance

unearnedFinal ← unearnedIdx ⊑ finalBalance
maintenanceFinal ← maintenanceIdx ⊑ finalBalance

# Signed and unsigned preservation of the original 12,000 JPY receipt
¯12000 lib.AssertEq unearnedFinal + maintenanceFinal
12000 lib.AssertEq (0 - unearnedFinal) + (0 - maintenanceFinal)
0 lib.AssertEq +´ finalBalance

# Timing separation remains explicit in both matrix and running-balance evidence
0 lib.AssertEq maintenanceIdx ⊑ advanceRow
0 lib.AssertEq bankIdx ⊑ recognitionRow

•Out "test_bookkeeping_matrix_unearned_revenue.bqn: OK"
