tab ← @+9

catalog ← {
  key⇐⟨
    "account-add","expense","multi","move","income","budget",
    "plan-add","plan-edit","plan-finish","reverse","issue","issue-close"
  ⟩,
  label⇐⟨
    "アカウント追加","支出 assets -> expenses","複数ポスティング (native Journal)",
    "資金移動 assets -> assets","収入 income -> assets","予算配賦 budget -> budget",
    "予定の追加 assets -> expenses","予定の日付・金額修正","予定の実績化 + 次回予定補充",
    "仕訳取消 (反対仕訳追記)","Issues & Decisions の追加","Issues & Decisions を閉じる"
  ⟩,
  family⇐⟨
    "account","journal","journal","journal","journal","budget",
    "plan","plan","plan","journal","issue","issue"
  ⟩
}

Validate ← {𝕊 catalog:
  lengths ← ≠¨⟨catalog.key,catalog.label,catalog.family⟩
  aligned ← ∧´(⊑lengths)=lengths
  unique ← (≠catalog.key)=≠⍷catalog.key
  state ← (aligned∧unique)⊑"error"‿"ok"
  {state⇐state,lengths⇐lengths,aligned⇐aligned,unique⇐unique}
}

Rows ← {𝕊 catalog:
  {𝕊 i:
    (i⊑catalog.key)∾tab∾(i⊑catalog.label)∾tab∾i⊑catalog.family
  }¨↕≠catalog.key
}

{catalog⇐catalog,Validate⇐Validate,Rows⇐Rows}
