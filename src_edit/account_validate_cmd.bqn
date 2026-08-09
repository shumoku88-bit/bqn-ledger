# Strict post-write validation for canonical accounts.journal.
accountSource ← •Import "../src/application/account_source_adapter.bqn"
tab ← @+9 ⋄ args ← •args
{𝕊:•Out "ERROR"∾tab∾"usage"∾tab∾"expected base" ⋄ •Exit 2}⍟(1≠≠args) @
result ← accountSource.Load ⊑args
{𝕊:
  {𝕊 diagnostic:•Out "ERROR"∾tab∾diagnostic.stage∾tab∾diagnostic.code∾tab∾diagnostic.message}¨result.diagnostics
  •Exit 1
}⍟(result.state≢"ok") @
•Out "OK"∾tab∾"ACCOUNTS_JOURNAL"∾tab∾•Fmt result.accounts.count
