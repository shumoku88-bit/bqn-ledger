#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
recent ← •Import "../src/accounting/recent_transactions.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
lf ← @+10
baseRaw ← •FChars "../"∾base∾"actual.journal"

# Physical source order is deliberately not date order.
# The final four source Transactions are A(Jan20), B(Feb01), C(Jan14), D(Jan05).
# Recent must follow physical position, not sort by date.
orderedRaw ← ∾⟨
  baseRaw,lf,
  "2026-01-20 * physical A",lf,
  "    ; event-id: recent-physical-a",lf,
  "    ; layer: actual",lf,
  "    ; currency: JPY",lf,
  "    expenses:food 1 JPY",lf,
  "    assets:cash -1 JPY",lf,lf,
  "2026-02-01 * physical B",lf,
  "    ; event-id: recent-physical-b",lf,
  "    ; layer: actual",lf,
  "    ; currency: JPY",lf,
  "    expenses:transport 2 JPY",lf,
  "    assets:cash -2 JPY",lf,lf,
  "2026-01-14 * physical C split",lf,
  "    ; event-id: recent-physical-c",lf,
  "    ; layer: actual",lf,
  "    ; currency: JPY",lf,
  "    expenses:food 4 JPY",lf,
  "    expenses:transport 6 JPY",lf,
  "    assets:cash -10 JPY",lf,lf,
  "2026-01-05 * physical D",lf,
  "    ; event-id: recent-physical-d",lf,
  "    ; layer: actual",lf,
  "    ; currency: JPY",lf,
  "    expenses:food 3 JPY",lf,
  "    assets:cash -3 JPY",lf
⟩
facts ← (snapshot.Build ⟨accountLines,orderedRaw,registry⟩).facts
"ok" lib.AssertEq facts.state
Ids ← {𝕊 references: {𝕩.transaction_id}¨references}

# Build takes the final N physical Transactions and reverses that physical tail.
latest ← recent.Build ⟨facts,3⟩
"ok" lib.AssertEq latest.state
⟨"recent-physical-d","recent-physical-c","recent-physical-b"⟩ lib.AssertEq Ids latest.rows.transaction_reference
⟨"2026-01-05","2026-01-14","2026-02-01"⟩ lib.AssertEq latest.rows.date
⟨3,10,2⟩ lib.AssertEq latest.rows.coefficient
⟨
  ⟨"expenses:food"⟩,
  ⟨"expenses:food","expenses:transport"⟩,
  ⟨"expenses:transport"⟩
⟩ lib.AssertEq latest.rows.debit_accounts
debitContributorCounts ← {≠𝕩}¨latest.rows.debit_contributors
creditContributorCounts ← {≠𝕩}¨latest.rows.credit_contributors
⟨2,3,2⟩ lib.AssertEq debitContributorCounts+creditContributorCounts

# BuildThrough filters by date eligibility first, then keeps the same physical-tail law.
# A and B are after Jan15; among eligible rows the physical tail is C,D, reversed to D,C.
through ← recent.BuildThrough ⟨facts,dates.Ordinal "2026-01-15",2⟩
"ok" lib.AssertEq through.state
⟨"recent-physical-d","recent-physical-c"⟩ lib.AssertEq Ids through.rows.transaction_reference
⟨"2026-01-05","2026-01-14"⟩ lib.AssertEq through.rows.date
⟨3,10⟩ lib.AssertEq through.rows.coefficient
⟨⟨"expenses:food"⟩,⟨"expenses:food","expenses:transport"⟩⟩ lib.AssertEq through.rows.debit_accounts

•Out "test_accounting_recent_transactions_ordering: ok"
