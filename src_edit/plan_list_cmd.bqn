# src_edit/plan_list_cmd.bqn
# Read-only BQN command for `tools/edit-bqn plan list`.
#
# Input args:
#   <baseDir> <showAll: 0|1> <format: tsv|text> <temporal: all|overdue|upcoming> <asOf: YYYY-MM-DD|empty>
#
# `--format tsv` is a UI contract used by tools/add-ui.sh plan selection.
# Output fields remain:
#   number plan_id date memo from to amount status display

validate ← •Import "validate.bqn"
planRows ← •Import "../src/application/editor_plan_rows.bqn"
planStatus ← •Import "../src/accounting/plan_temporal_status.bqn"

args ← •args ⋄ tab ← @+9
Fail ← {𝕊 msg: •Out "ERROR"∾tab∾msg ⋄ •Exit 1}
FailDiagnostics ← {𝕊 diagnostics:
  {𝕊 d: •Out "ERROR"∾tab∾d.code∾tab∾d.message}¨diagnostics
  •Exit 1
}

{𝕊:Fail "usage: plan_list_cmd.bqn <baseDir> <showAll: 0|1> <format: tsv|text> <temporal: all|overdue|upcoming> <asOf>"}⍟(5≠≠args) @
baseDir‿showAllArg‿format‿temporal‿asOf ← args

{𝕊:Fail ("invalid showAll flag: "∾showAllArg)}⍟(¬∨´showAllArg⊸≡¨"0"‿"1") @
showAll ← showAllArg≡"1"
{𝕊:Fail ("invalid format: "∾format∾" (expected 'tsv' or 'text')")}⍟(¬∨´format⊸≡¨"tsv"‿"text") @
{𝕊:Fail ("invalid temporal filter: "∾temporal∾" (expected 'all', 'overdue', or 'upcoming')")}⍟(¬∨´temporal⊸≡¨"all"‿"overdue"‿"upcoming") @
usesTemporal ← temporal≢"all"
{𝕊:Fail "--as-of is required for overdue/upcoming plan filtering"}⍟(usesTemporal ∧ 0=≠asOf) @
{𝕊:Fail "--all cannot be combined with overdue/upcoming plan filtering"}⍟(showAll ∧ usesTemporal) @
{𝕊:
  dateCheck ← validate.ValidateDate asOf
  {𝕊:Fail (1⊑dateCheck)}⍟(¬0⊑dateCheck) @
}⍟usesTemporal @

loaded ← planRows.Load baseDir
{𝕊:FailDiagnostics loaded.diagnostics}⍟(loaded.state≢"ok") @
allPlans ← loaded.rows
openPlans ← (¬{𝕩.closed}¨allPlans)/allPlans
TemporalMatch ← {𝕊 row:
  status ← planStatus.Classify ⟨row.date,asOf⟩
  overdue ← status≡"overdue"
  upcoming ← (status≡"due") ∨ status≡"future"
  (temporal≡"overdue")⊑⟨upcoming,overdue⟩
}
filteredOpen ← usesTemporal◶⟨{𝕊:openPlans},{𝕊:(TemporalMatch¨openPlans)/openPlans}⟩ @
plans ← showAll◶⟨{𝕊:filteredOpen},{𝕊:allPlans}⟩ @

StatusText ← {𝕊 row: row.closed◶⟨{𝕊:""},{𝕊:" [CLOSED]"}⟩ @}
StatusTsv ← {𝕊 row: row.closed◶⟨{𝕊:""},{𝕊:"CLOSED"}⟩ @}
Display ← {𝕊 index:
  row ← index⊑plans ⋄ n ← index+1
  (•Fmt n)∾": "∾row.date∾"  "∾row.description∾"  "∾row.from_account∾" -> "∾row.to_account∾"  "∾row.amount∾" "∾row.currency∾(StatusText row)
}
PrintText ← {𝕊 index: •Out (Display index)}
PrintTsv ← {𝕊 index:
  row ← index⊑plans ⋄ n ← index+1
  •Out (•Fmt n)∾tab∾row.plan_id∾tab∾row.date∾tab∾row.description∾tab∾row.from_account∾tab∾row.to_account∾tab∾row.amount∾tab∾(StatusTsv row)∾tab∾(Display index)
}

(format≡"tsv")◶⟨
  {𝕊:•Out "Plan rows:" ⋄ PrintText¨↕≠plans},
  {𝕊:PrintTsv¨↕≠plans}
⟩ @