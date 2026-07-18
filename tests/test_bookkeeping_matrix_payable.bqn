#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
loader ← •Import "../src_next/loader.bqn"
util ← •Import "../src_next/util.bqn"

# 1. Load and parse the payable study journal profile
raw ← •FChars "../fixtures/bookkeeping-matrix-payable/profile.journal"
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

"event-maintenance-payable-001" lib.AssertEq (0 ⊑ result.transactions).source_event_id
"event-payable-payment-001" lib.AssertEq (1 ⊑ result.transactions).source_event_id

# Verify postings count and order matches journal
expectedPostingCounts ← 2‿2
expectedPostingCounts lib.AssertEq {≠𝕩.postings}¨ result.transactions

# Service expense incurred transaction postings
t0_postings ← (0 ⊑ result.transactions).postings
"expenses:maintenance" lib.AssertEq (0 ⊑ t0_postings).account_key
2400 lib.AssertEq (0 ⊑ t0_postings).delta
"liabilities:accounts-payable" lib.AssertEq (1 ⊑ t0_postings).account_key
¯2400 lib.AssertEq (1 ⊑ t0_postings).delta

# Payable paid transaction postings
t1_postings ← (1 ⊑ result.transactions).postings
"liabilities:accounts-payable" lib.AssertEq (0 ⊑ t1_postings).account_key
2400 lib.AssertEq (0 ⊑ t1_postings).delta
"assets:bank" lib.AssertEq (1 ⊑ t1_postings).account_key
¯2400 lib.AssertEq (1 ⊑ t1_postings).delta


# 2. Event x Account matrix verification
matrixLines ← loader.ReadLines "fixtures/bookkeeping-matrix-payable/expected-event-account-matrix.tsv"
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
payableIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"liabilities:accounts-payable" ⟩
maintenanceIdx ← ⊑ matrixAccountKeys ⊐ ⟨ <"expenses:maintenance" ⟩

# Verify 0-cells in specific events
0 lib.AssertEq bankIdx ⊑ (0 ⊑ actualMatrix)        # No bank movement during service incurrence
0 lib.AssertEq maintenanceIdx ⊑ (1 ⊑ actualMatrix) # No new expense recognized during payment

# Verify sign rules in specific events
¯2400 lib.AssertEq payableIdx ⊑ (0 ⊑ actualMatrix)  # Liabilities increase = Negative
2400 lib.AssertEq payableIdx ⊑ (1 ⊑ actualMatrix)   # Liabilities decrease = Positive


# 3. Running Balances verification
balanceLines ← loader.ReadLines "fixtures/bookkeeping-matrix-payable/expected-running-balances.tsv"
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
¯2400 lib.AssertEq bankIdx ⊑ finalBalance
0 lib.AssertEq payableIdx ⊑ finalBalance
2400 lib.AssertEq maintenanceIdx ⊑ finalBalance

# Assert explicit invariants:
# 1. Accounts payable is -2400 after expense incurrence, 0 after payment
# 2. Maintenance expense remains 2400 after both events
# 3. Bank remains 0 after expense incurrence, -2400 after payment
balanceAfterIncurrence ← 0 ⊑ actualBalances
0 lib.AssertEq bankIdx ⊑ balanceAfterIncurrence
¯2400 lib.AssertEq payableIdx ⊑ balanceAfterIncurrence
2400 lib.AssertEq maintenanceIdx ⊑ balanceAfterIncurrence

balanceAfterPayment ← 1 ⊑ actualBalances
¯2400 lib.AssertEq bankIdx ⊑ balanceAfterPayment
0 lib.AssertEq payableIdx ⊑ balanceAfterPayment
2400 lib.AssertEq maintenanceIdx ⊑ balanceAfterPayment

•Out "test_bookkeeping_matrix_payable.bqn: OK"
