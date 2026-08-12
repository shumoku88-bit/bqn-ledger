#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
account_admission ← •Import "../src/ledger/account_admission.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
cycle_admission ← •Import "../src/ledger/cycle_admission.bqn"
cycleSelection ← •Import "../src/application/cycle_resolution.bqn"
fixed_resolver ← •Import "../src/accounting/cycle_fixed_resolution.bqn"
calendar_resolver ← •Import "../src/accounting/cycle_calendar_month_resolution.bqn"
income_resolver ← •Import "../src/accounting/cycle_income_anchor_resolution.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

base ← "fixtures/ledger-facts-phase1-proof/"
accountLines ← loader.ReadLines base∾"accounts.tsv"
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← (account_admission.Admit ⟨accountLines,registry⟩).accounts
actualFacts ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
lf ← @+10
tab ← @+9
Raw ← {𝕊 lines: ∾lines∾¨lf}
Join ← {𝕊 fields:
  out ← ⊑fields
  {𝕊 field: out∾↩tab∾field}¨1↓fields
  out
}

fixedAdmission ← cycle_admission.Admit ⟨loader.ReadLines base∾"cycle.tsv",accounts⟩
fixed ← fixed_resolver.Resolve fixedAdmission
"ok" lib.AssertEq fixed.state
"fixed" lib.AssertEq fixed.mode
"2026-01-01" lib.AssertEq fixed.start
"2026-02-01" lib.AssertEq fixed.end_exclusive
31 lib.AssertEq fixed.day_count
⟨⟩ lib.AssertEq fixed.start_contributors

calendarAdmission ← cycle_admission.Admit ⟨⟨Join ⟨"mode","calendarMonth"⟩,Join ⟨"start_day","25"⟩⟩,accounts⟩
calendarBefore ← calendar_resolver.Resolve ⟨calendarAdmission,"2026-01-10"⟩
"ok" lib.AssertEq calendarBefore.state
"2025-12-25" lib.AssertEq calendarBefore.start
"2026-01-25" lib.AssertEq calendarBefore.end_exclusive
31 lib.AssertEq calendarBefore.day_count
calendarOn ← calendar_resolver.Resolve ⟨calendarAdmission,"2026-01-25"⟩
"2026-01-25" lib.AssertEq calendarOn.start
"2026-02-25" lib.AssertEq calendarOn.end_exclusive
"error" lib.AssertEq (calendar_resolver.Resolve ⟨calendarAdmission,"2026-02-30"⟩).state

planRaw ← Raw ⟨
  "2026-02-01 next-income",
  "  ; plan-id: income-next",
  "  income:salary  -1000 JPY",
  "  assets:cash  1000 JPY"
⟩
planFacts ← (canonicalPlan.Build ⟨planRaw,accounts,registry⟩).facts
incomeAdmission ← cycle_admission.Admit ⟨
  ⟨Join ⟨"mode","incomeAnchor"⟩,Join ⟨"income_account","income:salary"⟩,Join ⟨"offset","0"⟩⟩,
  accounts
⟩
income ← income_resolver.Resolve ⟨incomeAdmission,"2026-01-12",actualFacts,planFacts⟩
"ok" lib.AssertEq income.state
"incomeAnchor" lib.AssertEq income.mode
"2026-01-02" lib.AssertEq income.start
"2026-02-01" lib.AssertEq income.end_exclusive
30 lib.AssertEq income.day_count
⟨"actual.journal"⟩ lib.AssertEq {𝕩.source}¨income.start_contributors
⟨"proof-salary-1"⟩ lib.AssertEq {𝕩.transaction_id}¨income.start_contributors
⟨"plan.journal"⟩ lib.AssertEq {𝕩.source}¨income.end_contributors
⟨"plan.journal:plan_id:income-next"⟩ lib.AssertEq {𝕩.transaction_id}¨income.end_contributors

# Application resolver selection stays aligned with the admitted mode axis.
selectedFixed ← cycleSelection.WithPlan ⟨fixedAdmission,"2026-01-12",actualFacts,planFacts⟩
"fixed" lib.AssertEq selectedFixed.mode
fixed.start lib.AssertEq selectedFixed.start
fixed.end_exclusive lib.AssertEq selectedFixed.end_exclusive
selectedCalendar ← cycleSelection.WithPlan ⟨calendarAdmission,"2026-01-10",actualFacts,planFacts⟩
"calendarMonth" lib.AssertEq selectedCalendar.mode
calendarBefore.start lib.AssertEq selectedCalendar.start
calendarBefore.end_exclusive lib.AssertEq selectedCalendar.end_exclusive
selectedIncome ← cycleSelection.WithPlan ⟨incomeAdmission,"2026-01-12",actualFacts,planFacts⟩
income.start lib.AssertEq selectedIncome.start
income.end_exclusive lib.AssertEq selectedIncome.end_exclusive
{𝕩.source}¨income.start_contributors lib.AssertEq {𝕩.source}¨selectedIncome.start_contributors
{𝕩.transaction_id}¨income.start_contributors lib.AssertEq {𝕩.transaction_id}¨selectedIncome.start_contributors
{𝕩.source}¨income.end_contributors lib.AssertEq {𝕩.source}¨selectedIncome.end_contributors
{𝕩.transaction_id}¨income.end_contributors lib.AssertEq {𝕩.transaction_id}¨selectedIncome.end_contributors

# Explicit observation excludes later Actual transactions from the frontier.
incomeAtJan10 ← income_resolver.Resolve ⟨incomeAdmission,"2026-01-10",actualFacts,planFacts⟩
"ok" lib.AssertEq incomeAtJan10.state
"2026-01-02" lib.AssertEq incomeAtJan10.start
"unavailable" lib.AssertEq (income_resolver.Resolve ⟨incomeAdmission,"2026-01-01",actualFacts,planFacts⟩).state
"actual_observation_missing" lib.AssertEq (income_resolver.Resolve ⟨incomeAdmission,"2026-01-01",actualFacts,planFacts⟩).reason

emptyPlanFacts ← (canonicalPlan.Build ⟨"",accounts,registry⟩).facts
noPlan ← income_resolver.Resolve ⟨incomeAdmission,"2026-01-12",actualFacts,emptyPlanFacts⟩
"unavailable" lib.AssertEq noPlan.state
"planned_income_anchor_missing" lib.AssertEq noPlan.reason
⟨⟩ lib.AssertEq noPlan.start_ordinal
⟨⟩ lib.AssertEq noPlan.day_count

wrongSource ← income_resolver.Resolve ⟨incomeAdmission,"2026-01-12",planFacts,actualFacts⟩
"error" lib.AssertEq wrongSource.state
"actual_facts_invalid" lib.AssertEq (⊑wrongSource.diagnostics).code

"2000-02-29" lib.AssertEq dates.FromParts dates.Parts "2000-02-29"
•Out "test_accounting_cycle_resolution: ok"
