# context.bqn
# Ledger context and period view construction for src_next.
#
# Architecture:
#   BuildAllRows      — load all posting rows from source TSV (depends on cycleStart
#                       for day_index resolution, but does not filter by period)
#   BuildPeriodView   — build cycle-bounded cube + ledger-wide TBDS from posting rows
#   BuildContext      — convenience: read cycle.tsv, build everything at once
#
# Contract:
#   cycle / period is a report query parameter, not a ledger loading boundary.
#   Posting rows are built for the full source history (cycleStart is for
#   day_index computation, not for row filtering).
#   TBDS uses all posting rows for opening balances, period-bounded for movement.
#   Context is read-only within sections. Sections must not mutate ctx.

loader ← •Import "loader.bqn"
ak ← •Import "account_key.bqn"
proj ← •Import "projection.bqn"
cycle ← •Import "cycle.bqn"
cube ← •Import "cube.bqn"
tbds ← •Import "tbds.bqn"

# BuildRowsForFile: build projection rows for a single source file.
BuildRowsForFile ← {𝕊 base‿resolved‿cycleStart‿srcFile:
  lines ← loader.ReadLines (base ∾ "/" ∾ srcFile)
  names  ← resolved.accounts
  roles  ← resolved.roles
  keys   ← resolved.account_keys
  n      ← ≠ lines
  args ← {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ lines)
    ⟨srcFile, i, flds, names, roles, keys, cycleStart⟩
  } ¨ ↕ n
  ∾ (proj.MakeRow ¨ args)
}

# BuildRowsForFileOptional: like BuildRowsForFile but returns empty for missing/empty files.
BuildRowsForFileOptional ← {𝕊 base‿resolved‿cycleStart‿srcFile:
  lines ← loader.ReadLinesOptional (base ∾ "/" ∾ srcFile)
  names  ← resolved.accounts
  roles  ← resolved.roles
  keys   ← resolved.account_keys
  args ← {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ lines)
    ⟨srcFile, i, flds, names, roles, keys, cycleStart⟩
  } ¨ ↕ (≠ lines)
  ∾ (proj.MakeRow ¨ args)
}

# BuildAllRows: construct all posting rows from source TSV files.
# Args: ⟨base, resolved, cycleStart⟩
#   cycleStart is used for day_index computation, not for row filtering.
#   All valid source dates produce posting rows regardless of cycle position.
# Returns: 1D array of posting row namespaces.
BuildAllRows ← {𝕊 base‿resolved‿cycleStart:
  jrows ← BuildRowsForFile ⟨base, resolved, cycleStart, "journal.tsv"⟩
  prows ← BuildRowsForFileOptional ⟨base, resolved, cycleStart, "plan.tsv"⟩
  brows ← BuildRowsForFileOptional ⟨base, resolved, cycleStart, "budget_alloc.tsv"⟩
  jrows ∾ prows ∾ brows
}

# BuildPeriodView: materialize cycle-bounded cube and ledger-wide TBDS from posting rows.
# Args: ⟨rows, resolved, cy⟩
#   rows     — all posting rows (ledger-wide, not period-filtered)
#   resolved — account_key.Resolve result
#   cy       — selected period (start, end_exclusive, day_count, mode)
# Returns: { cube, tbds }
BuildPeriodView ← {𝕊 rows‿resolved‿cy:
  # Cube is cycle-bounded: only rows with day_index in [0, day_count) are used.
  result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
  # TBDS uses all posting rows for opening balances, cycle-bounded for movement.
  tbdsRows ← tbds.Build ⟨rows, result, resolved, cy⟩
  { cube ⇐ result, tbds ⇐ tbdsRows }
}

# BuildContext: convenience — read cycle.tsv, build everything at once.
# Args: base (string, e.g. "data" or "fixtures/src-next-golden")
# Returns: context namespace.
BuildContext ← {𝕊 arg:
  is_string ← (0 = ≠ arg) ∨ (2 = •Type 0 ⊑ arg ∾ ⟨' '⟩)
  base ← is_string ⊑ ⟨ 0 ⊑ arg, arg ⟩
  base2 ← (0 < ≠ base) ⊑ ⟨ ".", base ⟩
  
  # Resolve default as_of: read cycle to find its start date
  cy_default ← cycle.ReadCycle base2
  as_of ← is_string ◶ ⟨ { 1 ⊑ arg }, { cy_default.start } ⟩ @
  
  cy           ← cycle.ReadCycle ⟨base2, as_of⟩
  accLines     ← loader.ReadLines (base2 ∾ "/accounts.tsv")
  resolved     ← ak.Resolve accLines
  rows         ← BuildAllRows ⟨base2, resolved, cy.start⟩
  view         ← BuildPeriodView ⟨rows, resolved, cy⟩
  
  # Load and parse issues.tsv
  issueLines   ← loader.ReadLinesOptional (base2 ∾ "/issues.tsv")
  MakeIssueRow ← {𝕊 flds:
    # Ensure at least 5 fields are present
    flds2 ← flds ∾ (5-≠flds) ⥊ ⟨""⟩
    {
      date   ⇐ 0 ⊑ flds2,
      status ⇐ 1 ⊑ flds2,
      title  ⇐ 2 ⊑ flds2,
      amount ⇐ 3 ⊑ flds2,
      memo   ⇐ 4 ⊑ flds2
    }
  }
  issueRawRows ← (0 < ≠ issueLines) ◶ ⟨ { ⟨⟩ }, { loader.SplitTsvKeepEmpty ¨ 1 ↓ issueLines } ⟩ @
  issues       ← MakeIssueRow ¨ issueRawRows

  {
    base         ⇐ base2,
    as_of        ⇐ as_of,
    cy           ⇐ cy,
    resolved     ⇐ resolved,
    posting_rows ⇐ rows,
    cube         ⇐ view.cube,
    tbds         ⇐ view.tbds,
    issues       ⇐ issues
  }
}

{ BuildContext ⇐ BuildContext, BuildAllRows ⇐ BuildAllRows, BuildPeriodView ⇐ BuildPeriodView, BuildRowsForFile ⇐ BuildRowsForFile, BuildRowsForFileOptional ⇐ BuildRowsForFileOptional }
