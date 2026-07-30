#!/usr/bin/env bqn

# Analysis-only probe for a stable add-ui action metadata boundary.
# It validates aligned catalog coordinates and exports a shell-readable TSV view.

Show ← {𝕊 name‿value:
  •Out name∾": "∾•Repr value
}
IndexOf ← {𝕊 item‿items: ⊑(item⊸≡¨items)⊐1}
tab ← @+9

catalog ← {
  key⇐⟨
    "account-add","expense","multi","move","income","budget",
    "plan-add","plan-edit","plan-finish","reverse","issue","issue-close"
  ⟩,
  label⇐⟨
    "アカウント追加","支出","複数ポスティング","資金移動","収入","予算配賦",
    "予定追加","予定修正","予定実績化・補充","仕訳取消","Issue追加","Issue終了"
  ⟩,
  family⇐⟨
    "account","journal","journal","journal","journal","budget",
    "plan","plan","plan","journal","issue","issue"
  ⟩
}

count ← ≠catalog.key
lengths ← ≠¨⟨catalog.key,catalog.label,catalog.family⟩
aligned ← ∧´(⊑lengths)=lengths
unique ← (≠catalog.key)=≠⍷catalog.key

LookupStatus ← {𝕊 key:
  i ← IndexOf ⟨key,catalog.key⟩
  (i=≠catalog.key)⊑⟨"ok","unknown"⟩
}
ExportLine ← {𝕊 i:
  (i⊑catalog.key)∾tab∾(i⊑catalog.label)∾tab∾i⊑catalog.family
}

duplicateKeys ← catalog.key∾⟨"expense"⟩
duplicateUnique ← (≠duplicateKeys)=≠⍷duplicateKeys

Show ⟨"coordinate lengths",lengths⟩
Show ⟨"aligned coordinates",aligned⟩
Show ⟨"unique keys",unique⟩
Show ⟨"duplicate variant unique",duplicateUnique⟩
Show ⟨"known lookup",LookupStatus "expense"⟩
Show ⟨"unknown lookup",LookupStatus "missing"⟩
Show ⟨"first key",⊑catalog.key⟩
Show ⟨"last key",⊑⌽catalog.key⟩

•Out "EXPORT_BEGIN"
•Out¨ExportLine¨↕count
•Out "EXPORT_END"
