#!/usr/bin/env bqn

# Analysis-only probe for tools/add-ui.sh.
# It compares a row-oriented action collection with a column-oriented BQN catalog
# and experiments with an aligned function array for UI-only dispatch description.

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
    "アカウント追加","支出 assets -> expenses","複数ポスティング (native Journal)",
    "資金移動 assets -> assets","収入 income -> assets","予算配賦 budget -> budget",
    "予定の追加 assets -> expenses","予定の日付・金額修正","予定の実績化 + 次回予定補充",
    "仕訳取消 (反対仕訳追記)","Issues & Decisions の追加","Issues & Decisions を閉じる"
  ⟩,
  family⇐⟨
    "account","journal","journal","journal","journal","budget",
    "plan","plan","plan","journal","issue","issue"
  ⟩,
  effect⇐⟨
    "append","append","append","append","append","append",
    "append","replace","orchestration","derived_append","append","replace"
  ⟩,
  inputs⇐⟨
    ⟨"account_role","account_name","asset_type?"⟩,
    ⟨"memo","from_asset","to_expense","amount","meta"⟩,
    ⟨"memo","meta","signed_postings_3+"⟩,
    ⟨"from_asset","to_asset","amount","memo","meta"⟩,
    ⟨"from_income","to_asset","amount","memo","meta"⟩,
    ⟨"memo","from_budget","to_budget","amount","meta"⟩,
    ⟨"memo","from_asset","to_expense","amount","meta","series?"⟩,
    ⟨"selected_plan","date?","amount?"⟩,
    ⟨"selected_plan","finish","next_plan?"⟩,
    ⟨"selected_transaction","reverse_memo?"⟩,
    ⟨"title","amount?","memo"⟩,
    ⟨"selected_issue","status","decision_memo"⟩
  ⟩
}

count ← ≠catalog.key

RecordAt ← {𝕊 i:
  {
    key⇐i⊑catalog.key,
    label⇐i⊑catalog.label,
    family⇐i⊑catalog.family,
    effect⇐i⊑catalog.effect,
    inputs⇐i⊑catalog.inputs
  }
}
RecordView ← {𝕊 action:
  ⟨action.key,action.label,action.family,action.effect,action.inputs⟩
}
rows ← RecordAt¨↕count

FindColumnRecord ← {𝕊 key:
  RecordAt (IndexOf ⟨key,catalog.key⟩)
}
FindRowRecord ← {𝕊 key:
  ⊑(key⊸≡¨{𝕩.key}¨rows)/rows
}
MenuLine ← {𝕊 i:
  (i⊑catalog.key)∾tab∾i⊑catalog.label
}
KeysForFamily ← {𝕊 family:
  (family⊸≡¨catalog.family)/catalog.key
}
KeysForEffect ← {𝕊 effect:
  (effect⊸≡¨catalog.effect)/catalog.key
}

DescribeAppend ← {𝕊 action: "append/"∾action.key}
DescribeReplace ← {𝕊 action: "replace/"∾action.key}
DescribeDerived ← {𝕊 action: "derived_append/"∾action.key}
DescribeOrchestration ← {𝕊 action: "orchestration/"∾action.key}
effectKeys ← ⟨"append","replace","derived_append","orchestration"⟩
effectHandlers ← ⟨DescribeAppend,DescribeReplace,DescribeDerived,DescribeOrchestration⟩
EffectIndex ← {𝕊 action: IndexOf ⟨action.effect,effectKeys⟩}
Describe ← EffectIndex◶effectHandlers

Show ⟨"action count",count⟩
Show ⟨"column key shape",≢catalog.key⟩
Show ⟨"row collection shape",≢rows⟩
Show ⟨"unique key count",≠⍷catalog.key⟩
Show ⟨"input count by action",≠¨catalog.inputs⟩
Show ⟨"menu lines from aligned columns",MenuLine¨↕count⟩
Show ⟨"first-occurrence families",⍷catalog.family⟩
Show ⟨"journal family keys",KeysForFamily "journal"⟩
Show ⟨"replace effect keys",KeysForEffect "replace"⟩

expenseFromColumns ← FindColumnRecord "expense"
expenseFromRows ← FindRowRecord "expense"
columnView ← RecordView expenseFromColumns
rowView ← RecordView expenseFromRows
Show ⟨"selected column record",columnView⟩
Show ⟨"selected row record",rowView⟩
Show ⟨"selected records agree",columnView≡rowView⟩
Show ⟨"reverse handler description",Describe (FindColumnRecord "reverse")⟩
Show ⟨"missing key index bound",IndexOf ⟨"missing",catalog.key⟩⟩

•Out ""
•Out "add_ui_action_catalog probe: complete"
