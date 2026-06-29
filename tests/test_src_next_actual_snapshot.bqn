#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
actual_snapshot ← •Import "../src_next/actual_snapshot.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-golden"
s ← actual_snapshot.BuildAt ⟨ctx, "2026-06-16"⟩

"2026-06-16" lib.AssertEq s.as_of
3 lib.AssertEq ≠ s.entries

# Full actual snapshot up to as_of, not cycle TBDS movement only.
expected ← ⟨
  ⟨"equity:opening/JPY", ¯100⟩,
  ⟨"expenses:food/JPY", 80⟩,
  ⟨"expenses:rent/JPY", 20⟩
⟩
expected lib.AssertEq s.entries
0 lib.AssertEq s.liq_total
0 lib.AssertEq s.assets_total
0 lib.AssertEq s.net_worth
# Test with missing-role fixture to verify that prefix fallback is eliminated.
# assets:cash balance is 800, but without role=asset it must not be included.
ctx_fallback ← ctx_mod.BuildContext "fixtures/src-next-missing-role-fallback"
s_fallback ← actual_snapshot.BuildAt ⟨ctx_fallback, "2026-06-16"⟩

0 lib.AssertEq s_fallback.assets_total
0 lib.AssertEq s_fallback.liq_total
0 lib.AssertEq s_fallback.net_worth

•Out "test_src_next_actual_snapshot.bqn: OK"

