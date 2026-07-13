# currency_setup_cli.bqn
# Read-only CLI adapter for M1.5 default-currency audit and JPY migration preview.

setup ← •Import "currency_setup.bqn"
util ← •Import "util.bqn"

ReadPreserve ← {𝕊 path:
  raw ← •FChars path
  clean ← ((@+13) ≠ raw) / raw
  (@+10) util.SplitKeepEmpty clean
}

ReadRequired ← {𝕊 path:
  {𝕊:
    •Out "ERROR: required source file not found: " ∾ path
    •Exit 1
  } ⍟ (¬ •file.Exists path) @
  ReadPreserve path
}

ReadOptional ← {𝕊 path:
  (•file.Exists path) ? ReadPreserve path ; ⟨⟩
}

PrintChangedRow ← {𝕊 fileName‿row:
  {𝕊:
    •Out "FILE " ∾ fileName ∾ " ROW " ∾ (•Fmt row.source_row)
    •Out "-" ∾ row.original_line
    •Out "+" ∾ row.proposed_line
  } ⍟ (row.classification ≡ "missing") @
}

PrintErrorRow ← {𝕊 row:
  {𝕊: •Out "ERROR: " ∾ row.message } ⍟ (row.state ≢ "ok") @
}

PrintFile ← {𝕊 mode‿file:
  •Out "file=" ∾ file.file_name ∾ " state=" ∾ file.state ∾ " missing=" ∾ (•Fmt file.missing_count) ∾ " explicit=" ∾ (•Fmt file.explicit_count) ∾ " errors=" ∾ (•Fmt file.error_count)
  {𝕊:
    {𝕊 row: PrintChangedRow ⟨file.file_name, row⟩}¨ file.rows
  } ⍟ ((mode ≡ "dry-run") ∧ (file.state ≡ "ok")) @
  PrintErrorRow¨ file.rows
}

Main ← {𝕊 mode‿base:
  validMode ← (mode ≡ "audit") ∨ (mode ≡ "dry-run")
  {𝕊:
    •Out "ERROR: mode must be audit or dry-run"
    •Exit 1
  } ⍟ (¬ validMode) @

  configLines ← ReadRequired (base ∾ "/config.tsv")
  accountLines ← ReadRequired (base ∾ "/accounts.tsv")
  journalLines ← ReadRequired (base ∾ "/journal.tsv")
  planLines ← ReadOptional (base ∾ "/plan.tsv")
  budgetLines ← ReadOptional (base ∾ "/budget_alloc.tsv")

  result ← setup.Build ⟨configLines, accountLines, journalLines, planLines, budgetLines, "JPY"⟩
  defaultResult ← result.default_currency

  •Out "state=" ∾ result.state
  •Out "default_key=" ∾ defaultResult.key
  •Out "default_state=" ∾ defaultResult.state
  •Out "default_currency=" ∾ defaultResult.currency
  •Out "default_provenance=" ∾ defaultResult.provenance
  •Out "migration_target=" ∾ result.migration_target
  •Out "changed_count=" ∾ (•Fmt result.changed_count)
  •Out "error_count=" ∾ (•Fmt result.error_count)

  {𝕊 file: PrintFile ⟨mode, file⟩}¨ result.files
  {𝕊: •Out "ERROR: " ∾ result.message } ⍟ ((result.state ≢ "ok") ∧ (0 < ≠ result.message)) @
  {𝕊: •Exit 1 } ⍟ (result.state ≢ "ok") @
}

{𝕊:
  •Out "ERROR: expected mode and base directory"
  •Exit 1
} ⍟ (2 ≠ ≠ •args) @

Main •args
