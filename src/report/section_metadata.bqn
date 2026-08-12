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
  header ← ∾⟨"key",tab,"label",tab,"category",tab,"owner",tab,"human_output",tab,"structured_output",lf⟩
  rows ← {𝕊 i:
    ∾⟨
      i⊑table.key,tab,i⊑table.label,tab,i⊑table.category,tab,i⊑table.owner,tab,
      i⊑table.human_output,tab,i⊑table.structured_output,lf
    ⟩
  }¨table.index
  ∾⟨header,∾rows⟩
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
  bodyLines ← {𝕊 i: "  "∾(i⊑encoded)∾((i<table.count-1)/",")}¨table.index
  lines ← ⟨"["⟩∾bodyLines∾⟨"]"⟩
  ∾{𝕩∾lf}¨lines
}

{Table⇐Table,FormatTsv⇐FormatTsv,FormatJson⇐FormatJson}
