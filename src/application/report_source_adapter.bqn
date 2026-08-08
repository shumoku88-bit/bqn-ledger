# Key-specific application I/O adapters. Paths are explicit at the CLI boundary.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
budgetSource ← •Import "budget_source_adapter.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}

# Legacy Actual remains only for routes whose Cycle/Household policy source
# topology has not yet migrated. Canonical Actual-only reports use CanonicalActual.
Actual ← {𝕊 base‿journalName‿registry:
  snapshot.Build ⟨io.ReadLines Join ⟨base,"accounts.tsv"⟩,io.ReadRaw Join ⟨base,journalName⟩,registry⟩
}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }
CanonicalPlan ← {𝕊 base‿registry: planSource.Load ⟨base,registry⟩ }
CanonicalBudget ← {𝕊 base‿registry: budgetSource.Load ⟨base,registry⟩ }

# Report manifests retain a Plan basename coordinate until report.toml Phase 6,
# but physical Plan ownership is already fixed by the canonical Household root.
# The legacy coordinate and caller-supplied Account carrier therefore do not choose
# a Plan source and are intentionally ignored here.
Plan ← {𝕊 base‿planName‿accounts‿registry:
  planName‿accounts ⋄ CanonicalPlan ⟨base,registry⟩
}

# Envelope request coordinates retain legacy Plan/Budget basenames until report.toml
# Phase 6, but neither chooses a physical companion source. Canonical plan.journal,
# budget.journal, and budget.toml are the read owners. The caller Account carrier is
# retained only by the Phase 5 Household structural-policy bridge downstream.
Companions ← {𝕊 base‿planName‿budgetName‿accounts‿registry:
  planName‿budgetName‿accounts
  planResult ← CanonicalPlan ⟨base,registry⟩
  budgetResult ← CanonicalBudget ⟨base,registry⟩
  diagnostics ← planResult.diagnostics∾budgetResult.diagnostics
  ok ← (planResult.state≡"ok") ∧ budgetResult.state≡"ok"
  result ← {state⇐"error",plan⇐@,budget⇐@,budget_policy⇐@,diagnostics⇐diagnostics}
  {𝕊:
    result↩{
      state⇐"ok",plan⇐planResult.facts,budget⇐budgetResult.facts,
      budget_policy⇐budgetResult.policy,diagnostics⇐diagnostics
    }
  }⍟ok @
  result
}
CycleLines ← {𝕊 base‿cycleName: io.ReadLines Join ⟨base,cycleName⟩}
DailyScopeLines ← {𝕊 base‿scopeName: io.ReadLines Join ⟨base,scopeName⟩}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{
  Registry⇐Registry,Actual⇐Actual,CanonicalActual⇐CanonicalActual,CanonicalPlan⇐CanonicalPlan,
  CanonicalBudget⇐CanonicalBudget,Plan⇐Plan,Companions⇐Companions,
  CycleLines⇐CycleLines,DailyScopeLines⇐DailyScopeLines,IssueLines⇐IssueLines
}
