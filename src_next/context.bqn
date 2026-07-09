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

MakePostingSource ← {𝕊 srcFile‿required‿lines:
  { source_file ⇐ srcFile, required ⇐ required, lines ⇐ lines }
}

# LoadPostingSourceSnapshot: load all posting source lines once.
# journal.tsv remains required; plan.tsv and budget_alloc.tsv remain optional.
LoadPostingSourceSnapshot ← {𝕊 base:
  journalLines ← loader.ReadLines (base ∾ "/journal.tsv")
  planLines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  budgetLines ← loader.ReadLinesOptional (base ∾ "/budget_alloc.tsv")
  {
    journal ⇐ MakePostingSource ⟨"journal.tsv", 1, journalLines⟩,
    plan ⇐ MakePostingSource ⟨"plan.tsv", 0, planLines⟩,
    budget_alloc ⇐ MakePostingSource ⟨"budget_alloc.tsv", 0, budgetLines⟩,
    sources ⇐ ⟨
      MakePostingSource ⟨"journal.tsv", 1, journalLines⟩,
      MakePostingSource ⟨"plan.tsv", 0, planLines⟩,
      MakePostingSource ⟨"budget_alloc.tsv", 0, budgetLines⟩
    ⟩
  }
}

ProofProven ← {𝕊 basis: { state ⇐ "proven", domain ⇐ "JPY", basis ⇐ basis, message ⇐ "" } }
ProofUnsupportedCurrency ← {𝕊 srcFile‿rowIdx:
  { state ⇐ "unsupported", domain ⇐ "", basis ⇐ "explicit_source_currency", message ⇐ "explicit source currency unsupported in Stage 2 minimal runtime slice: " ∾ srcFile ∾ " row " ∾ (•Fmt rowIdx) }
}

HasCurrencyMeta ← {𝕊 flds:
  metas ← 5 ↓ flds
  pref ← "currency="
  plen ← ≠ pref
  ok_len ← { plen ≤ ≠ 𝕩 } ¨ metas
  is_match ← ok_len × { pref ≡ plen ↑ 𝕩 } ¨ metas
  ∨´ 0 ∾ is_match
}

ResolveArithmeticCurrencyProof ← {𝕊 snapshot:
  proof ← ProofProven "legacy_compatibility"
  rowCount ← 0
  found ← 0
  {𝕊 src:
    rowCount ↩ rowCount + ≠ src.lines
    {𝕊 i:
      flds ← loader.SplitTsvKeepEmpty (i ⊑ src.lines)
      {𝕊:
        proof ↩ ProofUnsupportedCurrency ⟨src.source_file, i⟩
        found ↩ 1
      }⍟((¬found) ∧ HasCurrencyMeta flds) @
    }¨ ↕ ≠ src.lines
  }¨ snapshot.sources
  {𝕊: proof ↩ ProofProven "empty_source_compatibility"}⍟((0=rowCount) ∧ (¬found)) @
  proof
}

ArgsForSource ← {𝕊 src‿resolved‿cycleStart:
  names  ← resolved.accounts
  roles  ← resolved.roles
  keys   ← resolved.account_keys
  {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ src.lines)
    ⟨src.source_file, i, flds, names, roles, keys, cycleStart⟩
  } ¨ ↕ ≠ src.lines
}

# BuildRowsForSource: projection-owned authorization gate before naked deltas.
BuildRowsForSource ← {𝕊 source‿resolved‿cycleStart‿proof:
  args ← ArgsForSource ⟨source, resolved, cycleStart⟩
  proj.MakeRowsAuthorized ⟨proof, args⟩
}

# BuildRowsForFile: compatibility exported path; still loads one full posting-source
# snapshot and projects from that same snapshot after proof authorization.
BuildRowsForFile ← {𝕊 base‿resolved‿cycleStart‿srcFile:
  snapshot ← LoadPostingSourceSnapshot base
  proof ← ResolveArithmeticCurrencyProof snapshot
  idx ← (srcFile ≡ "plan.tsv") + 2 × (srcFile ≡ "budget_alloc.tsv")
  source ← idx ⊑ ⟨snapshot.journal, snapshot.plan, snapshot.budget_alloc⟩
  BuildRowsForSource ⟨source, resolved, cycleStart, proof⟩
}

# BuildRowsForFileOptional: compatibility wrapper; same authorization behavior as BuildRowsForFile.
BuildRowsForFileOptional ← BuildRowsForFile

# BuildAllRowsFromSnapshot: construct all posting rows from one already loaded snapshot.
BuildAllRowsFromSnapshot ← {𝕊 snapshot‿resolved‿cycleStart‿proof:
  proj.RequireArithmeticCurrencyProof proof
  jrows ← BuildRowsForSource ⟨snapshot.journal, resolved, cycleStart, proof⟩
  prows ← BuildRowsForSource ⟨snapshot.plan, resolved, cycleStart, proof⟩
  brows ← BuildRowsForSource ⟨snapshot.budget_alloc, resolved, cycleStart, proof⟩
  jrows ∾ prows ∾ brows
}

# BuildAllRows: compatibility wrapper preserving one-snapshot proof/projection invariant.
BuildAllRows ← {𝕊 base‿resolved‿cycleStart:
  snapshot ← LoadPostingSourceSnapshot base
  proof ← ResolveArithmeticCurrencyProof snapshot
  BuildAllRowsFromSnapshot ⟨snapshot, resolved, cycleStart, proof⟩
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
  posting_snapshot ← LoadPostingSourceSnapshot base2
  arithmetic_currency_proof ← ResolveArithmeticCurrencyProof posting_snapshot
  rows         ← BuildAllRowsFromSnapshot ⟨posting_snapshot, resolved, cy.start, arithmetic_currency_proof⟩
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
    arithmetic_currency_proof ⇐ arithmetic_currency_proof,
    cube         ⇐ view.cube,
    tbds         ⇐ view.tbds,
    issues       ⇐ issues
  }
}

{ BuildContext ⇐ BuildContext, LoadPostingSourceSnapshot ⇐ LoadPostingSourceSnapshot, ResolveArithmeticCurrencyProof ⇐ ResolveArithmeticCurrencyProof, BuildAllRowsFromSnapshot ⇐ BuildAllRowsFromSnapshot, BuildAllRows ⇐ BuildAllRows, BuildPeriodView ⇐ BuildPeriodView, BuildRowsForFile ⇐ BuildRowsForFile, BuildRowsForFileOptional ⇐ BuildRowsForFileOptional }
