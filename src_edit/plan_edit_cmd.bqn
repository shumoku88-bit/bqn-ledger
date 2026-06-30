# src_edit/plan_edit_cmd.bqn
# BQN command for `tools/edit-bqn plan edit`.
#
# Input args:
#   <baseDir> <index: 0 or number> <planId: "" or id> <date: "" or YYYY-MM-DD> <amount: "" or INT> <showAll: 0|1>
#
# Stdout protocol on success:
#   OK\tREPLACE\t<lineNum>\t<planId>
#   <old TSV row>
#   <new TSV row>
#
# Stdout protocol on validation error (with non-zero exit):
#   ERROR\t<message>

lib ← •Import "../src_next/util.bqn"
loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
plan_id ← •Import "plan_id.bqn"
config ← •Import "../src_next/config.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: plan_edit_cmd.bqn <baseDir> <index> <planId> <date> <amount> <showAll>"}⍟(6 ≠ ≠ args) @

baseDir ← 0 ⊑ args
indexVal ← lib.ToNum (1 ⊑ args)
idVal ← 2 ⊑ args
dateVal ← 3 ⊑ args
amountVal ← 4 ⊑ args
showAll ← "1" ≡ 5 ⊑ args

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

{ 𝕊 ⋄
  dateCheck ← validate.ValidateDate dateVal
  { 𝕊 ⋄ Fail (1 ⊑ dateCheck) }⍟(¬ 0 ⊑ dateCheck) @
}⍟(0 < ≠ dateVal) @

{ 𝕊 ⋄
  amountCheck ← validate.ValidateAmount amountVal
  { 𝕊 ⋄ Fail (1 ⊑ amountCheck) }⍟(¬ 0 ⊑ amountCheck) @
}⍟(0 < ≠ amountVal) @

LoadPlansList ← { 𝕩 ⋄
  planPath ← ResolvePath (sys.DefaultPlanFile @)
  journalPath ← ResolvePath (sys.DefaultJournalFile @)

  journalLines ← loader.ReadLinesOptional journalPath

  completedIDs ← plan_id.ExtractPlanId¨ journalLines
  nonEmptyCompleted ← (0 < ≠¨ completedIDs) / completedIDs

  rawPlanLines ← loader.ReadRaw planPath
  cleanPlanLines ← ((@+13) ≠ rawPlanLines) / rawPlanLines
  allLines ← (@+10) loader.SplitKeepEmpty cleanPlanLines

  IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }
  lineNums ← 1 + ↕ ≠ allLines

  dataMask ← IsDataLine¨ allLines
  dataLines ← dataMask / allLines
  dataLineNums ← dataMask / lineNums

  ParsePlanRow ← {𝕊 index:
    line ← index ⊑ dataLines
    lineNum ← index ⊑ dataLineNums
    flds ← loader.SplitTsvKeepEmpty line

    pid ← plan_id.ExtractPlanId line
    missingID ← 0 = ≠ pid
    invalidID ← (¬ missingID) ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ¬ (0 ⊑ plan_id.ValidatePlanIDFormat pid) } ⟩ @
    closed ← (¬ missingID) ◶ ⟨ { 𝕊 ⋄ 0 }, { 𝕊 ⋄ ∨´ pid ⊸ ≡¨ nonEmptyCompleted } ⟩ @

    {
      lineNum ⇐ lineNum ⋄
      fields ⇐ flds ⋄
      closed ⇐ closed ⋄
      planID ⇐ pid ⋄
      missingID ⇐ missingID ⋄
      invalidID ⇐ invalidID
    }
  }

  ParsePlanRow¨ ↕ ≠ dataLines
}

plans ← LoadPlansList @
selectedPlans ← showAll ◶ ⟨ { 𝕊 ⋄ (¬ {𝕩.closed}¨ plans) / plans }, { 𝕊 ⋄ plans } ⟩ @

selIdx ← 0
(indexVal > 0) ◶ ⟨
  { 𝕊 ⋄
    matches ← { 𝕩.planID ≡ idVal }¨ selectedPlans
    (∨´ matches) ◶ ⟨
      { 𝕊 ⋄ Fail (showAll ◶ ⟨ {"plan_id not found or already closed: " ∾ idVal}, {"plan_id not found: " ∾ idVal} ⟩ @) },
      { 𝕊 ⋄ selIdx ↩ ⊑ (matches / ↕ ≠ selectedPlans) }
    ⟩ @
  },
  { 𝕊 ⋄
    { 𝕊 ⋄ Fail ("invalid plan index: " ∾ (•Fmt indexVal) ∾ " (available: 1-" ∾ (•Fmt ≠ selectedPlans) ∾ ")") }⍟((indexVal < 1) ∨ (indexVal > ≠ selectedPlans)) @
    selIdx ↩ indexVal - 1
  }
⟩ @

selected ← selIdx ⊑ selectedPlans
{ 𝕊 ⋄ Fail "cannot edit closed plan" }⍟selected.closed @
{ 𝕊 ⋄ Fail "cannot edit plan without plan_id" }⍟selected.missingID @
{ 𝕊 ⋄ Fail ("cannot edit plan with invalid plan_id: " ∾ selected.planID) }⍟selected.invalidID @

oldFields ← selected.fields
{ 𝕊 ⋄ Fail "plan.tsv line has fewer than 5 tab-separated columns" }⍟(5 > ≠ oldFields) @

newFields ← oldFields
{ 𝕊 ⋄ newFields ↩ ⟨dateVal⟩ ∾ 1↓newFields }⍟(0 < ≠ dateVal) @
{ 𝕊 ⋄ newFields ↩ (4↑newFields) ∾ ⟨amountVal⟩ ∾ 5↓newFields }⍟(0 < ≠ amountVal) @

oldLine ← tab plan_id.Join oldFields
newLine ← tab plan_id.Join newFields

{ 𝕊 ⋄ Fail "edit would not change the selected plan row" }⍟(oldLine ≡ newLine) @

•Out "OK" ∾ tab ∾ "REPLACE" ∾ tab ∾ (•Fmt selected.lineNum) ∾ tab ∾ selected.planID
•Out oldLine
•Out newLine
