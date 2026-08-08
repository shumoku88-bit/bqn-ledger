# src_edit/plan_related_cmd.bqn
# Read-only command for `tools/edit-bqn plan related`.
#
# Input args:
#   <baseDir> <index> <plan_id> <actual_date> <format: tsv>
# Output protocol remains:
#   KEY <tab> <relation_kind> <tab> <relation_value>
#   ROW <tab> date <tab> memo <tab> from <tab> to <tab> amount <tab> plan_id <tab> display
#
# Relation order:
#   1. canonical metadata `series`
#   2. series extracted from legacy-shaped plan-id `plan-YYYY-MM-DD-<series>`
#   3. exact description/from/to/amount fallback

loader ← •Import "../src/application/source_io.bqn"
validate ← •Import "validate.bqn"
planId ← •Import "plan_id.bqn"
parse ← •Import "../src/text/parse.bqn"
dates ← •Import "../src/ledger/date_ordinal.bqn"
planRows ← •Import "../src/application/editor_plan_rows.bqn"

args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
FailDiagnostics ← {𝕊 diagnostics:
  {𝕊 d: •Out "ERROR"∾tab∾d.code∾tab∾d.message}¨diagnostics
  •Exit 1
}

{𝕊:Fail "usage: plan_related_cmd.bqn <baseDir> <index> <plan_id> <actual_date> <format: tsv>"}⍟(5≠≠args) @
baseDir‿indexArg‿selectorPlanID‿actualDate‿format ← args
{𝕊:Fail ("invalid format: "∾format∾" (expected 'tsv')")}⍟(format≢"tsv") @
dateCheck ← validate.ValidateDate actualDate
{𝕊:Fail (1⊑dateCheck)}⍟(¬0⊑dateCheck) @

MetaValue ← {𝕊 key‿metadata:
  matches ← key⊸≡¨{𝕩.key}¨metadata
  (∨´0∾matches)◶⟨{𝕊:""},{𝕊:(⊑matches/{𝕩.value}¨metadata)}⟩ @
}
SeriesFromPlanID ← {𝕊 pid:
  valid ← (0<≠pid) ∧ (0⊑planId.ValidatePlanIDFormat pid)
  parts ← valid◶⟨{𝕊:⟨⟩},{𝕊:'-' loader.SplitKeepEmpty pid}⟩ @
  valid◶⟨{𝕊:""},{𝕊:"-" planId.Join (4↓parts)}⟩ @
}
RelationKey ← {𝕊 row:
  metaSeries ← MetaValue ⟨"series",row.metadata⟩
  pidSeries ← SeriesFromPlanID row.plan_id
  exactKey ← ⟨"exact",row.description∾tab∾row.from_account∾tab∾row.to_account∾tab∾row.amount⟩
  pidKey ← (0<≠pidSeries)◶⟨{𝕊:exactKey},{𝕊:⟨"series",pidSeries⟩}⟩ @
  (0<≠metaSeries)◶⟨{𝕊:pidKey},{𝕊:⟨"series",metaSeries⟩}⟩ @
}
KeyString ← {(0⊑𝕩)∾tab∾1⊑𝕩}

loaded ← planRows.Load baseDir
{𝕊:FailDiagnostics loaded.diagnostics}⍟(loaded.state≢"ok") @
allPlans ← loaded.rows
openPlans ← (¬{𝕩.closed}¨allPlans)/allPlans

byId ← 0<≠selectorPlanID
selected ← byId◶⟨
  {𝕊:
    idx ← parse.ToNum indexArg
    {𝕊:Fail "--index must be positive"}⍟(idx<1) @
    {𝕊:Fail "--index out of range"}⍟(idx>≠openPlans) @
    (idx-1)⊑openPlans
  },
  {𝕊:
    matches ← (selectorPlanID⊸≡¨{𝕩.plan_id}¨allPlans)/allPlans
    {𝕊:Fail ("plan_id not found: "∾selectorPlanID)}⍟(0=≠matches) @
    ⊑matches
  }
⟩ @

selectedKey ← RelationKey selected
selectedKeyString ← KeyString selectedKey
Related ← {𝕊 row:
  ((dates.Ordinal row.date)>dates.Ordinal actualDate) ∧ selectedKeyString≡KeyString RelationKey row
}
relatedPlans ← (Related¨openPlans)/openPlans

•Out "KEY"∾tab∾(0⊑selectedKey)∾tab∾1⊑selectedKey
PrintRow ← {𝕊 row:
  display ← row.date∾tab∾row.description∾tab∾row.from_account∾" -> "∾row.to_account∾tab∾row.amount∾tab∾row.plan_id
  •Out "ROW"∾tab∾row.date∾tab∾row.description∾tab∾row.from_account∾tab∾row.to_account∾tab∾row.amount∾tab∾row.plan_id∾tab∾display
}
PrintRow¨relatedPlans
