#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

# 1. Load and parse the prepaid insurance study journal profile
raw ← •FChars "../fixtures/bookkeeping-matrix-prepaid-insurance/profile.journal"
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

"event-insurance-prepaid-001" lib.AssertEq (0 ⊑ result.transactions).source_event_id
"event-insurance-recognition-001" lib.AssertEq (1 ⊑ result.transactions).source_event_id

# Verify posting counts, order, and signed deltas match the journal
expectedPostingCounts ← 2‿2
expectedPostingCounts lib.AssertEq {≠𝕩.postings}¨ result.transactions

prepaymentPostings ← (0 ⊑ result.transactions).postings
"assets:prepaid-insurance" lib.AssertEq (0 ⊑ prepaymentPostings).account_key
12000 lib.AssertEq (0 ⊑ prepaymentPostings).delta
"assets:bank" lib.AssertEq (1 ⊑ prepaymentPostings).account_key
¯12000 lib.AssertEq (1 ⊑ prepaymentPostings).delta

recognitionPostings ← (1 ⊑ result.transactions).postings
"expenses:insurance" lib.AssertEq (0 ⊑ recognitionPostings).account_key
1000 lib.AssertEq (0 ⊑ recognitionPostings).delta
"assets:prepaid-insurance" lib.AssertEq (1 ⊑ recognitionPostings).account_key
¯1000 lib.AssertEq (1 ⊑ recognitionPostings).delta


# 2. Event x Account matrix verification
matrixLines ← loader.ReadLines "fixtures/bookkeeping-matrix-prepaid-insurance/expected-event-account-matrix.tsv"
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
prepaidIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"assets:prepaid-insurance" ⟩
insuranceIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"expenses:insurance" ⟩

prepaymentRow ← 0 ⊑ actualMatrix
recognitionRow ← 1 ⊑ actualMatrix

# Prepayment moves bank into a prepaid asset without recognizing expense
¯12000 lib.AssertEq bankIdx ⊑ prepaymentRow
12000 lib.AssertEq prepaidIdx ⊑ prepaymentRow
0 lib.AssertEq insuranceIdx ⊑ prepaymentRow

# Expense recognition consumes prepaid asset without moving bank
0 lib.AssertEq bankIdx ⊑ recognitionRow
¯1000 lib.AssertEq prepaidIdx ⊑ recognitionRow
1000 lib.AssertEq insuranceIdx ⊑ recognitionRow


# 3. Running balances verification
balanceLines ← loader.ReadLines "fixtures/bookkeeping-matrix-prepaid-insurance/expected-running-balances.tsv"
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


# 4. Explicit balances and accounting preservation relation
balanceAfterPrepayment ← 0 ⊑ actualBalances
¯12000 lib.AssertEq bankIdx ⊑ balanceAfterPrepayment
12000 lib.AssertEq prepaidIdx ⊑ balanceAfterPrepayment
0 lib.AssertEq insuranceIdx ⊑ balanceAfterPrepayment

finalBalance ← ¯1 ⊑ actualBalances
¯12000 lib.AssertEq bankIdx ⊑ finalBalance
11000 lib.AssertEq prepaidIdx ⊑ finalBalance
1000 lib.AssertEq insuranceIdx ⊑ finalBalance

# Initial payment is allocated between unconsumed prepaid asset and recognized expense
12000 lib.AssertEq (prepaidIdx ⊑ finalBalance) + insuranceIdx ⊑ finalBalance

•Out "test_bookkeeping_matrix_prepaid_insurance.bqn: OK"
