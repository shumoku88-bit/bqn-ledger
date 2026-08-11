# Pure topology admission for one canonical Journal root document.
# Accounting syntax remains owned by Journal admission. This owner only proves
# that include directives do not escape the canonical Account source.

parse ← •Import "../text/parse.bqn"

lf ← @+10
cr ← @+13
space ← @+32
tab ← @+9
semicolon ← ⊑ ";"
empty ← ⟨⟩

IsWhitespace ← {𝕊 c: (c=space) ∨ c=tab }
TrimLeft ← {𝕊 xs:
  prefix ← ∧` IsWhitespace¨xs
  (+´prefix)↓xs
}
TrimRight ← {𝕊 xs:
  reversed ← ⌽xs
  trimmed ← TrimLeft reversed
  ⌽trimmed
}
Trim ← { TrimRight TrimLeft 𝕩 }
BeforeComment ← {𝕊 text:
  positions ← semicolon=text
  index ← ≠text
  {𝕊:index↩⊑positions/↕≠text}⍟(∨´0∾positions) @
  index↑text
}
StartsDirective ← {𝕊 keyword‿line:
  text ← TrimLeft line
  n ← ≠keyword
  enough ← n≤≠text
  remainder ← n↓text
  boundary ← (0=≠remainder) ∨ IsWhitespace ⊑(remainder∾" ")
  prefix ← n↑text∾n⥊space
  enough ∧ (keyword≡prefix) ∧ boundary
}
Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_canonical_journal_root_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}

Admit ← {𝕊 raw‿expectedAccountSource:
  normalized ← (cr≠raw)/raw
  lines ← lf parse.SplitKeepEmpty normalized

  # Include topology is one physical-source relation. Classify the line axis
  # once, retain source coordinates for directive cells, and derive path masks
  # before publishing includes or diagnostics.
  indices ← ↕≠lines
  includeMask ← {StartsDirective ⟨"include",𝕩⟩}¨lines
  includeIndices ← includeMask/indices
  includeRows ← 1+includeIndices
  includeLines ← includeMask/lines
  paths ← {𝕊 line:
    body ← Trim BeforeComment TrimLeft line
    Trim (≠"include")↓body
  }¨includeLines
  emptyPath ← 0=≠¨paths
  knownPath ← {𝕩≡expectedAccountSource}¨paths
  unknownPath ← (¬emptyPath) ∧ ¬knownPath
  includes ← (¬emptyPath)/paths

  lineDiagnostics ← ∾⟨empty⟩∾{𝕊 i:
    row ← i⊑includeRows
    emptyDiagnostic ← (i⊑emptyPath)/⟨Diagnostic ⟨"journal_include_empty",row,"include directive requires a source path"⟩⟩
    unknownDiagnostic ← (i⊑unknownPath)/⟨Diagnostic ⟨"journal_include_unknown",row,"canonical Journal root may include only the canonical Account source"⟩⟩
    emptyDiagnostic∾unknownDiagnostic
  }¨↕≠paths
  duplicate ← 1<+´{𝕩≡expectedAccountSource}¨includes
  duplicateDiagnostic ← duplicate/⟨Diagnostic ⟨"journal_include_duplicate",0,"canonical Account source may be included at most once"⟩⟩
  diagnostics ← lineDiagnostics∾duplicateDiagnostic

  {state⇐(0=≠diagnostics)⊑"error"‿"ok",includes⇐includes,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
