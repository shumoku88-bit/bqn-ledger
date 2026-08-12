# src_edit/issue_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn issue add`.
#
# Input args:
#   <date> <status> <title> <amount> <memo> [schema: legacy|due|closed]
#
# The optional schema argument is supplied by the shell owner that observes the
# target source. Direct legacy callers remain compatible when it is omitted.
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

argCount ← ≠args
validArgCount ← (argCount=5) ∨ argCount=6
{𝕊 ⋄ Fail "usage: issue_add_cmd.bqn <date> <status> <title> <amount> <memo> [legacy|due|closed]"}⍟(¬validArgCount) @

dateVal ← 0 ⊑ args
statusVal ← 1 ⊑ args
titleVal ← 2 ⊑ args
amountVal ← 3 ⊑ args
memoVal ← 4 ⊑ args
schema ← "legacy"
{𝕊:schema↩5⊑args}⍟(argCount=6) @

validSchema ← ∨´schema⊸≡¨"legacy"‿"due"‿"closed"
{𝕊 ⋄ Fail ("invalid issue schema: " ∾ schema ∾ " (expected 'legacy', 'due', or 'closed')")}⍟(¬validSchema) @

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

closedVal ← (statusVal≡"open")⊑⟨"undetermined","none"⟩
issue ← {
  issue_id ⇐ "issue:" ∾ dateVal ∾ ":" ∾ titleVal ⋄
  status ⇐ statusVal ⋄
  date ⇐ dateVal ⋄
  due ⇐ "undetermined" ⋄
  closed ⇐ closedVal ⋄
  category ⇐ "general" ⋄
  title ⇐ titleVal ⋄
  amount ⇐ amountVal ⋄
  currency ⇐ "JPY" ⋄
  details ⇐ memoVal
}

row ← ""
{𝕊:row↩render.RenderIssueRow issue}⍟(schema≡"legacy") @
{𝕊:row↩render.RenderIssueRowWithDue issue}⍟(schema≡"due") @
{𝕊:row↩render.RenderIssueRowWithClosed issue}⍟(schema≡"closed") @

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ "issues.tsv"
•Out row
