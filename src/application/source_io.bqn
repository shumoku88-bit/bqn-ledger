# Application-boundary read-only source I/O. Core ledger/accounting/sections/report stay pure.

empty ← ⟨⟩
Split ← {
  separator ← 𝕨
  groups ← (+`separator=𝕩)⊔𝕩
  parts ← {(separator≠𝕩)/𝕩}¨groups
  (0<≠¨parts)/parts
}
Resolve ← {𝕊 path:
  absolute ← (0<≠path) ∧ ('/'=⊑path)
  absolute⊑⟨•wdpath∾"/"∾path,path⟩
}
ReadRaw ← {𝕊 path: •FChars Resolve path}
ReadLines ← {𝕊 path:
  raw ← ReadRaw path
  raw ↩ ((@+13)≠raw)/raw
  lines ← (@+10) Split raw
  IsData ← {𝕊 line:
    (0<≠line) ? ((⊑line≠'#') ∧ (⊑line≠⊑"\\")) ; 0
  }
  (IsData¨lines)/lines
}

{ReadRaw⇐ReadRaw,ReadLines⇐ReadLines}
