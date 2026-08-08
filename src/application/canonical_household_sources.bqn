# Stable canonical Household source basenames shared by BQN application adapters.
#
# This owner names physical files only. It does not read them, interpret policy,
# select writer authority, or provide legacy fallback. Migration adapters import
# these names instead of reconstructing basenames independently.

Accounts ← "accounts.journal"
Actual ← "actual.journal"
Plan ← "plan.journal"
Budget ← "budget.journal"
BudgetPolicy ← "budget.toml"
HouseholdPolicy ← "household.toml"
ReportPolicy ← "report.toml"
Issues ← "issues.tsv"

Basenames ← ⟨
  Accounts,
  Actual,
  Plan,
  Budget,
  BudgetPolicy,
  HouseholdPolicy,
  ReportPolicy,
  Issues
⟩

{
  Accounts⇐Accounts,
  Actual⇐Actual,
  Plan⇐Plan,
  Budget⇐Budget,
  BudgetPolicy⇐BudgetPolicy,
  HouseholdPolicy⇐HouseholdPolicy,
  ReportPolicy⇐ReportPolicy,
  Issues⇐Issues,
  Basenames⇐Basenames
}
