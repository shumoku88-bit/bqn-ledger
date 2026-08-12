# src_edit/issue_close_cmd.bqn
# BQN command for `tools/edit-bqn issue close`.
#
# Input args:
#   <baseDir> <index> <closeStatus: resolved|dropped> <decisionMemo> [closedDate]
#
# A ten-column source requires a strict closedDate. Older bounded-compatibility
# sources omit it because they cannot represent the coordinate.
#
# Stdout protocol on success:
#   OK\tREPLACE\t<lineNum>\t<issueTitle>
#   <old TSV row>
#   <new TSV row>

lib ← •Import "../src/text/parse.bqn"
loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"

args ← •args
tab ← @+9
legacyHeader ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩
closedHeader ← ⟨"issue_id","status","date","due","closed","category","title","amount","currency","details"⟩

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

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

Join ← {
  sep ← 𝕨
  list ← 𝕩
  (0 = ≠ list) ◶ ⟨ { 𝕊 ⋄ 1↓ ∾ (sep ⊸ ∾) ¨ list }, { 𝕊 ⋄ ""} ⟩ @
}

IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }

ReadDataLinesWithNums ← {
  raw ← loader.ReadRaw 𝕩
  stripped ← ((@+13) ≠ raw) / raw
  lines ← (@+10) loader.SplitKeepEmpty stripped
  nums ← 1 + ↕ ≠ lines
  mask ← IsDataLine¨ lines
  ⟨mask / lines, mask / nums⟩
}

lineData ← ReadDataLinesWithNums issuePath
allLines ← 0 ⊑ lineData
allNums ← 1 ⊑ lineData
{𝕊 ⋄ Fail "issues.tsv has no header"}⍟(0=≠allLines) @
headerFields ← loader.SplitTsvKeepEmpty ⊑allLines
legacySchema ← headerFields≡legacyHeader
dueSchema ← headerFields≡dueHeader
closedSchema ← headerFields≡closedHeader
headerOk ← legacySchema ∨ dueSchema ∨ closedSchema
{𝕊 ⋄ Fail "issues.tsv header must match the supported eight-, nine-, or ten-column schema"}⍟(¬headerOk) @
{𝕊 ⋄ Fail "closed-aware issues.tsv requires a close date"}⍟(closedSchema ∧ argCount=4) @
{𝕊 ⋄ Fail "eight-/nine-column issues.tsv cannot represent a close date"}⍟((¬closedSchema) ∧ argCount=5) @
{𝕊:
  valClosedDate ← validate.ValidateDate closedDate
  {𝕊 ⋄ Fail (1⊑valClosedDate)}⍟(¬0⊑valClosedDate) @
}⍟(argCount=5) @
expectedCount ← 8 + dueSchema + 2×closedSchema

bodyLines ← (0 < ≠ allLines) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allLines} ⟩ @
bodyNums ← (0 < ≠ allNums) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allNums} ⟩ @

ParseIssueRow ← {𝕊 index:
  line ← index ⊑ bodyLines
  lineNum ← index ⊑ bodyNums
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail "issues.tsv row width must match its header"}⍟(expectedCount ≠ ≠ fields) @
  statusRaw ← 1⊑fields
  closedFallback ← (statusRaw≡"open")⊑⟨"undetermined","none"⟩
  normalized ← fields
  {𝕊:normalized↩(3↑fields)∾⟨"undetermined",closedFallback⟩∾3↓fields}⍟legacySchema @
  {𝕊:normalized↩(4↑fields)∾⟨closedFallback⟩∾4↓fields}⍟dueSchema @
  issueId‿status‿date‿due‿closed‿category‿title‿amount‿currency‿memo ← normalized
  dateOk ← (0=≠date) ∨ 0⊑validate.ValidateDate date
  {𝕊 ⋄ Fail "issues.tsv date must be empty or a strict Gregorian date"}⍟(¬dateOk) @
  dueOk ← (due≡"none") ∨ (due≡"undetermined") ∨ 0⊑validate.ValidateDate due
  {𝕊 ⋄ Fail "issues.tsv due must be none, undetermined, or a strict Gregorian date"}⍟(¬dueOk) @
  closedOk ← (closed≡"none") ∨ (closed≡"undetermined") ∨ 0⊑validate.ValidateDate closed
  {𝕊 ⋄ Fail "issues.tsv closed must be none, undetermined, or a strict Gregorian date"}⍟(¬closedOk) @
  lifecycleOk ← (status≡"open") = (closed≡"none")
  {𝕊 ⋄ Fail "issues.tsv status and closed lifecycle disagree"}⍟(¬lifecycleOk) @
  {
    lineNum ⇐ lineNum ⋄
    line ⇐ line ⋄
    fields ⇐ fields ⋄
    issue_id ⇐ issueId ⋄
    status ⇐ status ⋄
    date ⇐ date ⋄
    due ⇐ due ⋄
    closed ⇐ closed ⋄
    category ⇐ category ⋄
    title ⇐ title ⋄
    amount ⇐ amount ⋄
    currency ⇐ currency ⋄
    memo ⇐ memo
  }
}

issues ← ParseIssueRow¨ ↕ ≠ bodyLines
openIssues ← ({𝕩.status ≡ "open"}¨ issues) / issues
{𝕊 ⋄ Fail ("invalid issue index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ openIssues) ∾ ")")}⍟((indexVal < 1) ∨ (indexVal > ≠ openIssues)) @

selected ← (indexVal - 1) ⊑ openIssues
notOpen ← ¬ (selected.status ≡ "open")
{𝕊 ⋄ Fail "cannot close issue that is not open"}⍟notOpen @
{𝕊:
  {𝕊:
    {𝕊 ⋄ Fail "closed date cannot precede recorded date"}⍟((dates.Ordinal closedDate)<dates.Ordinal selected.date) @
  }⍟(0<≠selected.date) @
}⍟closedSchema @

oldFields ← selected.fields
newFields ← (1↑oldFields) ∾ ⟨closeStatus⟩ ∾ 2↓oldFields
{𝕊:newFields↩(4↑newFields)∾⟨closedDate⟩∾5↓newFields}⍟closedSchema @
newMemo ← selected.memo ∾ "。Decision: " ∾ decisionMemo
newFields ↩ (¯1↓newFields) ∾ ⟨newMemo⟩

oldLine ← selected.line
newLine ← tab Join newFields

•Out "OK" ∾ tab ∾ "REPLACE" ∾ tab ∾ (•Fmt selected.lineNum) ∾ tab ∾ selected.title
•Out oldLine
•Out newLine
