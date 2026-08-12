# src_edit/issue_close_cmd.bqn
# BQN command for `tools/edit-bqn issue close`.
#
# Input args:
#   <baseDir> <index> <closeStatus: resolved|dropped> <decisionMemo>
#
# Stdout protocol on success:
#   OK\tREPLACE\t<lineNum>\t<issueTitle>
#   <old TSV row>
#   <new TSV row>

lib ← •Import "../src/text/parse.bqn"
loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"

args ← •args
tab ← @+9
legacyHeader ← ⟨"issue_id","status","date","category","title","amount","currency","details"⟩
dueHeader ← ⟨"issue_id","status","date","due","category","title","amount","currency","details"⟩

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: issue_close_cmd.bqn <baseDir> <index> <closeStatus: resolved|dropped> <decisionMemo>"}⍟(4 ≠ ≠ args) @

baseDir ← 0 ⊑ args
indexVal ← lib.ToNum (1 ⊑ args)
closeStatus ← 2 ⊑ args
decisionMemo ← 3 ⊑ args

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
headerOk ← legacySchema ∨ dueSchema
{𝕊 ⋄ Fail "issues.tsv header must match the supported eight- or nine-column schema"}⍟(¬headerOk) @
expectedCount ← 8 + dueSchema

bodyLines ← (0 < ≠ allLines) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allLines} ⟩ @
bodyNums ← (0 < ≠ allNums) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allNums} ⟩ @

ParseIssueRow ← {𝕊 index:
  line ← index ⊑ bodyLines
  lineNum ← index ⊑ bodyNums
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail "issues.tsv row width must match its header"}⍟(expectedCount ≠ ≠ fields) @
  normalized ← fields
  {𝕊:normalized↩(3↑fields)∾⟨"undetermined"⟩∾3↓fields}⍟legacySchema @
  issueId‿status‿date‿due‿category‿title‿amount‿currency‿memo ← normalized
  dueOk ← (due≡"none") ∨ (due≡"undetermined") ∨ 0⊑validate.ValidateDate due
  {𝕊 ⋄ Fail "issues.tsv due must be none, undetermined, or a strict Gregorian date"}⍟(¬dueOk) @
  {
    lineNum ⇐ lineNum ⋄
    line ⇐ line ⋄
    fields ⇐ fields ⋄
    issue_id ⇐ issueId ⋄
    status ⇐ status ⋄
    date ⇐ date ⋄
    due ⇐ due ⋄
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

oldFields ← selected.fields
newFields ← (1↑oldFields) ∾ ⟨closeStatus⟩ ∾ 2↓oldFields
newMemo ← selected.memo ∾ "。Decision: " ∾ decisionMemo
newFields ↩ (¯1↓newFields) ∾ ⟨newMemo⟩

oldLine ← selected.line
newLine ← tab Join newFields

•Out "OK" ∾ tab ∾ "REPLACE" ∾ tab ∾ (•Fmt selected.lineNum) ∾ tab ∾ selected.title
•Out oldLine
•Out newLine
