#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
cube_mod ← •Import "../src_next/cube.bqn"
trial_balance ← •Import "../src_next/trial_balance.bqn"

# ── opening-before-cycle fixture ──────────────────────────────

ctx ← ctx_mod.BuildContext "fixtures/src-next-opening-before-cycle"
tb ← trial_balance.Build ⟨ctx, cube_mod.layer_actual⟩

"actual" lib.AssertEq tb.layer_name
"2026-06-15" lib.AssertEq tb.period_start
"2026-08-15" lib.AssertEq tb.period_end_exclusive
4 lib.AssertEq ≠ tb.accounts

FindRow ← {𝕊 key:
  hits ← (key⊸≡¨ tb.accounts) / ↕ ≠ tb.accounts
  ⊑ hits
}

bankIdx ← FindRow "assets:bank/JPY"
foodIdx ← FindRow "expenses:food/JPY"
equityIdx ← FindRow "equity:opening-balances/JPY"

100000 lib.AssertEq bankIdx⊑tb.openings
0 lib.AssertEq bankIdx⊑tb.debits
¯1000 lib.AssertEq bankIdx⊑tb.credits
99000 lib.AssertEq bankIdx⊑tb.closings

0 lib.AssertEq foodIdx⊑tb.openings
1000 lib.AssertEq foodIdx⊑tb.debits
0 lib.AssertEq foodIdx⊑tb.credits
1000 lib.AssertEq foodIdx⊑tb.closings

¯100000 lib.AssertEq equityIdx⊑tb.openings
0 lib.AssertEq equityIdx⊑tb.debits
0 lib.AssertEq equityIdx⊑tb.credits
¯100000 lib.AssertEq equityIdx⊑tb.closings

# Zero-sum: total openings = 0, debits = -credits, total closings = 0
0 lib.AssertEq +´ tb.openings
(+´ tb.debits) lib.AssertEq ¯1 × (+´ tb.credits)
0 lib.AssertEq +´ tb.closings

# ── FormatTSV ─────────────────────────────────────────────────

tsv ← trial_balance.FormatTSV tb
1 lib.AssertEq ∨´ "account_key\topening"⍷tsv
1 lib.AssertEq ∨´ "assets:bank/JPY\t100000"⍷tsv
1 lib.AssertEq ∨´ "expenses:food/JPY\t0\t1000"⍷tsv

# ── FormatHuman ───────────────────────────────────────────────

human ← trial_balance.FormatHuman tb
1 lib.AssertEq ∨´ "Trial Balance"⍷human
1 lib.AssertEq ∨´ "Zero-sum check"⍷human
1 lib.AssertEq ∨´ "OK"⍷human

# ── Empty fixture ────────────────────────────────────────────

emptyCtx ← ctx_mod.BuildContext "fixtures/src-next-empty-projection"
emptyTb ← trial_balance.Build ⟨emptyCtx, cube_mod.layer_actual⟩
0 lib.AssertEq +´ emptyTb.closings
0 lib.AssertEq +´ emptyTb.openings
(≠ emptyTb.accounts) lib.AssertEq 6

emptyTsv ← trial_balance.FormatTSV emptyTb
1 lib.AssertEq ∨´ "account_key"⍷emptyTsv

•Out "test_src_next_trial_balance.bqn: OK"
