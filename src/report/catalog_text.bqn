# Source-independent deterministic retained catalog metadata text.

catalog ← •Import "catalog.bqn"
tab ← @+9
lf ← @+10
YesNo ← {𝕊 value: value⊑"no"‿"yes"}

FormatTsv ← {𝕊:
  table ← catalog.Table @
  out ← "key"∾tab∾"label"∾tab∾"shape"∾tab∾"human"∾tab∾"compact"∾tab∾"json"∾lf
  {𝕊 i:
    out∾↩(i⊑table.key)∾tab∾(i⊑table.label)∾tab∾(i⊑table.shape)∾tab
    out∾↩(YesNo (i⊑table.human))∾tab∾(YesNo (i⊑table.compact))∾tab∾(YesNo (i⊑table.json))∾lf
  }¨table.index
  out
}

{FormatTsv⇐FormatTsv}
