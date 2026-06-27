loader ← •Import "loader.bqn"

ParseLine ← {𝕊 line:
  tab ← @+9
  parts ← loader.SplitTsvKeepEmpty line
  key ← 0 ⊑ parts
  val ← (1 < ≠ parts) ◶ ⟨ { "" }, { 1 ⊑ parts } ⟩ @
  ⟨ key, val ⟩
}

rows ← loader.ReadLinesOptional "config/report_labels.tsv"
{𝕊:
  •Out "REPORT LABEL ERROR: config/report_labels.tsv is empty"
  •Exit 1
}⍟(0 = ≠ rows) @

parsed ← ParseLine ¨ rows
keys ← { 0 ⊑ 𝕩 } ¨ parsed
values ← { 1 ⊑ 𝕩 } ¨ parsed

ord ← ⍋ keys
sorted_keys ← ord ⊏ keys
dup_mask ← 1↓sorted_keys ≡ ¯1↓sorted_keys
{𝕊:
  •Out "REPORT LABEL ERROR: duplicate keys in config/report_labels.tsv"
  •Exit 1
}⍟(0 < +´ dup_mask) @

Get ← {
  k ← 𝕩
  idx ← 0 ⊑ (keys ⊐ ⟨k⟩)
  idx ⊑ values
}

{ Text ⇐ Get }
