# src_edit/issue_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn issue add`.
#
# Input args:
#   <date> <status> <title> <amount> <memo>
#
# Stdout protocol on success:
#   OK\tAPPEND\tissues.tsv
#   <complete TSV row>
#
# Stdout protocol on validation error (with non-zero exit):
#   ERROR\t<message>

validate ← •Import "validate.bqn"
render ← •Import "render.bqn"

tab ← @+9
args ← •args

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: issue_add_cmd.bqn <date> <status> <title> <amount> <memo>"}⍟(5 > ≠ args) @

dateVal ← 0 ⊑ args
statusVal ← 1 ⊑ args
titleVal ← 2 ⊑ args
amountVal ← 3 ⊑ args
memoVal ← 4 ⊑ args

valDate ← validate.ValidateDate dateVal
{𝕊 ⋄ Fail (1 ⊑ valDate)}⍟(¬ 0 ⊑ valDate) @

validStatus ← ∨´ statusVal ⊸ ≡¨ "open"‿"resolved"‿"dropped"
{𝕊 ⋄ Fail ("invalid status: " ∾ statusVal ∾ " (expected 'open', 'resolved', or 'dropped')")}⍟(¬ validStatus) @

{𝕊 ⋄ Fail "title is required"}⍟(0 = ≠ titleVal) @
valTitle ← validate.ValidateNoTabNewline "title"‿titleVal
{𝕊 ⋄ Fail (1 ⊑ valTitle)}⍟(¬ 0 ⊑ valTitle) @

valAmount ← validate.ValidateAmount amountVal
{𝕊 ⋄ Fail (1 ⊑ valAmount)}⍟(¬ 0 ⊑ valAmount) @

valMemo ← validate.ValidateNoTabNewline "memo"‿memoVal
{𝕊 ⋄ Fail (1 ⊑ valMemo)}⍟(¬ 0 ⊑ valMemo) @

row ← render.RenderIssueRow {
  date ⇐ dateVal ⋄
  status ⇐ statusVal ⋄
  title ⇐ titleVal ⋄
  amount ⇐ amountVal ⋄
  memo ⇐ memoVal
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ "issues.tsv"
•Out row
