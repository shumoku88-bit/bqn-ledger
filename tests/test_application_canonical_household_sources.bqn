# Test the stable canonical Household source topology owner.

sources ← •Import "../src/application/canonical_household_sources.bqn"

expected ← ⟨
  "accounts.journal",
  "actual.journal",
  "plan.journal",
  "budget.journal",
  "budget.toml",
  "household.toml",
  "report.toml",
  "issues.tsv"
⟩

! "accounts.journal" ≡ sources.accounts
! "actual.journal" ≡ sources.actual
! "plan.journal" ≡ sources.plan
! "budget.journal" ≡ sources.budget
! "budget.toml" ≡ sources.budgetPolicy
! "household.toml" ≡ sources.householdPolicy
! "report.toml" ≡ sources.reportPolicy
! "issues.tsv" ≡ sources.issues
! expected ≡ sources.basenames

•Out "test_application_canonical_household_sources passed"
