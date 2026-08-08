# Read-only application adapter for canonical Household Budget evidence.
#
# Physical basenames come from canonical_household_sources.bqn. Account identity
# comes from accounts.journal. budget.journal is projected directly to aligned
# Facts and budget.toml is admitted as BQN-native policy. No legacy TSV fallback
# or writer authority is present here.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
rootAdmission ← •Import "../ledger/canonical_journal_root_admission.bqn"
budgetAdmission ← •Import "../ledger/budget_journal_admission.bqn"
policyAdmission ← •Import "../ledger/budget_policy_admission.bqn"
facts ← •Import "../ledger/facts.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:
    raw ← io.ReadRaw Join ⟨base,sources.budget⟩
    rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
    result↩{state⇐"error",diagnostics⇐rootResult.diagnostics}
    {𝕊:
      admitted ← budgetAdmission.Admit ⟨raw,accountResult.accounts,registry⟩
      policy ← policyAdmission.Admit ⟨io.ReadRaw Join ⟨base,sources.budgetPolicy⟩,accountResult.accounts⟩
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

{Load⇐Load}
