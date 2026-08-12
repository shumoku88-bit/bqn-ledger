# Read-only application adapter for canonical Household Plan Facts.
#
# Physical basenames come from canonical_household_sources.bqn. Account identity
# comes from accounts.journal. Root include topology is checked before Plan-specific
# durable identity admission and generic aligned Fact projection.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
rootAdmission ← •Import "../ledger/canonical_journal_root_admission.bqn"
planAdmission ← •Import "../ledger/plan_journal_admission.bqn"
facts ← •Import "../ledger/facts.bqn"

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  result ← {state⇐"error",diagnostics⇐accountResult.diagnostics}
  {𝕊:
    raw ← io.ReadRaw (io.JoinPath ⟨base,sources.plan⟩)
    rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
    result↩{state⇐"error",diagnostics⇐rootResult.diagnostics}
    {𝕊:
      admitted ← planAdmission.Admit ⟨raw,accountResult.accounts,registry⟩
      result↩{state⇐"error",diagnostics⇐admitted.diagnostics}
      {𝕊:
        projected ← facts.Project ⟨admitted,accountResult.accounts⟩
        result↩{state⇐projected.state,facts⇐projected,diagnostics⇐projected.diagnostics}
      }⍟(admitted.state≡"ok") @
    }⍟(rootResult.state≡"ok") @
  }⍟(accountResult.state≡"ok") @
  result
}

{Load⇐Load}
