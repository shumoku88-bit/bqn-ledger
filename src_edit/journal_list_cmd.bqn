#!/usr/bin/env bqn
# src_edit/journal_list_cmd.bqn
# Read-only journal row export for UI shell wrappers.
#
# Args:
#   0: base directory
#   1: format: tsv|text
#
# `--format tsv` is a UI selection contract used by tools/add-ui.sh reverse.
# Fields:
#   number date memo from to amount display

loader ← •Import "../src_next/loader.bqn"
config ← •Import "../src_next/config.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: journal_list_cmd.bqn <baseDir> <format: tsv|text>"}⍟(2 ≠ ≠ args) @

baseDir ← 0 ⊑ args
format ← 1 ⊑ args

validFormat ← ∨´ format ⊸ ≡¨ "tsv"‿"text"
{𝕊 ⋄ Fail ("invalid format: " ∾ format ∾ " (expected 'tsv' or 'text')")}⍟(¬ validFormat) @

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

journalPath ← ResolvePath (sys.DefaultJournalFile @)
journalLines ← loader.ReadLinesOptional journalPath

ParseJournalRow ← {𝕊 index:
  line ← index ⊑ journalLines
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail ("journal.tsv row " ∾ (•Fmt (index + 1)) ∾ " has fewer than 5 tab-separated columns")}⍟(5 > ≠ fields) @
  5 ↑ fields
}

rows ← ParseJournalRow¨ ↕ ≠ journalLines

Display ← {𝕊 index:
  n ← index + 1
  f ← index ⊑ rows
  (•Fmt n) ∾ ": " ∾ (0⊑f) ∾ "  " ∾ (1⊑f) ∾ "  " ∾ (2⊑f) ∾ "→" ∾ (3⊑f) ∾ "  " ∾ (4⊑f)
}

PrintText ← {𝕊 index:
  •Out Display index
}

PrintTsv ← {𝕊 index:
  n ← index + 1
  f ← index ⊑ rows
  •Out (•Fmt n) ∾ tab ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ tab ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ tab ∾ (Display index)
}

(format ≡ "tsv") ◶ ⟨
  {𝕊 ⋄
    •Out "Journal rows:"
    {PrintText 𝕩}¨ ↕ ≠ rows
  },
  {𝕊 ⋄ {PrintTsv 𝕩}¨ ↕ ≠ rows}
⟩ @
