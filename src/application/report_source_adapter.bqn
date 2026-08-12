# Key-specific application I/O adapters over the canonical eight-file Household root.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
budgetSource ← •Import "budget_source_adapter.bqn"
householdSource ← •Import "household_source_adapter.bqn"
reportPolicySource ← •Import "report_policy_source_adapter.bqn"
canonical ← •Import "canonical_household_sources.bqn"
empty ← ⟨⟩

Registry ← {𝕊 path:registryBuilder.Build io.ReadLines path}
CanonicalActual ← {𝕊 base‿registry:actualSource.Load ⟨base,registry⟩}
CanonicalPlan ← {𝕊 base‿registry:planSource.Load ⟨base,registry⟩}
CanonicalBudget ← {𝕊 base‿registry:budgetSource.Load ⟨base,registry⟩}
CanonicalBudgetPolicy ← {𝕊 base‿accounts:budgetSource.LoadPolicy ⟨base,accounts⟩}
CanonicalHousehold ← {𝕊 base‿accounts‿budgetPolicy:householdSource.Load ⟨base,accounts,budgetPolicy⟩}
CanonicalReportPolicy ← {𝕊 base:reportPolicySource.Load base}

Unavailable ← {𝕊:{state⇐"error",diagnostics⇐empty}}
ContextFailure ← {𝕊 diagnosticsValue:{state⇐"error",plan⇐@,budget_policy⇐@,household⇐@,diagnostics⇐diagnosticsValue}}
ContextSuccess ← {𝕊 planResult‿policyResult‿householdResult‿diagnosticsValue:
  {state⇐"ok",plan⇐planResult.facts,budget_policy⇐policyResult,household⇐householdResult,diagnostics⇐diagnosticsValue}
}
CompanionFailure ← {𝕊 diagnosticsValue:{state⇐"error",plan⇐@,budget⇐@,budget_policy⇐@,household⇐@,diagnostics⇐diagnosticsValue}}
CompanionSuccess ← {𝕊 context‿budgetResult‿diagnosticsValue:
  {
    state⇐"ok",plan⇐context.plan,budget⇐budgetResult.facts,
    budget_policy⇐context.budget_policy,household⇐context.household,diagnostics⇐diagnosticsValue
  }
}

# A caller that already owns admitted Accounts defines one companion observation:
# Plan, Budget policy, Household policy, and Budget movement all reuse that exact
# Account Registry instead of independently re-reading accounts.journal.
HouseholdContext ← {𝕊 base‿accounts‿registry:
  planResult ← planSource.LoadFromAccounts ⟨base,accounts,registry⟩
  policyResult ← CanonicalBudgetPolicy ⟨base,accounts⟩
  householdResult ← (policyResult.state≡"ok")◶⟨
    {𝕊:Unavailable @},
    {𝕊:CanonicalHousehold ⟨base,accounts,policyResult⟩}
  ⟩ @
  diagnostics ← planResult.diagnostics∾policyResult.diagnostics∾householdResult.diagnostics
  ok ← (planResult.state≡"ok") ∧ (policyResult.state≡"ok") ∧ householdResult.state≡"ok"
  ok◶⟨
    {𝕊:ContextFailure diagnostics},
    {𝕊:ContextSuccess ⟨planResult,policyResult,householdResult,diagnostics⟩}
  ⟩ @
}

Companions ← {𝕊 base‿accounts‿registry:
  context ← HouseholdContext ⟨base,accounts,registry⟩
  budgetResult ← budgetSource.LoadFromAccounts ⟨base,accounts,registry⟩
  diagnostics ← context.diagnostics∾budgetResult.diagnostics
  ok ← (context.state≡"ok") ∧ budgetResult.state≡"ok"
  ok◶⟨
    {𝕊:CompanionFailure diagnostics},
    {𝕊:CompanionSuccess ⟨context,budgetResult,diagnostics⟩}
  ⟩ @
}
IssueLines ← {𝕊 base:io.ReadLines (io.JoinPath ⟨base,canonical.issues⟩)}

{
  Registry⇐Registry,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalBudget⇐CanonicalBudget,CanonicalBudgetPolicy⇐CanonicalBudgetPolicy,
  CanonicalHousehold⇐CanonicalHousehold,CanonicalReportPolicy⇐CanonicalReportPolicy,
  HouseholdContext⇐HouseholdContext,Companions⇐Companions,IssueLines⇐IssueLines
}
