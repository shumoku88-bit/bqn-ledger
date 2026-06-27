# tbds.bqn
# Trial Balance Dataset boundary for the next ledger engine candidate.
#
# TBDS is a period/account/layer state table derived from validated Posting IR
# rows. It is intentionally accounting-state only: no report text layout, no
# household advice, and no source TSV parsing.

cube ← •Import "cube.bqn"
proj ← •Import "projection.bqn"

# ── Account classification helpers ──────────────────────────
# Prefer explicit account metadata (row.role), then prefix fallback.
# Prefixes are project-wide naming conventions, not per-dataset configuration.

expPf ← "expenses:"
incPf ← "income:"

IsExpenseAccount ← {𝕊 row:
  (row.role ≡ "expense") ∨ (expPf ≡ (≠ expPf) ↑ row.account_name)
}

IsIncomeAccount ← {𝕊 row:
  (row.role ≡ "income") ∨ (incPf ≡ (≠ incPf) ↑ row.account_name)
}

# ── Movement builders ───────────────────────────────────────

MovementByLayerSide ← {𝕊 rows‿ak_count‿sideName:
  layer_idx ← {𝕩.layer_index}¨ rows
  side_vec ← {𝕩.side}¨ rows
  ak_idx ← {𝕩.account_key_index}¨ rows
  deltas ← {𝕩.delta}¨ rows

  LayerTotals ← {𝕊 l:
    mask ← (layer_idx = l) ∧ (sideName⊸≡¨ side_vec)
    l_ak_idx ← mask / ak_idx
    l_deltas ← mask / deltas
    { cube.Sum0 ((l_ak_idx = 𝕩) / l_deltas) }¨ ↕ ak_count
  }

  LayerTotals¨ ↕ cube.layer_count
}

# MovementByLayer: valid posting rows -> per-layer per-account net movement vectors.
# Args: ⟨rows, ak_count⟩
# Returns: layer_count vectors, each length ak_count.
MovementByLayer ← {𝕊 rows‿ak_count:
  debit ← MovementByLayerSide ⟨rows, ak_count, "debit"⟩
  credit ← MovementByLayerSide ⟨rows, ak_count, "credit"⟩
  { (𝕩⊑debit) + (𝕩⊑credit) }¨ ↕ cube.layer_count
}

# Build: construct TBDS rows for one selected period from ledger-wide Posting IR.
# Args: ⟨postingRows, result, resolved, cy⟩
#   postingRows - all Posting IR rows for the ledger-wide source history
#   result      - cube.Materialize result namespace for the selected period
#   resolved    - account_key.Resolve result namespace
#   cy          - cycle.ReadCycle result namespace
# Returns: 1D array of TBDS row namespaces.
#
# Contract:
#   opening  = valid postings dated before period_start
#   movement = valid postings inside [period_start, period_end_exclusive)
#   closing  = opening + movement
Build ← {𝕊 postingRows‿result‿resolved‿cy:
  startDn ← proj.DaysFromEpoch cy.start
  endDn ← proj.DaysFromEpoch cy.end_exclusive

  LedgerValid ← {𝕊 row:
    (row.status ≡ "ok") ∧ (row.account_key_index ≥ 0) ∧ (row.account_key_index < resolved.count) ∧ (row.layer_index ≥ 0) ∧ (row.layer_index < cube.layer_count)
  }
  ledgerRows ← (LedgerValid¨ postingRows) / postingRows
  rowDns ← {proj.DaysFromEpoch 𝕩.date}¨ ledgerRows

  beforeRows ← (rowDns < startDn) / ledgerRows
  periodRows ← ((rowDns ≥ startDn) ∧ (rowDns < endDn)) / ledgerRows

  OpeningByLayer ← {𝕊 rows‿ak_count:
    layer_idx ← {𝕩.layer_index}¨ rows
    ak_idx ← {𝕩.account_key_index}¨ rows
    deltas ← {𝕩.delta}¨ rows
    {𝕊 l:
      m ← layer_idx = l
      l_ak_idx ← m / ak_idx
      l_deltas ← m / deltas
      { cube.Sum0 ((l_ak_idx = 𝕩) / l_deltas) }¨ ↕ ak_count
    }¨ ↕ cube.layer_count
  }

  openings ← OpeningByLayer ⟨beforeRows, resolved.count⟩
  debitMovements ← MovementByLayerSide ⟨periodRows, resolved.count, "debit"⟩
  creditMovements ← MovementByLayerSide ⟨periodRows, resolved.count, "credit"⟩
  movements ← { (𝕩⊑debitMovements) + (𝕩⊑creditMovements) }¨ ↕ cube.layer_count
  periodId ← "cycle:" ∾ cy.start ∾ ".." ∾ cy.end_exclusive

  ∾ {𝕊 akIdx:
    {𝕊 layerIdx:
      opening ← akIdx ⊑ (layerIdx ⊑ openings)
      debitMovement ← akIdx ⊑ (layerIdx ⊑ debitMovements)
      creditMovement ← akIdx ⊑ (layerIdx ⊑ creditMovements)
      movement ← akIdx ⊑ (layerIdx ⊑ movements)
      closing ← opening + movement
      {
        period_id            ⇐ periodId,
        period_start         ⇐ cy.start,
        period_end_exclusive ⇐ cy.end_exclusive,
        as_of                ⇐ cy.end_exclusive,
        account_key          ⇐ akIdx ⊑ resolved.account_keys,
        account_key_index    ⇐ akIdx,
        account_name         ⇐ akIdx ⊑ resolved.accounts,
        currency             ⇐ akIdx ⊑ resolved.currencies,
        type                 ⇐ akIdx ⊑ resolved.types,
        role                 ⇐ akIdx ⊑ resolved.roles,
        budget               ⇐ akIdx ⊑ resolved.budgets,
        budget_group         ⇐ akIdx ⊑ resolved.budget_groups,
        spend_class          ⇐ akIdx ⊑ resolved.spend_classes,
        layer_name           ⇐ layerIdx ⊑ cube.layer_names,
        layer_index          ⇐ layerIdx,
        opening              ⇐ opening,
        debit_movement       ⇐ debitMovement,
        credit_movement      ⇐ creditMovement,
        movement             ⇐ movement,
        closing              ⇐ closing,
        status               ⇐ "ok",
        message              ⇐ ""
      }
    }¨ ↕ cube.layer_count
  }¨ ↕ resolved.count
}

# ── Query helpers ────────────────────────────────────────────

RowsForLayer ← {𝕊 layerIdx‿rows: (layerIdx = {𝕩.layer_index}¨ rows) / rows }
ExpenseRows ← {𝕊 rows: (IsExpenseAccount¨ rows) / rows }
IncomeRows ← {𝕊 rows: (IsIncomeAccount¨ rows) / rows }

# NonzeroActualBalances: filter TBDS rows to actual layer with nonzero closing balance.
# Args: tbdsRows (1D array of TBDS row namespaces)
# Returns: filtered 1D array of TBDS row namespaces, sorted by account_key_index.
NonzeroActualBalances ← {𝕊 rows:
  r ← RowsForLayer ⟨cube.layer_actual, rows⟩
  (({𝕩.closing}¨ r) ≠ 0) / r
}

ActualIncomeAmount ← {𝕊 rows:
  r ← IncomeRows (RowsForLayer ⟨cube.layer_actual, rows⟩)
  - cube.Sum0 ({𝕩.credit_movement}¨ r)
}

ActualExpenseAmount ← {𝕊 rows:
  r ← ExpenseRows (RowsForLayer ⟨cube.layer_actual, rows⟩)
  cube.Sum0 ({𝕩.debit_movement}¨ r)
}

PlanExpenseAmount ← {𝕊 rows:
  r ← ExpenseRows (RowsForLayer ⟨cube.layer_plan, rows⟩)
  cube.Sum0 ({𝕩.debit_movement}¨ r)
}

# ActualExpenseBreakdown: per-account actual-layer expense debit amounts.
# Args: tbdsRows (1D array of TBDS row namespaces)
# Returns: 1D array of ⟨account_key, amount⟩ pairs for nonzero expense accounts.
ActualExpenseBreakdown ← {𝕊 rows:
  r ← ExpenseRows (RowsForLayer ⟨cube.layer_actual, rows⟩)
  nz ← (({𝕩.debit_movement}¨ r) ≠ 0) / r
  {⟨𝕩.account_key, 𝕩.debit_movement⟩}¨ nz
}

# Format: compact machine-readable surface for TBDS checks.
# Only nonzero rows are printed by default to keep report-next-summary small.
Format ← {𝕊 rows:
  out ← "--- SrcNext TBDS ---" ∾ (@+10)
  out ↩ out ∾ "src_next_tbds_rows: " ∾ (•Fmt ≠ rows) ∾ (@+10)
  nz ← ((({𝕩.opening}¨ rows) ≠ 0) ∨ (({𝕩.movement}¨ rows) ≠ 0) ∨ (({𝕩.closing}¨ rows) ≠ 0)) / rows
  {
    r ← 𝕩
    out ↩ out ∾ "src_next_tbds_row: " ∾ r.account_key ∾ " " ∾ r.layer_name ∾ " opening=" ∾ (•Fmt r.opening) ∾ " debit=" ∾ (•Fmt r.debit_movement) ∾ " credit=" ∾ (•Fmt r.credit_movement) ∾ " movement=" ∾ (•Fmt r.movement) ∾ " closing=" ∾ (•Fmt r.closing) ∾ (@+10)
  }¨ nz
  {𝕊: out ↩ out ∾ "src_next_tbds_row: (none)" ∾ (@+10)}⍟(0 = ≠ nz) @
  out
}

{ MovementByLayer ⇐ MovementByLayer,
  MovementByLayerSide ⇐ MovementByLayerSide,
  Build ⇐ Build,
  RowsForLayer ⇐ RowsForLayer,
  ExpenseRows ⇐ ExpenseRows,
  IncomeRows ⇐ IncomeRows,
  NonzeroActualBalances ⇐ NonzeroActualBalances,
  ActualIncomeAmount ⇐ ActualIncomeAmount,
  ActualExpenseAmount ⇐ ActualExpenseAmount,
  PlanExpenseAmount ⇐ PlanExpenseAmount,
  ActualExpenseBreakdown ⇐ ActualExpenseBreakdown,
  Format ⇐ Format }
