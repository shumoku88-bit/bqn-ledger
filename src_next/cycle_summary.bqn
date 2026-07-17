# cycle_summary.bqn
# Cycle Summary section for src_next.
# Machine Format for checks; FormatHuman for human-readable output.

tbds ← •Import "tbds.bqn"
loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
plan_rows ← •Import "plan_rows.bqn"
L ← labels.Text
cube ← •Import "cube.bqn"

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

MakeDiagnostic ← {𝕊 source_row‿status‿date‿message:
  {
    source_file ⇐ "plan.tsv",
    source_row ⇐ source_row,
    status ⇐ status,
    date ⇐ date,
    message ⇐ message
  }
}

BuildRemainingEvidenceFromLines ← {𝕊 plan_lines‿journal_lines‿cy:
  JournalInCycle ← {𝕊 line:
    flds ← loader.SplitTsvKeepEmpty line
    d ← proj.FieldOrEmpty ⟨flds, 0⟩
    ok ← proj.IsValidDateText d
    r ← 0
    {𝕊:
      dn ← proj.DaysFromEpoch d
      r ↩ (dn ≥ proj.DaysFromEpoch cy.start) ∧ (dn < proj.DaysFromEpoch cy.end_exclusive)
    }⍟ok @
    r
  }
  journal_cycle_lines ← (JournalInCycle¨ journal_lines) / journal_lines
  journal_plan_ids ← plan_rows.PlanId¨ journal_cycle_lines

  {𝕊 i:
    line ← i ⊑ plan_lines
    flds ← loader.SplitTsvKeepEmpty line
    pid ← plan_rows.PlanId line
    completed ← ∨´ 0 ∾ (pid⊸≡¨ journal_plan_ids)
    {
      source_row ⇐ i,
      date ⇐ proj.FieldOrEmpty ⟨flds, 0⟩,
      plan_id ⇐ pid,
      completed ⇐ completed
    }
  }¨ ↕ ≠ plan_lines
}

BuildRemainingEvidence ← {𝕊 base‿cy:
  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  journal_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  BuildRemainingEvidenceFromLines ⟨plan_lines, journal_lines, cy⟩
}

RowsForPlanSource ← {𝕊 rows‿source_row:
  mask ← ({𝕩.source_file ≡ "plan.tsv"}¨ rows) ∧ ({𝕩.source_row = source_row}¨ rows)
  mask / rows
}

PairStructureOk ← {𝕊 ev‿rows:
  debit_count ← +´ ("debit"⊸≡¨ {𝕩.side}¨ rows)
  credit_count ← +´ ("credit"⊸≡¨ {𝕩.side}¨ rows)
  plan_layers ← {𝕩.layer_index = proj.layer_plan}¨ rows
  matching_dates ← ev.date⊸≡¨ {𝕩.date}¨ rows
  (2 = ≠ rows) ∧ (1 = debit_count) ∧ (1 = credit_count) ∧ (∧´ plan_layers) ∧ (∧´ matching_dates)
}

ExpenseDebitRows ← {𝕊 resolved‿rows:
  roles_with_sentinel ← resolved.roles ∾ ⟨""⟩
  IsExpenseDebit ← {𝕊 row:
    role ← row.account_key_index ⊑ roles_with_sentinel
    (row.side ≡ "debit") ∧ (role ≡ "expense")
  }
  (IsExpenseDebit¨ rows) / rows
}

BuildRemainingFromEvidence ← {𝕊 ctx‿as_of‿evidence:
  result ← {
    state ⇐ "error",
    reason ⇐ "invalid_observation",
    diagnostics ⇐ ⟨⟩,
    amount ⇐ "unavailable"
  }

  {𝕊:
    cy ← ctx.cy
    as_dn ← proj.DaysFromEpoch as_of
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    diagnostics ← ⟨⟩
    amounts ← ⟨⟩

    {𝕊 ev:
      d ← ev.date
      date_ok ← proj.IsValidDateText d

      {𝕊:
        diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "invalid_date", d, "invalid date: " ∾ d⟩⟩
      }⍟(¬ date_ok) @

      {𝕊:
        dn ← proj.DaysFromEpoch d
        applicable ← (dn ≥ as_dn) ∧ (dn < end_dn) ∧ (¬ ev.completed)

        {𝕊:
          joined ← RowsForPlanSource ⟨ctx.posting_rows, ev.source_row⟩
          pair_ok ← PairStructureOk ⟨ev, joined⟩

          {𝕊:
            diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, "structural_join", d, "plan source row does not join to exactly one debit/credit plan pair"⟩⟩
          }⍟(¬ pair_ok) @

          {𝕊:
            rejected ← ({𝕩.status ≢ "ok"}¨ joined) / joined
            {𝕊:
              bad ← ⊑ rejected
              diagnostics ↩ diagnostics ∾ ⟨MakeDiagnostic ⟨ev.source_row, bad.status, d, bad.message⟩⟩
            }⍟(0 < ≠ rejected) @

            {𝕊:
              expense_debits ← ExpenseDebitRows ⟨ctx.resolved, joined⟩
              {𝕊: expense_debit ← ⊑ expense_debits ⋄ amounts ↩ amounts ∾ ⟨expense_debit.delta⟩}⍟(1 = ≠ expense_debits) @
            }⍟(0 = ≠ rejected) @
          }⍟pair_ok @
        }⍟applicable @
      }⍟date_ok @
    }¨ evidence

    result ↩ {
      state ⇐ "error",
      reason ⇐ "rejected_plan_evidence",
      diagnostics ⇐ diagnostics,
      amount ⇐ "unavailable"
    }

    {𝕊:
      result ↩ {
        state ⇐ "ok",
        reason ⇐ "remaining_plan_active",
        diagnostics ⇐ ⟨⟩,
        amount ⇐ cube.Sum0 amounts
      }
    }⍟(0 = ≠ diagnostics) @
  }⍟(proj.IsValidDateText as_of) @

  result
}

PlanExpenseRemainingAt ← {𝕊 ctx‿as_of‿fallback_total:
  base ← ({𝕊: ctx.base}⎊{𝕊: ""}) @
  result ← {
    state ⇐ "ok",
    reason ⇐ "no_base_compatibility",
    diagnostics ⇐ ⟨⟩,
    amount ⇐ fallback_total
  }
  {𝕊:
    evidence ← BuildRemainingEvidence ⟨base, ctx.cy⟩
    result ↩ BuildRemainingFromEvidence ⟨ctx, as_of, evidence⟩
  }⍟(0 < ≠ base) @
  result
}

# Build: build a minimal cycle summary namespace from context.
# Uses TBDS query helpers for income/expense/net.
Build ← {𝕊 ctx:
  income_actual ← tbds.ActualIncomeAmount ctx.tbds
  expense_actual ← tbds.ActualExpenseAmount ctx.tbds
  net_actual ← income_actual - expense_actual
  plan_expense ← tbds.PlanExpenseAmount ctx.tbds

  # Calculate the Cycle Summary observation boundary and days remaining.
  base ← ({𝕊: ctx.base}⎊{𝕊: ""}) @
  as_of ← { (0 < ≠ base) ? (LatestActualDateInCycle ⟨base, ctx.cy⟩) ; "unavailable" }
  days_remaining ← ((as_of ≡ "unavailable") ∨ (ctx.cy.end_exclusive ≡ "unavailable")) ◶ ⟨ { 𝕩 ⋄
    as_dn ← proj.DaysFromEpoch as_of
    end_dn ← proj.DaysFromEpoch ctx.cy.end_exclusive
    0 ⌈ (end_dn - as_dn)
  }, { 𝕩 ⋄ 0 } ⟩ @

  remaining ← PlanExpenseRemainingAt ⟨ctx, as_of, plan_expense⟩

  result ← {
    state                  ⇐ remaining.state,
    reason                 ⇐ remaining.reason,
    diagnostics            ⇐ remaining.diagnostics,
    start                  ⇐ ctx.cy.start,
    end_exclusive          ⇐ ctx.cy.end_exclusive,
    day_count              ⇐ ctx.cy.day_count,
    days_remaining         ⇐ "unavailable",
    income_actual          ⇐ "unavailable",
    expense_actual         ⇐ "unavailable",
    net_actual             ⇐ "unavailable",
    plan_expense           ⇐ "unavailable",
    plan_expense_remaining ⇐ "unavailable",
    income_entries         ⇐ ⟨⟩
  }

  {𝕊:
    # Extract nonzero actual income entries for breakdown.
    all_actual ← tbds.RowsForLayer ⟨cube.layer_actual, ctx.tbds⟩
    IsIncome ← { (𝕩.role ≡ "income") ∧ (𝕩.credit_movement ≠ 0) }
    income_rows ← (IsIncome¨ all_actual) / all_actual
    income_entries ← {⟨𝕩.account_key, -𝕩.credit_movement⟩}¨ income_rows

    result ↩ {
      state                  ⇐ remaining.state,
      reason                 ⇐ remaining.reason,
      diagnostics            ⇐ remaining.diagnostics,
      start                  ⇐ ctx.cy.start,
      end_exclusive          ⇐ ctx.cy.end_exclusive,
      day_count              ⇐ ctx.cy.day_count,
      days_remaining         ⇐ days_remaining,
      income_actual          ⇐ income_actual,
      expense_actual         ⇐ expense_actual,
      net_actual             ⇐ net_actual,
      plan_expense           ⇐ plan_expense,
      plan_expense_remaining ⇐ remaining.amount,
      income_entries         ⇐ income_entries
    }
  }⍟(remaining.state ≡ "ok") @

  result
}

FormatDiagnostic ← {𝕊 i‿diagnostic:
  prefix ← "src_next_cycle_diagnostic_" ∾ (•Fmt (1 + i))
  out ← prefix ∾ "_source_file: " ∾ diagnostic.source_file ∾ (@+10)
  out ↩ out ∾ prefix ∾ "_source_row: " ∾ (•Fmt diagnostic.source_row) ∾ (@+10)
  out ↩ out ∾ prefix ∾ "_date: " ∾ diagnostic.date ∾ (@+10)
  out ↩ out ∾ prefix ∾ "_status: " ∾ diagnostic.status ∾ (@+10)
  out ↩ out ∾ prefix ∾ "_message: " ∾ diagnostic.message ∾ (@+10)
  out
}

Format ← {𝕊 summary:
  state ← ({𝕊: summary.state}⎊{𝕊: "ok"}) @
  reason ← ({𝕊: summary.reason}⎊{𝕊: "remaining_plan_active"}) @
  diagnostics ← ({𝕊: summary.diagnostics}⎊{𝕊: ⟨⟩}) @
  out ← "--- SrcNext Cycle Summary ---" ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_state: " ∾ state ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_reason: " ∾ reason ∾ (@+10)
  out ↩ out ∾ "src_next_cycle_diagnostic_count: " ∾ (•Fmt ≠ diagnostics) ∾ (@+10)

  {𝕊:
    out ↩ out ∾ "src_next_cycle_start: " ∾ summary.start ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_end_exclusive: " ∾ summary.end_exclusive ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_day_count: " ∾ (•Fmt summary.day_count) ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_income_actual: " ∾ (•Fmt summary.income_actual) ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_expense_actual: " ∾ (•Fmt summary.expense_actual) ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_net_actual: " ∾ (•Fmt summary.net_actual) ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_plan_expense: " ∾ (•Fmt summary.plan_expense) ∾ (@+10)
    out ↩ out ∾ "src_next_cycle_plan_expense_remaining: " ∾ (•Fmt summary.plan_expense_remaining) ∾ (@+10)
  }⍟(state ≡ "ok") @

  {𝕊:
    out ↩ out ∾ ∾ {𝕊 i: FormatDiagnostic ⟨i, i ⊑ diagnostics⟩}¨ ↕ ≠ diagnostics
  }⍟(state ≡ "error") @
  out
}

FormatHumanDiagnostic ← {𝕊 diagnostic:
  out ← "  - " ∾ diagnostic.source_file ∾ " source_row=" ∾ (•Fmt diagnostic.source_row)
  out ↩ out ∾ " date=" ∾ diagnostic.date ∾ " status=" ∾ diagnostic.status ∾ (@+10)
  out ↩ out ∾ "    " ∾ diagnostic.message ∾ (@+10)
  out
}

# FormatHuman: render cycle summary as human-readable text.
# Args: ⟨summary, expenseEntries⟩
#   summary       - from Build(ctx)
#   expenseEntries - ⟨account_key, amount⟩ pairs from expense_breakdown.Build(ctx)
FormatHuman ← {𝕊 summary‿expenseEntries:
  state ← ({𝕊: summary.state}⎊{𝕊: "ok"}) @
  reason ← ({𝕊: summary.reason}⎊{𝕊: "remaining_plan_active"}) @
  diagnostics ← ({𝕊: summary.diagnostics}⎊{𝕊: ⟨⟩}) @
  out ← ""

  {𝕊:
    out ↩ (L "cycle.section_title") ∾ (@+10) ∾ (@+10)
    out ↩ out ∾ "  " ∾ fmt.Bad "ERROR: Cycle Summary stopped because plan evidence is invalid." ∾ (@+10)
    out ↩ out ∾ "  reason: " ∾ reason ∾ (@+10) ∾ (@+10)
    out ↩ out ∾ ∾ FormatHumanDiagnostic¨ diagnostics
  }⍟(state ≢ "ok") @

  {𝕊:
    # Amount formatter: convert ¯ to - (width 14)
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

    out ↩ (L "cycle.section_title") ∾ (@+10) ∾ (@+10)

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

    # Income breakdown
    inc_amounts ← {1⊑𝕩}¨ summary.income_entries
    inc_sorted ← (⌽⍋inc_amounts) ⊏ summary.income_entries
    tbl_inc ← FormatTableGroup inc_sorted
    out ↩ out ∾ (0 < ≠tbl_inc) ◶ ⟨{""}, {(L "cycle.income_breakdown_title") ∾ (@+10) ∾ tbl_inc ∾ (@+10)}⟩ @

    # Expense breakdown
    exp_amounts ← {1⊑𝕩}¨ expenseEntries
    exp_sorted ← (⌽⍋exp_amounts) ⊏ expenseEntries
    tbl_exp ← FormatTableGroup exp_sorted
    out ↩ out ∾ (0 < ≠tbl_exp) ◶ ⟨{""}, {(L "cycle.expense_breakdown_title") ∾ (@+10) ∾ tbl_exp ∾ (@+10)}⟩ @
  }⍟(state ≡ "ok") @

  out
}

{
  Build ⇐ Build,
  Format ⇐ Format,
  FormatHuman ⇐ FormatHuman,
  BuildRemainingEvidenceFromLinesForTest ⇐ BuildRemainingEvidenceFromLines,
  BuildRemainingFromEvidenceForTest ⇐ BuildRemainingFromEvidence
}
