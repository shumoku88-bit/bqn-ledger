#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
sources ← •Import "../src/application/report_source_adapter.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

base ← "fixtures/ledger-facts-phase1-proof"
registryResult ← sources.Registry "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry
actual ← sources.CanonicalActual ⟨base,registry⟩
"ok" lib.AssertEq actual.state
companions ← sources.Companions ⟨base,actual.facts.accounts,registry⟩
"ok" lib.AssertEq companions.state

# The allocation is dated 2026-01-01 while the income-anchored Cycle starts on
# 2026-01-02. Entitlement is a Budget position, so opening allocation evidence
# must carry into the Cycle instead of disappearing from the statement.
result ← envelopes.Build ⟨
  companions.budget,companions.budget_policy,companions.household,
  actual.facts,companions.plan,"JPY",
  dates.Ordinal "2026-01-02",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12"
⟩
"ok" lib.AssertEq result.state
⟨60⟩ lib.AssertEq result.envelopes.entitlement
⟨30⟩ lib.AssertEq result.envelopes.actual_consumption
⟨30⟩ lib.AssertEq result.envelopes.ledger_remaining
30 lib.AssertEq result.totals.backing_required
935 lib.AssertEq result.totals.backing_surplus
40 lib.AssertEq result.totals.ledger_unassigned
895 lib.AssertEq result.totals.reconciliation_delta
"budget.journal" lib.AssertEq (⊑⊑result.envelopes.entitlement_contributors).source

•Out "test_accounting_envelope_backing_opening_position: ok"
