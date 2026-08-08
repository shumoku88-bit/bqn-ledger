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

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }
CanonicalPlan ← {𝕊 base‿registry: planSource.Load ⟨base,registry⟩ }
CanonicalBudget ← {𝕊 base‿registry: budgetSource.Load ⟨base,registry⟩ }
CanonicalBudgetPolicy ← {𝕊 base‿accounts: budgetSource.LoadPolicy ⟨base,accounts⟩ }
CanonicalHousehold ← {𝕊 base‿accounts‿budgetPolicy: householdSource.Load ⟨base,accounts,budgetPolicy⟩ }
CanonicalReportPolicy ← {𝕊 base: reportPolicySource.Load base}

HouseholdContext ← {𝕊 base‿accounts‿registry:
  planResult ← CanonicalPlan ⟨base,registry⟩
  policyResult ← CanonicalBudgetPolicy ⟨base,accounts⟩
  diagnostics ← planResult.diagnostics∾policyResult.diagnostics
  householdResult ← {state⇐"error",diagnostics⇐empty}
  {𝕊:
    householdResult↩CanonicalHousehold ⟨base,accounts,policyResult⟩
    diagnostics∾↩householdResult.diagnostics
  }⍟(policyResult.state≡"ok") @
  ok ← (planResult.state≡"ok") ∧ (policyResult.state≡"ok") ∧ householdResult.state≡"ok"
  result ← {state⇐"error",plan⇐@,budget_policy⇐@,household⇐@,diagnostics⇐diagnostics}
  {𝕊:result↩{state⇐"ok",plan⇐planResult.facts,budget_policy⇐policyResult,household⇐householdResult,diagnostics⇐diagnostics}}⍟ok @
  result
}

Companions ← {𝕊 base‿accounts‿registry:
  context ← HouseholdContext ⟨base,accounts,registry⟩
  budgetResult ← CanonicalBudget ⟨base,registry⟩
  diagnostics ← context.diagnostics∾budgetResult.diagnostics
  ok ← (context.state≡"ok") ∧ budgetResult.state≡"ok"
  result ← {state⇐"error",plan⇐@,budget⇐@,budget_policy⇐@,household⇐@,diagnostics⇐diagnostics}
  {𝕊:
    result↩{
      state⇐"ok",plan⇐context.plan,budget⇐budgetResult.facts,
      budget_policy⇐context.budget_policy,household⇐context.household,diagnostics⇐diagnostics
    }
  }⍟ok @
  result
}
IssueLines ← {𝕊 base: io.ReadLines Join ⟨base,canonical.issues⟩}

{
  Registry⇐Registry,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalBudget⇐CanonicalBudget,CanonicalBudgetPolicy⇐CanonicalBudgetPolicy,
  CanonicalHousehold⇐CanonicalHousehold,CanonicalReportPolicy⇐CanonicalReportPolicy,
  HouseholdContext⇐HouseholdContext,Companions⇐Companions,IssueLines⇐IssueLines
}
