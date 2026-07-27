#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
conf ← •Import "../src_next/config.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"
remaining_plan ← •Import "../src_next/outlook_remaining_plan.bqn"
env_comp ← •Import "../src_next/envelope_computation.bqn"
outlook ← •Import "../src_next/outlook.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
adapted ← outlook.Build ctx
as_of ← adapted.as_of
cfg ← conf.LoadConfig ctx.base

# All effects happen while preparing this test evidence. The Outlook semantic
# boundary itself receives no base path, source adapter, config loader, or ctx.
input ← {
  cy ⇐ ctx.cy,
  as_of ⇐ as_of,
  frontier ⇐ {available⇐1,date⇐"2026-06-16"},
  legacy_default ⇐ 1,
  snapshot ⇐ actual_snapshot.BuildFromPrepared ⟨ctx.posting_rows, ctx.cube, ctx.resolved, as_of⟩,
  remaining_plan ⇐ remaining_plan.BuildAt ⟨ctx, as_of⟩,
  risk_style ⇐ cfg.PolicyRiskStyle @,
  next_obligations ⇐ ⟨⟩,
  envelope_summary ⇐ env_comp.Build ctx,
  life_groups ⇐ cfg.HouseholdGroupLifeLabels @,
  reserve_groups ⇐ cfg.HouseholdGroupReserveLabels @
}
prepared ← outlook.BuildFromPrepared input

adapted.state lib.AssertEq prepared.state
adapted.reason lib.AssertEq prepared.reason
adapted.diagnostics lib.AssertEq prepared.diagnostics
adapted.as_of lib.AssertEq prepared.as_of
adapted.last_journal lib.AssertEq prepared.last_journal
adapted.last_recorded_on lib.AssertEq prepared.last_recorded_on
adapted.record_frontier_relation lib.AssertEq prepared.record_frontier_relation
adapted.record_frontier_distance_days lib.AssertEq prepared.record_frontier_distance_days
adapted.journal_lag lib.AssertEq prepared.journal_lag
adapted.cycle_start lib.AssertEq prepared.cycle_start
adapted.cycle_end_exclusive lib.AssertEq prepared.cycle_end_exclusive
adapted.cycle_mode lib.AssertEq prepared.cycle_mode
adapted.days_left lib.AssertEq prepared.days_left
adapted.days_elapsed lib.AssertEq prepared.days_elapsed
adapted.liq_total lib.AssertEq prepared.liq_total
adapted.sav_total lib.AssertEq prepared.sav_total
adapted.inv_total lib.AssertEq prepared.inv_total
adapted.assets_total lib.AssertEq prepared.assets_total
adapted.liabilities_total lib.AssertEq prepared.liabilities_total
adapted.net_worth lib.AssertEq prepared.net_worth
adapted.liq_breakdown lib.AssertEq prepared.liq_breakdown
adapted.liq_daily lib.AssertEq prepared.liq_daily
adapted.liq_safe_daily lib.AssertEq prepared.liq_safe_daily
adapted.planned_future_income lib.AssertEq prepared.planned_future_income
adapted.fixed_reserve lib.AssertEq prepared.fixed_reserve
adapted.next_obligations lib.AssertEq prepared.next_obligations
adapted.next_obligation_total lib.AssertEq prepared.next_obligation_total
adapted.budget_breakdown lib.AssertEq prepared.budget_breakdown
adapted.reserve_breakdown lib.AssertEq prepared.reserve_breakdown
adapted.budget_daily_total lib.AssertEq prepared.budget_daily_total

adaptedMachine ← outlook.Format adapted
preparedMachine ← outlook.Format prepared
adaptedMachine lib.AssertEq preparedMachine
adaptedHuman ← outlook.FormatHuman adapted
preparedHuman ← outlook.FormatHuman prepared
adaptedHuman lib.AssertEq preparedHuman

•Out "test_src_next_outlook_prepared.bqn: OK"
