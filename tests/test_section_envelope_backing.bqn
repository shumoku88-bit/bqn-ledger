#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
companion ← •Import "../src/ledger/companion_snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
accounting ← •Import "../src/accounting/envelope_backing.bqn"
section ← •Import "../src/sections/envelope_backing.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
companions ← companion.Build ⟨loader.ReadLines base∾"plan.tsv",loader.ReadLines base∾"budget_alloc.tsv",actual.accounts,registry⟩
statement ← accounting.Build ⟨companions.budget,actual,companions.plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨0⟩⟩
result ← section.Build ⟨statement,"2026-01-01","2026-02-01","2026-01-12"⟩
"ok" lib.AssertEq result.state
"backed" lib.AssertEq result.status
1 lib.AssertEq result.envelopes.count
30 lib.AssertEq result.totals.signed_envelope_total
(•FChars "../"∾base∾"envelope_backing.destination.human.txt") lib.AssertEq section.FormatHuman result
(•FChars "../"∾base∾"envelope_backing.destination.compact.txt") lib.AssertEq section.FormatCompact result
(•FChars "../"∾base∾"envelope_backing.destination.json") lib.AssertEq section.FormatJson result
underStatement ← {
  state⇐"ok",reason⇐"",domain⇐statement.domain,start_ordinal⇐statement.start_ordinal,
  end_exclusive_ordinal⇐statement.end_exclusive_ordinal,observation_ordinal⇐statement.observation_ordinal,
  scale⇐statement.scale,status⇐"under_backed",envelopes⇐statement.envelopes,
  totals⇐{
    entitlement⇐statement.totals.entitlement,actual_consumption⇐statement.totals.actual_consumption,
    actual_refunds⇐statement.totals.actual_refunds,ledger_remaining⇐statement.totals.ledger_remaining,
    open_plan_reserve⇐statement.totals.open_plan_reserve,post_plan_headroom⇐statement.totals.post_plan_headroom,
    funding_balance⇐¯1,signed_envelope_total⇐statement.totals.signed_envelope_total,
    backing_required⇐statement.totals.backing_required,backing_surplus⇐¯31,
    ledger_unassigned⇐statement.totals.ledger_unassigned,reconciliation_delta⇐¯71
  },funding_account_indices⇐statement.funding_account_indices,
  funding_contributors⇐statement.funding_contributors,unassigned_contributors⇐statement.unassigned_contributors,
  diagnostics⇐⟨⟩
}
under ← section.Build ⟨underStatement,"2026-01-01","2026-02-01","2026-01-12"⟩
lib.Assert ∨´"Status: under_backed"⍷section.FormatHuman under
lib.Assert ∨´"ledger_envelope_status: under_backed"⍷section.FormatCompact under
lib.Assert ∨´"under_backed"⍷section.FormatJson under

rejected ← section.Build ⟨statement,"2026-01-01","2026-02-01","2026-01-11"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.envelopes.count
•Out "test_section_envelope_backing: ok"
