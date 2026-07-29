# Strict admitted Accounts for editor operations.
# Currency and role are explicit; compatibility prefix/default inference is absent.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
admission ← •Import "../ledger/account_admission.bqn"
Admit ← {𝕊 lines:
  registryResult ← registryBuilder.Build io.ReadLines "config/currencies.tsv"
  result ← {state⇐"error",accounts⇐{count⇐0,index⇐⟨⟩},diagnostics⇐⟨⟩}
  {𝕊:
    result↩admission.Admit ⟨lines,registryResult.registry⟩
    missingRole ← ∨´0∾0=≠¨result.accounts.role
    {𝕊:result↩{state⇐"error",accounts⇐result.accounts,diagnostics⇐result.diagnostics}}⍟(missingRole) @
  }⍟(registryResult.state≡"ok") @
  result
}
Require ← {𝕊 lines:
  result ← Admit lines
  {𝕊:•Out "ERROR: accounts source rejected" ⋄ •Exit 1}⍟(result.state≢"ok") @
  result.accounts
}

{Admit⇐Admit,Require⇐Require}
