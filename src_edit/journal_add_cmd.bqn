# src_edit/journal_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn journal add` and `budget add`.
#
# Input args:
#   <baseDir> <targetKind: journal|budget> <date> <memo> <from> <to> <amount> [meta...]
#
# Stdout protocol on success:
#   OK\tAPPEND\t<target-file>
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

{𝕊 ⋄ Fail "usage: journal_add_cmd.bqn <baseDir> <targetKind: journal|budget> <date> <memo> <from> <to> <amount> [meta...]"}⍟(7 > ≠ args) @

baseDir ← 0 ⊑ args
targetKind ← 1 ⊑ args
dateVal ← 2 ⊑ args
memoVal ← 3 ⊑ args
fromVal ← 4 ⊑ args
toVal ← 5 ⊑ args
amountVal ← 6 ⊑ args
metaTokens ← 7 ↓ args

validTargetKind ← ∨´ targetKind ⊸ ≡¨ "journal"‿"budget"
{𝕊 ⋄ Fail ("invalid target kind: " ∾ targetKind)}⍟(¬ validTargetKind) @
targetFile ← (targetKind ≡ "budget") ◶ ⟨ {𝕊 ⋄ sys.DefaultJournalFile @}, {𝕊 ⋄ sys.DefaultBudgetAllocFile @} ⟩ @

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

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ targetFile
•Out row
