# Read-only application adapter for canonical Household Budget evidence.
# budget.journal owns movements; budget.toml owns policy. The two admissions may
# be requested independently so unrelated Household consumers do not depend on
# Budget movement validity.

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
Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:
    raw ← io.ReadRaw (io.JoinPath ⟨base,sources.budget⟩)
    rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
    result↩{state⇐"error",diagnostics⇐rootResult.diagnostics}
    {𝕊:
      admitted ← budgetAdmission.Admit ⟨raw,accountResult.accounts,registry⟩
      policy ← LoadPolicy ⟨base,accountResult.accounts⟩
      diagnostics ← admitted.diagnostics∾policy.diagnostics
      result↩{state⇐"error",diagnostics⇐diagnostics}
      {𝕊:
        projected ← facts.Project ⟨admitted,accountResult.accounts⟩
        diagnostics↩diagnostics∾projected.diagnostics
        result↩{state⇐projected.state,facts⇐projected,policy⇐policy,diagnostics⇐diagnostics}
      }⍟((admitted.state≡"ok") ∧ policy.state≡"ok") @
    }⍟(rootResult.state≡"ok") @
  }⍟(accountResult.state≡"ok") @
  result
}

{Load⇐Load,LoadPolicy⇐LoadPolicy}
