# cycle_summary.bqn
# Cycle Summary section for src_next.
# Machine Format for checks; FormatHuman for human-readable output.

tbds ← •Import "tbds.bqn"
loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text
cube ← •Import "cube.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d: dn ← proj.DaysFromEpoch d ⋄ (dn ≥ start_dn) ∧ (dn < end_dn) }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available ∧ (0 < ≠ lines)) @
  out
}

PlanExpenseRemaining ← {𝕊 ctx‿fallback_total:
  base ← ({𝕊: ctx.base}⎊{𝕊: ""}) @
  out ← fallback_total
  {𝕊:
    cy ← ctx.cy
    resolved ← ctx.resolved
    lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
    as_of ← LatestActualDateInCycle ⟨base, cy⟩
    as_dn ← proj.DaysFromEpoch as_of
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    accounts ← resolved.accounts
    roles ← resolved.roles

    IsExpenseTo ← {𝕊 line:
      flds ← Pad5 loader.SplitTsvKeepEmpty line
      toAcc ← 3⊑flds
      idx ← ⊑ accounts ⊐ ⟨toAcc⟩
      role ← idx ⊑ (roles ∾ ⟨""⟩)
      (role ≡ "expense") ∨ ("expenses:" ≡ 9 ↑ toAcc)
    }
    InRemaining ← {𝕊 line:
      flds ← Pad5 loader.SplitTsvKeepEmpty line
      dn ← proj.DaysFromEpoch (0⊑flds)
      (dn ≥ as_dn) ∧ (dn < end_dn)
    }
    Amount ← {𝕊 line:
      flds ← Pad5 loader.SplitTsvKeepEmpty line
      amtText ← 4⊑flds
      proj.IsIntegerText amtText ? •BQN amtText ; 0
    }
    mask ← (IsExpenseTo¨ lines) ∧ (InRemaining¨ lines)
    out ↩ +´ (Amount¨ (mask / lines)) ∾ ⟨0⟩
  }⍟(0 < ≠ base) @
  out
}

# Build: build a minimal cycle summary namespace from context.
# Uses TBDS query helpers for income/expense/net.
Build ← {𝕊 ctx:
  income_actual ← tbds.ActualIncomeAmount ctx.tbds
  expense_actual ← tbds.ActualExpenseAmount ctx.tbds
  net_actual ← income_actual - expense_actual
  plan_expense ← tbds.PlanExpenseAmount ctx.tbds
  plan_expense_remaining ← PlanExpenseRemaining ⟨ctx, plan_expense⟩

  # Calculate days remaining in the cycle
  base ← ({𝕊: ctx.base}⎊{𝕊: ""}) @
  as_of ← { (0 < ≠ base) ? (LatestActualDateInCycle ⟨base, ctx.cy⟩) ; "unavailable" }
  days_remaining ← ((as_of ≡ "unavailable") ∨ (ctx.cy.end_exclusive ≡ "unavailable")) ◶ ⟨ { 𝕩 ⋄
    as_dn ← proj.DaysFromEpoch as_of
    end_dn ← proj.DaysFromEpoch ctx.cy.end_exclusive
    0 ⌈ (end_dn - as_dn)
  }, { 𝕩 ⋄ 0 } ⟩ @

  # Extract nonzero actual income entries for breakdown
  all_actual ← tbds.RowsForLayer ⟨cube.layer_actual, ctx.tbds⟩
  StartsWith ← { pref ← 𝕨 ⋄ pref ≡ (≠ pref) ↑ 𝕩 }
  IsIncome ← { (("income:" StartsWith 𝕩.account_key) ∧ (𝕩.credit_movement ≠ 0)) }
  income_rows ← (IsIncome¨ all_actual) / all_actual
  income_entries ← {⟨𝕩.account_key, -𝕩.credit_movement⟩}¨ income_rows

  {
    start                  ⇐ ctx.cy.start,
    end_exclusive          ⇐ ctx.cy.end_exclusive,
    day_count              ⇐ ctx.cy.day_count,
    days_remaining         ⇐ days_remaining,
    income_actual          ⇐ income_actual,
    expense_actual         ⇐ expense_actual,
    net_actual             ⇐ net_actual,
    plan_expense           ⇐ plan_expense,
    plan_expense_remaining ⇐ plan_expense_remaining,
    income_entries         ⇐ income_entries
  }
}

Format ← {𝕊 summary:
  out ← "--- SrcNext Cycle Summary ---" ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_start: " ∾ summary.start ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_end_exclusive: " ∾ summary.end_exclusive ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_day_count: " ∾ (•Fmt summary.day_count) ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_income_actual: " ∾ (•Fmt summary.income_actual) ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_expense_actual: " ∾ (•Fmt summary.expense_actual) ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_net_actual: " ∾ (•Fmt summary.net_actual) ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_plan_expense: " ∾ (•Fmt summary.plan_expense) ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_plan_expense_remaining: " ∾ (•Fmt summary.plan_expense_remaining) ∾ (@+10)
  out
}

# FormatHuman: render cycle summary as human-readable text.
# Args: ⟨summary, expenseEntries⟩
#   summary       - from Build(ctx)
#   expenseEntries - ⟨account_key, amount⟩ pairs from expense_breakdown.Build(ctx)
FormatHuman ← {𝕊 summary‿expenseEntries:
  # ¯ を - に変換する金額フォーマッタ (幅14)
  FmtAmt2 ← { s ← fmt.PadL ⟨14, 𝕩⟩ ⋄ { 𝕩 ≡ '¯' ? '-' ; 𝕩 }¨ s }

  FormatTableGroup ← {
    (0 = ≠𝕩) ? "" ;
    rows ← {
      key ← 0⊑𝕩 ⋄ amt ← 1⊑𝕩
      padded_key ← fmt.PadV ⟨24, key⟩
      formatted_amt ← FmtAmt2 amt
      "  " ∾ padded_key ∾ "  " ∾ formatted_amt ∾ (@+10)
    }¨ 𝕩
    ∾ rows
  }

  out ← (L "cycle.section_title") ∾ (@+10) ∾ (@+10)
  
  days_str ← •Fmt summary.days_remaining
  out ↩ out ∾ (L "cycle.cycle_prefix") ∾ (fmt.RangeDisp ⟨summary.start, summary.end_exclusive⟩) ∾ (L "cycle.days_left_prefix") ∾ days_str ∾ (L "cycle.days_left_suffix") ∾ (@+10) ∾ (@+10)

  inc_raw ← FmtAmt2 summary.income_actual
  exp_raw ← FmtAmt2 summary.expense_actual
  net_raw ← FmtAmt2 summary.net_actual
  rem_raw ← FmtAmt2 summary.plan_expense_remaining
  inc_str ← fmt.Ok inc_raw
  exp_str ← fmt.Bad exp_raw
  net_str ← (summary.net_actual < 0) ⊑ ⟨fmt.Ok net_raw, fmt.Bad net_raw⟩
  rem_str ← fmt.Future rem_raw

  out ↩ out ∾ "  " ∾ (fmt.PadV ⟨24, L "cycle.income_total_label"⟩) ∾ "+ " ∾ inc_str ∾ (@+10)
  out ↩ out ∾ "  " ∾ (fmt.PadV ⟨24, L "cycle.expense_total_label"⟩) ∾ "- " ∾ exp_str ∾ (@+10)
  out ↩ out ∾ "  ────────────────────────────" ∾ (@+10)
  out ↩ out ∾ "  " ∾ (fmt.PadV ⟨24, L "cycle.net_label"⟩) ∾ "  " ∾ net_str ∾ (@+10) ∾ (@+10)
  out ↩ out ∾ "  " ∾ (fmt.PadV ⟨24, L "cycle.planned_remaining_label"⟩) ∾ "- " ∾ rem_str ∾ (@+10) ∾ (@+10)

  # ── 収入内訳 ──
  inc_amounts ← {1⊑𝕩}¨ summary.income_entries
  inc_sorted ← (⌽⍋inc_amounts) ⊏ summary.income_entries
  tbl_inc ← FormatTableGroup inc_sorted
  out ↩ out ∾ (0 < ≠tbl_inc) ◶ ⟨{""}, {(L "cycle.income_breakdown_title") ∾ (@+10) ∾ tbl_inc ∾ (@+10)}⟩ @

  # ── 支出内訳 ──
  exp_amounts ← {1⊑𝕩}¨ expenseEntries
  exp_sorted ← (⌽⍋exp_amounts) ⊏ expenseEntries
  tbl_exp ← FormatTableGroup exp_sorted
  out ↩ out ∾ (0 < ≠tbl_exp) ◶ ⟨{""}, {(L "cycle.expense_breakdown_title") ∾ (@+10) ∾ tbl_exp ∾ (@+10)}⟩ @

  out
}

{ Build ⇐ Build, Format ⇐ Format, FormatHuman ⇐ FormatHuman }
