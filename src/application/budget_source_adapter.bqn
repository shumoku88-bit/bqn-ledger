# Read-only application adapter for canonical Household Budget evidence.
# budget.journal owns its admitted source-ordered movement relation; generic Facts
# remain an additional projection for unrelated consumers. budget.toml owns policy.
# Policy may be requested independently so unrelated Household consumers do not
# depend on Budget movement validity.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
rootAdmission ← •Import "../ledger/canonical_journal_root_admission.bqn"
budgetAdmission ← •Import "../ledger/budget_journal_admission.bqn"
policyAdmission ← •Import "../ledger/budget_policy_admission.bqn"
facts ← •Import "../ledger/facts.bqn"

LoadPolicy ← {𝕊 base‿accounts:
  policyAdmission.Admit ⟨io.ReadRaw (io.JoinPath ⟨base,sources.budgetPolicy⟩),accounts⟩
}

# Wider application observations can provide one admitted Account Registry and
# interpret Budget movement/policy against the same Account evidence as siblings.
LoadFromAccounts ← {𝕊 base‿accounts‿registry:
  raw ← io.ReadRaw (io.JoinPath ⟨base,sources.budget⟩)
  rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
  result ← {state⇐"error",movements⇐@,facts⇐@,policy⇐@,diagnostics⇐rootResult.diagnostics}
  {𝕊:
    admitted ← budgetAdmission.Admit ⟨raw,accounts,registry⟩
    policy ← LoadPolicy ⟨base,accounts⟩
    diagnostics ← admitted.diagnostics∾policy.diagnostics
    result↩{state⇐"error",movements⇐@,facts⇐@,policy⇐policy,diagnostics⇐diagnostics}
    {𝕊:
      projected ← facts.Project ⟨admitted,accounts⟩
      diagnostics↩diagnostics∾projected.diagnostics
      result↩{state⇐projected.state,movements⇐admitted,facts⇐projected,policy⇐policy,diagnostics⇐diagnostics}
    }⍟((admitted.state≡"ok") ∧ policy.state≡"ok") @
  }⍟(rootResult.state≡"ok") @
  result
}

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:result↩LoadFromAccounts ⟨base,accountResult.accounts,registry⟩}⍟(accountResult.state≡"ok") @
  result
}

{Load⇐Load,LoadFromAccounts⇐LoadFromAccounts,LoadPolicy⇐LoadPolicy}
