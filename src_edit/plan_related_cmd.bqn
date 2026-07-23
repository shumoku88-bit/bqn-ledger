# src_edit/plan_related_cmd.bqn
# Read-only command for `tools/edit-bqn plan related`.
#
# Input args:
#   <baseDir> <index> <plan_id> <actual_date> <format: tsv>
#
# Output protocol for tsv:
#   KEY <tab> <relation_kind> <tab> <relation_value>
#   ROW <tab> date <tab> memo <tab> from <tab> to <tab> amount <tab> plan_id <tab> display
#
# Relation order is intentional and owned here, not in shell UI:
#   1. meta series=...
#   2. series extracted from plan_id=plan-YYYY-MM-DD-<series>
#   3. exact memo/from/to/amount fallback

loader ← •Import "../src_next/loader.bqn"
validate ← •Import "validate.bqn"
plan_id ← •Import "plan_id.bqn"
config ← •Import "../src_next/config.bqn"
lib ← •Import "../src_next/util.bqn"
dateutil ← •Import "../src_next/date.bqn"
actual_source ← •Import "../src_next/actual_source.bqn"

sys ← config.LoadSystemDefaults @
args ← •args
tab ← @+9

Fail ← {𝕊 msg:
  •Out "ERROR" ∾ tab ∾ msg
  •Exit 1
}

{𝕊 ⋄ Fail "usage: plan_related_cmd.bqn <baseDir> <index> <plan_id> <actual_date> <format: tsv>"}⍟(5 ≠ ≠ args) @

baseDir ← 0 ⊑ args
indexArg ← 1 ⊑ args
selectorPlanID ← 2 ⊑ args
actualDate ← 3 ⊑ args
format ← 4 ⊑ args

validFormat ← format ≡ "tsv"
{𝕊 ⋄ Fail ("invalid format: " ∾ format ∾ " (expected 'tsv')")}⍟(¬ validFormat) @

actualDateCheck ← validate.ValidateDate actualDate
{𝕊 ⋄ Fail (1 ⊑ actualDateCheck)}⍟(¬ 0 ⊑ actualDateCheck) @

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

StartsWith ← plan_id.StartsWith

MetaValue ← {𝕊 key‿fields:
  meta ← (5 < ≠ fields) ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ 5 ↓ fields} ⟩ @
  prefix ← key ∾ "="
  IsKey ← { ((≠ prefix) ≤ ≠ 𝕩) ? prefix StartsWith 𝕩 ; 0 }
  mask ← IsKey¨ meta
  has ← ∨´ mask
  has ◶ ⟨ {𝕊 ⋄ ""}, {𝕊 ⋄ (1 + ≠ key) ↓ (⊑ (mask / ↕ ≠ meta)) ⊑ meta} ⟩ @
}

SeriesFromPlanID ← {𝕊 pid:
  valid ← (0 < ≠ pid) ∧ (0 ⊑ plan_id.ValidatePlanIDFormat pid)
  parts ← valid ◶ ⟨ {𝕊 ⋄ ⟨⟩}, {𝕊 ⋄ '-' loader.SplitKeepEmpty pid} ⟩ @
  valid ◶ ⟨ {𝕊 ⋄ ""}, {𝕊 ⋄ "-" plan_id.Join (4 ↓ parts)} ⟩ @
}

RelationKey ← {𝕊 fields‿pid:
  metaSeries ← MetaValue "series"‿fields
  pidSeries ← SeriesFromPlanID pid
  exactKey ← ⟨"exact", (1⊑fields) ∾ tab ∾ (2⊑fields) ∾ tab ∾ (3⊑fields) ∾ tab ∾ (4⊑fields)⟩
  pidKey ← (0 < ≠ pidSeries) ◶ ⟨ {𝕊 ⋄ exactKey}, {𝕊 ⋄ ⟨"series", pidSeries⟩} ⟩ @
  (0 < ≠ metaSeries) ◶ ⟨ {𝕊 ⋄ pidKey}, {𝕊 ⋄ ⟨"series", metaSeries⟩} ⟩ @
}

KeyString ← { (0⊑𝕩) ∾ tab ∾ (1⊑𝕩) }

accounts ← LoadAccounts @
planPath ← ResolvePath (sys.DefaultPlanFile @)
completionEvidence ← actual_source.CompletionEvidence baseDir
completedIDsAll ← {𝕩.plan_id}¨completionEvidence
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
  closed ← (¬ missingID) ◶ ⟨ {𝕊 ⋄ 0}, {𝕊 ⋄ ∨´ pid ⊸ ≡¨ completedIDs} ⟩ @
  key ← RelationKey fields‿pid
  ⟨lineNum, <fields, closed, <pid, <key⟩
}

allPlans ← ParsePlanRow¨ ↕ ≠ planLines
openPlans ← (¬ {2⊑𝕩}¨ allPlans) / allPlans

ToNumOrZero ← { lib.ToNum 𝕩 }
ifByID ← 0 < ≠ selectorPlanID
selected ← ifByID ◶ ⟨
  {𝕊 ⋄
    idx ← ToNumOrZero indexArg
    {𝕊 ⋄ Fail "--index must be positive"}⍟(idx < 1) @
    {𝕊 ⋄ Fail "--index out of range"}⍟(idx > ≠ openPlans) @
    (idx-1) ⊑ openPlans
  },
  {𝕊 ⋄
    matches ← ({ selectorPlanID ≡ >3⊑𝕩 }¨ allPlans) / allPlans
    {𝕊 ⋄ Fail ("plan_id not found: " ∾ selectorPlanID)}⍟(0 = ≠ matches) @
    ⊑ matches
  }
⟩ @

selectedKey ← > 4 ⊑ selected
selectedKeyString ← KeyString selectedKey

Related ← {𝕊 r:
  f ← > 1 ⊑ r
  pid ← > 3 ⊑ r
  key ← > 4 ⊑ r
  date ← 0 ⊑ f
  ((dateutil.Ordinal date) > dateutil.Ordinal actualDate) ∧ (selectedKeyString ≡ KeyString key)
}

relatedPlans ← (Related¨ openPlans) / openPlans

•Out "KEY" ∾ tab ∾ (0⊑selectedKey) ∾ tab ∾ (1⊑selectedKey)

PrintRow ← {𝕊 r:
  f ← > 1 ⊑ r
  pid ← > 3 ⊑ r
  pidDisplay ← (0 = ≠ pid) ◶ ⟨ {𝕊 ⋄ pid}, {𝕊 ⋄ "(missing)"} ⟩ @
  display ← (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ " -> " ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ tab ∾ pidDisplay
  •Out "ROW" ∾ tab ∾ (0⊑f) ∾ tab ∾ (1⊑f) ∾ tab ∾ (2⊑f) ∾ tab ∾ (3⊑f) ∾ tab ∾ (4⊑f) ∾ tab ∾ pidDisplay ∾ tab ∾ display
}

{PrintRow 𝕩}¨ relatedPlans
