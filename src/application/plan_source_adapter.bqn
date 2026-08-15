# Read-only application adapter for canonical Household Plan Facts.
#
# Physical basenames come from canonical_household_sources.bqn. Account identity
# comes from accounts.journal. Root include topology is checked before Plan-specific
# durable identity admission and generic aligned Fact projection. Plan retirement
# remains a Plan-owned companion relation rather than being flattened into generic
# Transaction/Posting Facts.

io ← •Import "source_io.bqn"
sources ← •Import "canonical_household_sources.bqn"
accountSource ← •Import "account_source_adapter.bqn"
rootAdmission ← •Import "../ledger/canonical_journal_root_admission.bqn"
planAdmission ← •Import "../ledger/plan_journal_admission.bqn"
facts ← •Import "../ledger/facts.bqn"

# Wider application observations can provide one admitted Account Registry and
# interpret Plan alongside other canonical sources without re-reading Accounts.
LoadFromAccounts ← {𝕊 base‿accounts‿registry:
  raw ← io.ReadRaw (io.JoinPath ⟨base,sources.plan⟩)
  rootResult ← rootAdmission.Admit ⟨raw,sources.accounts⟩
  (rootResult.state≡"ok")◶⟨
    {𝕊:{state⇐"error",retirements⇐@,diagnostics⇐rootResult.diagnostics}},
    {𝕊:
      admitted ← planAdmission.Admit ⟨raw,accounts,registry⟩
      (admitted.state≡"ok")◶⟨
        {𝕊:{state⇐"error",retirements⇐@,diagnostics⇐admitted.diagnostics}},
        {𝕊:
          projected ← facts.Project ⟨admitted,accounts⟩
          {
            state⇐projected.state,facts⇐projected,retirements⇐admitted.retirements,
            diagnostics⇐projected.diagnostics
          }
        }
      ⟩ @
    }
  ⟩ @
}

Load ← {𝕊 base‿registry:
  accountResult ← accountSource.Load base
  (accountResult.state≡"ok")◶⟨
    {𝕊:{state⇐"error",retirements⇐@,diagnostics⇐accountResult.diagnostics}},
    {𝕊:LoadFromAccounts ⟨base,accountResult.accounts,registry⟩}
  ⟩ @
}

{Load⇐Load,LoadFromAccounts⇐LoadFromAccounts}
