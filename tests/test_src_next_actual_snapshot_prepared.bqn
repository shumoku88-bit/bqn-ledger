#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"

ctx ← ctx_mod.BuildContext "fixtures/actual-snapshot-numeric-owner-target"
as_of ← "2026-02-05"

# The semantic boundary receives only prepared calculation evidence. It has no
# base path, cycle policy, source adapter, or broad report context.
prepared ← actual_snapshot.BuildFromPrepared ⟨
  ctx.posting_rows,
  ctx.cube,
  ctx.resolved,
  as_of
⟩
adapted ← actual_snapshot.BuildAt ⟨ctx, as_of⟩

adapted.state lib.AssertEq prepared.state
adapted.reason lib.AssertEq prepared.reason
adapted.diagnostics lib.AssertEq prepared.diagnostics
adapted.as_of lib.AssertEq prepared.as_of
adapted.amounts lib.AssertEq prepared.amounts
adapted.entries lib.AssertEq prepared.entries
adapted.liq_total lib.AssertEq prepared.liq_total
adapted.sav_total lib.AssertEq prepared.sav_total
adapted.inv_total lib.AssertEq prepared.inv_total
adapted.assets_total lib.AssertEq prepared.assets_total
adapted.liabilities_total lib.AssertEq prepared.liabilities_total
adapted.net_worth lib.AssertEq prepared.net_worth
adapted.liq_breakdown lib.AssertEq prepared.liq_breakdown
"ok" lib.AssertEq prepared.state
"snapshot_active" lib.AssertEq prepared.reason
250 lib.AssertEq prepared.liq_total
250 lib.AssertEq prepared.net_worth

invalid ← actual_snapshot.BuildFromPrepared ⟨
  ctx.posting_rows,
  ctx.cube,
  ctx.resolved,
  "not-a-date"
⟩
"error" lib.AssertEq invalid.state
"invalid_observation" lib.AssertEq invalid.reason
"unavailable" lib.AssertEq invalid.net_worth

•Out "test_src_next_actual_snapshot_prepared.bqn: OK"
