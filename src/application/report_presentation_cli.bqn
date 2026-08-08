# Effectful adapter exposing admitted canonical Report presentation policy to
# terminal/report wrappers. No source filename or accounting coordinate is
# published here.

source ← •Import "report_policy_source_adapter.bqn"
tab ← @+9 ⋄ args ← •args
Fail ← {𝕊 code‿message:•Out "ERROR"∾tab∾code∾tab∾message ⋄ •Exit 1}
PrintDiagnostics ← {𝕊 diagnostics:{𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨diagnostics ⋄ •Exit 1}

{𝕊:Fail ⟨"usage","expected BASE"⟩}⍟(1≠≠args) @
policy ← source.Load ⊑args
{𝕊:PrintDiagnostics policy.diagnostics}⍟(policy.state≢"ok") @
•Out "negative_style"∾tab∾policy.presentation.negative_style
•Out "negative_color"∾tab∾policy.presentation.negative_color
•Out "daily_flow_max_date_columns"∾tab∾•Fmt policy.presentation.daily_flow_max_date_columns
