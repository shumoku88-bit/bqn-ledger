#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"
outlook ← •Import "../src_next/outlook.bqn"

base ← "fixtures/outlook-actual-snapshot-characterization"
ctx ← ctx_mod.BuildContext base
observation ← "2026-02-05"

"2026-02-01" lib.AssertEq ctx.cy.start
"2026-02-11" lib.AssertEq ctx.cy.end_exclusive

# actual_snapshot is a ledger-to-O cumulative view rather than a cycle movement
# view. It includes the pre-cycle opening event and the O-day event, while rows
# after O remain excluded even when they are inside or beyond the selected cycle.
at_o ← actual_snapshot.BuildAt ⟨ctx, observation⟩
observation lib.AssertEq at_o.as_of
250 lib.AssertEq at_o.liq_total
250 lib.AssertEq at_o.assets_total
250 lib.AssertEq at_o.net_worth
expected_at_o ← ⟨
  ⟨"assets:cash/JPY", 250⟩,
  ⟨"income:base/JPY", ¯300⟩,
  ⟨"expenses:misc/JPY", 50⟩
⟩
expected_at_o lib.AssertEq at_o.entries

# Moving O beyond cycle end admits both the end-exclusive row and the later
# out-of-cycle row. BuildAt itself has an O cutoff but no cycle cutoff.
after_cycle ← actual_snapshot.BuildAt ⟨ctx, "2026-02-12"⟩
260 lib.AssertEq after_cycle.liq_total
260 lib.AssertEq after_cycle.assets_total
260 lib.AssertEq after_cycle.net_worth
expected_after_cycle ← ⟨
  ⟨"assets:cash/JPY", 260⟩,
  ⟨"income:base/JPY", ¯300⟩,
  ⟨"income:after_o/JPY", ¯30⟩,
  ⟨"income:outside/JPY", ¯20⟩,
  ⟨"expenses:misc/JPY", 90⟩
⟩
expected_after_cycle lib.AssertEq after_cycle.entries

# The actual_snapshot helper is cycle-bounded, while Outlook's compatibility
# frontier helper intentionally scans from cycle start with no upper cycle bound.
actual_cycle_latest ← actual_snapshot.LatestActualDateInCycle ⟨base, ctx.cy⟩
outlook_frontier_latest ← outlook.LatestActualDateInCycle ⟨base, ctx.cy⟩
"2026-02-06" lib.AssertEq actual_cycle_latest
"2026-02-12" lib.AssertEq outlook_frontier_latest

# Explicit Outlook O owns actual balances and remaining-plan dates. L may still
# sit after O and after cycle end. Current anchor handling admits both rows that
# carry anchor metadata, including the nonexistent anchor, while excluding the
# otherwise identical unanchored row. This locks the current branch behavior for
# a later compatibility decision; it is not endorsed as the target policy.
vm ← outlook.BuildAt ⟨ctx, observation⟩
observation lib.AssertEq vm.as_of
"2026-02-12" lib.AssertEq vm.last_recorded_on
"after_observation" lib.AssertEq vm.record_frontier_relation
7 lib.AssertEq vm.record_frontier_distance_days
0 lib.AssertEq vm.journal_lag
6 lib.AssertEq vm.days_left
250 lib.AssertEq vm.liq_total
0 lib.AssertEq vm.planned_future_income
130 lib.AssertEq vm.fixed_reserve
20 lib.AssertEq vm.liq_daily

•Out "test_src_next_outlook_actual_snapshot_characterization.bqn: OK"
