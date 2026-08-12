# Application-boundary read-only source I/O shared by report and editor adapters.
# It preserves source bytes/rows; schema admission and accounting stay downstream.

parse ← •Import "../text/parse.bqn"
Split ← parse.Split
SplitKeepEmpty ← parse.SplitKeepEmpty

JoinPath ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
ResolvePath ← {𝕊 path:
  absolute ← (0<≠path) ∧ (("/"≡1↑path) ∨ ("~"≡1↑path))
  absolute◶⟨
    {𝕊:•wdpath∾"/"∾path},
    {𝕊:path}
  ⟩ @
}
ReadRaw ← {𝕊 path: •FChars ResolvePath path}
ReadLines ← {𝕊 path:
  raw ← ReadRaw path
  stripped ← ((@+13)≠raw)/raw
  lines ← (@+10) Split stripped
  IsData ← {𝕊 line:
    (0<≠line) ? ((⊑line≠'#') ∧ (⊑line≠⊑"\\")) ; 0
  }
  (IsData¨lines)/lines
}
# Missing is optional; an existing but unreadable path still raises.
ReadLinesOptional ← {𝕊 path:
  resolved ← ResolvePath path
  (•file.Exists resolved) ? ReadLines resolved ; ⟨⟩
}
SplitTsv ← {𝕊 line: (@+9) Split line}
SplitTsvKeepEmpty ← {𝕊 line: (@+9) SplitKeepEmpty line}

{
  JoinPath⇐JoinPath,ReadRaw⇐ReadRaw,ReadLines⇐ReadLines,
  ReadLinesOptional⇐ReadLinesOptional,SplitTsv⇐SplitTsv,
  SplitTsvKeepEmpty⇐SplitTsvKeepEmpty,Split⇐Split,SplitKeepEmpty⇐SplitKeepEmpty
}
