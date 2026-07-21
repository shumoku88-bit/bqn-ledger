# journal_read_only_source_carrier.bqn
# Test-only read-only carrier for public synthetic Minimal BQN Journal evidence.
# Performs no I/O and is not connected to production routing.
# Preserves Stage 1 and Stage 2A outputs without changing Posting IR rows.

parser ← •Import "journal_profile_stage1.bqn"
adapter ← •Import "journal_posting_ir_stage2a.bqn"

Build ← {𝕊 ⟨carrier, resolved, cycleStart⟩:
  lf ← @+10
  raw ← ∾ carrier.lines ∾¨ lf
  parsed ← parser.Parse raw

  state ← "error"
  transactions ← parsed.transactions
  postingRows ← ⟨⟩
  diagnostics ← parsed.diagnostics

  {
    adapterResult ← adapter.Build ⟨parsed.transactions, resolved, cycleStart⟩
    state ↩ ((parsed.state ≡ "ok") ∧ (adapterResult.state ≡ "ok")) ⊑ "error"‿"ok"
    postingRows ↩ (adapterResult.state ≡ "ok") ⊑ ⟨⟩‿adapterResult.posting_rows
    diagnostics ↩ parsed.diagnostics ∾ adapterResult.diagnostics
  }⍟(parsed.state ≡ "ok") @

  {
    state ⇐ state,
    source_file ⇐ carrier.source_file,
    transactions ⇐ transactions,
    posting_rows ⇐ postingRows,
    diagnostics ⇐ diagnostics
  }
}

{Build ⇐ Build}
