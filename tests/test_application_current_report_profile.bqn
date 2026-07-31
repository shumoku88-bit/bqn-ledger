#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
io ← •Import "../src/application/source_io.bqn"
route ← •Import "../src/application/report_route.bqn"
cycleResult ← •Import "../src/accounting/cycle_result.bqn"
profile ← •Import "../src/application/current_report_profile.bqn"

lines ← io.ReadLines "fixtures/ledger-facts-phase1-proof/report_all_human.destination.tsv"
fields ← io.SplitTsv¨1↓lines
rows ← {𝕊 row: {key⇐0⊑row,surface⇐1⊑row,arguments⇐2↓row}}¨fields
admissions ← {route.Admit ⟨𝕩.key,𝕩.surface,𝕩.arguments⟩}¨rows
(12⥊⟨"ok"⟩) lib.AssertEq {𝕩.state}¨admissions
FindAdmission ← {𝕊 key: (⊑(key⊸≡¨{𝕩.key}¨admissions)⊐1)⊑admissions}
⟨"domain","as_of","actual_source"⟩ lib.AssertEq (FindAdmission "balances").coordinate_role
⟨"domain","as_of","actual_source"⟩ lib.AssertEq (FindAdmission "balance-sheet").coordinate_role

profileSources ← profile.SourceNames admissions
"cycle.tsv" lib.AssertEq profileSources.current_cycle
"cycle.tsv" lib.AssertEq profileSources.comparison_current_cycle
"cycle_baseline.destination.tsv" lib.AssertEq profileSources.baseline_cycle
"plan.tsv" lib.AssertEq profileSources.plan
"aligned_elapsed" lib.AssertEq profile.ComparisonPolicy admissions

reorderedComparison ← {
  key⇐"cycle-comparison",
  coordinate_role⇐⟨"policy","domain"⟩,
  coordinates⇐⟨"role_selected","JPY"⟩
}
admissionsWithReorderedPolicy ← {
  𝕊 admitted: (admitted.key≡"cycle-comparison")⊑⟨admitted,reorderedComparison⟩
}¨admissions
"role_selected" lib.AssertEq profile.ComparisonPolicy admissionsWithReorderedPolicy

cycleAccountsWithPlan ← route.Admit ⟨
  "cycle-accounts","human",⟨"JPY","2026-01-12","actual.journal","cycle.tsv","cycle_plan.tsv"⟩
⟩
"ok" lib.AssertEq cycleAccountsWithPlan.state
admissionsWithCyclePlan ← {
  𝕊 admitted: (admitted.key≡"cycle-accounts")⊑⟨admitted,cycleAccountsWithPlan⟩
}¨admissions
"cycle_plan.tsv" lib.AssertEq (profile.SourceNames admissionsWithCyclePlan).plan

current ← cycleResult.Success ⟨"fixed","2026-01-12","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
baseline ← cycleResult.Success ⟨"fixed","2025-12-31","2025-12-22","2026-01-22",⟨⟩,⟨⟩⟩
result ← profile.Build ⟨admissions,"2026-01-12",current,baseline⟩

"ok" lib.AssertEq result.state
"2026-01-12" lib.AssertEq result.observation
⟨⟩ lib.AssertEq result.diagnostics
12 lib.AssertEq ≠result.rows

expectedKeys ← ⟨
  "envelopes","balances","balance-sheet","profit-and-loss","recent","planned",
  "cycle-accounts","cycle-comparison","monthly-accounts","daily-flow","daily-target","issues"
⟩
expectedKeys lib.AssertEq {𝕩.key}¨result.rows
(12⥊⟨"human"⟩) lib.AssertEq {𝕩.surface}¨result.rows

expectedArguments ← ⟨
  ⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal","plan.tsv","budget_alloc.tsv","assets:cash"⟩,
  ⟨"JPY","2026-01-12","actual.journal"⟩,
  ⟨"JPY","2026-01-12","actual.journal"⟩,
  ⟨"JPY","2026-01-01","2026-01-13","actual.journal"⟩,
  ⟨"10","actual.journal"⟩,
  ⟨"2026-01-12","actual.journal","plan.tsv","cycle.tsv"⟩,
  ⟨"JPY","2026-01-12","actual.journal","cycle.tsv"⟩,
  ⟨"JPY","2026-01-12","2026-01-02","aligned_elapsed","actual.journal","cycle.tsv","cycle_baseline.destination.tsv"⟩,
  ⟨"JPY","2026-01","2026-02","actual.journal"⟩,
  ⟨"JPY","2026-01-01","2026-02-01","2026-01-12","actual.journal"⟩,
  ⟨"JPY","2026-01-12","2026-01-22","actual.journal","daily_target_plan.destination.tsv","daily_target_scope.destination.tsv"⟩,
  ⟨"issues.destination.tsv"⟩
⟩
expectedArguments lib.AssertEq {𝕩.arguments}¨result.rows

# Planned observation follows its admitted role even when coordinates are rearranged.
reorderedPlanned ← {
  key⇐"planned",surface⇐"human",
  coordinate_role⇐⟨"actual_source","observation","plan_source","cycle_source"⟩,
  coordinates⇐⟨"actual.journal","stale-observation","plan.tsv","cycle.tsv"⟩
}
admissionsWithReorderedPlanned ← {
  𝕊 admitted: (admitted.key≡"planned")⊑⟨admitted,reorderedPlanned⟩
}¨admissions
reorderedPlannedResult ← profile.Build ⟨admissionsWithReorderedPlanned,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedPlannedResult.state
reorderedPlannedRow ← (⊑("planned"⊸≡¨{𝕩.key}¨reorderedPlannedResult.rows)⊐1)⊑reorderedPlannedResult.rows
⟨"actual.journal","2026-01-12","plan.tsv","cycle.tsv"⟩ lib.AssertEq reorderedPlannedRow.arguments

# Cycle Accounts observation follows its admitted role and preserves optional Plan coordinates.
reorderedCycleAccounts ← {
  key⇐"cycle-accounts",surface⇐"human",
  coordinate_role⇐⟨"actual_source","plan_source","domain","observation","cycle_source"⟩,
  coordinates⇐⟨"actual.journal","cycle_plan.tsv","JPY","stale-observation","cycle.tsv"⟩
}
admissionsWithReorderedCycleAccounts ← {
  𝕊 admitted: (admitted.key≡"cycle-accounts")⊑⟨admitted,reorderedCycleAccounts⟩
}¨admissions
reorderedCycleAccountsResult ← profile.Build ⟨admissionsWithReorderedCycleAccounts,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedCycleAccountsResult.state
reorderedCycleAccountsRow ← (⊑("cycle-accounts"⊸≡¨{𝕩.key}¨reorderedCycleAccountsResult.rows)⊐1)⊑reorderedCycleAccountsResult.rows
⟨"actual.journal","cycle_plan.tsv","JPY","2026-01-12","cycle.tsv"⟩ lib.AssertEq reorderedCycleAccountsRow.arguments

# Cycle Comparison observations follow separate admitted roles and preserve optional Plan coordinates.
reorderedCycleComparison ← {
  key⇐"cycle-comparison",surface⇐"human",
  coordinate_role⇐⟨
    "actual_source","baseline_observation","plan_source","domain",
    "policy","current_cycle_source","current_observation","baseline_cycle_source"
  ⟩,
  coordinates⇐⟨
    "actual.journal","stale-baseline","cycle_plan.tsv","JPY",
    "aligned_elapsed","cycle.tsv","stale-current","cycle_baseline.destination.tsv"
  ⟩
}
admissionsWithReorderedCycleComparison ← {
  𝕊 admitted: (admitted.key≡"cycle-comparison")⊑⟨admitted,reorderedCycleComparison⟩
}¨admissions
reorderedCycleComparisonResult ← profile.Build ⟨admissionsWithReorderedCycleComparison,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedCycleComparisonResult.state
reorderedCycleComparisonRow ← (⊑("cycle-comparison"⊸≡¨{𝕩.key}¨reorderedCycleComparisonResult.rows)⊐1)⊑reorderedCycleComparisonResult.rows
⟨
  "actual.journal","2026-01-02","cycle_plan.tsv","JPY",
  "aligned_elapsed","cycle.tsv","2026-01-12","cycle_baseline.destination.tsv"
⟩ lib.AssertEq reorderedCycleComparisonRow.arguments

# Profit and Loss period follows separate admitted roles and preserves domain and Actual source.
reorderedProfitAndLoss ← {
  key⇐"profit-and-loss",surface⇐"human",
  coordinate_role⇐⟨"actual_source","end_exclusive","domain","start"⟩,
  coordinates⇐⟨"actual.journal","stale-end","JPY","stale-start"⟩
}
admissionsWithReorderedProfitAndLoss ← {
  𝕊 admitted: (admitted.key≡"profit-and-loss")⊑⟨admitted,reorderedProfitAndLoss⟩
}¨admissions
reorderedProfitAndLossResult ← profile.Build ⟨admissionsWithReorderedProfitAndLoss,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedProfitAndLossResult.state
reorderedProfitAndLossRow ← (⊑("profit-and-loss"⊸≡¨{𝕩.key}¨reorderedProfitAndLossResult.rows)⊐1)⊑reorderedProfitAndLossResult.rows
⟨"actual.journal","2026-01-13","JPY","2026-01-01"⟩ lib.AssertEq reorderedProfitAndLossRow.arguments

# Daily Flow period and observation follow separate admitted roles and preserve domain and Actual source.
reorderedDailyFlow ← {
  key⇐"daily-flow",surface⇐"human",
  coordinate_role⇐⟨"actual_source","observation","domain","end_exclusive","start"⟩,
  coordinates⇐⟨"actual.journal","stale-observation","JPY","stale-end","stale-start"⟩
}
admissionsWithReorderedDailyFlow ← {
  𝕊 admitted: (admitted.key≡"daily-flow")⊑⟨admitted,reorderedDailyFlow⟩
}¨admissions
reorderedDailyFlowResult ← profile.Build ⟨admissionsWithReorderedDailyFlow,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedDailyFlowResult.state
reorderedDailyFlowRow ← (⊑("daily-flow"⊸≡¨{𝕩.key}¨reorderedDailyFlowResult.rows)⊐1)⊑reorderedDailyFlowResult.rows
⟨"actual.journal","2026-01-12","JPY","2026-02-01","2026-01-01"⟩ lib.AssertEq reorderedDailyFlowRow.arguments

# Daily Target observation follows its admitted role and preserves target and all source coordinates.
reorderedDailyTarget ← {
  key⇐"daily-target",surface⇐"human",
  coordinate_role⇐⟨"daily_scope_source","target","actual_source","domain","observation","plan_source"⟩,
  coordinates⇐⟨"daily_target_scope.destination.tsv","2026-01-22","actual.journal","JPY","stale-observation","daily_target_plan.destination.tsv"⟩
}
admissionsWithReorderedDailyTarget ← {
  𝕊 admitted: (admitted.key≡"daily-target")⊑⟨admitted,reorderedDailyTarget⟩
}¨admissions
reorderedDailyTargetResult ← profile.Build ⟨admissionsWithReorderedDailyTarget,"2026-01-12",current,baseline⟩
"ok" lib.AssertEq reorderedDailyTargetResult.state
reorderedDailyTargetRow ← (⊑("daily-target"⊸≡¨{𝕩.key}¨reorderedDailyTargetResult.rows)⊐1)⊑reorderedDailyTargetResult.rows
⟨"daily_target_scope.destination.tsv","2026-01-22","actual.journal","JPY","2026-01-12","daily_target_plan.destination.tsv"⟩ lib.AssertEq reorderedDailyTargetRow.arguments

# Year rollover changes only the volatile Monthly Accounts end-exclusive month.
yearEndCurrent ← cycleResult.Success ⟨"fixed","2026-12-31","2026-12-01","2027-01-15",⟨⟩,⟨⟩⟩
yearEndBaseline ← cycleResult.Success ⟨"fixed","2026-10-31","2026-10-01","2026-11-15",⟨⟩,⟨⟩⟩
yearEnd ← profile.Build ⟨admissions,"2026-12-31",yearEndCurrent,yearEndBaseline⟩
"ok" lib.AssertEq yearEnd.state
yearEndMonthly ← (⊑("monthly-accounts"⊸≡¨{𝕩.key}¨yearEnd.rows)⊐1)⊑yearEnd.rows
⟨"JPY","2026-01","2027-01","actual.journal"⟩ lib.AssertEq yearEndMonthly.arguments

# Every rejected profile remains fail-closed and publishes one bounded diagnostic.
CheckRejected ← {𝕊 observation‿currentCycle‿baselineCycle‿expectedCode:
  rejected ← profile.Build ⟨admissions,observation,currentCycle,baselineCycle⟩
  "error" lib.AssertEq rejected.state
  ⟨⟩ lib.AssertEq rejected.rows
  1 lib.AssertEq ≠rejected.diagnostics
  diagnostic ← ⊑rejected.diagnostics
  "error" lib.AssertEq diagnostic.severity
  "application_current_report_profile" lib.AssertEq diagnostic.stage
  expectedCode lib.AssertEq diagnostic.code
}

badCurrent ← cycleResult.Error ⟨"fixed","2026-01-12","fixture_current_error","fixture current error"⟩
badBaseline ← cycleResult.Error ⟨"fixed","2025-12-31","fixture_baseline_error","fixture baseline error"⟩
calendarCurrent ← cycleResult.Success ⟨"calendarMonth","2026-01-12","2026-01-01","2026-02-01",⟨⟩,⟨⟩⟩
notPrevious ← cycleResult.Success ⟨"fixed","2026-01-12","2026-01-01","2026-01-20",⟨⟩,⟨⟩⟩
shortBaseline ← cycleResult.Success ⟨"fixed","2025-12-31","2025-12-30","2026-01-02",⟨⟩,⟨⟩⟩

CheckRejected ⟨"not-a-date",current,baseline,"current_observation_invalid"⟩
CheckRejected ⟨"2026-01-12",badCurrent,baseline,"current_cycle_not_ok"⟩
CheckRejected ⟨"2026-01-12",current,badBaseline,"baseline_cycle_not_ok"⟩
CheckRejected ⟨"2026-01-12",calendarCurrent,baseline,"comparison_cycle_mode_mismatch"⟩
CheckRejected ⟨"2026-01-12",current,notPrevious,"baseline_cycle_not_previous"⟩
CheckRejected ⟨"2026-02-01",current,baseline,"current_observation_outside_cycle"⟩
CheckRejected ⟨"2026-01-12",current,shortBaseline,"aligned_baseline_unavailable"⟩

•Out "test_application_current_report_profile: ok"
