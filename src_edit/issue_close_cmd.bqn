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

lib ← •Import "../src_next/util.bqn"
loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"

args ← •args
tab ← @+9

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
bodyLines ← (0 < ≠ allLines) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allLines} ⟩ @
bodyNums ← (0 < ≠ allNums) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 1 ↓ allNums} ⟩ @

ParseIssueRow ← {𝕊 index:
  line ← index ⊑ bodyLines
  lineNum ← index ⊑ bodyNums
  fields ← loader.SplitTsvKeepEmpty line
  {𝕊 ⋄ Fail "issues.tsv line has fewer than 5 tab-separated columns"}⍟(5 > ≠ fields) @
  {
    lineNum ⇐ lineNum ⋄
    line ⇐ line ⋄
    fields ⇐ fields ⋄
    date ⇐ 0 ⊑ fields ⋄
    status ⇐ 1 ⊑ fields ⋄
    title ⇐ 2 ⊑ fields ⋄
    amount ⇐ 3 ⊑ fields ⋄
    memo ⇐ 4 ⊑ fields
  }
}

issues ← ParseIssueRow¨ ↕ ≠ bodyLines
openIssues ← ({𝕩.status ≡ "open"}¨ issues) / issues
{𝕊 ⋄ Fail ("invalid issue index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ openIssues) ∾ ")")}⍟((indexVal < 1) ∨ (indexVal > ≠ openIssues)) @

selected ← (indexVal - 1) ⊑ openIssues
notOpen ← ¬ (selected.status ≡ "open")
{𝕊 ⋄ Fail "cannot close issue that is not open"}⍟notOpen @

oldFields ← selected.fields
newMemo ← selected.memo ∾ "。Decision: " ∾ decisionMemo
newFields ← ⟨selected.date, closeStatus, selected.title, selected.amount, newMemo⟩

oldLine ← selected.line
newLine ← tab Join newFields

•Out "OK" ∾ tab ∾ "REPLACE" ∾ tab ∾ (•Fmt selected.lineNum) ∾ tab ∾ selected.title
•Out oldLine
•Out newLine
