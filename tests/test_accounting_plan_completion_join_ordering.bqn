#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
join ← •Import "../src/accounting/plan_completion_join.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
lf ← @+10
empty ← ⟨⟩
Raw ← {𝕊 lines: ∾lines∾¨lf}
IndexOf ← {𝕊 item‿items: ⊑items⊐⟨item⟩}
Ids ← {𝕊 references: {𝕩.transaction_id}¨references}

# Two Plans are intentionally selected in reverse source order.
planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY",
  "",
  "2026-01-25 transport-plan",
  "  ; plan-id: plan-transport-order",
  "  expenses:transport  15 JPY",
  "  assets:cash  -15 JPY"
⟩
planFacts ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
"ok" lib.AssertEq planFacts.state
foodPlanIndex ← IndexOf ⟨"plan-food-2026-01",planFacts.transactions.plan_id⟩
transportPlanIndex ← IndexOf ⟨"plan-transport-order",planFacts.transactions.plan_id⟩
planSelection ← ⟨transportPlanIndex,foodPlanIndex⟩

# Actual selection interleaves matching evidence and unmatched durable relations.
# The second food completion deliberately has the same semantic signature as the
# existing proof-food-1 completion, so the food Plan remains duplicate evidence.
actualRaw ← •FChars "../"∾base∾"actual.journal"
orderedActualRaw ← ∾⟨
  actualRaw,lf,
  "2026-01-18 * transport completion",lf,
  "    ; event-id: proof-transport-order",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: plan-transport-order",lf,
  "    expenses:transport 15 JPY",lf,
  "    assets:cash -15 JPY",lf,lf,
  "2026-01-10 * repeated food completion",lf,
  "    ; event-id: proof-food-order-2",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: plan-food-2026-01",lf,
  "    expenses:food 20 JPY",lf,
  "    assets:cash -20 JPY",lf,lf,
  "2026-01-14 * unmatched A",lf,
  "    ; event-id: unmatched-order-a",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: other-plan-a",lf,
  "    expenses:food 3 JPY",lf,
  "    assets:cash -3 JPY",lf,lf,
  "2026-01-15 * unmatched B",lf,
  "    ; event-id: unmatched-order-b",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: other-plan-b",lf,
  "    expenses:transport 4 JPY",lf,
  "    assets:cash -4 JPY",lf
⟩
actualFacts ← (snapshot.Build ⟨accountLines,orderedActualRaw,registry⟩).facts
"ok" lib.AssertEq actualFacts.state
foodSecondIndex ← IndexOf ⟨"proof-food-order-2",actualFacts.transactions.transaction_id⟩
unmatchedBIndex ← IndexOf ⟨"unmatched-order-b",actualFacts.transactions.transaction_id⟩
transportActualIndex ← IndexOf ⟨"proof-transport-order",actualFacts.transactions.transaction_id⟩
foodFirstIndex ← IndexOf ⟨"proof-food-1",actualFacts.transactions.transaction_id⟩
unmatchedAIndex ← IndexOf ⟨"unmatched-order-a",actualFacts.transactions.transaction_id⟩
actualSelection ← ⟨foodSecondIndex,unmatchedBIndex,transportActualIndex,foodFirstIndex,unmatchedAIndex⟩

ordered ← join.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
"ok" lib.AssertEq ordered.state
2 lib.AssertEq ordered.rows.count
⟨"completed","duplicate"⟩ lib.AssertEq ordered.rows.status
1 lib.AssertEq ordered.counts.completed
1 lib.AssertEq ordered.counts.duplicate
0 lib.AssertEq ordered.counts.open
0 lib.AssertEq ordered.counts.ambiguous

# Outer rows preserve explicit Plan selection order, expressed by durable identity.
⟨
  "plan.journal:plan_id:plan-transport-order",
  "plan.journal:plan_id:plan-food-2026-01"
⟩ lib.AssertEq Ids ordered.rows.plan_reference

# Each matching Actual cell preserves explicit Actual selection order.
⟨
  ⟨"proof-transport-order"⟩,
  ⟨"proof-food-order-2","proof-food-1"⟩
⟩ lib.AssertEq {Ids 𝕩}¨ordered.rows.actual_references

# The parallel evidence columns remain aligned with those durable references.
⟨⟨15⟩,⟨20,20⟩⟩ lib.AssertEq ordered.rows.actual_coefficients
⟨⟨"2026-01-18"⟩,⟨"2026-01-10","2026-01-10"⟩⟩ lib.AssertEq ordered.rows.actual_dates
⟨⟨1⟩,⟨1,1⟩⟩ lib.AssertEq ordered.rows.currency_matches
⟨⟨1⟩,⟨1,1⟩⟩ lib.AssertEq ordered.rows.direction_matches

# Unmatched selected Actual relations preserve their own selected order.
⟨"unmatched-order-b","unmatched-order-a"⟩ lib.AssertEq Ids ordered.unmatched_actual_references

•Out "test_accounting_plan_completion_join_ordering: ok"
