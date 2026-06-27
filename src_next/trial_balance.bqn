# trial_balance.bqn
# Trial Balance — accounting-grade period-end account state report.
#
# Consumes TBDS rows and produces a Trial Balance for one layer.
# Each row shows: account_key, opening, debit_movement, credit_movement, closing.
#
# Contract:
#   - opening = sum(deltas before period_start)
#   - movement = sum(deltas inside period)
#   - closing = opening + movement
#   - debits must equal credits (zero-sum invariant)

tbds_mod ← •Import "tbds.bqn"
cube_mod ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# Build: extract Trial Balance rows from TBDS for a selected layer.
# Args: ⟨ctx, layerIdx⟩
#   ctx      — context namespace with ctx.tbds and ctx.cy
#   layerIdx — layer index (default: cube.layer_actual)
# Returns: namespace with parallel arrays for each column.
Build ← {𝕊 ctx‿layerIdx:
  cy ← ctx.cy
  rows ← ctx.tbds
  layerRows ← (layerIdx = {𝕩.layer_index}¨ rows) / rows
  # Sort by account_key_index for stable output
  indices ← {𝕩.account_key_index}¨ layerRows
  sorted ← (⍋ indices) ⊏ layerRows
  {
    period_start ⇐ cy.start,
    period_end_exclusive ⇐ cy.end_exclusive,
    as_of ⇐ cy.end_exclusive,
    layer_name ⇐ layerIdx ⊑ cube_mod.layer_names,
    accounts ⇐ {𝕩.account_key}¨ sorted,
    openings ⇐ {𝕩.opening}¨ sorted,
    debits ⇐ {𝕩.debit_movement}¨ sorted,
    credits ⇐ {𝕩.credit_movement}¨ sorted,
    closings ⇐ {𝕩.closing}¨ sorted
  }
}

# FormatTSV: machine-readable TSV export.
FormatTSV ← {𝕊 tb:
  header ← "account_key\topening\tdebit_movement\tcredit_movement\tclosing" ∾ (@+10)
  n ← ≠ tb.accounts
  body ← ∾ {𝕊 i:
    (i⊑tb.accounts) ∾ "\t" ∾ (•Fmt (i⊑tb.openings)) ∾ "\t" ∾ (•Fmt (i⊑tb.debits)) ∾ "\t" ∾ (•Fmt (i⊑tb.credits)) ∾ "\t" ∾ (•Fmt (i⊑tb.closings)) ∾ (@+10)
  }¨ ↕ n
  header ∾ body
}

# Format: compact machine-readable summary (key=value style for check.sh compat).
Format ← {𝕊 tb:
  out ← "--- SrcNext Trial Balance ---" ∾ (@+10)
  out ↩ out ∾ "src_next_trial_balance_period: " ∾ tb.period_start ∾ ".." ∾ tb.period_end_exclusive ∾ (@+10)
  out ↩ out ∾ "src_next_trial_balance_layer: " ∾ tb.layer_name ∾ (@+10)
  out ↩ out ∾ "src_next_trial_balance_rows: " ∾ (•Fmt ≠ tb.accounts) ∾ (@+10)
  {
    out ↩ out ∾ "src_next_trial_balance_row: " ∾ (𝕩⊑tb.accounts) ∾ " opening=" ∾ (•Fmt (𝕩⊑tb.openings)) ∾ " debit=" ∾ (•Fmt (𝕩⊑tb.debits)) ∾ " credit=" ∾ (•Fmt (𝕩⊑tb.credits)) ∾ " closing=" ∾ (•Fmt (𝕩⊑tb.closings)) ∾ (@+10)
  }¨ ↕ ≠ tb.accounts
  out
}

# FormatHuman: human-readable Trial Balance table.
FormatHuman ← {𝕊 tb:
  n ← ≠ tb.accounts
  maxName ← ⌈´ (fmt.VWidth¨ tb.accounts) ∾ ⟨7⟩

  out ← (L "trial_balance.section_title_prefix") ∾ tb.layer_name ∾ (L "trial_balance.section_title_suffix") ∾ (@+10)
  out ↩ out ∾ "Period: " ∾ (fmt.RangeDisp ⟨tb.period_start, tb.period_end_exclusive⟩) ∾ (@+10)
  out ↩ out ∾ "As of : " ∾ tb.as_of ∾ (@+10)
  out ↩ out ∾ (@+10)

  # Header
  out ↩ out ∾ (maxName ⥊ " ") ∾ " |   Opening |     Debit |    Credit |   Closing" ∾ (@+10)
  out ↩ out ∾ (maxName ⥊ "-") ∾ "-+----------+----------+----------+----------" ∾ (@+10)

  {
    nm ← 𝕩⊑tb.accounts ⋄ op ← 𝕩⊑tb.openings
    db ← 𝕩⊑tb.debits ⋄ cr ← 𝕩⊑tb.credits ⋄ cl ← 𝕩⊑tb.closings
    pad ← (maxName - fmt.VWidth nm) ⥊ " "
    out ↩ out ∾ nm ∾ pad ∾ " | " ∾ (fmt.FmtAmt op) ∾ " | " ∾ (fmt.FmtAmt db) ∾ " | " ∾ (fmt.FmtAmt cr) ∾ " | " ∾ (fmt.FmtAmt cl) ∾ (@+10)
  }¨ ↕ n

  # Totals row
  total_op ← +´ tb.openings
  total_db ← +´ tb.debits
  total_cr ← +´ tb.credits
  total_cl ← +´ tb.closings

  out ↩ out ∾ (maxName ⥊ "-") ∾ "-+----------+----------+----------+----------" ∾ (@+10)
  totalLabel ← "Total"
  totalPad ← (maxName - ≠ totalLabel) ⥊ " "
  out ↩ out ∾ totalLabel ∾ totalPad ∾ " | " ∾ (fmt.FmtAmt total_op) ∾ " | " ∾ (fmt.FmtAmt total_db) ∾ " | " ∾ (fmt.FmtAmt total_cr) ∾ " | " ∾ (fmt.FmtAmt total_cl) ∾ (@+10)

  # Zero-sum check
  balanced ← (total_op = 0) ∧ (total_db = ¯1 × total_cr) ∧ (total_cl = 0)
  check ← balanced ⊑ "FAIL"‿"OK"
  colorCheck ← balanced ⊑ ⟨(fmt.Bad check), (fmt.Ok check)⟩
  out ↩ out ∾ (@+10) ∾ "Zero-sum check (debit=credit): " ∾ colorCheck ∾ (@+10)
  out ↩ out ∾ (@+10)
  out
}

{ Build ⇐ Build, FormatTSV ⇐ FormatTSV, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
