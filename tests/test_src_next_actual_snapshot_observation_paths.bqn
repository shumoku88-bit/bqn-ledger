#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"

base ← "fixtures/src-next-daily-trend-stability-after"

early_ctx ← ctx_mod.BuildContext ⟨base, "2026-01-03"⟩
late_ctx ← ctx_mod.BuildContext ⟨base, "2026-01-06"⟩

# The context anchors differ while the fixed cycle remains the same.
"2026-01-03" lib.AssertEq early_ctx.as_of
"2026-01-06" lib.AssertEq late_ctx.as_of
"2026-01-01" lib.AssertEq early_ctx.cy.start
"2026-01-01" lib.AssertEq late_ctx.cy.start
"2026-01-11" lib.AssertEq early_ctx.cy.end_exclusive
"2026-01-11" lib.AssertEq late_ctx.cy.end_exclusive

# Explicit BuildAt obeys its supplied hard cutoff.
early_explicit ← actual_snapshot.BuildAt ⟨early_ctx, early_ctx.as_of⟩
late_explicit ← actual_snapshot.BuildAt ⟨late_ctx, late_ctx.as_of⟩

"2026-01-03" lib.AssertEq early_explicit.as_of
"2026-01-06" lib.AssertEq late_explicit.as_of

expected_early ← ⟨
  ⟨"assets:cash/JPY", 100⟩,
  ⟨"assets:other/JPY", ¯1⟩,
  ⟨"income:salary/JPY", ¯100⟩,
  ⟨"expenses:misc/JPY", 1⟩
⟩
expected_late ← ⟨
  ⟨"assets:cash/JPY", 100⟩,
  ⟨"assets:other/JPY", ¯2⟩,
  ⟨"income:salary/JPY", ¯100⟩,
  ⟨"expenses:misc/JPY", 2⟩
⟩

expected_early lib.AssertEq early_explicit.entries
expected_late lib.AssertEq late_explicit.entries

# Default Build ignores ctx.as_of as its cutoff. It derives a local latest-actual
# date from journal data, so both contexts produce the same 2026-01-06 snapshot.
early_default ← actual_snapshot.Build early_ctx
late_default ← actual_snapshot.Build late_ctx

"2026-01-06" lib.AssertEq early_default.as_of
"2026-01-06" lib.AssertEq late_default.as_of
expected_late lib.AssertEq early_default.entries
expected_late lib.AssertEq late_default.entries

•Out "test_src_next_actual_snapshot_observation_paths.bqn: OK"
