# journal_shadow_context.bqn
# Standalone, read-only file-backed Minimal Journal shadow-context builder.
# TSV remains the production source of truth and the sole write path.

loader ← •Import "../src/application/source_io.bqn"
cycle ← •Import "cycle.bqn"
ak ← •Import "account_key.bqn"
carrier_module ← •Import "journal_read_only_source_carrier.bqn"
context_module ← •Import "context.bqn"

empty ← ⟨⟩
sourceMode ← "journal-shadow"

IoDiagnostic ← {𝕊 messageText:
  {
    severity⇐"error",
    stage⇐"journal_shadow_context",
    code⇐"journal_file_read_failed",
    message⇐messageText
  }
}

Build ← {𝕊 ⟨base, journalPath, as_of⟩:
  transactions ← empty
  postingRows ← empty
  diagnostics ← empty
  shadowContext ← @
  state ← "error"

  # Read raw text so Minimal Journal comments and blank-line paragraph structure
  # reach Stage 1 unchanged. Catch converts native file errors to checked results.
  loaded ← ({𝕊:
    raw ← loader.ReadRaw journalPath
    {state⇐"ok", raw⇐raw, diagnostics⇐empty}
  } ⎊ {𝕊:
    messageText ← •CurrentError @
    {state⇐"error", raw⇐"", diagnostics⇐⟨IoDiagnostic messageText⟩}
  }) @

  diagnostics ↩ loaded.diagnostics

  {𝕊:
    cy ← cycle.ReadCycle ⟨base, as_of⟩
    accountLines ← loader.ReadLines (base ∾ "/accounts.tsv")
    resolved ← ak.Resolve accountLines
    journalLines ← (@+10) loader.SplitKeepEmpty loaded.raw
    carrier ← {source_file⇐journalPath, lines⇐journalLines}
    carried ← carrier_module.Build ⟨carrier, resolved, cy.start⟩

    transactions ↩ carried.transactions
    diagnostics ↩ carried.diagnostics

    {𝕊:
      postingRows ↩ carried.posting_rows
      view ← context_module.BuildPeriodView ⟨postingRows, resolved, cy⟩
      shadowContext ↩ {
        base⇐base,
        as_of⇐as_of,
        cy⇐cy,
        resolved⇐resolved,
        posting_rows⇐postingRows,
        cube⇐view.cube,
        tbds⇐view.tbds,
        issues⇐empty,
        source_mode⇐sourceMode,
        source_path⇐journalPath,
        transactions⇐transactions,
        diagnostics⇐empty
      }
      diagnostics ↩ empty
      state ↩ "ok"
    }⍟(carried.state ≡ "ok") @
  }⍟(loaded.state ≡ "ok") @

  {
    state⇐state,
    source_mode⇐sourceMode,
    source_path⇐journalPath,
    transactions⇐transactions,
    posting_rows⇐postingRows,
    diagnostics⇐diagnostics,
    context⇐shadowContext
  }
}

{Build⇐Build}
