# ytd_summary.bqn
# Compact YTD actual summary for src_next Stage 4 trial.
#
# src_next summary has no as_of argument. This section therefore scans actual
# journal rows in the calendar year containing the loaded cycle end and before
# cycle.end_exclusive. The rendered range makes that observation boundary explicit.

proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

YearStartForEnd ← {𝕊 endExclusive: (4↑endExclusive) ∾ "-01-01" }

StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }

GetRole ← {
  (0 < ≠ 1 ⊑ 𝕩) ? 1 ⊑ 𝕩 ;
  ("assets:" StartsWith 0 ⊑ 𝕩) ? "asset" ;
  ("liabilities:" StartsWith 0 ⊑ 𝕩) ? "liability" ;
  ("budget:" StartsWith 0 ⊑ 𝕩) ? "budget" ;
  ("income:" StartsWith 0 ⊑ 𝕩) ? "income" ;
  ("expenses:" StartsWith 0 ⊑ 𝕩) ? "expense" ;
  "unknown"
}

BuildRows ← {𝕊 ctx‿rangeStart:
  rows0 ← (({𝕩.source_file}¨ ctx.posting_rows) ≡¨ <"journal.tsv") / ctx.posting_rows
  {𝕊 r:
    day ← 0
    dateOk ← proj.IsValidDateText r.date
    {𝕊: day ↩ (proj.DaysFromEpoch r.date) - proj.DaysFromEpoch rangeStart}⍟dateOk @
    {
      source_file       ⇐ r.source_file,
      source_row        ⇐ r.source_row,
      source_id         ⇐ r.source_id,
      tx_id             ⇐ r.tx_id,
      posting_id        ⇐ r.posting_id,
      date              ⇐ r.date,
      side              ⇐ r.side,
      day_index         ⇐ day,
      account_key       ⇐ r.account_key,
      account_key_index ⇐ r.account_key_index,
      layer_name        ⇐ r.layer_name,
      layer_index       ⇐ r.layer_index,
      delta             ⇐ r.delta,
      kind              ⇐ r.kind,
      status            ⇐ r.status,
      message           ⇐ r.message
    }
  }¨ rows0
}

# Build: build YTD summary from context.
# Args: ctx (context namespace)
Build ← {𝕊 ctx:
  resolved ← ctx.resolved
  cy ← ctx.cy
  rangeStart ← YearStartForEnd cy.end_exclusive
  dayCount ← (proj.DaysFromEpoch cy.end_exclusive) - proj.DaysFromEpoch rangeStart
  rows ← BuildRows ⟨ctx, rangeStart⟩
  result ← cube.Materialize ⟨rows, dayCount, resolved.count⟩

  valid ← result.valid_rows
  layer_idx ← {𝕩.layer_index}¨ valid
  kind_vec ← {𝕩.kind}¨ valid
  side_vec ← {𝕩.side}¨ valid
  deltas ← {𝕩.delta}¨ valid

  # 1. Backward-compatible fields
  income_mask ← (layer_idx = cube.layer_actual) ∧ ("income"⊸≡¨ kind_vec) ∧ ("credit"⊸≡¨ side_vec)
  income_actual ← - cube.Sum0 (income_mask / deltas)
  expense_actual ← result.actual_expense_total
  net_actual ← income_actual - expense_actual

  exp_mask ← (resolved.roles ≡¨ <"expense") ∨ ("expenses:" ⊸ ≡¨ 9 ↑¨ resolved.accounts)
  fixed_mask ← exp_mask ∧ (resolved.spend_classes ≡¨ <"fixed")
  var_mask ← exp_mask ∧ (¬fixed_mask)

  ak_idx ← {𝕩.account_key_index}¨ valid
  debit_mask ← (layer_idx = cube.layer_actual) ∧ ("debit"⊸≡¨ side_vec)
  debit_ak_idx ← debit_mask / ak_idx
  debit_deltas ← debit_mask / deltas
  amounts ← { cube.Sum0 ((debit_ak_idx = 𝕩) / debit_deltas) }¨ ↕ resolved.count

  fixed_indices ← (fixed_mask ∧ (amounts ≠ 0)) / ↕ resolved.count
  fixed_keys ← fixed_indices ⊏ resolved.account_keys
  fixed_sums ← fixed_indices ⊏ amounts
  fixed_total ← cube.Sum0 fixed_sums
  fixed_ord ← ⌽ ⍋ fixed_sums
  fixed_breakdown ← { ⟨ 𝕩 ⊑ fixed_keys, 𝕩 ⊑ fixed_sums ⟩ } ¨ fixed_ord

  var_indices ← (var_mask ∧ (amounts ≠ 0)) / ↕ resolved.count
  var_keys ← var_indices ⊏ resolved.account_keys
  var_sums ← var_indices ⊏ amounts
  var_total ← cube.Sum0 var_sums
  var_ord ← ⌽ ⍋ var_sums
  var_breakdown ← { ⟨ 𝕩 ⊑ var_keys, 𝕩 ⊑ var_sums ⟩ } ¨ var_ord

  # 2. Cumulative movements for all accounts (actual layer)
  credit_mask ← (layer_idx = cube.layer_actual) ∧ ("credit"⊸≡¨ side_vec)
  credit_ak_idx ← credit_mask / ak_idx
  credit_deltas ← credit_mask / deltas
  credit_amounts ← { cube.Sum0 ((credit_ak_idx = 𝕩) / credit_deltas) }¨ ↕ resolved.count

  resolved_roles ← { GetRole ⟨𝕩 ⊑ resolved.accounts, 𝕩 ⊑ resolved.roles⟩ }¨ ↕ resolved.count
  # credit_amounts are negative in TBDS convention, so net = amounts + credit_amounts.
  # Display sign convention:
  #   asset/liability: net as-is (asset increase = positive, liability increase = negative)
  #   expense/income:  -net (expense charge = negative, income = positive)
  net ← { (𝕩 ⊑ amounts) + (𝕩 ⊑ credit_amounts) }¨ ↕ resolved.count
  flows ← {
    role ← 𝕩 ⊑ resolved_roles
    ((role ≡ "asset") ∨ (role ≡ "liability")) ? (𝕩 ⊑ net) ; -(𝕩 ⊑ net)
  }¨ ↕ resolved.count

  nz_mask ← flows ≠ 0
  income_indices ← ((resolved_roles ≡¨ <"income") ∧ nz_mask) / ↕ resolved.count
  expense_indices ← ((resolved_roles ≡¨ <"expense") ∧ nz_mask) / ↕ resolved.count
  asset_indices ← ((resolved_roles ≡¨ <"asset") ∧ nz_mask) / ↕ resolved.count
  liability_indices ← ((resolved_roles ≡¨ <"liability") ∧ nz_mask) / ↕ resolved.count

  SortAbsDesc ← {
    idx ← 𝕩
    vals ← idx ⊏ flows
    abs_vals ← | vals
    ord ← ⌽ ⍋ abs_vals
    ord ⊏ idx
  }

  income_indices ↩ SortAbsDesc income_indices
  expense_indices ↩ SortAbsDesc expense_indices
  asset_indices ↩ SortAbsDesc asset_indices
  liability_indices ↩ SortAbsDesc liability_indices

  ordered_indices ← income_indices ∾ expense_indices ∾ asset_indices ∾ liability_indices
  ytd_entries ← {
    ⟨𝕩 ⊑ resolved.account_keys, 𝕩 ⊑ flows⟩
  }¨ ordered_indices

  {
    range_start ⇐ rangeStart,
    range_end_exclusive ⇐ cy.end_exclusive,
    valid_rows ⇐ result.valid_count,
    skipped_rows ⇐ result.skipped_count,
    income_actual ⇐ income_actual,
    expense_actual ⇐ expense_actual,
    net_actual ⇐ net_actual,
    fixed_total ⇐ fixed_total,
    var_total ⇐ var_total,
    fixed_breakdown ⇐ fixed_breakdown,
    var_breakdown ⇐ var_breakdown,
    ytd_entries ⇐ ytd_entries
  }
}

Format ← {𝕊 summary:
  out ← "--- SrcNext YTD Summary ---" ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_range: " ∾ summary.range_start ∾ ".." ∾ summary.range_end_exclusive ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_valid_projection_rows: " ∾ (•Fmt summary.valid_rows) ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_skipped_projection_rows: " ∾ (•Fmt summary.skipped_rows) ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_income_actual: " ∾ (•Fmt summary.income_actual) ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_expense_actual: " ∾ (•Fmt summary.expense_actual) ∾ (@+10)
  out ↩ out ∾ "src_next_ytd_net_actual: " ∾ (•Fmt summary.net_actual) ∾ (@+10)
  out
}

FmtYtdAmt ← {
  (𝕩 = 0) ? "0" ;
  ((𝕩 > 0) ⊑ ⟨"-" , "+"⟩) ∾ (•Fmt | 𝕩)
}

# FormatHuman: render YTD actual summary as human-readable text.
FormatHuman ← {𝕊 summary:
  ytd_entries ← summary.ytd_entries
  w_acc ← ⌈´ ⟨20⟩ ∾ (fmt.VWidth¨ {0⊑𝕩}¨ ytd_entries)
  w_amt ← 10

  AlignR ← {𝕊 w‿x:
    s ← (1 = •Type x) ⊑ ⟨x, •Fmt x⟩
    ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
  }

  out ← (L "ytd.section_title") ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ (summary.range_start ∾ " 〜 " ∾ summary.range_end_exclusive) ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ (fmt.PadV ⟨w_acc, "account"⟩) ∾ " | " ∾ (AlignR ⟨w_amt, "YTD"⟩) ∾ (@+10)

  {
    key ← 0⊑𝕩 ⋄ amt ← 1⊑𝕩
    padded_key ← fmt.PadV ⟨w_acc, key⟩
    formatted_amt ← AlignR ⟨w_amt, FmtYtdAmt amt⟩
    out ↩ out ∾ padded_key ∾ " | " ∾ formatted_amt ∾ (@+10)
  }¨ ytd_entries

  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
