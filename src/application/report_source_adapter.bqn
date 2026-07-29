# Key-specific application I/O adapters. Paths are explicit at the CLI boundary.

io ← •Import "source_io.bqn"
registryBuilder ← •Import "../ledger/currency_registry.bqn"
snapshot ← •Import "../ledger/snapshot.bqn"
empty ← ⟨⟩

Join ← {𝕊 base‿name: base∾(('/'≠¯1↑base)/"/")∾name}
Registry ← {𝕊 path: registryBuilder.Build io.ReadLines path}
Actual ← {𝕊 base‿journalName‿registry:
  snapshot.Build ⟨io.ReadLines Join ⟨base,"accounts.tsv"⟩,io.ReadRaw Join ⟨base,journalName⟩,registry⟩
}
IssueLines ← {𝕊 base‿issueName: io.ReadLines Join ⟨base,issueName⟩}

{Registry⇐Registry,Actual⇐Actual,IssueLines⇐IssueLines}
