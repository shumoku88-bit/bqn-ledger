# Source-independent six-field destination section metadata.

catalog ← •Import "catalog.bqn"
json ← •Import "json_text.bqn"
tab ← @+9 ⋄ lf ← @+10

Table ← {𝕊:
  source ← catalog.Table @
  {
    count⇐source.count,index⇐source.index,key⇐source.key,label⇐source.label,
    category⇐source.category,owner⇐source.owner,
    human_output⇐source.count⥊⟨"yes"⟩,structured_output⇐source.count⥊⟨"metadata"⟩
  }
}
FormatTsv ← {𝕊:
  table ← Table @
  out ← "key"∾tab∾"label"∾tab∾"category"∾tab∾"owner"∾tab∾"human_output"∾tab∾"structured_output"∾lf
  {𝕊 i:
    out∾↩(i⊑table.key)∾tab∾(i⊑table.label)∾tab∾(i⊑table.category)∾tab∾(i⊑table.owner)∾tab
    out∾↩(i⊑table.human_output)∾tab∾(i⊑table.structured_output)∾lf
  }¨table.index
  out
}
FormatJson ← {𝕊:
  table ← Table @
  encoded ← {𝕊 i:
    json.Object ⟨
      json.Pair ⟨"key",json.String i⊑table.key⟩,
      json.Pair ⟨"label",json.String i⊑table.label⟩,
      json.Pair ⟨"category",json.String i⊑table.category⟩,
      json.Pair ⟨"owner",json.String i⊑table.owner⟩,
      json.Pair ⟨"human_output",json.String i⊑table.human_output⟩,
      json.Pair ⟨"structured_output",json.String i⊑table.structured_output⟩
    ⟩
  }¨table.index
  out ← "["∾lf
  {𝕊 i:out∾↩"  "∾(i⊑encoded)∾((i<table.count-1)/",")∾lf}¨table.index
  out∾"]"∾lf
}

{Table⇐Table,FormatTsv⇐FormatTsv,FormatJson⇐FormatJson}
