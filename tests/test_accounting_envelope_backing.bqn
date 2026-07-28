#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src_next/loader.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
companion ← •Import "../src/ledger/companion_snapshot.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
envelopes ← •Import "../src/accounting/envelope_backing.bqn"
base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
lines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨lines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
companions ← companion.Build ⟨loader.ReadLines base∾"plan.tsv",loader.ReadLines base∾"budget_alloc.tsv",actual.accounts,registry⟩
result ← envelopes.Build ⟨companions.budget,actual,companions.plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨0⟩⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.envelopes.count
⟨60⟩ lib.AssertEq result.envelopes.entitlement
⟨30⟩ lib.AssertEq result.envelopes.actual_consumption
⟨0⟩ lib.AssertEq result.envelopes.actual_refunds
⟨30⟩ lib.AssertEq result.envelopes.ledger_remaining
⟨0⟩ lib.AssertEq result.envelopes.open_plan_reserve
⟨30⟩ lib.AssertEq result.envelopes.post_plan_headroom
965 lib.AssertEq result.totals.funding_balance
30 lib.AssertEq result.totals.backing_required
935 lib.AssertEq result.totals.backing_surplus
40 lib.AssertEq result.totals.ledger_unassigned
895 lib.AssertEq result.totals.reconciliation_delta
"backed" lib.AssertEq result.status
"actual.journal" lib.AssertEq (⊑result.funding_contributors).source
"budget_alloc.tsv" lib.AssertEq (⊑⊑result.envelopes.entitlement_contributors).source
"actual.journal" lib.AssertEq (⊑⊑result.envelopes.consumption_contributors).source
unavailable ← envelopes.Build ⟨companions.budget,actual,companions.plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨⟩⟩
"unavailable" lib.AssertEq unavailable.state
0 lib.AssertEq unavailable.envelopes.count
invalidFunding ← envelopes.Build ⟨companions.budget,actual,companions.plan,"JPY",dates.Ordinal "2026-01-01",dates.Ordinal "2026-02-01",dates.Ordinal "2026-01-12",⟨1⟩⟩
"error" lib.AssertEq invalidFunding.state
"funding_scope_invalid" lib.AssertEq (⊑invalidFunding.diagnostics).code
•Out "test_accounting_envelope_backing: ok"
