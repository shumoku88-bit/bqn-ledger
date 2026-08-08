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

! "accounts.journal" ≡ sources.Accounts
! "actual.journal" ≡ sources.Actual
! "plan.journal" ≡ sources.Plan
! "budget.journal" ≡ sources.Budget
! "budget.toml" ≡ sources.BudgetPolicy
! "household.toml" ≡ sources.HouseholdPolicy
! "report.toml" ≡ sources.ReportPolicy
! "issues.tsv" ≡ sources.Issues
! expected ≡ sources.Basenames
! 8 = ≠ sources.Basenames
! 8 = ≠ ⍷ sources.Basenames

•Out "test_application_canonical_household_sources passed"
