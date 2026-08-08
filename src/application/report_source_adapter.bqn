# Key-specific application I/O adapters. Paths are explicit at the CLI boundary.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"
actualSource ← •Import "actual_source_adapter.bqn"
planSnapshot ← •Import "../ledger/plan_snapshot.bqn"
companionSnapshot ← •Import "../ledger/companion_snapshot.bqn"

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}

# Legacy Actual remains only for routes whose Plan/Cycle/Budget source topology has
# not yet migrated. Canonical Actual-only reports use CanonicalActual instead.
Actual ← {𝕊 base‿journalName‿registry:
  snapshot.Build ⟨io.ReadLines Join ⟨base,"accounts.tsv"⟩,io.ReadRaw Join ⟨base,journalName⟩,registry⟩
}
CanonicalActual ← {𝕊 base‿registry: actualSource.Load ⟨base,registry⟩ }

Plan ← {𝕊 base‿planName‿accounts‿registry:
  planSnapshot.Build ⟨io.ReadLines Join ⟨base,planName⟩,accounts,registry⟩
}
Companions ← {𝕊 base‿planName‿budgetName‿accounts‿registry:
  companionSnapshot.Build ⟨
    io.ReadLines Join ⟨base,planName⟩,io.ReadLines Join ⟨base,budgetName⟩,accounts,registry
  ⟩
}
CycleLines ← {𝕊 base‿cycleName: io.ReadLines Join ⟨base,cycleName⟩}
DailyScopeLines ← {𝕊 base‿scopeName: io.ReadLines Join ⟨base,scopeName⟩}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{
  Registry⇐Registry,Actual⇐Actual,CanonicalActual⇐CanonicalActual,
  Plan⇐Plan,Companions⇐Companions,
  CycleLines⇐CycleLines,DailyScopeLines⇐DailyScopeLines,IssueLines⇐IssueLines
}
