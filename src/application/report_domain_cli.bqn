# Effectful domain-selection adapter for current Report entry points.

sources ← •Import "report_source_adapter.bqn"
selection ← •Import "report_domain_selection.bqn"
tab ← @+9 ⋄ args ← •args
Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:{𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics ⋄ •Exit 1}

{𝕊:Fail ⟨"usage","expected BASE [DOMAIN]"⟩}⍟(2<≠args) @
base ← ⊑args
requested ← (2=≠args)◶⟨{𝕊:""},{𝕊:1⊑args}⟩ @
registryResult ← sources.Registry "config/currencies.tsv"
{𝕊:Fail ⟨registryResult.code,registryResult.message⟩}⍟(registryResult.state≢"ok") @
actual ← sources.CanonicalActual ⟨base,registryResult.registry⟩
{𝕊:PrintDiagnostics actual.diagnostics}⍟(actual.state≢"ok") @
resolved ← selection.Resolve ⟨actual.facts,requested⟩
{𝕊:PrintDiagnostics resolved.diagnostics}⍟(resolved.state≢"ok") @
•Out resolved.domain
