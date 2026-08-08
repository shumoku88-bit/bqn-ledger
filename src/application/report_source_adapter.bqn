# Key-specific application I/O adapters. Paths are explicit at the CLI boundary.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSource ← •Import "plan_source_adapter.bqn"
budgetSnapshot ← •Import "../ledger/budget_snapshot.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}

# Legacy Actual remains only for routes whose Cycle/Budget/Household policy source
# topology has not yet migrated. Canonical Actual-only reports use CanonicalActual.
Actual ← {𝕊 base‿journalName‿registry:
  snapshot.Build ⟨io.ReadLines Join ⟨base,"accounts.tsv"⟩,io.ReadRaw Join ⟨base,journalName⟩,registry⟩
}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }

# Report manifests retain a Plan basename coordinate until report.toml Phase 6,
# but physical Plan ownership is already fixed by the canonical Household root.
# The legacy coordinate and caller-supplied Account carrier therefore do not choose
# a Plan source and are intentionally ignored here.
Plan ← {𝕊 base‿planName‿accounts‿registry:
  planName‿accounts ⋄ planSource.Load ⟨base,registry⟩
}

# Envelope remains mixed-source until Budget Phase 4: canonical Plan Facts plus
# retained budget_alloc.tsv Facts. No Plan TSV is read through this composition.
Companions ← {𝕊 base‿planName‿budgetName‿accounts‿registry:
  planResult ← Plan ⟨base,planName,accounts,registry⟩
  budgetResult ← budgetSnapshot.Build ⟨io.ReadLines Join ⟨base,budgetName⟩,accounts,registry⟩
  diagnostics ← planResult.diagnostics∾budgetResult.diagnostics
  ok ← (planResult.state≡"ok") ∧ budgetResult.state≡"ok"
  result ← {state⇐"error",plan⇐@,budget⇐@,diagnostics⇐diagnostics}
  {𝕊: result↩{state⇐"ok",plan⇐planResult.facts,budget⇐budgetResult.facts,diagnostics⇐diagnostics}}⍟ok @
  result
}
CycleLines ← {𝕊 base‿cycleName: io.ReadLines Join ⟨base,cycleName⟩}
DailyScopeLines ← {𝕊 base‿scopeName: io.ReadLines Join ⟨base,scopeName⟩}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{
  Registry⇐Registry,Actual⇐Actual,CanonicalActual⇐CanonicalActual,
  Plan⇐Plan,Companions⇐Companions,
  CycleLines⇐CycleLines,DailyScopeLines⇐DailyScopeLines,IssueLines⇐IssueLines
}
