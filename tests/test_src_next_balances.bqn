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

m3Base ← "fixtures/currency-m3-balances"
selectedJpy ← balances.BuildSelected ⟨m3Base, "JPY"⟩
"ok" lib.AssertEq selectedJpy.state
"JPY" lib.AssertEq selectedJpy.selected_currency
"explicit_selection" lib.AssertEq selectedJpy.provenance
0 lib.AssertEq selectedJpy.calculation_scale
0 lib.AssertEq selectedJpy.presentation_scale
2 lib.AssertEq ≠ selectedJpy.entries

selectedIls ← balances.BuildSelected ⟨m3Base, "ILS"⟩
"ok" lib.AssertEq selectedIls.state
"ILS" lib.AssertEq selectedIls.selected_currency
2 lib.AssertEq selectedIls.calculation_scale
2 lib.AssertEq selectedIls.presentation_scale
4 lib.AssertEq ≠ selectedIls.entries
ilsHuman ← balances.FormatSelectedHuman selectedIls
1 lib.AssertEq ∨´ "Currency view: ILS (explicit selection)" ⍷ ilsHuman
1 lib.AssertEq ∨´ "₪12.50" ⍷ ilsHuman
1 lib.AssertEq ∨´ "₪0.05" ⍷ ilsHuman

selectedDefault ← balances.BuildSelected ⟨m3Base, ""⟩
"ok" lib.AssertEq selectedDefault.state
"JPY" lib.AssertEq selectedDefault.selected_currency
"ledger_default" lib.AssertEq selectedDefault.provenance

•Out "test_src_next_balances.bqn: OK"
