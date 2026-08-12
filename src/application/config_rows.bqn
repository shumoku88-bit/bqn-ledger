# Pure bounded key/value row matching for application configuration adapters.

parse ← •Import "../text/parse.bqn"
ParseLine ← {
  tab ← @+9
  separator ← (⊑tab∊𝕩)◶⟨{'='},{tab}⟩ @
  parts ← separator parse.SplitKeepEmpty 𝕩
  key ← 0⊑parts
  value ← (1<≠parts)◶⟨{""},{1⊑parts}⟩ @
  ⟨key,value⟩
}
Build ← {𝕊 lines:
  parsed ← ParseLine¨lines
  keys ← {0⊑𝕩}¨parsed
  Matches ← {𝕊 key: (key⊸≡¨keys)/parsed}
  {Matches⇐Matches}
}

{Build⇐Build}
