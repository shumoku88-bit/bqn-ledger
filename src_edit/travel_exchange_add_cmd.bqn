# travel_exchange_add_cmd.bqn
# I/O boundary for travel_exchange_events.tsv validation and APPEND protocol.

loader ← •Import "../src/application/source_io.bqn"
exchange ← •Import "../src/editor/travel_exchange_event.bqn"
editorAccounts ← •Import "../src/application/editor_accounts.bqn"
defaults ← •Import "../src/application/system_defaults.bqn"

args ← •args
tab ← @+9
file ← "travel_exchange_events.tsv"
sys ← defaults.Load @
FailDiagnostics ← {𝕊 diagnostics:
  {•Out "ERROR"∾tab∾𝕩.code∾tab∾𝕩.field∾tab∾𝕩.message}¨diagnostics
  •Exit 1
}
{𝕊⋄•Out "ERROR"∾tab∾"usage"⋄•Exit 2}⍟(2>≠args) @
base ← 0⊑args
mode ← 1⊑args
accountLines ← loader.ReadLinesOptional (base∾"/"∾sys.DefaultAccountsFile @)
resolved ← editorAccounts.Require accountLines
accounts ← {𝕊 i: {name⇐i⊑resolved.key, exists⇐1, currency⇐i⊑resolved.currency}}¨ resolved.index
lines ← loader.ReadLinesOptional (base∾"/"∾file)

{𝕊:
  result ← exchange.ValidateExisting ⟨lines, accounts⟩
  {𝕊⋄FailDiagnostics result.diagnostics}⍟(result.state≢"ok") @
  •Out "OK"∾tab∾"VALID"∾tab∾file∾tab∾•Fmt result.event_count
  •Exit 0
}⍟(mode≡"validate") @

{𝕊⋄•Out "ERROR"∾tab∾"usage"⋄•Exit 2}⍟((mode≢"add")∨12≠≠args) @
fields ← 2↓args
result ← exchange.ValidateSourceAndPreview {candidate_fields⇐fields, existing_lines⇐lines, accounts⇐accounts}
{𝕊⋄FailDiagnostics result.diagnostics}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"APPEND"∾tab∾file
•Out ⊑result.preview_rows
