#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"
outlook ← •Import "../src_next/outlook.bqn"
SnapshotAt ← {𝕊 ctx‿asOf: actual_snapshot.BuildFromPrepared ⟨ctx.posting_rows, ctx.cube, ctx.resolved, asOf⟩}

base ← "fixtures/outlook-actual-snapshot-characterization"
ctx ← ctx_mod.BuildContext base
observation ← "2026-02-05"

"2026-02-01" lib.AssertEq ctx.cy.start
"2026-02-11" lib.AssertEq ctx.cy.end_exclusive

# actual_snapshot is a ledger-to-O cumulative view rather than a cycle movement
# view. It includes the pre-cycle opening event and the O-day event, while rows
# after O remain excluded even when they are inside or beyond the selected cycle.
at_o ← SnapshotAt ⟨ctx, observation⟩
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
after_cycle ← SnapshotAt ⟨ctx, "2026-02-12"⟩
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

# The actual_snapshot helper is cycle-bounded, while Outlook's prepared
# frontier policy intentionally scans from cycle start with no upper bound.
prepared_dates ← actual_source.DatesFromContext ctx
actual_cycle_latest ← actual_snapshot.LatestActualDateInCycleFromDates ⟨prepared_dates, ctx.cy⟩
outlook_frontier ← outlook.RecordedFrontierInfoFromDates ⟨prepared_dates, ctx.cy⟩
"2026-02-06" lib.AssertEq actual_cycle_latest
1 lib.AssertEq outlook_frontier.available
"2026-02-12" lib.AssertEq outlook_frontier.date

# PR #266 characterized the former raw-parser path as fixed_reserve=210 because
# it admitted matched, nonexistent, and unanchored anchors alike. The approved
# Slice B contract intentionally replaces that behavior. The nonexistent anchor
# is applicable invalid plan evidence, so Outlook now fails closed while keeping
# the actual snapshot and record-frontier characterization above intact.
vm ← outlook.BuildAt ⟨ctx, observation⟩
observation lib.AssertEq vm.as_of
"2026-02-12" lib.AssertEq vm.last_recorded_on
"after_observation" lib.AssertEq vm.record_frontier_relation
7 lib.AssertEq vm.record_frontier_distance_days
0 lib.AssertEq vm.journal_lag
"error" lib.AssertEq vm.state
"rejected_plan_evidence" lib.AssertEq vm.reason
1 lib.AssertEq ≠ vm.diagnostics
"unknown_anchor" lib.AssertEq (⊑ vm.diagnostics).status
"unavailable" lib.AssertEq vm.liq_total
"unavailable" lib.AssertEq vm.fixed_reserve
"unavailable" lib.AssertEq vm.liq_daily

•Out "test_src_next_outlook_actual_snapshot_characterization.bqn: OK"
