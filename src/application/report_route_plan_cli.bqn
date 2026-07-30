# Machine-readable report-route plan adapter. Reads no household sources.

route ← •Import "report_route.bqn"
tab ← @+9
args ← •args

{𝕊:
  •Out "ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE [COORDINATE...]"
  •Exit 2
}⍟(2>≠args) @

result ← route.Admit ⟨0⊑args,1⊑args,2↓args⟩
{𝕊:
  {𝕊 diagnostic:
    •Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message
  }¨result.diagnostics
  •Exit 1
}⍟(result.state≢"ok") @

•Out "ROUTE"∾tab∾result.key∾tab∾result.surface∾tab∾(•Fmt ≠result.coordinates)∾tab∾•Fmt result.sources.count
{𝕊 sourceIndex:
  •Out "SOURCE"∾tab∾(•Fmt sourceIndex⊑result.sources.argument_index)∾tab∾
    (sourceIndex⊑result.sources.kind)∾tab∾sourceIndex⊑result.sources.role
}¨result.sources.index
