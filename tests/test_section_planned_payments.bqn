#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
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
planRaw ← •FChars "../"∾base∾"plan.journal"
planFacts ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
cycle ← fixed_cycle.Resolve cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩

# Base proof fixture test
result ← section.Build ⟨planFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq result.state
2 lib.AssertEq result.rows.count
⟨"future","future"⟩ lib.AssertEq result.rows.status
⟨"current_cycle","future_cycles"⟩ lib.AssertEq result.rows.time_group
⟨"2026-01-15","2026-02-01"⟩ lib.AssertEq result.rows.date
⟨"food","salary"⟩ lib.AssertEq result.rows.category
⟨"rent","next-income"⟩ lib.AssertEq result.rows.memo
⟨200,1000⟩ lib.AssertEq result.rows.planned_coefficient
⟨0,0⟩ lib.AssertEq result.rows.planned_scale
⟨0⟩ lib.AssertEq result.current_cycle_indices
⟨1⟩ lib.AssertEq result.future_cycle_indices
⟨⟩ lib.AssertEq result.overdue_indices
200 lib.AssertEq result.current_cycle_total_coefficient
1000 lib.AssertEq result.future_cycles_total_coefficient
0 lib.AssertEq result.overdue_total_coefficient
200 lib.AssertEq result.due_through_cycle_total_coefficient
"plan.journal" lib.AssertEq (0⊑result.rows.plan_reference).source
"plan.journal" lib.AssertEq (1⊑result.rows.plan_reference).source

human ← section.FormatHuman result
compact ← section.FormatCompact result
json ← section.FormatJson result
(loader.ReadRaw base∾"planned_payments.destination.human.txt") lib.AssertEq human
(loader.ReadRaw base∾"planned_payments.destination.compact.txt") lib.AssertEq compact
(loader.ReadRaw base∾"planned_payments.destination.json") lib.AssertEq json

# Empty plan facts
emptyPlanFacts ← (canonicalPlan.Build ⟨"",accounts,registry⟩).facts
emptyResult ← section.Build ⟨emptyPlanFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq emptyResult.state
0 lib.AssertEq emptyResult.rows.count
lib.Assert ∨´"""open_items"": []"⍷section.FormatJson emptyResult
lib.Assert ∨´"ledger_planned_payment: (none)"⍷section.FormatCompact emptyResult

# Cases A-D Qualification: Overdue, Current-cycle (overdue/due/future), and Future-cycles open plans
multiPlanRaw ← Raw ⟨
  "2025-12-25 overdue-past",
  "  ; plan-id: overdue-past",
  "  expenses:food  400 JPY",
  "  assets:cash  -400 JPY",
  "",
  "2026-01-05 current-past",
  "  ; plan-id: current-past",
  "  expenses:food  100 JPY",
  "  assets:cash  -100 JPY",
  "",
  "2026-01-12 current-due",
  "  ; plan-id: current-due",
  "  expenses:food  200 JPY",
  "  assets:cash  -200 JPY",
  "",
  "2026-01-20 current-future",
  "  ; plan-id: current-future",
  "  expenses:food  300 JPY",
  "  assets:cash  -300 JPY",
  "",
  "2026-02-15 future-plan",
  "  ; plan-id: future-plan",
  "  expenses:food  500 JPY",
  "  assets:cash  -500 JPY"
⟩
multiPlanFacts ← (canonicalPlan.Build ⟨multiPlanRaw,accounts,registry⟩).facts
multiResult ← section.Build ⟨multiPlanFacts,actualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq multiResult.state
5 lib.AssertEq multiResult.rows.count
⟨"overdue","overdue","due","future","future"⟩ lib.AssertEq multiResult.rows.status
⟨"overdue","current_cycle","current_cycle","current_cycle","future_cycles"⟩ lib.AssertEq multiResult.rows.time_group
⟨0⟩ lib.AssertEq multiResult.overdue_indices
⟨1,2,3⟩ lib.AssertEq multiResult.current_cycle_indices
⟨4⟩ lib.AssertEq multiResult.future_cycle_indices
400 lib.AssertEq multiResult.overdue_total_coefficient
600 lib.AssertEq multiResult.current_cycle_total_coefficient
1000 lib.AssertEq multiResult.due_through_cycle_total_coefficient
500 lib.AssertEq multiResult.future_cycles_total_coefficient

# Case E: Completed previous-cycle plan is excluded
pastCompletedPlanRaw ← Raw ⟨
  "2025-12-15 past-paid",
  "  ; plan-id: past-paid-1",
  "  expenses:food  50 JPY",
  "  assets:cash  -50 JPY"
⟩
pastCompletedActualRaw ← ∾⟨
  actualRaw,lf,"2025-12-15 * completed past plan",lf,
  "    ; event-id: proof-past-paid",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: past-paid-1",lf,
  "    expenses:food 50 JPY",lf,
  "    assets:cash -50 JPY",lf
⟩
pastCompletedPlanFacts ← (canonicalPlan.Build ⟨pastCompletedPlanRaw,accounts,registry⟩).facts
pastCompletedActualFacts ← (snapshot.Build ⟨accountLines,pastCompletedActualRaw,registry⟩).facts
pastResult ← section.Build ⟨pastCompletedPlanFacts,pastCompletedActualFacts,cycle,"2026-01-12"⟩
"ok" lib.AssertEq pastResult.state
0 lib.AssertEq pastResult.rows.count

# Case F: Duplicate / ambiguous completion fails closed
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

# Invalid observation check
badObservation ← section.Build ⟨planFacts,actualFacts,cycle,"2026-01-11"⟩
"error" lib.AssertEq badObservation.state
0 lib.AssertEq badObservation.rows.count
"observation_evidence_mismatch" lib.AssertEq (⊑badObservation.diagnostics).code

•Out "test_section_planned_payments: ok"
