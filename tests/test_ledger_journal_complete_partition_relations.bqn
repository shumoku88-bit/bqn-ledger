#!/usr/bin/env bqn

lib ← •Import "test_lib.bqn"
loader ← •Import "../src/application/source_io.bqn"
registry_core ← •Import "../src/ledger/currency_registry.bqn"
admission ← •Import "../src/ledger/journal_complete_admission.bqn"

lf ← @+10
registry ← (registry_core.Build loader.ReadLines "config/currencies.tsv").registry
accounts ← {
  key⇐⟨"assets:cash","expenses:food"⟩,
  currency⇐⟨"JPY","JPY"⟩
}

# Synthetic single-domain partition coordinates must map back to the physical
# complete-Journal transaction and Posting rows. Physical-fallback identity is
# reconstructed from the mapped transaction start, not the synthetic row.
fallbackRaw ← ∾⟨
  "include accounts.journal"∾lf,
  ""∾lf,
  "2026-01-01 * fallback identity"∾lf,
  "    assets:cash  10 JPY"∾lf,
  "    expenses:food  -10 JPY"∾lf,
  ""∾lf,
  "2026-01-02 * durable identity"∾lf,
  "    ; event-id: durable-2"∾lf,
  "    assets:cash  20 JPY"∾lf,
  "    expenses:food  -20 JPY"
⟩
fallback ← admission.Admit ⟨fallbackRaw,accounts,registry⟩
"ok" lib.AssertEq fallback.state
0 lib.AssertEq ≠fallback.diagnostics
2 lib.AssertEq ≠fallback.transactions
⟨"physical_fallback","durable"⟩ lib.AssertEq {𝕩.identity_kind}¨fallback.transactions
⟨"stage0-line-3","durable-2"⟩ lib.AssertEq {𝕩.source_event_id}¨fallback.transactions
⟨3,7⟩ lib.AssertEq {𝕩.source_start_line}¨fallback.transactions
⟨⟨4,5⟩,⟨9,10⟩⟩ lib.AssertEq {{𝕩.source_line}¨𝕩.postings}¨fallback.transactions
⟨⟨"stage0-line-3:0","stage0-line-3:1"⟩,⟨"durable-2:0","durable-2:1"⟩⟩ lib.AssertEq {{𝕩.posting_id}¨𝕩.postings}¨fallback.transactions

# Transaction-local diagnostics remain transaction/source-major even after an
# earlier invalid transaction. Whole-source durable identity diagnostics are
# appended after all local transaction diagnostics.
mixedRaw ← ∾⟨
  "2026-02-01 * malformed first"∾lf,
  "    assets:cash  10 JPY extra"∾lf,
  "    expenses:food  -10 JPY"∾lf,
  ""∾lf,
  "2026-02-02 * duplicate durable one"∾lf,
  "    ; event-id: repeated-event"∾lf,
  "    assets:cash  20 JPY"∾lf,
  "    expenses:food  -20 JPY"∾lf,
  ""∾lf,
  "2026-02-03 * duplicate durable two"∾lf,
  "    ; event-id: repeated-event"∾lf,
  "    assets:cash  30 JPY"∾lf,
  "    expenses:food  -30 JPY"
⟩
mixed ← admission.Admit ⟨mixedRaw,accounts,registry⟩
"error" lib.AssertEq mixed.state
0 lib.AssertEq ≠mixed.transactions
⟨"posting_shape_invalid","event_id_duplicate"⟩ lib.AssertEq {𝕩.code}¨mixed.diagnostics
⟨2,0⟩ lib.AssertEq {𝕩.line}¨mixed.diagnostics

•Out "test_ledger_journal_complete_partition_relations: ok"
