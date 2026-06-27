# main.bqn — src_next entrypoint
# Phase 1: read-only loader + AccountKey table prototype.
# Phase 2: projection row skeleton (structure only, no cube materialize).
#
# Usage:
#   bqn src_next/main.bqn fixtures/basic
#   bqn src_next/main.bqn fixtures/generalization-moko
#   bqn src_next/main.bqn data

loader ← •Import "loader.bqn"
ak ← •Import "account_key.bqn"
proj ← •Import "projection.bqn"
cycle ← •Import "cycle.bqn"
cube ← •Import "cube.bqn"
household_policy ← •Import "household_policy.bqn"
household_metadata ← •Import "household_metadata.bqn"

# ── Phase 1: AccountKey table ───────────────────────────────

PrintAccountKey ← {𝕊 base2:
  lines ← loader.ReadLines (base2 ∾ "/accounts.tsv")
  resolved ← ak.Resolve lines

  •Out "--- AccountKey Table ---"
  •Out "base: " ∾ base2
  •Out "accounts: " ∾ (•Fmt resolved.count)
  •Out ""
  •Out ak.FormatTable resolved
  •Out ""
  •Out "Legend:"
  •Out "  AccountKey = account + / + currency"
  •Out "  Default currency: JPY (when no currency=XXX in accounts.tsv metadata)"
  •Out "  Currency conversion: out of scope for Phase 1"

  resolved
}

# ── Phase 2: Projection row skeleton ────────────────────────

PrintProjHeader ← {𝕊 𝕩:
  •Out ""
  •Out "--- Projection Row Structure ---"
  •Out ""
  •Out "Concept (PROJECTION_CONTRACT.md §3):"
  •Out ""
  {•Out 𝕩∾"  "}¨ proj.proj_cols
  •Out ""
  •Out "Layer mapping:"
  •Out "  journal.tsv      -> actual   (layer_index=0)"
  •Out "  plan.tsv         -> plan     (layer_index=1)"
  •Out "  budget_alloc.tsv -> budget   (layer_index=2)"
  •Out "  (forecast)       -> forecast (layer_index=3, reserved)"
  •Out ""
  •Out "Ledger-like: one source row normally emits debit and credit projection rows."
  •Out "Skeleton: no final report section."
}

# BuildRowsForFile: build projection rows for a single source file.
# Args: ⟨base2, resolved, cycleStart, srcFile⟩
# Returns: 1D array of projection row namespaces (empty if file missing/empty)
BuildRowsForFile ← {𝕊 base2‿resolved‿cycleStart‿srcFile:
  lines ← loader.ReadLines (base2 ∾ "/" ∾ srcFile)
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

# PrintRowsForFile: build and print projection rows for a source file.
# Args: ⟨base2, resolved, cycleStart, srcFile, title⟩
# Returns: 1D array of projection row namespaces
PrintRowsForFile ← {𝕊 base2‿resolved‿cycleStart‿srcFile‿title:
  rows ← BuildRowsForFile ⟨base2, resolved, cycleStart, srcFile⟩
  •Out ""
  •Out "--- Sample Projection Rows (" ∾ title ∾ ") ---"
  •Out ""
  {𝕊:
    •Out proj.FormatProjTable rows
  }⍟(0 < ≠ rows) @
  {𝕊:
    •Out "(none)"
  }⍟(0 = ≠ rows) @
  rows
}

PrintSampleRows ← {𝕊 base2‿resolved‿cycleStart:
  jrows ← PrintRowsForFile ⟨base2, resolved, cycleStart, "journal.tsv", "journal.tsv"⟩
  # plan.tsv is optional; use ReadLinesOptional to avoid crash when missing
  linesPlan ← loader.ReadLinesOptional (base2 ∾ "/plan.tsv")
  names  ← resolved.accounts
  roles  ← resolved.roles
  keys   ← resolved.account_keys
  argsPlan ← {𝕊 i:
    flds ← loader.SplitTsvKeepEmpty (i ⊑ linesPlan)
    ⟨"plan.tsv", i, flds, names, roles, keys, cycleStart⟩
  } ¨ ↕ (≠ linesPlan)
  prows ← ∾ (proj.MakeRow ¨ argsPlan)
  •Out ""
  •Out "--- Sample Projection Rows (plan.tsv) ---"
  •Out ""
  {𝕊: •Out proj.FormatProjTable prows }⍟(0 < ≠ prows) @
  {𝕊: •Out "(none)" }⍟(0 = ≠ prows) @
  jrows ∾ prows
}

# ── Main ─────────────────────────────────────────────────────

Main ← {𝕊 base:
  base2 ← (0 < ≠ base) ⊑ ⟨ ".", base ⟩

  # ── Cycle info ─────────────────────────────────────────────
  cy ← cycle.ReadCycle base2
  •Out cycle.FormatCycleInfo cy

  # ── AccountKey table ───────────────────────────────────────
  resolved ← PrintAccountKey base2

  # ── Projection skeleton ────────────────────────────────────
  PrintProjHeader 0
  rows ← PrintSampleRows ⟨base2, resolved, cy.start⟩
  •Out ""
  •Out proj.FormatBalanceCheck rows

  # ── Credit-side unknown accounts now detected by projection.bqn MakeRow ──

  # ── Cube materialize & sanity ──────────────────────────────
  result ← cube.Materialize ⟨rows, cy.day_count, resolved.count⟩
  •Out cube.FormatCubeSanity ⟨result, resolved.account_keys, cy.day_count, resolved.count⟩

  # ── Minimal report-like summary ────────────────────────────
  •Out ""
  •Out cube.FormatMinimalReportSummary ⟨result, resolved.account_keys, cy.start, cy.end_exclusive⟩

  # ── Household policy diagnostics ───────────────────────────
  policy_summary ← household_policy.BuildSummary ⟨base2, resolved, result.valid_rows⟩
  policy_text ← household_policy.FormatSummary policy_summary
  {𝕊: •Out policy_text}⍟(0 < ≠ policy_text) @

  # ── Household metadata diagnostics ─────────────────────────
  hm ← household_metadata.Build { resolved ⇐ resolved }
  hm_text ← household_metadata.Format hm
  {𝕊: •Out hm_text}⍟(0 < ≠ hm_text) @

  # ── Cube numeric verification ──────────────────────────────
  •Out ""
  •Out cube.VerifyNumeric ⟨result, resolved.account_keys⟩
}

Main ⊑•args
