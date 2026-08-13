# src_edit/issue_close_cmd.bqn
# BQN command for `tools/edit-bqn issue close`.
#
# Semantic Issue selection comes from canonical Issue admission. The writer keeps
# only the physical 8/9/10-column source shape needed for exact row replacement.
#
# Input args:
#   <baseDir> <index> <closeStatus: resolved|dropped> <decisionMemo> [closedDate]
#
# Stdout protocol on success:
#   OK\tREPLACE\t<lineNum>\t<issueTitle>
#   <old TSV row>
#   <new TSV row>

lib ← •Import "../src/text/parse.bqn"
loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
registryMod ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/issue_admission.bqn"

args ← •args
tab ← @+9
legacyHeader ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩
closedHeader ← ⟨"issue_id","status","date","due","closed","category","title","amount","currency","details"⟩

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}
Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}
IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }

argCount ← ≠args
validArgCount ← (argCount=4) ∨ argCount=5
{𝕊 ⋄ Fail "usage: issue_close_cmd.bqn <baseDir> <index> <closeStatus: resolved|dropped> <decisionMemo> [closedDate]"}⍟(¬validArgCount) @

baseDir ← 0 ⊑ args
indexVal ← lib.ToNum (1 ⊑ args)
closeStatus ← 2 ⊑ args
decisionMemo ← 3 ⊑ args
closedDate ← ""
{𝕊:closedDate↩4⊑args}⍟(argCount=5) @

validStatus ← ∨´ closeStatus ⊸ ≡¨ "resolved"‿"dropped"
{𝕊 ⋄ Fail ("invalid close status: " ∾ closeStatus ∾ " (expected 'resolved' or 'dropped')")}⍟(¬ validStatus) @
blankOnly ← (0 = ≠ decisionMemo) ∨ (∧´ decisionMemo ∊ " ")
maybeDateOnly ← (10 ≤ ≠ decisionMemo) ∧ (0 ⊑ validate.ValidateDate (10 ↑ decisionMemo)) ∧ ((0 = ≠ 10 ↓ decisionMemo) ∨ (∧´ (10 ↓ decisionMemo) ∊ " "))
{𝕊 ⋄ Fail "decision memo is required"}⍟blankOnly @
{𝕊 ⋄ Fail "decision memo must include text after the date"}⍟maybeDateOnly @
valMemo ← validate.ValidateNoTabNewline "decision memo"‿decisionMemo
{𝕊 ⋄ Fail (1 ⊑ valMemo)}⍟(¬ 0 ⊑ valMemo) @

issuePath ← baseDir ∾ "/issues.tsv"
raw ← loader.ReadRaw issuePath
stripped ← ((@+13) ≠ raw) / raw
sourceLines ← (@+10) loader.SplitKeepEmpty stripped

registryResult ← registryMod.Build loader.ReadLines "config/currencies.tsv"
{𝕊 ⋄ Fail "currency registry invalid"}⍟(registryResult.state≢"ok") @
result ← admission.Admit ⟨sourceLines,registryResult.registry⟩
{𝕊 ⋄ Fail (⊑result.diagnostics).message}⍟(result.state≢"ok") @
issues ← result.issues

# Admission owns header/row/lifecycle validity. The writer still observes the
# admitted source's physical header because replacement must preserve its shape.
dataIndices ← (IsDataLine¨sourceLines) / ↕≠sourceLines
{𝕊 ⋄ Fail "issues.tsv has no header"}⍟(0=≠dataIndices) @
headerFields ← loader.SplitTsvKeepEmpty (⊑dataIndices)⊑sourceLines
legacySchema ← headerFields≡legacyHeader
dueSchema ← headerFields≡dueHeader
closedSchema ← headerFields≡closedHeader
{𝕊 ⋄ Fail "issues.tsv header must match the supported eight-, nine-, or ten-column schema"}⍟(¬legacySchema ∧ ¬dueSchema ∧ ¬closedSchema) @
{𝕊 ⋄ Fail "closed-aware issues.tsv requires a close date"}⍟(closedSchema ∧ argCount=4) @
{𝕊 ⋄ Fail "eight-/nine-column issues.tsv cannot represent a close date"}⍟((¬closedSchema) ∧ argCount=5) @
{𝕊:
  valClosedDate ← validate.ValidateDate closedDate
  {𝕊 ⋄ Fail (1⊑valClosedDate)}⍟(¬0⊑valClosedDate) @
}⍟(argCount=5) @

openIndices ← ("open"⊸≡¨issues.status) / issues.index
{𝕊 ⋄ Fail ("invalid issue index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ openIndices) ∾ ")")}⍟((indexVal < 1) ∨ (indexVal > ≠ openIndices)) @
selectedIndex ← (indexVal-1)⊑openIndices
selectedDate ← selectedIndex⊑issues.date
{𝕊:
  {𝕊:
    {𝕊 ⋄ Fail "closed date cannot precede recorded date"}⍟((dates.Ordinal closedDate)<dates.Ordinal selectedDate) @
  }⍟(0<≠selectedDate) @
}⍟closedSchema @

lineNum ← selectedIndex⊑issues.source_row
oldLine ← (lineNum-1)⊑sourceLines
oldFields ← loader.SplitTsvKeepEmpty oldLine
newFields ← (1↑oldFields) ∾ ⟨closeStatus⟩ ∾ 2↓oldFields
{𝕊:newFields↩(4↑newFields)∾⟨closedDate⟩∾5↓newFields}⍟closedSchema @
newMemo ← (selectedIndex⊑issues.details) ∾ "。Decision: " ∾ decisionMemo
newFields ↩ (¯1↓newFields) ∾ ⟨newMemo⟩
newLine ← tab Join newFields

•Out "OK" ∾ tab ∾ "REPLACE" ∾ tab ∾ (•Fmt lineNum) ∾ tab ∾ selectedIndex⊑issues.title
•Out oldLine
•Out newLine
