#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
snapshot ← •Import "../src_next/snapshot.bqn"
cube_mod ← •Import "../src_next/cube.bqn"

MakeVm ← {𝕊 cycleAvail‿asOf‿elapsed‿skipped‿unknown‿outOfCycle:
  {
    cycle_available ⇐ cycleAvail,
    as_of ⇐ asOf,
    days_elapsed ⇐ elapsed,
    readiness ⇐ {
      skipped_rows ⇐ skipped,
      unknown_account_count ⇐ unknown,
      out_of_cycle_skipped_count ⇐ outOfCycle
    }
  }
}

"unknown" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨0, "unavailable/no_cycle", ¯1, 0, 0, 0⟩)
"unknown" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨1, "unavailable/no_cycle", ¯1, 0, 0, 0⟩)
"reset" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨1, "2026-06-15", 0, 0, 0, 0⟩)
"stable" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨1, "2026-06-17", 2, 0, 0, 0⟩)
"caution" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨1, "2026-06-17", 2, 1, 0, 0⟩)
"caution" lib.AssertEq snapshot.StatusLabel (MakeVm ⟨1, "2026-06-17", 2, 0, 1, 0⟩)
"" lib.AssertEq snapshot.SelectArt "stable"

# ── Mock Build & FormatHuman test ──────────────────────────────

mockResolved ← {
  roles ⇐ ⟨"asset", "asset", "asset", "liability"⟩,
  accounts ⇐ ⟨"assets:smbc", "assets:yucho", "assets:invest", "liabilities:card"⟩,
  types ⇐ ⟨"liquid", "savings", "invest", ""⟩,
  account_keys ⇐ ⟨"assets:smbc/JPY", "assets:yucho/JPY", "assets:invest/JPY", "liabilities:card/JPY"⟩,
  budgets ⇐ ⟨"", "", "", ""⟩,
  budget_groups ⇐ ⟨"", "", "", ""⟩,
  spend_classes ⇐ ⟨"", "", "", ""⟩,
  count ⇐ 4
}

mockCube ← {
  actual_account_totals ⇐ ⟨1000, 2000, 5000, ¯500⟩,
  actual_expense_total ⇐ 0,
  plan_expense_total ⇐ 0,
  valid_count ⇐ 10,
  skipped_count ⇐ 0,
  skipped_rows ⇐ ⟨⟩,
  skipped_summary ⇐ {
    status ⇐ 0,
    day_before_start ⇐ 0,
    day_after_end ⇐ 0,
    account_key_index ⇐ 0,
    layer_index ⇐ 0,
    unknown ⇐ 0,
    invalid_count ⇐ 0,
    out_of_period_count ⇐ 0
  }
}

mockCtx ← {
  base ⇐ "fixtures/src-next-golden",
  cy ⇐ { start ⇐ "2026-06-15", end_exclusive ⇐ "2026-06-22", day_count ⇐ 7 },
  resolved ⇐ mockResolved,
  cube ⇐ mockCube,
  tbds ⇐ ⟨⟩
}

# Snapshot.Build now uses TBDS closing balances for asset totals and
# so calculation coverage lives in test_src_next_actual_snapshot.bqn. Keep this
# test focused on FormatHuman rendering.
vm ← {
  liq_total ⇐ 1000,
  sav_total ⇐ 2000,
  inv_total ⇐ 5000,
  assets_total ⇐ 8000,
  liabilities_total ⇐ ¯500,
  net_worth ⇐ 7500
}

# Check FormatHuman output
human ← snapshot.FormatHuman vm
1 lib.AssertEq ∨´ "1. 全体サマリ (Snapshot)"⍷human
1 lib.AssertEq ∨´ "1000"⍷human
1 lib.AssertEq ∨´ "2000"⍷human
1 lib.AssertEq ∨´ "5000"⍷human
1 lib.AssertEq ∨´ "8000"⍷human
1 lib.AssertEq ∨´ "500"⍷human     # Absolute liabilities value
1 lib.AssertEq ∨´ "7500"⍷human

•Out "test_src_next_snapshot.bqn: OK"
