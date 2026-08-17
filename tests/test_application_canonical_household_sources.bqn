# Test the stable canonical Household source topology owner.

sources ← •Import "../src/application/canonical_household_sources.bqn"

! "accounts.journal" ≡ sources.accounts
! "actual.journal" ≡ sources.actual
! "plan.journal" ≡ sources.plan
! "entitlement.journal" ≡ sources.entitlement
! "envelope.toml" ≡ sources.envelopePolicy
! "household.toml" ≡ sources.householdPolicy
! "report.toml" ≡ sources.reportPolicy
! "issues.tsv" ≡ sources.issues

names ← ⟨
  sources.accounts,sources.actual,sources.plan,sources.entitlement,
  sources.envelopePolicy,sources.householdPolicy,sources.reportPolicy,sources.issues
⟩
! (≠names) = ≠⍷names

•Out "test_application_canonical_household_sources passed"
