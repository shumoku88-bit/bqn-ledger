# cube.bqn
# Tiny cube materializer for the cycle-ledger prototype.
#
# Boundary for this file:
#   ledger-like projection rows
#     -> row acceptance boundary (valid rows / skipped rows)
#     -> cube materialize from valid rows only
#     -> validation summary
#     -> minimal inspection rendering
#
# Contract (AXIS_CONTRACT.md):
#   First-phase core shape: Day × AccountKey × Layer
#
# Contract (PROJECTION_CONTRACT.md §9):
#   Projection rows → cube shape → simple sums by Day/AccountKey/Layer
#
# Non-goals:
#   - does not produce final report sections
#   - does not export derived TSV
#   - does not implement trial balance / multi-posting / generated entries

# ── Layer constants ──────────────────────────────────────────

layer_actual   ← 0
layer_plan     ← 1
layer_budget   ← 2
layer_forecast ← 3

layer_names ← ⟨"actual", "plan", "budget", "forecast"⟩
layer_count ← 4

# ── Safe sum helper ────────────────────────────────────────
# Returns 0 for empty vector; identical to +´ otherwise.
# Self-documents every place where we reduce a possibly-empty
# vector of deltas or boolean masks.

Sum0 ← { 0 < ≠𝕩 ? +´𝕩 ; 0 }

# ── Row acceptance boundary ─────────────────────────────────
# Projection rows may carry sentinel values such as account_key_index = ak_count
# for unknown accounts, or day_index outside the loaded cycle. These rows are
# valid projection evidence, but they must not be used as cube indices.

RowStatusOk ← {𝕊 row: row.status ≡ "ok" }
RowDayInRange ← {𝕊 row‿day_count: (row.day_index ≥ 0) ∧ (row.day_index < day_count) }
RowAccountInRange ← {𝕊 row‿ak_count: (row.account_key_index ≥ 0) ∧ (row.account_key_index < ak_count) }
RowLayerInRange ← {𝕊 row: (row.layer_index ≥ 0) ∧ (row.layer_index < layer_count) }

IsValidRow ← {𝕊 row‿day_count‿ak_count:
  (RowStatusOk row) ∧ (RowDayInRange ⟨row, day_count⟩) ∧ (RowAccountInRange ⟨row, ak_count⟩) ∧ (RowLayerInRange row)
}

# First-match skipped category. Keep this aligned with RowSkipReason.
RowSkipCategory ← {𝕊 row‿day_count‿ak_count:
  c ← "unknown"
  c ↩ (row.status ≢ "ok") ⊑ c‿"status"
  c ↩ ((c ≡ "unknown") ∧ (row.day_index < 0)) ⊑ c‿"day_before_start"
  c ↩ ((c ≡ "unknown") ∧ (row.day_index ≥ day_count)) ⊑ c‿"day_after_end"
  c ↩ ((c ≡ "unknown") ∧ ((row.account_key_index < 0) ∨ (row.account_key_index ≥ ak_count))) ⊑ c‿"account_key_index"
  c ↩ ((c ≡ "unknown") ∧ ((row.layer_index < 0) ∨ (row.layer_index ≥ layer_count))) ⊑ c‿"layer_index"
  c
}

# Human-readable skipped reason. First match wins: status, day bounds,
# account-key bounds, then layer bounds.
RowSkipReason ← {𝕊 row‿day_count‿ak_count:
  r ← "unknown reason"
  r ↩ (row.status ≢ "ok") ⊑ r‿("status: " ∾ row.status)
  r ↩ ((r ≡ "unknown reason") ∧ (row.day_index < 0)) ⊑ r‿("day_index " ∾ (•Fmt row.day_index) ∾ " < 0")
  r ↩ ((r ≡ "unknown reason") ∧ (row.day_index ≥ day_count)) ⊑ r‿("day_index " ∾ (•Fmt row.day_index) ∾ " >= " ∾ (•Fmt day_count))
  r ↩ ((r ≡ "unknown reason") ∧ (row.account_key_index < 0)) ⊑ r‿("account_key_index " ∾ (•Fmt row.account_key_index) ∾ " < 0")
  r ↩ ((r ≡ "unknown reason") ∧ (row.account_key_index ≥ ak_count)) ⊑ r‿("account_key_index " ∾ (•Fmt row.account_key_index) ∾ " >= " ∾ (•Fmt ak_count))
  r ↩ ((r ≡ "unknown reason") ∧ ((row.layer_index < 0) ∨ (row.layer_index ≥ layer_count))) ⊑ r‿("invalid layer_index " ∾ (•Fmt row.layer_index))
  r
}

BuildSkippedSummary ← {𝕊 skipped_rows‿day_count‿ak_count:
  cats ← { RowSkipCategory ⟨𝕩, day_count, ak_count⟩ }¨ skipped_rows
  reasons ← { RowSkipReason ⟨𝕩, day_count, ak_count⟩ }¨ skipped_rows
  CountCat ← {𝕊 c: Sum0 (c⊸≡¨ cats) }
  status_n       ← CountCat "status"
  unknown_acc_n  ← Sum0 ("unknown_account"⊸≡¨ {𝕩.status}¨ skipped_rows)
  invalid_date_n ← Sum0 ("invalid_date"⊸≡¨ {𝕩.status}¨ skipped_rows)
  invalid_amt_n  ← Sum0 ("invalid_amount"⊸≡¨ {𝕩.status}¨ skipped_rows)
  before_n       ← CountCat "day_before_start"
  after_n        ← CountCat "day_after_end"
  ak_idx_n       ← CountCat "account_key_index"
  layer_n        ← CountCat "layer_index"
  unknown_n      ← CountCat "unknown"
  {
    total              ⇐ ≠ skipped_rows,
    status             ⇐ status_n,
    day_before_start   ⇐ before_n,
    day_after_end      ⇐ after_n,
    account_key_index  ⇐ ak_idx_n,
    layer_index        ⇐ layer_n,
    unknown            ⇐ unknown_n,
    unknown_account    ⇐ unknown_acc_n,
    invalid_date       ⇐ invalid_date_n,
    invalid_amount     ⇐ invalid_amt_n,
    invalid_count       ⇐ status_n + ak_idx_n + layer_n + unknown_n,
    out_of_period_count ⇐ before_n + after_n,
    categories         ⇐ cats,
    reasons            ⇐ reasons
  }
}

PartitionRows ← {𝕊 rows‿day_count‿ak_count:
  valid_mask ← { IsValidRow ⟨𝕩, day_count, ak_count⟩ }¨ rows
  valid_rows ← valid_mask / rows
  skipped_rows ← (¬ valid_mask) / rows

  skipped_info ← {𝕊 row:
    ⟨ RowSkipReason ⟨row, day_count, ak_count⟩, row.source_file, (•Fmt row.source_row), row.source_id ⟩
  } ¨ skipped_rows

  {
    valid_rows      ⇐ valid_rows,
    skipped_rows    ⇐ skipped_rows,
    valid_count     ⇐ ≠ valid_rows,
    skipped_count   ⇐ ≠ skipped_rows,
    skipped_info    ⇐ skipped_info,
    skipped_summary ⇐ BuildSkippedSummary ⟨skipped_rows, day_count, ak_count⟩
  }
}

# ── Validation summary ──────────────────────────────────────
# Keep numeric validation separate from rendering so callers can use the
# booleans directly without parsing output text.

MakeValidationSummary ← {𝕊 valid_layer_totals‿layer_totals_vec‿proj_ak_totals‿ak_totals:
  valid_actual_total ← 0⊑valid_layer_totals
  valid_plan_total   ← 1⊑valid_layer_totals
  cube_actual_total  ← 0⊑layer_totals_vec
  cube_plan_total    ← 1⊑layer_totals_vec

  actual_match ← valid_actual_total = cube_actual_total
  plan_match   ← valid_plan_total = cube_plan_total
  ak_match     ← proj_ak_totals ≡ ak_totals

  {
    valid_actual_delta_total      ⇐ valid_actual_total,
    cube_actual_total             ⇐ cube_actual_total,
    actual_total_match            ⇐ actual_match,
    valid_plan_delta_total        ⇐ valid_plan_total,
    cube_plan_total               ⇐ cube_plan_total,
    plan_total_match              ⇐ plan_match,
    actual_per_account_totals_match ⇐ ak_match
  }
}

# ── Cube materialization ─────────────────────────────────────
# Args: ⟨rows, day_count, ak_count⟩
#   rows      - 1D array of projection row namespaces (from projection.bqn MakeRow)
#   day_count - Number of days in the cycle
#   ak_count  - Number of resolved account keys
# Returns namespace:
#   cube, valid_rows, skipped_rows, skipped_summary,
#   layer totals, per-account totals, and validation_summary.
Materialize ← {𝕊 ⟨rows, day_count, ak_count⟩:
  part ← PartitionRows ⟨rows, day_count, ak_count⟩
  valid_rows ← part.valid_rows

  # ── Materialize cube from valid rows only ──────────────────
  # Cube shape: day_count × ak_count × layer_count
  # Flat index: day × ak_count × layer_count + ak × layer_count + layer
  flat_size ← day_count × ak_count × layer_count
  al_size ← ak_count × layer_count

  FlatIdx ← {𝕊 row:
    (row.day_index × al_size) + (row.account_key_index × layer_count) + row.layer_index
  }

  indices ← FlatIdx ¨ valid_rows
  deltas ← { 𝕩.delta } ¨ valid_rows
  valid_total_delta ← Sum0 deltas

  # Per-layer valid totals (for layer-aware verification)
  layer_idx ← {𝕩.layer_index}¨ valid_rows
  valid_layer_totals ← { Sum0 ((layer_idx = 𝕩) / deltas) }¨ ↕ layer_count

  # Build dense cube from sparse (index, delta) pairs.
  # Iterates over all flat cells, filtering valid_rows per cell.
  # For household-scale data (day_count×ak_count×layer_count ≪ 10⁴,
  # valid_rows ≪ 10²), this is fast enough.
  # For larger datasets, replace with grouped accumulation: ⊔ then scatter.
  cube_flat ← { Sum0 ((indices = 𝕩) / deltas) }¨ ↕ flat_size

  # Reshape to 3D: day × ak × layer
  cube ← day_count‿ak_count‿layer_count ⥊ cube_flat

  # ── Layer totals ──────────────────────────────────────────
  # Sum over days, then over account_keys, leaving layer axis.
  layer_totals_vec ← +˝ +˝ cube

  # ── Nonzero actual (layer 0) account totals ───────────────
  # Reorder axes to put layer first, pick layer 0, sum over days.
  layer0 ← 0 ⊏ (1‿2‿0 ⍉ cube)  # shape: day × ak
  ak_totals ← +˝ layer0           # shape: ak_count

  # ── Per-account delta totals from valid rows by layer ─────
  # These stay projection-derived so minimal report output can compare
  # directly against the ledger-like rows before any full report UI exists.
  ak_idx ← {𝕩.account_key_index}¨ valid_rows
  LayerAkTotals ← {𝕊 l:
    m ← layer_idx = l
    l_ak_idx ← m / ak_idx
    l_deltas ← m / deltas
    { Sum0 ((l_ak_idx = 𝕩) / l_deltas) }¨ ↕ ak_count
  }
  actual_account_totals ← LayerAkTotals layer_actual
  plan_account_totals ← LayerAkTotals layer_plan

  # Current-cycle expense totals: debit-side expense rows only. This gives
  # a small, comparable report-like number while preserving ledger balance
  # layer totals separately.
  kind_vec ← {𝕩.kind}¨ valid_rows
  side_vec ← {𝕩.side}¨ valid_rows
  ExpenseTotal ← {𝕊 l:
    mask ← (layer_idx = l) ∧ ("expense"⊸≡¨ kind_vec) ∧ ("debit"⊸≡¨ side_vec)
    Sum0 (mask / deltas)
  }
  actual_expense_total ← ExpenseTotal layer_actual
  plan_expense_total ← ExpenseTotal layer_plan

  # For cross-check against cube-derived ak_totals (actual layer only).
  proj_ak_totals ← actual_account_totals

  validation_summary ← MakeValidationSummary ⟨valid_layer_totals, layer_totals_vec, proj_ak_totals, ak_totals⟩

  {
    cube              ⇐ cube,
    valid_rows        ⇐ part.valid_rows,
    skipped_rows      ⇐ part.skipped_rows,
    valid_count       ⇐ part.valid_count,
    skipped_count     ⇐ part.skipped_count,
    skipped_info      ⇐ part.skipped_info,
    skipped_summary   ⇐ part.skipped_summary,
    layer_totals_vec  ⇐ layer_totals_vec,
    valid_layer_totals ⇐ valid_layer_totals,
    ak_totals         ⇐ ak_totals,
    actual_account_totals ⇐ actual_account_totals,
    plan_account_totals ⇐ plan_account_totals,
    actual_expense_total ⇐ actual_expense_total,
    plan_expense_total ⇐ plan_expense_total,
    valid_total_delta ⇐ valid_total_delta,
    proj_ak_totals    ⇐ proj_ak_totals,
    validation_summary ⇐ validation_summary
  }
}

# ── Minimal report summary rendering ────────────────────────
# Machine-ish, stable comparison surface for src_next. This is deliberately
# much smaller than the production human-facing report.

FormatMinimalReportSummary ← {𝕊 ⟨result, ak_keys, cycle_start, cycle_end⟩:
  out ← "--- SrcNext Minimal Report Summary ---" ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_range: " ∾ cycle_start ∾ ".." ∾ cycle_end ∾ (@+10)
  out ↩ out ∾ "src_next_valid_projection_rows: " ∾ (•Fmt result.valid_count) ∾ (@+10)
  out ↩ out ∾ "src_next_skipped_projection_rows: " ∾ (•Fmt result.skipped_count) ∾ (@+10)
  out ↩ out ∾ "src_next_actual_total: " ∾ (•Fmt (layer_actual ⊑ result.layer_totals_vec)) ∾ (@+10)
  out ↩ out ∾ "src_next_plan_total: " ∾ (•Fmt (layer_plan ⊑ result.layer_totals_vec)) ∾ (@+10)
  out ↩ out ∾ "src_next_actual_expense_total: " ∾ (•Fmt result.actual_expense_total) ∾ (@+10)
  out ↩ out ∾ "src_next_plan_expense_total: " ∾ (•Fmt result.plan_expense_total) ∾ (@+10)

  FmtAccountTotals ← {𝕊 label‿totals:
    nz_mask ← totals ≠ 0
    nz_idx ← nz_mask / ↕ ≠ totals
    {
      idx ← 𝕩
      key ← idx ⊑ ak_keys
      total ← idx ⊑ totals
      out ↩ out ∾ label ∾ ": " ∾ (•Fmt idx) ∾ " " ∾ key ∾ " " ∾ (•Fmt total) ∾ (@+10)
    }¨ nz_idx
  }
  FmtAccountTotals ⟨"src_next_actual_account_total", result.actual_account_totals⟩
  FmtAccountTotals ⟨"src_next_plan_account_total", result.plan_account_totals⟩

  out
}

# ── Minimal inspection rendering ────────────────────────────

FormatCubeSanity ← {𝕊 ⟨result, ak_keys, day_count, ak_count⟩:
  cube_shape_str ← (•Fmt day_count) ∾ " × " ∾ (•Fmt ak_count) ∾ " × " ∾ (•Fmt layer_count)

  out ← "--- Cube Sanity ---" ∾ (@+10)
  out ↩ out ∾ "shape: " ∾ cube_shape_str ∾ (@+10)
  out ↩ out ∾ "valid projection rows: " ∾ (•Fmt result.valid_count) ∾ (@+10)
  out ↩ out ∾ "skipped projection rows: " ∾ (•Fmt result.skipped_count) ∾ (@+10)

  # Skipped rows detail (only when present)
  {𝕊:
    out ↩ out ∾ (@+10) ∾ "skipped rows:" ∾ (@+10)
    FmtSkip ← {𝕊 s:
      reason ← 0⊑s ⋄ srcFile ← 1⊑s ⋄ rowIdx ← 2⊑s ⋄ srcId ← 3⊑s
      "  " ∾ reason ∾ "  " ∾ srcFile ∾ ":" ∾ rowIdx ∾ "  " ∾ srcId ∾ (@+10)
    }
    out ↩ out ∾ ∾ (FmtSkip ¨ result.skipped_info)
  }⍟(0 < result.skipped_count) @

  # Layer totals
  out ↩ out ∾ (@+10) ∾ "layer totals:" ∾ (@+10)
  {
    name ← 𝕩 ⊑ layer_names
    total ← 𝕩 ⊑ result.layer_totals_vec
    out ↩ out ∾ "  " ∾ name ∾ ": " ∾ (•Fmt total) ∾ (@+10)
  }¨ ↕ layer_count

  # Nonzero actual account totals
  out ↩ out ∾ (@+10) ∾ "nonzero actual account totals:" ∾ (@+10)
  ak_totals ← result.ak_totals
  nz_mask ← ak_totals ≠ 0
  nz_count ← +´ nz_mask

  {𝕊:
    out ↩ out ∾ "  account_key_index  account_key  total" ∾ (@+10)
    nz_idx ← nz_mask / ↕ ak_count
    {
      idx ← 𝕩
      total ← idx ⊑ ak_totals
      key ← idx ⊑ ak_keys
      out ↩ out ∾ "  " ∾ (•Fmt idx) ∾ "  " ∾ key ∾ "  " ∾ (•Fmt total) ∾ (@+10)
    }¨ nz_idx
  }⍟(0 < nz_count) @
  {𝕊: out ↩ out ∾ "  (none)" ∾ (@+10) }⍟(0 = nz_count) @

  out
}

# ── Cube numeric verification rendering ─────────────────────
# Renders validation_summary while preserving the existing compact golden
# surface: actual / plan total checks and actual per-account check.

VerifyNumeric ← {𝕊 ⟨result, ak_keys⟩:
  v ← result.validation_summary

  out ← "--- Cube Numeric Verification ---" ∾ (@+10)
  out ↩ out ∾ "valid_actual_delta_total: " ∾ (•Fmt v.valid_actual_delta_total) ∾ (@+10)
  out ↩ out ∾ "cube_actual_total: " ∾ (•Fmt v.cube_actual_total) ∾ (@+10)
  out ↩ out ∾ "actual_total_match: " ∾ (v.actual_total_match ⊑ "FAIL"‿"ok") ∾ (@+10)
  out ↩ out ∾ (@+10) ∾ "valid_plan_delta_total: " ∾ (•Fmt v.valid_plan_delta_total) ∾ (@+10)
  out ↩ out ∾ "cube_plan_total: " ∾ (•Fmt v.cube_plan_total) ∾ (@+10)
  out ↩ out ∾ "plan_total_match: " ∾ (v.plan_total_match ⊑ "FAIL"‿"ok") ∾ (@+10)
  out ↩ out ∾ (@+10) ∾ "actual_per_account_totals_match: " ∾ (v.actual_per_account_totals_match ⊑ "FAIL"‿"ok") ∾ (@+10)

  # If actual total mismatch, print detail
  {𝕊:
    diff ← v.valid_actual_delta_total - v.cube_actual_total
    out ↩ out ∾ "  actual delta_total diff: " ∾ (•Fmt diff) ∾ (@+10)
  }⍟(¬v.actual_total_match) @

  # If plan total mismatch, print detail
  {𝕊:
    diff ← v.valid_plan_delta_total - v.cube_plan_total
    out ↩ out ∾ "  plan delta_total diff: " ∾ (•Fmt diff) ∾ (@+10)
  }⍟(¬v.plan_total_match) @

  # If per-account mismatch, print detail
  {𝕊:
    ak_count ← ≠ result.ak_totals
    mismatches ← (result.proj_ak_totals ≠ result.ak_totals) / ↕ ak_count
    out ↩ out ∾ "  mismatched account_key_indices:" ∾ (@+10)
    {
      idx ← 𝕩
      proj_t ← idx ⊑ result.proj_ak_totals
      cube_t ← idx ⊑ result.ak_totals
      key ← idx ⊑ ak_keys
      out ↩ out ∾ "    " ∾ key ∾ " proj:" ∾ (•Fmt proj_t) ∾ " cube:" ∾ (•Fmt cube_t) ∾ (@+10)
    }¨ mismatches
  }⍟(¬v.actual_per_account_totals_match) @

  out
}

{
  Materialize ⇐ Materialize,
  PartitionRows ⇐ PartitionRows,
  IsValidRow ⇐ IsValidRow,
  RowSkipCategory ⇐ RowSkipCategory,
  RowSkipReason ⇐ RowSkipReason,
  BuildSkippedSummary ⇐ BuildSkippedSummary,
  MakeValidationSummary ⇐ MakeValidationSummary,
  FormatMinimalReportSummary ⇐ FormatMinimalReportSummary,
  FormatCubeSanity ⇐ FormatCubeSanity,
  VerifyNumeric ⇐ VerifyNumeric,
  Sum0 ⇐ Sum0,
  layer_actual ⇐ layer_actual,
  layer_plan ⇐ layer_plan,
  layer_budget ⇐ layer_budget,
  layer_forecast ⇐ layer_forecast,
  layer_names ⇐ layer_names,
  layer_count ⇐ layer_count
}
