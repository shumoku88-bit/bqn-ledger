#!/usr/bin/env bqn
# Integration witness: production report source and destination adapters carry the
# admitted Entitlement relation to Envelope Entitlement and Backing.

lib ← •Import "test_lib.bqn"
sources ← •Import "../src/application/report_source_adapter.bqn"
destination ← •Import "../src/application/report_destination.bqn"

base ← "fixtures/ledger-facts-phase1-proof"
registryResult ← sources.Registry "config/currencies.tsv"
"ok" lib.AssertEq registryResult.state
registry ← registryResult.registry
actualResult ← sources.CanonicalActual ⟨base,registry⟩
"ok" lib.AssertEq actualResult.state
actual ← actualResult.facts
companions ← sources.Companions ⟨base,actual.accounts,registry⟩
"ok" lib.AssertEq companions.state
"entitlement.journal" lib.AssertEq companions.entitlement.source_name
1 lib.AssertEq companions.entitlement.origins.count
1 lib.AssertEq companions.entitlement.transfers.count

evidence ← {
  registry⇐registry,actual⇐actual,plan⇐companions.plan,plan_retirements⇐companions.plan_retirements,
  entitlement⇐companions.entitlement,envelope_policy⇐companions.envelope_policy,
  household⇐companions.household,envelope_history⇐companions.envelope_history,issue_lines⇐⟨⟩
}
composition ← destination.Build ⟨0,⟨"JPY","2026-01-01","2026-02-01","2026-01-12"⟩,evidence⟩
"ok" lib.AssertEq composition.state
⟨60⟩ lib.AssertEq composition.result.envelopes.entitlement
"entitlement.journal" lib.AssertEq (⊑⊑composition.result.envelopes.entitlement_contributors).source

•Out "test_application_report_envelope_movement_wiring: ok"
