# src_edit/journal_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn journal add`.
#
# Input args:
#   <baseDir> <date> <memo> <from> <to> <amount> [meta...]
#
# Stdout protocol on success:
#   OK\tAPPEND\tjournal.tsv
#   <complete TSV row>
#
# Stdout protocol on validation error (with non-zero exit):
#   ERROR\t<message>

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: journal_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> [meta...]"}⍟(6 > ≠ args) @

baseDir ← 0 ⊑ args
dateVal ← 1 ⊑ args
memoVal ← 2 ⊑ args
fromVal ← 3 ⊑ args
toVal ← 4 ⊑ args
amountVal ← 5 ⊑ args
metaTokens ← 6 ↓ args

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

LoadAccountsList ← {𝕩 ⋄
  path ← ResolvePath (sys.DefaultAccountsFile @)
  lines ← loader.ReadLinesOptional path
  IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
  dataLines ← (IsDataLine¨ lines) / lines
  fields ← loader.SplitTsvKeepEmpty¨ dataLines
  nonEmpty ← (0 < ≠¨ fields) / fields
  {⊑ 𝕩}¨ nonEmpty
}

accounts ← LoadAccountsList @

check ← validate.ValidateJournalLikeAdd {
  date ⇐ dateVal ⋄
  memo ⇐ memoVal ⋄
  from ⇐ fromVal ⋄
  to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄
  meta ⇐ metaTokens ⋄
  accounts ⇐ accounts
}

{𝕊 ⋄ Fail (1 ⊑ check)}⍟(¬ 0 ⊑ check) @

row ← render.RenderJournalRow {
  date ⇐ dateVal ⋄
  memo ⇐ memoVal ⋄
  from ⇐ fromVal ⋄
  to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄
  meta ⇐ metaTokens
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ (sys.DefaultJournalFile @)
•Out row
