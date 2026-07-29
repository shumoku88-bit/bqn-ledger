# Pure selected-key listing for the application all runner.

request ← •Import "../report/request.bqn"
tab ← @+9 ⋄ args ← •args
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected KEY SURFACE" ⋄ •Exit 2}⍟(2≠≠args) @
result ← request.Validate args
{𝕊:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.code∾tab∾diagnostic.message}¨result.diagnostics
  •Exit 1
}⍟(result.state≢"ok") @
•Out¨result.section_keys
