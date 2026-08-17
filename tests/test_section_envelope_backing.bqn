#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
entitlementAdmission ← •Import "../src/ledger/entitlement_journal_admission.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
envelopePolicyAdmission ← •Import "../src/ledger/envelope_policy_admission.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
accounting ← •Import "envelope_backing_test_adapter.bqn"
section ← •Import "../src/sections/envelope_backing.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
actual ← (snapshot.Build ⟨accountSource,•FChars "../"∾base∾"actual.journal",registry⟩).facts
planRaw ← •FChars "../"∾base∾"plan.journal"
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
policy ← envelopePolicyAdmission.Admit ⟨•FChars "../"∾base∾"envelope.toml",actual.accounts⟩
"ok" lib.AssertEq policy.state

history ← accounting.HistoryFor actual
entitlementRaw ← •FChars "../"∾base∾"entitlement.journal"
entitlement ← entitlementAdmission.Admit ⟨entitlementRaw,history,registry⟩
"ok" lib.AssertEq entitlement.state

statement ← accounting.Build ⟨entitlement,policy,actual,plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"⟩
result ← section.Build ⟨statement,"2026-01-01","2026-02-01","2026-01-12"⟩
"ok" lib.AssertEq result.state
"backed" lib.AssertEq result.status
1 lib.AssertEq result.origin.present
"2026-01-01" lib.AssertEq result.origin.date
"JPY" lib.AssertEq result.origin.commodity
"phase-one clean epoch" lib.AssertEq result.origin.memo
"entitlement.journal:line:1" lib.AssertEq result.origin.source_event_id
1 lib.AssertEq result.origin.source_line
1 lib.AssertEq result.envelopes.count
⟨"food"⟩ lib.AssertEq result.envelopes.envelope_id
30 lib.AssertEq result.totals.signed_envelope_total
0 lib.AssertEq result.totals.fulfillment
(•FChars "../"∾base∾"envelope_backing.destination.human.txt") lib.AssertEq section.FormatHuman result
(•FChars "../"∾base∾"envelope_backing.destination.compact.txt") lib.AssertEq section.FormatCompact result
(•FChars "../"∾base∾"envelope_backing.destination.json") lib.AssertEq section.FormatJson result
underStatement ← {
  state⇐"ok",reason⇐"",domain⇐statement.domain,start_ordinal⇐statement.start_ordinal,
  end_exclusive_ordinal⇐statement.end_exclusive_ordinal,observation_ordinal⇐statement.observation_ordinal,
  scale⇐statement.scale,status⇐"under_backed",envelopes⇐statement.envelopes,
  entitlement_observation⇐statement.entitlement_observation,
  totals⇐{
    entitlement⇐statement.totals.entitlement,actual_consumption⇐statement.totals.actual_consumption,
    actual_refunds⇐statement.totals.actual_refunds,fulfillment⇐statement.totals.fulfillment,ledger_remaining⇐statement.totals.ledger_remaining,
    commitment⇐statement.totals.commitment,post_plan_headroom⇐statement.totals.post_plan_headroom,
    funding_balance⇐¯1,signed_envelope_total⇐statement.totals.signed_envelope_total,
    backing_required⇐statement.totals.backing_required,backing_surplus⇐¯31
  },funding_account_indices⇐statement.funding_account_indices,
  funding_contributors⇐statement.funding_contributors,diagnostics⇐⟨⟩
}
under ← section.Build ⟨underStatement,"2026-01-01","2026-02-01","2026-01-12"⟩
lib.Assert ∨´"Status: under_backed"⍷section.FormatHuman under
lib.Assert ∨´"ledger_envelope_status: under_backed"⍷section.FormatCompact under
lib.Assert ∨´"under_backed"⍷section.FormatJson under

rejected ← section.Build ⟨statement,"2026-01-01","2026-02-01","2026-01-11"⟩
"error" lib.AssertEq rejected.state
0 lib.AssertEq rejected.envelopes.count
•Out "test_section_envelope_backing: ok"
