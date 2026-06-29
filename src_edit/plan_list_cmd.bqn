# src_edit/plan_list_cmd.bqn
# Read-only BQN command for experimental `tools/edit-bqn plan list`.
#
# Input args:
#   <baseDir> <showAll: 0|1> <format: tsv|text>
#
# `--format tsv` is a UI contract used by tools/add-ui.sh plan selection.
# Keep byte/field compatibility with the Go editor:
#   number plan_id date memo from to amount status display

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

{𝕊 ⋄ Fail "usage: plan_list_cmd.bqn <baseDir> <showAll: 0|1> <format: tsv|text>"}⍟(3 ≠ ≠ args) @

baseDir ← 0 ⊑ args
showAllArg ← 1 ⊑ args
format ← 2 ⊑ args

validShowAll ← ∨´ showAllArg ⊸ ≡¨ "0"‿"1"
{𝕊 ⋄ Fail ("invalid showAll flag: " ∾ showAllArg)}⍟(¬ validShowAll) @
showAll ← showAllArg ≡ "1"

validFormat ← ∨´ format ⊸ ≡¨ "tsv"‿"text"
{𝕊 ⋄ Fail ("invalid format: " ∾ format ∾ " (expected 'tsv' or 'text')")}⍟(¬ validFormat) @

ResolvePath ← { baseDir ∾ "/" ∾ 𝕩 }

IsDataLine ← { (0 < ≠ 𝕩) ? ((⊑ 𝕩 ≠ '#') ∧ (⊑ 𝕩 ≠ ⊑"\\")) ; 0 }

ReadDataLinesWithNums ← {
  raw ← loader.ReadRaw 𝕩
  stripped ← ((@+13) ≠ raw) / raw
  lines ← (@+10) loader.SplitKeepEmpty stripped
  nums ← 1 + ↕ ≠ lines
  mask ← IsDataLine¨ lines
  ⟨mask / lines, mask / nums⟩
}

LoadAccounts ← {𝕩 ⋄
  lines ← loader.ReadLines (ResolvePath (sys.DefaultAccountsFile @))
  fields ← loader.SplitTsvKeepEmpty¨ lines
  nonEmpty ← (0 < ≠¨ fields) / fields
  {⊑ 𝕩}¨ nonEmpty
}

ValidatePlanFields ← {𝕊 fields:
  {𝕊 ⋄ Fail "plan.tsv line has fewer than 5 tab-separated columns"}⍟(5 > ≠ fields) @
  dateCheck ← validate.ValidateDate (0 ⊑ fields)
  {𝕊 ⋄ Fail (1 ⊑ dateCheck)}⍟(¬ 0 ⊑ dateCheck) @
  fromCheck ← validate.ValidateAccount "from"‿(2 ⊑ fields)‿accounts
  {𝕊 ⋄ Fail (1 ⊑ fromCheck)}⍟(¬ 0 ⊑ fromCheck) @
  toCheck ← validate.ValidateAccount "to"‿(3 ⊑ fields)‿accounts
  {𝕊 ⋄ Fail (1 ⊑ toCheck)}⍟(¬ 0 ⊑ toCheck) @
  amountCheck ← validate.ValidateAmount (4 ⊑ fields)
  {𝕊 ⋄ Fail (1 ⊑ amountCheck)}⍟(¬ 0 ⊑ amountCheck) @
  metaCheck ← validate.ValidateMeta (5 ↓ fields)
  {𝕊 ⋄ Fail (1 ⊑ metaCheck)}⍟(¬ 0 ⊑ metaCheck) @
  1
}

accounts ← LoadAccounts @
planPath ← ResolvePath (sys.DefaultPlanFile @)
journalPath ← ResolvePath (sys.DefaultJournalFile @)

journalLines ← loader.ReadLinesOptional journalPath
completedIDsAll ← plan_id.ExtractPlanId¨ journalLines
completedIDs ← (0 < ≠¨ completedIDsAll) / completedIDsAll

lineData ← ReadDataLinesWithNums planPath
planLines ← 0 ⊑ lineData
lineNums ← 1 ⊑ lineData

ParsePlanRow ← {𝕊 index:
  line ← index ⊑ planLines
  lineNum ← index ⊑ lineNums
  fields ← loader.SplitTsvKeepEmpty line
  validationOk ← ValidatePlanFields fields
  pid ← plan_id.ExtractPlanId line
  missingID ← 0 = ≠ pid
  invalidID ← (¬ missingID) ◶ ⟨ {𝕊 ⋄ 0}, {𝕊 ⋄ ¬ (0 ⊑ plan_id.ValidatePlanIDFormat pid)} ⟩ @
  closed ← (¬ missingID) ◶ ⟨ {𝕊 ⋄ 0}, {𝕊 ⋄ ∨´ pid ⊸ ≡¨ completedIDs} ⟩ @
  ⟨lineNum, <fields, closed, <pid, missingID, invalidID⟩
}

allPlans ← ParsePlanRow¨ ↕ ≠ planLines
plans ← showAll ◶ ⟨ {𝕊 ⋄ (¬ {2⊑𝕩}¨ allPlans) / allPlans}, {𝕊 ⋄ allPlans} ⟩ @

StatusText ← {𝕊 r:
  closed ← 2 ⊑ r
  missingID ← 4 ⊑ r
  invalidID ← 5 ⊑ r
  closed ◶ ⟨
    {𝕊 ⋄ missingID ◶ ⟨ {𝕊 ⋄ invalidID ◶ ⟨ {𝕊 ⋄ ""}, {𝕊 ⋄ " [INVALID-ID]"} ⟩ @}, {𝕊 ⋄ " [MISSING-ID]"} ⟩ @},
    {𝕊 ⋄ " [CLOSED]"}
  ⟩ @
}

StatusTsv ← {𝕊 r:
  closed ← 2 ⊑ r
  missingID ← 4 ⊑ r
  invalidID ← 5 ⊑ r
  closed ◶ ⟨
    {𝕊 ⋄ missingID ◶ ⟨ {𝕊 ⋄ invalidID ◶ ⟨ {𝕊 ⋄ ""}, {𝕊 ⋄ "INVALID-ID"} ⟩ @}, {𝕊 ⋄ "MISSING-ID"} ⟩ @},
    {𝕊 ⋄ "CLOSED"}
  ⟩ @
}

PrintText ← {𝕊 index:
  r ← index ⊑ plans
  n ← index + 1
  f ← > 1 ⊑ r
  •Out (•Fmt n) ∾ ": " ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ " -> " ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ (StatusText r)
}

PrintTsv ← {𝕊 index:
  r ← index ⊑ plans
  n ← index + 1
  f ← > 1 ⊑ r
  pid ← > 3 ⊑ r
  statusTextVal ← StatusText r
  display ← (•Fmt n) ∾ ": " ∾ (0⊑f) ∾ "  " ∾ (1⊑f) ∾ "  " ∾ (2⊑f) ∾ " -> " ∾ (3⊑f) ∾ "  " ∾ (4⊑f) ∾ statusTextVal
  •Out (•Fmt n) ∾ tab ∾ pid ∾ tab ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ tab ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ tab ∾ (StatusTsv r) ∾ tab ∾ display
}

(format ≡ "tsv") ◶ ⟨
  {𝕊 ⋄
    •Out "Plan rows:"
    {PrintText 𝕩}¨ ↕ ≠ plans
  },
  {𝕊 ⋄ {PrintTsv 𝕩}¨ ↕ ≠ plans}
⟩ @
