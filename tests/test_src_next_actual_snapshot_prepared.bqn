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
