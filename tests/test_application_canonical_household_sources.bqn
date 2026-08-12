# Test the stable canonical Household source topology owner.

sources ← •Import "../src/application/canonical_household_sources.bqn"

! "accounts.journal" ≡ sources.accounts
! "actual.journal" ≡ sources.actual
! "plan.journal" ≡ sources.plan
! "budget.journal" ≡ sources.budget
! "budget.toml" ≡ sources.budgetPolicy
! "household.toml" ≡ sources.householdPolicy
! "report.toml" ≡ sources.reportPolicy
! "issues.tsv" ≡ sources.issues

names ← ⟨
  sources.accounts,sources.actual,sources.plan,sources.budget,
  sources.budgetPolicy,sources.householdPolicy,sources.reportPolicy,sources.issues
⟩
! (≠names) = ≠⍷names

•Out "test_application_canonical_household_sources passed"
