#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
ctx_mod ← •Import "../src_next/context.bqn"
cube ← •Import "../src_next/cube.bqn"
balances ← •Import "../src_next/balances.bqn"

ctx ← ctx_mod.BuildContext "fixtures/src-next-opening-before-cycle"
rows ← ctx.tbds

actualRows ← (cube.layer_actual = {𝕩.layer_index}¨ rows) / rows
RowByKey ← {𝕊 key:
  hits ← (key⊸≡¨ ({𝕩.account_key}¨ actualRows)) / actualRows
  ⊑ hits
}

bank ← RowByKey "assets:bank/JPY"
food ← RowByKey "expenses:food/JPY"
equity ← RowByKey "equity:opening-balances/JPY"

100000 lib.AssertEq bank.opening
¯1000 lib.AssertEq bank.movement
99000 lib.AssertEq bank.closing

0 lib.AssertEq food.opening
1000 lib.AssertEq food.debit_movement
1000 lib.AssertEq food.movement
1000 lib.AssertEq food.closing

¯100000 lib.AssertEq equity.opening
0 lib.AssertEq equity.movement
¯100000 lib.AssertEq equity.closing

# Balance view must use closing, not period movement.
ents ← balances.Build ctx
EntByKey ← {𝕊 key:
  hits ← (key⊸≡¨ ({0⊑𝕩}¨ ents)) / ents
  ⊑ hits
}

bankEnt ← EntByKey "assets:bank/JPY"
99000 lib.AssertEq 1⊑bankEnt

•Out "test_src_next_tbds_opening_before_cycle.bqn: OK"
