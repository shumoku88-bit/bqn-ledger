# Key-specific application I/O adapters over the canonical eight-file Household root.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
budgetSource ← •Import "budget_source_adapter.bqn"
householdSource ← •Import "household_source_adapter.bqn"
empty ← ⟨⟩

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }
CanonicalPlan ← {𝕊 base‿registry: planSource.Load ⟨base,registry⟩ }
CanonicalBudget ← {𝕊 base‿registry: budgetSource.Load ⟨base,registry⟩ }
CanonicalHousehold ← {𝕊 base‿accounts‿budgetPolicy: householdSource.Load ⟨base,accounts,budgetPolicy⟩ }

Companions ← {𝕊 base‿accounts‿registry:
  planResult ← CanonicalPlan ⟨base,registry⟩
  budgetResult ← CanonicalBudget ⟨base,registry⟩
  diagnostics ← planResult.diagnostics∾budgetResult.diagnostics
  householdResult ← {state⇐"error",diagnostics⇐empty}
  {𝕊:
    householdResult↩CanonicalHousehold ⟨base,accounts,budgetResult.policy⟩
    diagnostics∾↩householdResult.diagnostics
  }⍟(budgetResult.state≡"ok") @
  ok ← (planResult.state≡"ok") ∧ (budgetResult.state≡"ok") ∧ householdResult.state≡"ok"
  result ← {state⇐"error",plan⇐@,budget⇐@,budget_policy⇐@,household⇐@,diagnostics⇐diagnostics}
  {𝕊:
    result↩{
      state⇐"ok",plan⇐planResult.facts,budget⇐budgetResult.facts,
      budget_policy⇐budgetResult.policy,household⇐householdResult,diagnostics⇐diagnostics
    }
  }⍟ok @
  result
}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{
  Registry⇐Registry,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalBudget⇐CanonicalBudget,CanonicalHousehold⇐CanonicalHousehold,
  Companions⇐Companions,IssueLines⇐IssueLines
}
