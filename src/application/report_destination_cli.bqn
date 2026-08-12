# Effectful production adapter for one admitted retained-report route.

request ← •Import "../report/request.bqn"
route ← •Import "report_route.bqn"
destination ← •Import "report_destination.bqn"
render ← •Import "../report/render.bqn"
sources ← •Import "report_source_adapter.bqn"
policySource ← •Import "report_policy_source_adapter.bqn"
empty ← ⟨⟩ ⋄ tab ← @+9
args ← •args
Fail ← {𝕊 code‿message: •Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:
  {𝕊 diagnostic: •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics
  •Exit 1
}
RegistryDiagnostic ← {𝕊 result:{severity⇐"error",stage⇐"currency_registry",code⇐result.code,message⇐result.message}}
Contains ← {𝕊 item‿items:∨´0∾item⊸≡¨items}

{𝕊:Fail ⟨"usage","expected BASE KEY SURFACE and key-specific semantic coordinates"⟩}⍟(3>≠args) @
base‿key‿surface ← 3↑args ⋄ coordinates ← 3↓args
admitted ← request.Validate ⟨key,surface⟩
{𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
presentation ← {negative_style⇐"minus"}
{𝕊:
  policy ← policySource.Load base
  {𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
  presentation↩policy.presentation
}⍟(surface≡"human") @
{𝕊:Fail ⟨"all_not_implemented","parallel CLI currently requires one retained key"⟩}⍟(key≡"all") @
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics ⟨RegistryDiagnostic registryResult⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
routeAdmission ← route.Admit ⟨key,surface,coordinates⟩
{𝕊:PrintDiagnostics routeAdmission.diagnostics}⍟(routeAdmission.state≢"ok") @
catalogIndex ← routeAdmission.catalog_index ⋄ coordinates↩routeAdmission.coordinates

actualKeys ← ⟨"envelopes","balances","balance-sheet","profit-and-loss","recent","planned","cycle-accounts","cycle-comparison","monthly-accounts","daily-flow","daily-target"⟩
contextKeys ← ⟨"planned","cycle-accounts","cycle-comparison","daily-flow","daily-target"⟩
actual ← @ ⋄ plan ← @ ⋄ budget ← @ ⋄ budgetPolicy ← @ ⋄ household ← @ ⋄ issueLines ← empty
{𝕊:
  actualResult ← sources.CanonicalActual ⟨base,registry⟩
  {𝕊:PrintDiagnostics actualResult.diagnostics}⍟(actualResult.state≢"ok") @
  actual↩actualResult.facts
}⍟(Contains ⟨key,actualKeys⟩) @
{𝕊:
  companions ← sources.Companions ⟨base,actual.accounts,registry⟩
  {𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
  plan↩companions.plan ⋄ budget↩companions.budget ⋄ budgetPolicy↩companions.budget_policy ⋄ household↩companions.household
}⍟(key≡"envelopes") @
{𝕊:
  context ← sources.HouseholdContext ⟨base,actual.accounts,registry⟩
  {𝕊:PrintDiagnostics context.diagnostics}⍟(context.state≢"ok") @
  plan↩context.plan ⋄ budgetPolicy↩context.budget_policy ⋄ household↩context.household
}⍟(Contains ⟨key,contextKeys⟩) @
{𝕊:issueLines↩sources.IssueLines base}⍟(key≡"issues") @

evidence ← {
  registry⇐registry,actual⇐actual,plan⇐plan,budget⇐budget,
  budget_policy⇐budgetPolicy,household⇐household,issue_lines⇐issueLines
}
composition ← destination.Build ⟨catalogIndex,coordinates,evidence⟩
{𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
rendered ← render.Render ⟨key,surface,composition,presentation⟩
{𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
text ← rendered.text
{𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
•Out text
