# Source validation and durable source-qualified references for cross-Fact-set consumers.

SourceIs ← {𝕊 facts‿sourceName:
  ok ← 0
  {𝕊: ok↩(⊑facts.sources.name)≡sourceName}⍟((facts.state≡"ok") ∧ facts.sources.count=1) @
  ok
}
Transaction ← {𝕊 facts‿transactionIndex:
  {source⇐⊑facts.sources.name,transaction_id⇐transactionIndex⊑facts.transactions.transaction_id}
}
Posting ← {𝕊 facts‿postingIndex:
  {source⇐⊑facts.sources.name,posting_id⇐postingIndex⊑facts.postings.posting_id}
}

{SourceIs⇐SourceIs,Transaction⇐Transaction,Posting⇐Posting}
