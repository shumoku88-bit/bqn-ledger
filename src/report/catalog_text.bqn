# Source-independent deterministic retained catalog metadata text.

catalog ← •Import "catalog.bqn"
tab ← @+9
lf ← @+10
YesNo ← {𝕊 value: value⊑"no"‿"yes"}

FormatTsv ← {𝕊:
  table ← catalog.Table @
  header ← ∾⟨"key",tab,"label",tab,"shape",tab,"human",tab,"compact",tab,"json",lf⟩
  rows ← {𝕊 i:
    ∾⟨
      i⊑table.key,tab,i⊑table.label,tab,i⊑table.shape,tab,
      YesNo (i⊑table.human),tab,YesNo (i⊑table.compact),tab,YesNo (i⊑table.json),lf
    ⟩
  }¨table.index
  ∾⟨header,∾rows⟩
}

{FormatTsv⇐FormatTsv}
