#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
parser ← •Import "../src_next/journal_profile_stage1.bqn"
adapter ← •Import "../src_next/journal_posting_ir_stage2a.bqn"
carrier_module ← •Import "../src_next/journal_read_only_source_carrier.bqn"
ak ← •Import "../src_next/account_key.bqn"
cube ← •Import "../src_next/cube.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-split-purchase-characterization"
cycleStart ← "2026-08-01"
dayCount ← 31
layerAxis ← cube.layer_names

# 5.1 Fixture and registry assertions
accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines
accountAxis ← resolved.account_keys

7 lib.AssertEq resolved.count

expectedAccounts ← ⟨
  "assets:cash",
  "assets:bank",
  "expenses:tobacco",
  "expenses:coffee",
  "expenses:food:daily",
  "expenses:food:stock",
  "expenses:household"
⟩
expectedKeys ← ⟨
  "assets:cash/JPY",
  "assets:bank/JPY",
  "expenses:tobacco/JPY",
  "expenses:coffee/JPY",
  "expenses:food:daily/JPY",
  "expenses:food:stock/JPY",
  "expenses:household/JPY"
⟩
expectedAccounts lib.AssertEq resolved.accounts
expectedKeys lib.AssertEq resolved.account_keys

expectedRoles ← ⟨"asset", "asset", "expense", "expense", "expense", "expense", "expense"⟩
expectedRoles lib.AssertEq resolved.roles

# 5.2 Stage 1 assertions
raw ← •FChars ("../" ∾ base ∾ "/profile.journal")
parsed ← parser.Parse raw

"ok" lib.AssertEq parsed.state
0 lib.AssertEq ≠ parsed.diagnostics
3 lib.AssertEq ≠ parsed.transactions
⟨3, 3, 4⟩ lib.AssertEq ≠¨ {𝕩.postings}¨ parsed.transactions

# Transaction A
txA ← 0 ⊑ parsed.transactions
"2026-08-05" lib.AssertEq txA.date
"Convenience store" lib.AssertEq txA.description
'*' lib.AssertEq txA.status_marker
"actual" lib.AssertEq txA.layer_name
"physical_fallback" lib.AssertEq txA.identity_kind
⟨"expenses:tobacco", "expenses:coffee", "assets:cash"⟩ lib.AssertEq {𝕩.account_key}¨ txA.postings
⟨600, 150, ¯750⟩ lib.AssertEq {𝕩.delta}¨ txA.postings
⟨0, 1, 2⟩ lib.AssertEq {𝕩.posting_index}¨ txA.postings
0 lib.AssertEq +´ {𝕩.delta}¨ txA.postings

# Transaction B
txB ← 1 ⊑ parsed.transactions
"2026-08-06" lib.AssertEq txB.date
"Supermarket food split" lib.AssertEq txB.description
'*' lib.AssertEq txB.status_marker
"actual" lib.AssertEq txB.layer_name
"physical_fallback" lib.AssertEq txB.identity_kind
⟨"expenses:food:daily", "expenses:food:stock", "assets:bank"⟩ lib.AssertEq {𝕩.account_key}¨ txB.postings
⟨1400, 900, ¯2300⟩ lib.AssertEq {𝕩.delta}¨ txB.postings
⟨0, 1, 2⟩ lib.AssertEq {𝕩.posting_index}¨ txB.postings
0 lib.AssertEq +´ {𝕩.delta}¨ txB.postings

# Transaction C
txC ← 2 ⊑ parsed.transactions
"2026-08-07" lib.AssertEq txC.date
"Supermarket mixed purchase" lib.AssertEq txC.description
'*' lib.AssertEq txC.status_marker
"actual" lib.AssertEq txC.layer_name
"physical_fallback" lib.AssertEq txC.identity_kind
⟨"expenses:food:daily", "expenses:food:stock", "expenses:household", "assets:bank"⟩ lib.AssertEq {𝕩.account_key}¨ txC.postings
⟨1400, 900, 500, ¯2800⟩ lib.AssertEq {𝕩.delta}¨ txC.postings
⟨0, 1, 2, 3⟩ lib.AssertEq {𝕩.posting_index}¨ txC.postings
0 lib.AssertEq +´ {𝕩.delta}¨ txC.postings

# Invariant fallback identity checks
lib.Assert ∧´ {0 = +´ {"event-id" ≡ 𝕩.key}¨ 𝕩.metadata}¨ parsed.transactions
eventIds ← {𝕩.source_event_id}¨ parsed.transactions
lib.Assert ∧´ {0 < ≠ 𝕩}¨ eventIds
lib.Assert (0⊑eventIds) ≢ (1⊑eventIds)
lib.Assert (0⊑eventIds) ≢ (2⊑eventIds)
lib.Assert (1⊑eventIds) ≢ (2⊑eventIds)

# 5.3 Read-only carrier assertions
rawJournal ← loader.ReadRaw (base ∾ "/profile.journal")
journalLines ← (@+10) loader.SplitKeepEmpty rawJournal
carrier ← {
  source_file ⇐ "supplied-synthetic-split.journal",
  lines ⇐ journalLines
}
carrierResult ← carrier_module.Build ⟨carrier, resolved, cycleStart⟩

"ok" lib.AssertEq carrierResult.state
0 lib.AssertEq ≠ carrierResult.diagnostics
3 lib.AssertEq ≠ carrierResult.transactions
10 lib.AssertEq ≠ carrierResult.posting_rows
"supplied-synthetic-split.journal" lib.AssertEq carrierResult.source_file

# Check transactional identity/provenance retains order
⟨"Convenience store", "Supermarket food split", "Supermarket mixed purchase"⟩ lib.AssertEq {𝕩.description}¨ carrierResult.transactions
rows ← carrierResult.posting_rows
lib.Assert ∧´ {"ok" ≡ 𝕩.status}¨ rows
lib.Assert ∧´ {"profile.journal" ≡ 𝕩.source_file}¨ rows

# Standard 16-field check for each row
Assert16Fields ← {𝕊 row:
  lib.Assert 0 < ≠ row.source_file
  lib.Assert 0 ≤ row.source_row
  lib.Assert 0 < ≠ row.source_id
  lib.Assert 0 < ≠ row.tx_id
  lib.Assert 0 < ≠ row.posting_id
  lib.Assert 10 = ≠ row.date
  lib.Assert 0 ≤ row.day_index
  lib.Assert 0 < ≠ row.account_key
  lib.Assert 0 ≤ row.account_key_index
  lib.Assert 0 < ≠ row.layer_name
  lib.Assert 0 ≤ row.layer_index
  lib.Assert (row.side ≡ "debit") ∨ (row.side ≡ "credit")
  lib.Assert 0 ≢ row.delta
  lib.Assert 0 < ≠ row.kind
  lib.Assert row.status ≡ "ok"
  lib.Assert row.message ≡ ""
  1
}
lib.Assert ∧´ Assert16Fields¨ rows

# 5.4 Posting IR coordinate assertions
expectedRowAccounts ← ⟨
  "expenses:tobacco/JPY", "expenses:coffee/JPY", "assets:cash/JPY",
  "expenses:food:daily/JPY", "expenses:food:stock/JPY", "assets:bank/JPY",
  "expenses:food:daily/JPY", "expenses:food:stock/JPY", "expenses:household/JPY", "assets:bank/JPY"
⟩
expectedRowDeltas ← ⟨
  600, 150, ¯750,
  1400, 900, ¯2300,
  1400, 900, 500, ¯2800
⟩
expectedSides ← ⟨
  "debit", "debit", "credit",
  "debit", "debit", "credit",
  "debit", "debit", "debit", "credit"
⟩
expectedRowAccounts lib.AssertEq {𝕩.account_key}¨ rows
expectedRowDeltas lib.AssertEq {𝕩.delta}¨ rows
expectedSides lib.AssertEq {𝕩.side}¨ rows

# Transaction identification and grouping
txA_rows ← 3 ↑ rows
txB_rows ← 3 ↑ 3 ↓ rows
txC_rows ← 4 ↑ 6 ↓ rows

lib.Assert ∧´ { (⊑{𝕩.tx_id}¨txA_rows) ≡ 𝕩 }¨ {𝕩.tx_id}¨ txA_rows
lib.Assert ∧´ { (⊑{𝕩.tx_id}¨txB_rows) ≡ 𝕩 }¨ {𝕩.tx_id}¨ txB_rows
lib.Assert ∧´ { (⊑{𝕩.tx_id}¨txC_rows) ≡ 𝕩 }¨ {𝕩.tx_id}¨ txC_rows

idA ← (⊑txA_rows).tx_id
idB ← (⊑txB_rows).tx_id
idC ← (⊑txC_rows).tx_id
lib.Assert idA ≢ idB
lib.Assert idA ≢ idC
lib.Assert idB ≢ idC

3 lib.AssertEq ≠ txA_rows
3 lib.AssertEq ≠ txB_rows
4 lib.AssertEq ≠ txC_rows

0 lib.AssertEq +´ {𝕩.delta}¨ txA_rows
0 lib.AssertEq +´ {𝕩.delta}¨ txB_rows
0 lib.AssertEq +´ {𝕩.delta}¨ txC_rows

# 5.5 Aggregate account reduction assertions
GetTotalForAccount ← {𝕊 key:
  matches ← {𝕩.account_key ≡ key}¨ rows
  +´ 0 ∾ {𝕩.delta}¨ matches / rows
}

600 lib.AssertEq GetTotalForAccount "expenses:tobacco/JPY"
150 lib.AssertEq GetTotalForAccount "expenses:coffee/JPY"
2800 lib.AssertEq GetTotalForAccount "expenses:food:daily/JPY"
1800 lib.AssertEq GetTotalForAccount "expenses:food:stock/JPY"
500 lib.AssertEq GetTotalForAccount "expenses:household/JPY"
¯750 lib.AssertEq GetTotalForAccount "assets:cash/JPY"
¯5100 lib.AssertEq GetTotalForAccount "assets:bank/JPY"

0 lib.AssertEq +´ {𝕩.delta}¨ rows

# Expense total = 5850 (positive expense deltas)
# Note that row.kind is "expense" transaction-wide, so we verify using account roles
GetRoleForAccountKey ← {𝕊 key:
  idx ← ⊑ resolved.account_keys ⊐ ⟨key⟩
  idx ⊑ resolved.roles
}
expenseRows ← { (𝕩.delta > 0) ∧ ("expense" ≡ GetRoleForAccountKey 𝕩.account_key) }¨ rows
5850 lib.AssertEq +´ {𝕩.delta}¨ expenseRows / rows

# Payment total = -5850
paymentRows ← { ("asset" ≡ GetRoleForAccountKey 𝕩.account_key) }¨ rows
¯5850 lib.AssertEq +´ {𝕩.delta}¨ paymentRows / rows

# Cube Materialization checks
journalCube ← cube.Materialize ⟨rows, dayCount, resolved.count⟩
expectedShape ← ⟨dayCount, resolved.count, cube.layer_count⟩
expectedShape lib.AssertEq ≢ journalCube.cube

10 lib.AssertEq journalCube.valid_count
0 lib.AssertEq journalCube.skipped_count
0 lib.AssertEq ≠ journalCube.skipped_rows
5850 lib.AssertEq journalCube.actual_expense_total

expectedTotals ← ⟨
  ¯750,   # assets:cash/JPY
  ¯5100,  # assets:bank/JPY
  600,    # expenses:tobacco/JPY
  150,    # expenses:coffee/JPY
  2800,   # expenses:food:daily/JPY
  1800,   # expenses:food:stock/JPY
  500     # expenses:household/JPY
⟩
expectedTotals lib.AssertEq journalCube.actual_account_totals
⟨0, 0, 0, 0⟩ lib.AssertEq journalCube.layer_totals_vec

•Out "test_journal_split_purchase_transaction_characterization.bqn: OK"
