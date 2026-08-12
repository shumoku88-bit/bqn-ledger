# Stable canonical Household source basenames shared by BQN application adapters.
#
# This owner names physical files only. It does not read them, interpret policy,
# select writer authority, or provide legacy fallback. Migration adapters import
# these names instead of reconstructing basenames independently.

accounts ← "accounts.journal"
actual ← "actual.journal"
plan ← "plan.journal"
budget ← "budget.journal"
budgetPolicy ← "budget.toml"
householdPolicy ← "household.toml"
reportPolicy ← "report.toml"
issues ← "issues.tsv"

{
  accounts⇐accounts,
  actual⇐actual,
  plan⇐plan,
  budget⇐budget,
  budgetPolicy⇐budgetPolicy,
  householdPolicy⇐householdPolicy,
  reportPolicy⇐reportPolicy,
  issues⇐issues
}
