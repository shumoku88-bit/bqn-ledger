# Key-specific application I/O adapters. Canonical Household paths are fixed by
# the eight-file root; legacy report coordinates remain only until report.toml Phase 6.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
budgetSource ← •Import "budget_source_adapter.bqn"
householdSource ← •Import "household_source_adapter.bqn"
empty ← ⟨⟩

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}

# Temporary legacy Actual entry remains only until all Phase 5 consumers below are
# migrated in this Draft. It is removed before the Phase 5 exit gate.
Actual ← {𝕊 base‿journalName‿registry:
  snapshot.Build ⟨io.ReadLines Join ⟨base,"accounts.tsv"⟩,io.ReadRaw Join ⟨base,journalName⟩,registry⟩
}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }
CanonicalPlan ← {𝕊 base‿registry: planSource.Load ⟨base,registry⟩ }
CanonicalBudget ← {𝕊 base‿registry: budgetSource.Load ⟨base,registry⟩ }
CanonicalHousehold ← {𝕊 base‿accounts‿budgetPolicy: householdSource.Load ⟨base,accounts,budgetPolicy⟩ }

# Legacy Plan coordinate remains in request shapes until Phase 6 but cannot choose
# physical Plan I/O.
Plan ← {𝕊 base‿planName‿accounts‿registry:
  planName‿accounts ⋄ CanonicalPlan ⟨base,registry⟩
}

# Read all canonical companion evidence needed by Envelope/Household semantics.
Companions ← {𝕊 base‿planName‿budgetName‿accounts‿registry:
  planName‿budgetName
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
CycleLines ← {𝕊 base‿cycleName: io.ReadLines Join ⟨base,cycleName⟩}
DailyScopeLines ← {𝕊 base‿scopeName: io.ReadLines Join ⟨base,scopeName⟩}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{
  Registry⇐Registry,Actual⇐Actual,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalBudget⇐CanonicalBudget,CanonicalHousehold⇐CanonicalHousehold,Plan⇐Plan,Companions⇐Companions,
  CycleLines⇐CycleLines,DailyScopeLines⇐DailyScopeLines,IssueLines⇐IssueLines
}
