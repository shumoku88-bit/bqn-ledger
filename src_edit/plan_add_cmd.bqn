# src_edit/plan_add_cmd.bqn
# Narrow BQN command for experimental `tools/edit-bqn plan add`.
#
# Input args:
#   <baseDir> <date> <memo> <from> <to> <amount> <planID-or-empty> [meta...]
#
# Stdout protocol on success:
#   OK	APPEND	<plan-file>
#   <complete TSV row>

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
render ← •Import "render.bqn"
plan_id ← •Import "plan_id.bqn"
config ← •Import "../src_next/config.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: plan_add_cmd.bqn <baseDir> <date> <memo> <from> <to> <amount> <planID-or-empty> [meta...]"}⍟(7 > ≠ args) @

baseDir ← 0 ⊑ args
dateVal ← 1 ⊑ args
memoVal ← 2 ⊑ args
fromVal ← 3 ⊑ args
toVal ← 4 ⊑ args
amountVal ← 5 ⊑ args
planIdArg ← 6 ⊑ args
metaTokens ← 7 ↓ args

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

HasPlanIDMeta ← { ∨´ { "plan_id=" plan_id.StartsWith 𝕩 }¨ 𝕩 }
{𝕊 ⋄ Fail "--meta plan_id=... is not allowed; use --id or let plan add generate plan_id"}⍟(HasPlanIDMeta metaTokens) @

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

planPath ← ResolvePath (sys.DefaultPlanFile @)
journalPath ← ResolvePath (sys.DefaultJournalFile @)
existingIDs ← plan_id.LoadExistingPlanIDs { plan_path ⇐ planPath ⋄ journal_path ⇐ journalPath }

finalPlanID ← ""
(0 = ≠ planIdArg) ◶ ⟨
  {𝕊 ⋄
    idCheck ← plan_id.ValidatePlanIDFormat planIdArg
    {𝕊 ⋄ Fail ("invalid plan_id: " ∾ planIdArg)}⍟(¬ 0 ⊑ idCheck) @
    {𝕊 ⋄ Fail ("plan_id already exists: " ∾ planIdArg)}⍟(∨´ planIdArg ⊸ ≡¨ existingIDs) @
    finalPlanID ↩ planIdArg
  },
  {𝕊 ⋄
    finalPlanID ↩ plan_id.GeneratePlanID {
      date ⇐ dateVal ⋄
      memo ⇐ memoVal ⋄
      meta ⇐ metaTokens ⋄
      existing_ids ⇐ existingIDs
    }
  }
⟩ @

finalMeta ← metaTokens ∾ ⟨"plan_id=" ∾ finalPlanID⟩
row ← render.RenderJournalRow {
  date ⇐ dateVal ⋄
  memo ⇐ memoVal ⋄
  from ⇐ fromVal ⋄
  to ⇐ toVal ⋄
  amount ⇐ amountVal ⋄
  meta ⇐ finalMeta
}

•Out "OK" ∾ tab ∾ "APPEND" ∾ tab ∾ (sys.DefaultPlanFile @)
•Out row
