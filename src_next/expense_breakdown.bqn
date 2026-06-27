# expense_breakdown.bqn
# Compact current-cycle actual expense breakdown for src_next Stage 4 trial.

tbds ← •Import "tbds.bqn"
cube ← •Import "cube.bqn"

# Build: extract per-account actual expense debit amounts from context.
# Args: ctx (context namespace with ctx.tbds)
# Returns: namespace with entries (⟨key,amount⟩ pairs) and total.
Build ← {𝕊 ctx:
  exp_entries ← tbds.ActualExpenseBreakdown ctx.tbds
  
  # liabilities with debit movement (actual repayment)
  all_actual ← tbds.RowsForLayer ⟨cube.layer_actual, ctx.tbds⟩
  StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }
  IsRepayment ← { ("liabilities:" StartsWith 𝕩.account_key) ∧ (𝕩.debit_movement > 0) }
  repay_rows ← (IsRepayment¨ all_actual) / all_actual
  repay_entries ← {⟨𝕩.account_key, 𝕩.debit_movement⟩}¨ repay_rows
  
  entries ← exp_entries ∾ repay_entries
  total ← cube.Sum0 {1⊑𝕩}¨ entries
  { entries ⇐ entries, total ⇐ total }
}

# Format: render expense breakdown as compact machine-readable text.
Format ← {𝕊 summary:
  out ← "--- SrcNext Cycle Expense Breakdown ---" ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_expense_breakdown_total: " ∾ (•Fmt summary.total) ∾ (@+10)
  {
    out ↩ out ∾ "src_next_cycle_expense_breakdown: " ∾ (0⊑𝕩) ∾ " " ∾ (•Fmt (1⊑𝕩)) ∾ (@+10)
  }¨ summary.entries
  {𝕊: out ↩ out ∾ "src_next_cycle_expense_breakdown: (none) 0" ∾ (@+10)}⍟(0 = ≠ summary.entries) @
  out
}

{ Build ⇐ Build, Format ⇐ Format }
