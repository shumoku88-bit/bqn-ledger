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

{𝕊:Fail ⟨"usage","expected BASE KEY SURFACE and key-specific semantic coordinates"⟩}⍟(3>≠args) @
base‿key‿surface ← 3↑args ⋄ coordinates ← 3↓args
admitted ← request.Validate ⟨key,surface⟩
{𝕊:PrintDiagnostics admitted.diagnostics}⍟(admitted.state≢"ok") @
presentation ← (surface≡"human")◶⟨
  {𝕊:{negative_style⇐"minus"}},
  {𝕊:
    policy ← policySource.Load base
    {𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
    policy.presentation
  }
⟩ @
{𝕊:Fail ⟨"all_not_implemented","parallel CLI currently requires one retained key"⟩}⍟(key≡"all") @
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:PrintDiagnostics ⟨RegistryDiagnostic registryResult⟩}⍟(registryResult.state≢"ok") @
registry ← registryResult.registry
routeAdmission ← route.Admit ⟨key,surface,coordinates⟩
{𝕊:PrintDiagnostics routeAdmission.diagnostics}⍟(routeAdmission.state≢"ok") @
catalogIndex ← routeAdmission.catalog_index ⋄ coordinates↩routeAdmission.coordinates

MakeEvidence ← {𝕊 actualValue‿planValue‿planRetirementsValue‿budgetValue‿budgetPolicyValue‿householdValue‿envelopeHistoryValue‿issueLinesValue:
  {
    registry⇐registry,actual⇐actualValue,plan⇐planValue,plan_retirements⇐planRetirementsValue,budget⇐budgetValue,
    budget_policy⇐budgetPolicyValue,household⇐householdValue,envelope_history⇐envelopeHistoryValue,
    issue_lines⇐issueLinesValue
  }
}
RequireActual ← {𝕊:
  actualResult ← sources.CanonicalActual ⟨base,registry⟩
  {𝕊:PrintDiagnostics actualResult.diagnostics}⍟(actualResult.state≢"ok") @
  actualResult.facts
}
LoadCompanions ← {𝕊:
  actual ← RequireActual @
  companions ← sources.Companions ⟨base,actual.accounts,registry⟩
  {𝕊:PrintDiagnostics companions.diagnostics}⍟(companions.state≢"ok") @
  MakeEvidence ⟨actual,companions.plan,companions.plan_retirements,companions.budget,companions.budget_policy,companions.household,companions.envelope_history,empty⟩
}
LoadActual ← {𝕊:
  actual ← RequireActual @
  MakeEvidence ⟨actual,@,@,@,@,@,@,empty⟩
}
LoadContext ← {𝕊:
  actual ← RequireActual @
  context ← sources.HouseholdContext ⟨base,actual.accounts,registry⟩
  {𝕊:PrintDiagnostics context.diagnostics}⍟(context.state≢"ok") @
  MakeEvidence ⟨actual,context.plan,context.plan_retirements,@,context.budget_policy,context.household,context.envelope_history,empty⟩
}
LoadIssues ← {𝕊:
  MakeEvidence ⟨@,@,@,@,@,@,@,sources.IssueLines base⟩
}
evidenceLoaders ← ⟨
  LoadCompanions,LoadActual,LoadActual,LoadActual,LoadActual,LoadContext,
  LoadContext,LoadContext,LoadActual,LoadContext,LoadContext,LoadIssues
⟩
evidence ← catalogIndex◶evidenceLoaders @

composition ← destination.Build ⟨catalogIndex,coordinates,evidence⟩
{𝕊:PrintDiagnostics composition.diagnostics}⍟(composition.state≢"ok") @
rendered ← render.Render ⟨key,surface,composition,presentation⟩
{𝕊:PrintDiagnostics rendered.diagnostics}⍟(rendered.state≢"ok") @
text ← rendered.text
{𝕊:text↩¯1↓text}⍟((0<≠text) ∧ (@+10)=¯1↑text) @
•Out text
