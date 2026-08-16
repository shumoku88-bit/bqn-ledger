#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_journal_admission.bqn"
snapshot ← •Import "canonical_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
join ← •Import "../src/accounting/plan_completion_join.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accountSource ← •FChars "../"∾base∾"accounts.journal"
accounts ← (account_admission.Admit accountSource).accounts
lf ← @+10
Raw ← {𝕊 lines: ∾lines∾¨lf}
planRaw ← Raw ⟨
  "2026-01-20 food-plan",
  "  ; plan-id: plan-food-2026-01",
  "  expenses:food  25 JPY",
  "  assets:cash  -25 JPY"
⟩
planFacts ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
actualRaw ← •FChars "../"∾base∾"actual.journal"
BuildActualFacts ← {𝕊 raw: (snapshot.Build ⟨accountSource,raw,registry⟩).facts}
actualFacts ← BuildActualFacts actualRaw

startOrdinal ← dates.Ordinal "2026-01-01"
endOrdinal ← dates.Ordinal "2026-02-01"
planSelection ← ((planFacts.transactions.date_ordinal≥startOrdinal) ∧ planFacts.transactions.date_ordinal<endOrdinal)/planFacts.transactions.index
actualSelection ← ((actualFacts.transactions.date_ordinal≥startOrdinal) ∧ actualFacts.transactions.date_ordinal<endOrdinal)/actualFacts.transactions.index
completed ← join.Build ⟨planFacts,actualFacts,planSelection,actualSelection⟩
"ok" lib.AssertEq completed.state
1 lib.AssertEq completed.rows.count
⟨"completed"⟩ lib.AssertEq completed.rows.status
0 lib.AssertEq completed.counts.open
1 lib.AssertEq completed.counts.completed
⟨25⟩ lib.AssertEq completed.rows.planned_coefficient
⟨0⟩ lib.AssertEq completed.rows.planned_scale
⟨"assets:cash"⟩ lib.AssertEq completed.rows.planned_from_account
⟨"expenses:food"⟩ lib.AssertEq completed.rows.planned_to_account
⟨⟨20⟩⟩ lib.AssertEq completed.rows.actual_coefficients
⟨⟨0⟩⟩ lib.AssertEq completed.rows.actual_scales
⟨⟨"JPY"⟩⟩ lib.AssertEq completed.rows.actual_currencies
⟨⟨⟨"expenses:food"⟩⟩⟩ lib.AssertEq completed.rows.actual_debit_accounts
⟨⟨⟨"assets:cash"⟩⟩⟩ lib.AssertEq completed.rows.actual_credit_accounts
⟨⟨1⟩⟩ lib.AssertEq completed.rows.currency_matches
⟨⟨1⟩⟩ lib.AssertEq completed.rows.direction_matches
"plan.journal" lib.AssertEq (⊑completed.rows.plan_reference).source
"plan.journal:plan_id:plan-food-2026-01" lib.AssertEq (⊑completed.rows.plan_reference).transaction_id
"actual.journal" lib.AssertEq (⊑⊑completed.rows.actual_references).source
"proof-food-1" lib.AssertEq (⊑⊑completed.rows.actual_references).transaction_id
⟨⟩ lib.AssertEq completed.unmatched_actual_references

open ← join.Build ⟨planFacts,actualFacts,⟨0⟩,⟨0,2⟩⟩
⟨"open"⟩ lib.AssertEq open.rows.status
1 lib.AssertEq open.counts.open
⟨⟨⟩⟩ lib.AssertEq open.rows.actual_coefficients

DuplicateCompletion ← {𝕊 amountText:
  ∾⟨
    actualRaw,lf,"2026-01-10 * repeated completion",lf,
    "    ; event-id: proof-food-2",lf,
    "    ; layer: actual",lf,
    "    ; plan-id: plan-food-2026-01",lf,
    "    expenses:food ",amountText," JPY",lf,
    "    assets:cash -",amountText," JPY",lf
  ⟩
}
duplicateFacts ← BuildActualFacts DuplicateCompletion "20"
duplicate ← join.Build ⟨planFacts,duplicateFacts,⟨0⟩,duplicateFacts.transactions.index⟩
⟨"duplicate"⟩ lib.AssertEq duplicate.rows.status
1 lib.AssertEq duplicate.counts.duplicate
⟨⟨20,20⟩⟩ lib.AssertEq duplicate.rows.actual_coefficients

ambiguousFacts ← BuildActualFacts DuplicateCompletion "21"
ambiguous ← join.Build ⟨planFacts,ambiguousFacts,⟨0⟩,ambiguousFacts.transactions.index⟩
⟨"ambiguous"⟩ lib.AssertEq ambiguous.rows.status
1 lib.AssertEq ambiguous.counts.ambiguous
⟨⟨20,21⟩⟩ lib.AssertEq ambiguous.rows.actual_coefficients

unknownRaw ← ∾⟨
  actualRaw,lf,"2026-01-11 * unrelated completion",lf,
  "    ; event-id: unrelated-completion",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: other-plan",lf,
  "    expenses:food 7 JPY",lf,
  "    assets:cash -7 JPY",lf
⟩
unknownFacts ← BuildActualFacts unknownRaw
unknown ← join.Build ⟨planFacts,unknownFacts,⟨0⟩,unknownFacts.transactions.index⟩
"ok" lib.AssertEq unknown.state
1 lib.AssertEq ≠unknown.unmatched_actual_references
"unrelated-completion" lib.AssertEq (⊑unknown.unmatched_actual_references).transaction_id

ilsAccountSource ← Raw ⟨
  "account assets:ils","  type: Asset","  commodity: ILS","",
  "account expenses:ils","  type: Expense","  commodity: ILS"
⟩
ilsAccounts ← (account_admission.Admit ilsAccountSource).accounts
ilsPlanRaw ← Raw ⟨
  "2026-03-20 service",
  "  ; plan-id: ils-service",
  "  expenses:ils  12.30 ILS",
  "  assets:ils  -12.30 ILS"
⟩
ilsPlan ← (canonicalPlan.Build ⟨ilsPlanRaw,ilsAccounts,registry⟩).facts
ilsRaw ← ∾⟨
  "commodity ILS",lf,lf,
  "account assets:ils",lf,"    ; role: asset",lf,lf,
  "account expenses:ils",lf,"    ; role: expense",lf,lf,
  "2026-03-21 * service actual",lf,
  "    ; event-id: ils-service-actual",lf,
  "    ; layer: actual",lf,
  "    ; plan-id: ils-service",lf,
  "    expenses:ils 11.25 ILS",lf,
  "    assets:ils -11.25 ILS",lf
⟩
ilsActual ← (snapshot.Build ⟨ilsAccountSource,ilsRaw,registry⟩).facts
ilsJoined ← join.Build ⟨ilsPlan,ilsActual,⟨0⟩,⟨0⟩⟩
⟨123⟩ lib.AssertEq ilsJoined.rows.planned_coefficient
⟨1⟩ lib.AssertEq ilsJoined.rows.planned_scale
⟨⟨1125⟩⟩ lib.AssertEq ilsJoined.rows.actual_coefficients
⟨⟨2⟩⟩ lib.AssertEq ilsJoined.rows.actual_scales

selectionPlanFacts ← {state⇐"ok",sources⇐planFacts.sources,transactions⇐{index⇐⟨0,1⟩}}
duplicatePlanSelection ← join.Build ⟨selectionPlanFacts,actualFacts,⟨0,1,0⟩,⟨⟩⟩
"error" lib.AssertEq duplicatePlanSelection.state
0 lib.AssertEq duplicatePlanSelection.rows.count
0 lib.AssertEq duplicatePlanSelection.counts.completed
1 lib.AssertEq ≠duplicatePlanSelection.diagnostics
"plan_selection_duplicate" lib.AssertEq (⊑duplicatePlanSelection.diagnostics).code

duplicateActualSelection ← join.Build ⟨planFacts,actualFacts,⟨⟩,⟨0,1,0⟩⟩
"error" lib.AssertEq duplicateActualSelection.state
0 lib.AssertEq duplicateActualSelection.rows.count
0 lib.AssertEq duplicateActualSelection.counts.completed
1 lib.AssertEq ≠duplicateActualSelection.diagnostics
"actual_selection_duplicate" lib.AssertEq (⊑duplicateActualSelection.diagnostics).code

swapped ← join.Build ⟨actualFacts,planFacts,actualFacts.transactions.index,planFacts.transactions.index⟩
"error" lib.AssertEq swapped.state
0 lib.AssertEq swapped.rows.count

•Out "test_accounting_plan_completion_join: ok"
