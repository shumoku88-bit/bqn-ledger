# Effectful current multi-report adapter.
# It keeps one admitted report evidence lifetime across one current request set.
# `concat` preserves report-all bytes; `frame` exposes report bodies to shell cache staging.

request ← •Import "../report/request.bqn"
route ← •Import "report_route.bqn"
destination ← •Import "report_destination.bqn"
render ← •Import "../report/render.bqn"
sources ← •Import "report_source_adapter.bqn"
policySource ← •Import "report_policy_source_adapter.bqn"
parse ← •Import "../text/parse.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9 ⋄ newline ← @+10

Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
RegistryDiagnostic ← {𝕊 result:{severity⇐"error",stage⇐"currency_registry",code⇐result.code,message⇐result.message}}

args ← •args
{𝕊:Fail ⟨"usage","expected BASE MODE SURFACE followed by current request rows"⟩}⍟(4>≠args) @
base‿mode‿surface ← 3↑args ⋄ rows ← 3↓args
{𝕊:Fail ⟨"batch_mode_invalid","MODE must be concat or frame"⟩}⍟((mode≢"concat") ∧ mode≢"frame") @
selection ← request.Validate ⟨"all",surface⟩
{𝕊:PrintDiagnostics selection.diagnostics}⍟(selection.state≢"ok") @

AdmitRow ← {𝕊 row:
  fields ← tab parse.SplitKeepEmpty row
  {𝕊:Fail ⟨"current_request_row_invalid","current request row is incomplete"⟩}⍟(2>≠fields) @
  key‿rowSurface ← 2↑fields ⋄ coordinates ← 2↓fields
  {𝕊:Fail ⟨"current_request_surface_mismatch","current request row surface differs from selection"⟩}⍟(rowSurface≢surface) @
  admitted ← route.Admit ⟨key,rowSurface,coordinates⟩
  {𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
  {key⇐key,surface⇐rowSurface,catalog_index⇐admitted.catalog_index,coordinates⇐admitted.coordinates}
}
admittedRows ← AdmitRow¨rows
expectedKeys ← selection.section_keys
actualKeys ← {𝕩.key}¨admittedRows
{𝕊:Fail ⟨"current_request_count_mismatch","current request set must contain every selected key"⟩}⍟((≠expectedKeys)≠≠actualKeys) @
{𝕊:Fail ⟨"current_request_order_mismatch","current request set must use catalog surface order"⟩}⍟(expectedKeys≢actualKeys) @

registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics ⟨RegistryDiagnostic registryResult⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
actualResult ← sources.CanonicalActual ⟨base,registry⟩
{𝕊:PrintDiagnostics actualResult.diagnostics}⍟(actualResult.state≢"ok") @
actual ← actualResult.facts
companions ← sources.Companions ⟨base,actual.accounts,registry⟩
{𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
issueLines ← empty
{𝕊:issueLines↩sources.IssueLines base}⍟(∨´0∾"issues"⊸≡¨actualKeys) @
presentation ← {negative_style⇐"minus"}
{𝕊:
  policy ← policySource.Load base
  {𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
  presentation↩policy.presentation
}⍟(surface≡"human") @

evidence ← {
  registry⇐registry,actual⇐actual,plan⇐companions.plan,plan_retirements⇐companions.plan_retirements,budget⇐companions.budget,
  budget_policy⇐companions.budget_policy,household⇐companions.household,
  envelope_history⇐companions.envelope_history,issue_lines⇐issueLines
}
RenderRow ← {𝕊 row:
  composition ← destination.Build ⟨row.catalog_index,row.coordinates,evidence⟩
  {𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
  rendered ← render.Render ⟨row.key,row.surface,composition,presentation⟩
  {𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
  text ← rendered.text
  {𝕊:text↩¯1↓text}⍟((0<≠text) ∧ newline=¯1↑text) @
  {key⇐row.key,text⇐text,line_count⇐1++´newline=text}
}
renderedRows ← RenderRow¨admittedRows

{𝕊:{𝕊 row:•Out row.text}¨renderedRows}⍟(mode≡"concat") @
{𝕊:
  •Out "BQN-LEDGER-REPORT-BATCH"∾tab∾"1"∾tab∾•Fmt ≠renderedRows
  {𝕊 row:
    •Out "REPORT"∾tab∾row.key∾tab∾•Fmt row.line_count
    •Out row.text
  }¨renderedRows
}⍟(mode≡"frame") @
