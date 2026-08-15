# Test helper for consumers of the shared canonical household.toml fixture.
# It exercises the same current-policy projection boundary as production source
# adapters before calling the strict current Household policy owner.

projection ← •Import "../src/ledger/household_current_policy_projection.bqn"
core ← •Import "../src/ledger/household_policy_admission.bqn"

Admit ← {𝕊 raw‿accounts‿budgetPolicy:
  core.Admit ⟨projection.CurrentPolicy raw,accounts,budgetPolicy⟩
}

{Admit⇐Admit}
