#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "../src/ledger/snapshot.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
fixed_cycle ← •Import "../src/accounting/cycle_fixed_resolution.bqn"
section ← •Import "../src/sections/planned_payments.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
actualRaw ← •FChars "../"∾base∾"actual.journal"
actualFacts ← (snapshot.Build ⟨accountLines,actualRaw,registry⟩).facts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY"
⟩
planFacts ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
cycle ← fixed_cycle.Resolve cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩

result ← section.Build ⟨planFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq result.state
1 lib.AssertEq result.rows.count
⟨"completed"⟩ lib.AssertEq result.rows.status
⟨"2026-01-20"⟩ lib.AssertEq result.rows.date
⟨"food"⟩ lib.AssertEq result.rows.category
⟨"food-plan"⟩ lib.AssertEq result.rows.memo
⟨25⟩ lib.AssertEq result.rows.planned_coefficient
⟨0⟩ lib.AssertEq result.rows.planned_scale
⟨20⟩ lib.AssertEq result.rows.actual_coefficient
⟨0⟩ lib.AssertEq result.rows.actual_scale
⟨⟩ lib.AssertEq result.open_indices
⟨0⟩ lib.AssertEq result.completed_indices
0 lib.AssertEq result.open_total_coefficient
0 lib.AssertEq result.open_total_scale
"plan.journal" lib.AssertEq (⊑result.rows.plan_reference).source
"actual.journal" lib.AssertEq (⊑result.rows.actual_reference).source
4 lib.AssertEq ≠(⊑result.rows.planned_contributors)∾⊑result.rows.actual_contributors

human ← section.FormatHuman result
compact ← section.FormatCompact result
json ← section.FormatJson result
(loader.ReadRaw base∾"planned_payments.destination.human.txt") lib.AssertEq human
(loader.ReadRaw base∾"planned_payments.destination.compact.txt") lib.AssertEq compact
(loader.ReadRaw base∾"planned_payments.destination.json") lib.AssertEq json

emptyPlanFacts ← (canonicalPlan.Build ⟨"",accounts,registry⟩).facts
emptyResult ← section.Build ⟨emptyPlanFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.rows.count
lib.Assert ∨´"[]"⍷section.FormatJson emptyResult
lib.Assert ∨´"ledger_planned_payment: (none)"⍷section.FormatCompact emptyResult

# Temporal state is section-local and uses the latest selected Actual observation.
# Source order intentionally differs from date order. Presentation must dereference
# the joined canonical Plan transaction index, not the joined row ordinal.
openPlanRaw ← Raw ⟨
  "2026-01-20 future",
  "  ; plan-id: future",
  "  expenses:food  3 JPY",
  "  assets:cash  -3 JPY",
  "",
  "2026-01-05 past",
  "  ; plan-id: past",
  "  expenses:food  1 JPY",
  "  assets:cash  -1 JPY",
  "",
  "2026-01-12 today",
  "  ; plan-id: today",
  "  expenses:food  2 JPY",
  "  assets:cash  -2 JPY"
⟩
openPlanFacts ← (canonicalPlan.Build ⟨openPlanRaw,accounts,registry⟩).facts
openResult ← section.Build ⟨openPlanFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq openResult.state
⟨"overdue","due","future"⟩ lib.AssertEq openResult.rows.status
⟨"past","today","future"⟩ lib.AssertEq openResult.rows.memo
6 lib.AssertEq openResult.open_total_coefficient
⟨0,1,2⟩ lib.AssertEq openResult.open_indices
⟨⟩ lib.AssertEq openResult.completed_indices

badObservation ← section.Build ⟨planFacts,actualFacts,cycle,"2026-01-11"⟩
"error" lib.AssertEq badObservation.state
0 lib.AssertEq badObservation.rows.count
"observation_evidence_mismatch" lib.AssertEq (⊑badObservation.diagnostics).code

# A duplicate completion is explicit evidence, not another amount to sum.
duplicateRaw ← ∾⟨
  actualRaw,lf,"2026-01-10 * repeated completion",lf,
  "    ; event-id: proof-food-repeat",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: plan-food-2026-01",lf,
  "    expenses:food 20 JPY",lf,
  "    assets:cash -20 JPY",lf
⟩
duplicateActual ← (snapshot.Build ⟨accountLines,duplicateRaw,registry⟩).facts
duplicateResult ← section.Build ⟨planFacts,duplicateActual,cycle,"2026-01-12"⟩
"error" lib.AssertEq duplicateResult.state
0 lib.AssertEq duplicateResult.rows.count
lib.Assert ∨´"completion_duplicate"⊸≡¨{𝕩.code}¨duplicateResult.diagnostics

•Out "test_section_planned_payments: ok"
