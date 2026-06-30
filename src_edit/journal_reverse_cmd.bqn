# src_edit/journal_reverse_cmd.bqn
# BQN command for `tools/edit-bqn journal reverse`.
#
# Input args:
#   <baseDir> <id: "" or memo/id> <index: 0 or number> <reverseDate: "" or YYYY-MM-DD>
#
# Stdout protocol on success:
#   OK\tAPPEND\tjournal.tsv\t<targetIdx>\t<origDate>\t<origMemo>\t<origFrom>\t<origTo>\t<origAmount>
#   <reversed TSV row>
#
# Stdout protocol on validation error (with non-zero exit):
#   ERROR\t<message>

lib ← •Import "../src_next/util.bqn"
loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
config ← •Import "../src_next/config.bqn"
date ← •Import "../src_next/date.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: journal_reverse_cmd.bqn <baseDir> <id> <index> <date>"}⍟(4 ≠ ≠ args) @

baseDir ← 0 ⊑ args
idVal ← 1 ⊑ args
indexVal ← lib.ToNum (2 ⊑ args)
reverseDate ← 3 ⊑ args

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

revDate ← (0 = ≠ reverseDate) ◶ ⟨ { 𝕊 ⋄ reverseDate }, { 𝕊 ⋄ date.Today @ } ⟩ @
dateCheck ← validate.ValidateDate revDate
{ 𝕊 ⋄ Fail (1 ⊑ dateCheck) }⍟(¬ 0 ⊑ dateCheck) @

journalPath ← ResolvePath (sys.DefaultJournalFile @)
journalLines ← loader.ReadLinesOptional journalPath

targetLine ← ""
targetIdx ← 0

(indexVal > 0) ◶ ⟨
  { 𝕊 ⋄
    matches ← { flds ← loader.SplitTsvKeepEmpty 𝕩 ⋄ (2 ≤ ≠ flds) ◶ ⟨ {0}, { (1 ⊑ flds) ≡ idVal } ⟩ @ }¨ journalLines
    matchIndices ← matches / 1 + ↕ ≠ journalLines
    { 𝕊 ⋄ Fail ("no journal row found with id: " ∾ idVal) }⍟(0 = ≠ matchIndices) @
    { 𝕊 ⋄ Fail ("multiple journal rows match id " ∾ idVal ∾ " (indices: " ∾ (•Fmt matchIndices) ∾ "). Use --index to specify") }⍟(1 < ≠ matchIndices) @
    targetIdx ↩ ⊑ matchIndices
    targetLine ↩ (targetIdx - 1) ⊑ journalLines
  },
  { 𝕊 ⋄
    { 𝕊 ⋄ Fail ("invalid index " ∾ (•Fmt indexVal) ∾ " (journal has " ∾ (•Fmt ≠ journalLines) ∾ " data rows)") }⍟((indexVal < 1) ∨ (indexVal > ≠ journalLines)) @
    targetLine ↩ (indexVal - 1) ⊑ journalLines
    targetIdx ↩ indexVal
  }
⟩ @

fields ← loader.SplitTsvKeepEmpty targetLine
{ 𝕊 ⋄ Fail ("journal row " ∾ (•Fmt targetIdx) ∾ " has fewer than 5 fields") }⍟(5 > ≠ fields) @

originalDate ← 0 ⊑ fields
originalMemo ← 1 ⊑ fields
originalFrom ← 2 ⊑ fields
originalTo ← 3 ⊑ fields
originalAmount ← 4 ⊑ fields
originalMeta ← 5 ↓ fields

{ 𝕊 ⋄ Fail ("cannot reverse row " ∾ (•Fmt targetIdx) ∾ ": from and to accounts are the same") }⍟(originalFrom ≡ originalTo) @

reversedMemo ← "[reverse]" ∾ originalMemo

renderedReverse ← render.RenderJournalRow {
  date ⇐ revDate ⋄
  memo ⇐ reversedMemo ⋄
  from ⇐ originalTo ⋄
  to ⇐ originalFrom ⋄
  amount ⇐ originalAmount ⋄
  meta ⇐ originalMeta
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ (sys.DefaultJournalFile @) ∾ tab ∾ (•Fmt targetIdx) ∾ tab ∾ originalDate ∾ tab ∾ originalMemo ∾ tab ∾ originalFrom ∾ tab ∾ originalTo ∾ tab ∾ originalAmount
•Out renderedReverse
