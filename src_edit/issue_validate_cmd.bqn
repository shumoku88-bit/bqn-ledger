# Strict post-write validation for canonical issues.tsv.
io ← •Import "../src/application/source_io.bqn"
registryMod ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/issue_admission.bqn"
args ← •args
tab ← @+9
{𝕊:•Out "ERROR"∾tab∾"expected base directory" ⋄ •Exit 2}⍟(1≠≠args) @
base ← ⊑args
registryResult ← registryMod.Build io.ReadLines "config/currencies.tsv"
{𝕊:•Out "ERROR"∾tab∾"currency registry invalid" ⋄ •Exit 1}⍟(registryResult.state≢"ok") @
result ← admission.Admit ⟨io.ReadLines base∾"/issues.tsv",registryResult.registry⟩
{𝕊:
  {•Out "ERROR"∾tab∾𝕩.code}¨result.diagnostics
  •Exit 1
}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"issues"∾tab∾•Fmt result.issues.count
