# Pure topology admission for the canonical Actual root document.
# Accounting syntax remains owned by Journal admission. This owner only proves
# that include directives do not escape the canonical Account source.

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
TrimRight ← {𝕊 xs: ⌽TrimLeft⌽xs }
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
  enough ∧ (keyword≡n↑text) ∧ boundary
}
Diagnostic ← {𝕊 codeText‿lineNumber‿messageText:
  {severity⇐"error",stage⇐"ledger_actual_root_admission",code⇐codeText,line⇐lineNumber,message⇐messageText}
}

Admit ← {𝕊 raw‿expectedAccountSource:
  normalized ← (cr≠raw)/raw
  lines ← lf (⊣⊔˜+`∘=) normalized
  diagnostics ← empty
  includes ← empty
  {𝕊 i:
    line ← i⊑lines
    {𝕊:
      body ← Trim BeforeComment TrimLeft line
      path ← Trim (≠"include")↓body
      {𝕊: diagnostics∾↩⟨Diagnostic ⟨"actual_include_empty",i+1,"include directive requires a source path"⟩⟩}⍟(0=≠path) @
      {𝕊:
        includes∾↩⟨path⟩
        {𝕊: diagnostics∾↩⟨Diagnostic ⟨"actual_include_unknown",i+1,"Actual root may include only the canonical Account source"⟩⟩}⍟(path≢expectedAccountSource) @
      }⍟(0<≠path) @
    }⍟(StartsDirective ⟨"include",line⟩) @
  }¨↕≠lines
  diagnostics∾↩((1<+´expectedAccountSource⊸≡¨includes)/⟨Diagnostic ⟨"actual_include_duplicate",0,"canonical Account source may be included at most once"⟩⟩)
  {state⇐(0=≠diagnostics)⊑"error"‿"ok",includes⇐includes,diagnostics⇐diagnostics}
}

{Admit⇐Admit}
