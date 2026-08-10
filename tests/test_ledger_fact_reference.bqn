#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
reference ← •Import "../src/ledger/fact_reference.bqn"

Facts ← {𝕊 state‿sourceNames:
  {
    state⇐state,
    sources⇐{count⇐≠sourceNames,name⇐sourceNames},
    transactions⇐{transaction_id⇐⟨"txn-alpha","txn-beta"⟩},
    postings⇐{posting_id⇐⟨"txn-alpha:0","txn-beta:0"⟩}
  }
}

actual ← Facts ⟨"ok",⟨"actual.journal"⟩⟩
lib.Assert reference.SourceIs ⟨actual,"actual.journal"⟩
lib.Assert ¬reference.SourceIs ⟨actual,"plan.journal"⟩
lib.Assert ¬reference.SourceIs ⟨Facts ⟨"ok",⟨⟩⟩,"actual.journal"⟩
lib.Assert ¬reference.SourceIs ⟨Facts ⟨"ok",⟨"actual.journal","plan.journal"⟩⟩,"actual.journal"⟩
lib.Assert ¬reference.SourceIs ⟨Facts ⟨"error",⟨"actual.journal"⟩⟩,"actual.journal"⟩

transaction ← reference.Transaction ⟨actual,1⟩
"actual.journal" lib.AssertEq transaction.source
"txn-beta" lib.AssertEq transaction.transaction_id

posting ← reference.Posting ⟨actual,1⟩
"actual.journal" lib.AssertEq posting.source
"txn-beta:0" lib.AssertEq posting.posting_id
