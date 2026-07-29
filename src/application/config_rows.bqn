# Pure bounded key/value row representation for application configuration adapters.

parse ← •Import "../text/parse.bqn"
ParseLine ← {
  tab ← @+9
  separator ← (⊑tab∊𝕩)◶⟨{'='},{tab}⟩ @
  parts ← separator parse.SplitKeepEmpty 𝕩
  key ← 0⊑parts
  value ← (1<≠parts)◶⟨{""},{1⊑parts}⟩ @
  ⟨key, value⟩
}
Build ← {𝕊 lines:
  parsed ← ParseLine¨lines
  keys ← {0⊑𝕩}¨parsed
  values ← {1⊑𝕩}¨parsed
  Matches ← {𝕊 key: (key⊸≡¨keys)/parsed}
  Lookup ← {𝕊 key:
    index ← ⊑(keys⊐⟨key⟩)∾⟨≠keys⟩
    (index<≠keys) ? ⟨1, index⊑values⟩ ; ⟨0, ""⟩
  }
  Get ← {𝕊 key: found‿value ← Lookup key ⋄ found⊑⟨"", value⟩}
  {keys⇐keys,values⇐values,Matches⇐Matches,Lookup⇐Lookup,Get⇐Get}
}

{ParseLine⇐ParseLine,Build⇐Build}
