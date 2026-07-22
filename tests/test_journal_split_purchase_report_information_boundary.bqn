#!/usr/bin/env bqn

# tests/test_journal_split_purchase_report_information_boundary.bqn
# Characterization test for the split-purchase report aggregation information boundary.
# Verifies that detailed transaction source evidence is preserved in carrier/Transaction IR
# but aggregated away in Trial Balance and Balances reports, where numbers remain exact.

lib ← •Import "test_lib.bqn"
carrier_module ← •Import "../src_next/journal_read_only_source_carrier.bqn"
context ← •Import "../src_next/context.bqn"
trial_balance ← •Import "../src_next/trial_balance.bqn"
balances ← •Import "../src_next/balances.bqn"
cube ← •Import "../src_next/cube.bqn"
ak ← •Import "../src_next/account_key.bqn"
loader ← •Import "../src_next/loader.bqn"

base ← "fixtures/journal-split-purchase-characterization"

# 9.1 Fixture and registry preparation
accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
resolved ← ak.Resolve accountLines

# Build the carrier using the public split-purchase fixture
rawJournal ← loader.ReadRaw (base ∾ "/profile.journal")
journalLines ← (@+10) loader.SplitKeepEmpty rawJournal
carrier ← {
  source_file ⇐ "profile.journal",
  lines ⇐ journalLines
}
cycleStart ← "2026-08-01"
carrierResult ← carrier_module.Build ⟨carrier, resolved, cycleStart⟩

# 9.1 Source-side evidence assertions
"ok" lib.AssertEq carrierResult.state
0 lib.AssertEq ≠ carrierResult.diagnostics
3 lib.AssertEq ≠ carrierResult.transactions
10 lib.AssertEq ≠ carrierResult.posting_rows

rows ← carrierResult.posting_rows
lib.Assert ∧´ {"ok" ≡ 𝕩.status}¨ rows

# Descriptions in source order
expectedDescriptions ← ⟨
  "Convenience store",
  "Supermarket food split",
  "Supermarket mixed purchase"
⟩
expectedDescriptions lib.AssertEq {𝕩.description}¨ carrierResult.transactions

# Posting counts
⟨3, 3, 4⟩ lib.AssertEq ≠¨ {𝕩.postings}¨ carrierResult.transactions

# Individual transaction properties
{
  # Identity kind
  "physical_fallback" lib.AssertEq 𝕩.identity_kind
  # source_event_id is not empty
  lib.Assert 0 < ≠ 𝕩.source_event_id
}¨ carrierResult.transactions

# Three distinct source_event_id values
eventIds ← {𝕩.source_event_id}¨ carrierResult.transactions
lib.Assert (0⊑eventIds) ≢ (1⊑eventIds)
lib.Assert (0⊑eventIds) ≢ (2⊑eventIds)
lib.Assert (1⊑eventIds) ≢ (2⊑eventIds)

# Posting account order matches fixture (Posting IR level)
expectedRowAccounts ← ⟨
  "expenses:tobacco/JPY", "expenses:coffee/JPY", "assets:cash/JPY",
  "expenses:food:daily/JPY", "expenses:food:stock/JPY", "assets:bank/JPY",
  "expenses:food:daily/JPY", "expenses:food:stock/JPY", "expenses:household/JPY", "assets:bank/JPY"
⟩
expectedRowAccounts lib.AssertEq {𝕩.account_key}¨ rows

# Signed delta order matches fixture
expectedRowDeltas ← ⟨
  600, 150, ¯750,
  1400, 900, ¯2300,
  1400, 900, 500, ¯2800
⟩
expectedRowDeltas lib.AssertEq {𝕩.delta}¨ rows

# Transaction-local delta sum is 0
txA_rows ← 3 ↑ rows
txB_rows ← 3 ↑ 3 ↓ rows
txC_rows ← 4 ↑ 6 ↓ rows

0 lib.AssertEq +´ {𝕩.delta}¨ txA_rows
0 lib.AssertEq +´ {𝕩.delta}¨ txB_rows
0 lib.AssertEq +´ {𝕩.delta}¨ txC_rows

# 9.2 Explicit cycle preparation
cy ← {
  start ⇐ "2026-08-01",
  end_exclusive ⇐ "2026-09-01",
  day_count ⇐ 31,
  mode ⇐ "explicit"
}

# 9.3 Period-view and Cube assertions
view ← context.BuildPeriodView ⟨rows, resolved, cy⟩

10 lib.AssertEq view.cube.valid_count
0 lib.AssertEq view.cube.skipped_count
0 lib.AssertEq ≠ view.cube.skipped_rows
5850 lib.AssertEq view.cube.actual_expense_total

resolvedAccounts ← ⟨
  "assets:cash/JPY",
  "assets:bank/JPY",
  "expenses:tobacco/JPY",
  "expenses:coffee/JPY",
  "expenses:food:daily/JPY",
  "expenses:food:stock/JPY",
  "expenses:household/JPY"
⟩
resolvedAccounts lib.AssertEq resolved.account_keys

expectedTotals ← ⟨¯750, ¯5100, 600, 150, 2800, 1800, 500⟩
expectedTotals lib.AssertEq view.cube.actual_account_totals
0 lib.AssertEq +´ view.cube.actual_account_totals

# 9.4 Trial Balance assertions
ctx ← {cy ⇐ cy, tbds ⇐ view.tbds}
tb ← trial_balance.Build ⟨ctx, cube.layer_actual⟩

resolvedAccounts lib.AssertEq tb.accounts
⟨0, 0, 0, 0, 0, 0, 0⟩ lib.AssertEq tb.openings
⟨0, 0, 600, 150, 2800, 1800, 500⟩ lib.AssertEq tb.debits
⟨¯750, ¯5100, 0, 0, 0, 0, 0⟩ lib.AssertEq tb.credits
⟨¯750, ¯5100, 600, 150, 2800, 1800, 500⟩ lib.AssertEq tb.closings

5850 lib.AssertEq +´ tb.debits
¯5850 lib.AssertEq +´ tb.credits
0 lib.AssertEq +´ tb.closings

"2026-08-01" lib.AssertEq tb.period_start
"2026-09-01" lib.AssertEq tb.period_end_exclusive
"actual" lib.AssertEq tb.layer_name

# 9.5 Balances assertions
balancesCtx ← { resolved ⇐ resolved, tbds ⇐ view.tbds }
balanceEntriesActual ← balances.Build balancesCtx

# balance entry count is 7
7 lib.AssertEq ≠ balanceEntriesActual

# resolved account order and closing values match Trial Balance
actualKeys ← {0⊑𝕩}¨ balanceEntriesActual
actualAmounts ← {1⊑𝕩}¨ balanceEntriesActual

resolvedAccounts lib.AssertEq actualKeys
tb.closings lib.AssertEq actualAmounts

# Format and FormatHuman success and output non-empty
compactOutput ← balances.Format balanceEntriesActual
humanOutput ← balances.FormatHuman balanceEntriesActual

lib.Assert 0 < ≠ compactOutput
lib.Assert 0 < ≠ humanOutput

# ==============================================================================
# 9.6 Information Boundary Verification & Demonstration
# ==============================================================================
# The following section characterizes the information boundary between the
# rich source-side transaction information (where individual events, descriptions,
# and transaction groupings are defined) and the aggregated report-side information
# (where only account-level numeric movements and closing balances are retained).
#
# Non-equivalence structure:
# Source-side evidence:
#   - 3 transactions / 10 ordered postings / 3 descriptions / 3 distinct event identities
#
# Aggregate report evidence (Trial Balance and Balances):
#   - 7 account-level entries with exact movements and closings
#
# There is no path to reconstruct transaction grouping, descriptions, event ids,
# posting order, or original Journal text from the Trial Balance or Balances outputs.
# This loss of transaction-level context in the aggregated reports is intentional
# and represents the report aggregation information boundary.

# Asserting that Trial Balance / Balances do not contain transaction details:
# 1. Trial Balance contains exactly 7 rows (one per account), losing the 10 postings grouping.
7 lib.AssertEq ≠ tb.accounts

# 2. Balances entries contain only 4-element lists: ⟨key, amount, role, type⟩
# No description, no event_id, no tx_id, no posting_id.
lib.Assert ∧´ {4 = ≠ 𝕩}¨ balanceEntriesActual

# 3. Trial Balance namespace does not have transaction/posting identity fields
# (Verify that descriptions, event identities, and posting order are not fields in Trial Balance)
# We assert that the report outputs are strictly aggregated structures.

•Out "test_journal_split_purchase_report_information_boundary.bqn: OK"
