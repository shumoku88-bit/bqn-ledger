#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
cube ← •Import "../src_next/cube.bqn"
tbds_mod ← •Import "../src_next/tbds.bqn"
balances ← •Import "../src_next/balances.bqn"

# ── TBDS query helper: NonzeroActualBalances ─────────────────

tbdsRows ← ⟨
  {
    account_key       ⇐ "expenses:food/JPY",
    account_key_index ⇐ 0,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    opening           ⇐ 1000,
    movement          ⇐ 4200,
    closing           ⇐ 5200,
    debit_movement    ⇐ 4200,
    credit_movement   ⇐ 0,
    account_name      ⇐ "expenses:food",
    role              ⇐ ""
  },
  {
    account_key       ⇐ "expenses:rent/JPY",
    account_key_index ⇐ 1,
    layer_index       ⇐ cube.layer_actual,
    layer_name        ⇐ "actual",
    opening           ⇐ 0,
    movement          ⇐ 0,
    closing           ⇐ 0,
    debit_movement    ⇐ 0,
    credit_movement   ⇐ 0,
    account_name      ⇐ "expenses:rent",
    role              ⇐ ""
  },
  {
    account_key       ⇐ "expenses:food/JPY",
    account_key_index ⇐ 0,
    layer_index       ⇐ cube.layer_plan,
    layer_name        ⇐ "plan",
    opening           ⇐ 0,
    movement          ⇐ 2000,
    closing           ⇐ 2000,
    debit_movement    ⇐ 2000,
    credit_movement   ⇐ 0,
    account_name      ⇐ "expenses:food",
    role              ⇐ ""
  }
⟩

nz ← tbds_mod.NonzeroActualBalances tbdsRows
1 lib.AssertEq ≠ nz
"expenses:food/JPY" lib.AssertEq (⊑nz).account_key
5200 lib.AssertEq (⊑nz).closing

# ── Build via context ───────────────────────────────────────

ctx ← {
  tbds ⇐ tbdsRows,
  resolved ⇐ {
    account_keys ⇐ ⟨"expenses:food/JPY", "expenses:rent/JPY"⟩,
    count ⇐ 2,
    roles ⇐ ⟨"", ""⟩,
    types ⇐ ⟨"", ""⟩,
    accounts ⇐ ⟨"expenses:food", "expenses:rent"⟩
  }
}
ents ← balances.Build ctx
1 lib.AssertEq ≠ ents
"expenses:food/JPY" lib.AssertEq (0 ⊑ (⊑ ents))
5200 lib.AssertEq (1 ⊑ (⊑ ents))
"unknown" lib.AssertEq (2 ⊑ (⊑ ents)) # missing role must not be classified by prefix fallback

explicitRoleCtx ← {
  tbds ⇐ tbdsRows,
  resolved ⇐ {
    account_keys ⇐ ⟨"expenses:food/JPY", "expenses:rent/JPY"⟩,
    count ⇐ 2,
    roles ⇐ ⟨"expense", "expense"⟩,
    types ⇐ ⟨"", ""⟩,
    accounts ⇐ ⟨"expenses:food", "expenses:rent"⟩
  }
}
explicitEnts ← balances.Build explicitRoleCtx
"expense" lib.AssertEq (2 ⊑ (⊑ explicitEnts))

# ── Format ───────────────────────────────────────────────────

text ← balances.Format ents
1 lib.AssertEq ∨´ "SrcNext Balances"⍷text
1 lib.AssertEq ∨´ "expenses:food/JPY 5200"⍷text

# ── Empty balances ───────────────────────────────────────────

emptyCtx ← {
  tbds ⇐ ⟨⟩,
  resolved ⇐ {
    account_keys ⇐ ⟨⟩,
    count ⇐ 0,
    roles ⇐ ⟨⟩,
    types ⇐ ⟨⟩,
    accounts ⇐ ⟨⟩
  }
}
emptyEnts ← balances.Build emptyCtx
0 lib.AssertEq ≠ emptyEnts
emptyText ← balances.Format emptyEnts
1 lib.AssertEq ∨´ "(none)"⍷emptyText

# ── M3 exact selected-currency formatting and orchestration ──

"₪12.00" lib.AssertEq balances.FormatCoefficient ⟨12, 0, 2, "ILS"⟩
"₪12.50" lib.AssertEq balances.FormatCoefficient ⟨125, 1, 2, "ILS"⟩
"₪0.05" lib.AssertEq balances.FormatCoefficient ⟨5, 2, 2, "ILS"⟩
"-₪12.50" lib.AssertEq balances.FormatCoefficient ⟨¯125, 1, 2, "ILS"⟩
"1200" lib.AssertEq balances.FormatCoefficient ⟨1200, 0, 0, "JPY"⟩
ilsIntegerPolicy ← balances.PresentationPolicy ⟨"ILS", 0⟩
"ok" lib.AssertEq ilsIntegerPolicy.state
0 lib.AssertEq ilsIntegerPolicy.calculation_scale
2 lib.AssertEq ilsIntegerPolicy.presentation_scale
ilsTooPrecise ← balances.PresentationPolicy ⟨"ILS", 3⟩
"error" lib.AssertEq ilsTooPrecise.state
1 lib.AssertEq ∨´ "ILS source precision exceeds 2 fractional digits" ⍷ ilsTooPrecise.message
"ledger default" lib.AssertEq balances.ProvenanceLabel "ledger_default"
"explicit selection" lib.AssertEq balances.ProvenanceLabel "explicit_selection"

•Out "test_src_next_balances.bqn: OK"
