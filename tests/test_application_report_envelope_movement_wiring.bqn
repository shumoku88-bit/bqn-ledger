#!/usr/bin/env bqn
# Integration witness: production report source and destination adapters carry the
# admitted Budget movement relation to Envelope Entitlement. Generic Budget Facts
# exist on Companions but are deliberately absent from this report evidence value.

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
"budget.journal" lib.AssertEq companions.budget_movements.source_name
2 lib.AssertEq ≠companions.budget_movements.transactions
2 lib.AssertEq companions.budget.transactions.count

evidenceWithoutBudgetFacts ← {
  registry⇐registry,actual⇐actual,plan⇐companions.plan,plan_retirements⇐companions.plan_retirements,
  budget_movements⇐companions.budget_movements,budget_policy⇐companions.budget_policy,
  household⇐companions.household,envelope_history⇐companions.envelope_history,issue_lines⇐⟨⟩
}
composition ← destination.Build ⟨0,⟨"JPY","2026-01-01","2026-02-01","2026-01-12"⟩,evidenceWithoutBudgetFacts⟩
"ok" lib.AssertEq composition.state
⟨60⟩ lib.AssertEq composition.result.envelopes.entitlement
"budget.journal" lib.AssertEq (⊑⊑composition.result.envelopes.entitlement_contributors).source

•Out "test_application_report_envelope_movement_wiring: ok"
