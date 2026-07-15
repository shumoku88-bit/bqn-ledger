# report_section_metadata.bqn — structured report section metadata export
#
# This is a UI-facing metadata surface. It does not read source TSV and does not
# build report ViewModels. Human report output remains owned by report.bqn.
#
# Output format: TSV
# Fields: key, label, category, owner, human_output, structured_output

labels ← •Import "report_labels.bqn"
report_sections ← •Import "report_sections.bqn"
L ← labels.Text

tab ← @+9
quote ← @+34
backslash ← @+92

HasArg ← {𝕊 args‿flag: 0 < +´ flag⊸≡¨ args }
ArgValue ← {𝕊 args‿flag:
  idx ← ⊑ ((flag⊸≡¨ args) ⊐ ⟨1⟩)
  next_idx ← 1 + idx
  (next_idx < ≠args) ? (next_idx ⊑ args) ; ""
}

EscapeJsonChar ← {𝕊 c:
  (c=quote) ⊑ ⟨((c=backslash) ⊑ ⟨⟨c⟩, backslash∾backslash⟩), backslash∾quote⟩
}

JsonString ← {𝕊 s: quote ∾ (∾ EscapeJsonChar¨ s) ∾ quote }
JsonField ← {𝕊 key‿value: (JsonString key) ∾ ": " ∾ (JsonString value) }

TrimReportHeading ← {𝕊 s:
  out ← s
  out ↩ {2↓𝕩}⍟((2 ≤ ≠out) ∧ ("==" ≡ 2↑out)) out
  out ↩ {1↓𝕩}⍟((1 ≤ ≠out) ∧ (' ' = ⊑out)) out
  out ↩ {¯2↓𝕩}⍟((2 ≤ ≠out) ∧ ("==" ≡ ¯2↑out)) out
  out ↩ {¯1↓𝕩}⍟((1 ≤ ≠out) ∧ (' ' = ⊑¯1↑out)) out
  out
}

TrimLeadingOrdinal ← {𝕊 s:
  out ← s
  out ↩ {3↓𝕩}⍟((3 ≤ ≠out) ∧ ('.' = 1⊑out) ∧ (' ' = 2⊑out)) out
  out ↩ {4↓𝕩}⍟((4 ≤ ≠out) ∧ ('.' = 2⊑out) ∧ (' ' = 3⊑out)) out
  out
}

DisplayLabel ← {𝕊 s: TrimLeadingOrdinal TrimReportHeading s }

FormatRow ← {𝕊 row:
  key ← 0⊑row
  label ← DisplayLabel 1⊑row
  category ← 2⊑row
  owner ← 3⊑row
  human ← 4⊑row
  structured ← 5⊑row
  key∾tab∾label∾tab∾category∾tab∾owner∾tab∾human∾tab∾structured
}

FormatJsonRow ← {𝕊 row:
  fields ← ⟨
    ⟨"key", 0⊑row⟩
    ⟨"label", DisplayLabel 1⊑row⟩
    ⟨"category", 2⊑row⟩
    ⟨"owner", 3⊑row⟩
    ⟨"human_output", 4⊑row⟩
    ⟨"structured_output", 5⊑row⟩
  ⟩
  "  {" ∾ (∾ {𝕊 i:
    prefix ← (i=0) ⊑ ⟨", ", ""⟩
    prefix ∾ JsonField (i⊑fields)
  }¨ ↕≠fields) ∾ "}"
}

ResolveLabel ← {𝕊 spec:
  is_literal ← "literal:" ≡ 8↑spec
  is_trial_balance ← spec ≡ "trial_balance.actual"
  out ← ""
  {𝕊: out ↩ 8↓spec}⍟is_literal @
  {𝕊:
    out ↩ (L "trial_balance.section_title_prefix")∾"actual"∾(L "trial_balance.section_title_suffix")
  }⍟is_trial_balance @
  {𝕊: out ↩ L spec}⍟(¬ is_literal ∨ is_trial_balance) @
  out
}

ResolveDescriptor ← {𝕊 row:
  ⟨0⊑row, ResolveLabel 1⊑row, 2⊑row, 3⊑row, 4⊑row, 5⊑row⟩
}

rows ← ResolveDescriptor¨ report_sections.rows

PrintTsv ← {𝕊:
  •Out "key"∾tab∾"label"∾tab∾"category"∾tab∾"owner"∾tab∾"human_output"∾tab∾"structured_output"
  {𝕊 row: •Out FormatRow row}¨ rows
}

PrintJson ← {𝕊:
  •Out "["
  {𝕊 i:
    suffix ← (i = (≠rows)-1) ⊑ ⟨",", ""⟩
    •Out (FormatJsonRow (i⊑rows)) ∾ suffix
  }¨ ↕≠rows
  •Out "]"
}

Main ← {𝕊 args:
  fmtname ← ArgValue ⟨args, "--format"⟩
  (fmtname ≡ "json") ? (PrintJson @) ; (PrintTsv @)
}

Main •args
