#!/usr/bin/env bqn
lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registryBuilder ← •Import "../src/ledger/currency_registry.bqn"
snapshot ← •Import "legacy_snapshot_fixture.bqn"
canonicalPlan ← •Import "canonical_plan_test_facts.bqn"
admission ← •Import "../src/application/daily_scope_admission.bqn"
adapter ← •Import "../src/application/daily_scope_adapter.bqn"
compose ← •Import "../src/report/compose.bqn"
tab ← @+9
lf ← @+10
Join ← {𝕊 fields:
  out ← ⊑fields
  {𝕊 field:out∾↩tab∾field}¨1↓fields
  out
}
Raw ← {𝕊 lines: ∾lines∾¨lf}

base ← "fixtures/ledger-facts-phase1-proof/"
registry ← (registryBuilder.Build loader.ReadLines "config/currencies.tsv").registry
accountLines ← loader.ReadLines base∾"accounts.tsv"
actual ← (snapshot.Build ⟨accountLines,•FChars "../"∾base∾"actual.journal",registry⟩).facts
planRaw ← Raw ⟨
  "2026-01-15 rent",
  "  ; plan-id: plan-rent-daily-target",
  "  expenses:food  200 JPY",
  "  assets:cash  -200 JPY"
⟩
plan ← (canonicalPlan.Build ⟨planRaw,actual.accounts,registry⟩).facts
admitted ← admission.Admit ⟨loader.ReadLines base∾"daily_target_scope.destination.tsv",registry⟩
"ok" lib.AssertEq admitted.state
2 lib.AssertEq admitted.rows.count
scope ← adapter.Build ⟨admitted,actual,plan,"JPY","2026-01-12","2026-01-22"⟩
"ok" lib.AssertEq scope.state
1 lib.AssertEq ≠scope.asset_scope.rows
1 lib.AssertEq ≠scope.obligation_scope.rows
965 lib.AssertEq (⊑scope.asset_scope.rows).coefficient
200 lib.AssertEq (⊑scope.obligation_scope.rows).coefficient
50 lib.AssertEq (⊑scope.obligation_scope.rows).excluded_coefficient
"proven" lib.AssertEq (⊑scope.obligation_scope.rows).reservation_state
result ← compose.DailyTarget ⟨"2026-01-12","2026-01-22","JPY",scope.asset_scope,scope.obligation_scope⟩
"ok" lib.AssertEq result.state
815 lib.AssertEq result.result.calculation.capacity_balance
81 lib.AssertEq result.result.calculation.daily_target

missing ← admission.Admit ⟨⟨⟩,registry⟩
"error" lib.AssertEq missing.state
"daily_scope_header_missing" lib.AssertEq (⊑missing.diagnostics).code
headerOnly ← admission.Admit ⟨⟨admission.header⟩,registry⟩
"ok" lib.AssertEq headerOnly.state
emptyScope ← adapter.Build ⟨headerOnly,actual,plan,"JPY","2026-01-12","2026-01-22"⟩
"ok" lib.AssertEq emptyScope.state
invalidLines ← ⟨admission.header,"obligation"∾(@+9)∾"rent"∾(@+9)∾""∾(@+9)∾"plan-rent-daily-target"∾(@+9)∾"50"∾(@+9)∾""∾(@+9)∾"reservation:rent"⟩
invalid ← admission.Admit ⟨invalidLines,registry⟩
"error" lib.AssertEq invalid.state
0 lib.AssertEq invalid.rows.count
"daily_reservation_currency_pair_invalid" lib.AssertEq (⊑invalid.diagnostics).code

duplicateScopeIds ← admission.Admit ⟨
  ⟨
    admission.header,
    Join ⟨"asset","cash","assets:cash","","","",""⟩,
    Join ⟨"asset","reserve","assets:cash","","","",""⟩,
    Join ⟨"asset","cash","assets:cash","","","",""⟩
  ⟩,
  registry
⟩
"error" lib.AssertEq duplicateScopeIds.state
0 lib.AssertEq duplicateScopeIds.rows.count
1 lib.AssertEq ≠duplicateScopeIds.diagnostics
"daily_scope_id_duplicate" lib.AssertEq (⊑duplicateScopeIds.diagnostics).code
0 lib.AssertEq (⊑duplicateScopeIds.diagnostics).source_row

duplicateReservationRefs ← admission.Admit ⟨
  ⟨
    admission.header,
    Join ⟨"obligation","rent-1","","plan-rent-1","10","JPY","reservation:shared"⟩,
    Join ⟨"obligation","rent-2","","plan-rent-2","20","JPY","reservation:other"⟩,
    Join ⟨"obligation","rent-3","","plan-rent-3","30","JPY","reservation:shared"⟩
  ⟩,
  registry
⟩
"error" lib.AssertEq duplicateReservationRefs.state
0 lib.AssertEq duplicateReservationRefs.rows.count
1 lib.AssertEq ≠duplicateReservationRefs.diagnostics
"daily_reservation_reference_duplicate" lib.AssertEq (⊑duplicateReservationRefs.diagnostics).code
0 lib.AssertEq (⊑duplicateReservationRefs.diagnostics).source_row

unknownAccountLines ← ⟨admission.header,Join ⟨"asset","missing","assets:missing","","","",""⟩⟩
unknownAccount ← admission.Admit ⟨unknownAccountLines,registry⟩
unknownAccountScope ← adapter.Build ⟨unknownAccount,actual,plan,"JPY","2026-01-12","2026-01-22"⟩
"error" lib.AssertEq unknownAccountScope.state
"daily_asset_account_unknown" lib.AssertEq (⊑unknownAccountScope.diagnostics).code
unknownPlanLines ← ⟨admission.header,Join ⟨"obligation","missing","","plan-missing","","",""⟩⟩
unknownPlan ← admission.Admit ⟨unknownPlanLines,registry⟩
unknownPlanScope ← adapter.Build ⟨unknownPlan,actual,plan,"JPY","2026-01-12","2026-01-22"⟩
"error" lib.AssertEq unknownPlanScope.state
"daily_obligation_plan_unknown" lib.AssertEq (⊑unknownPlanScope.diagnostics).code

mixedUnknownLines ← ⟨
  admission.header,
  Join ⟨"asset","missing-asset","assets:missing","","","",""⟩,
  Join ⟨"obligation","missing-plan","","plan-missing","","",""⟩
⟩
mixedUnknown ← admission.Admit ⟨mixedUnknownLines,registry⟩
mixedUnknownScope ← adapter.Build ⟨mixedUnknown,actual,plan,"JPY","2026-01-12","2026-01-22"⟩
⟨"daily_asset_account_unknown","daily_obligation_plan_unknown"⟩ lib.AssertEq {𝕩.code}¨mixedUnknownScope.diagnostics

outsideScope ← adapter.Build ⟨admitted,actual,plan,"JPY","2026-01-12","2026-01-14"⟩
"exclude" lib.AssertEq (⊑outsideScope.obligation_scope.rows).decision
outside ← compose.DailyTarget ⟨"2026-01-12","2026-01-14","JPY",outsideScope.asset_scope,outsideScope.obligation_scope⟩
0 lib.AssertEq outside.result.calculation.gross_obligations
•Out "test_application_daily_scope: ok"
