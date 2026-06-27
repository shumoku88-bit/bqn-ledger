# planned_payments.bqn
# Compact current-cycle plan source rows for src_next Stage 4 trial.
# Read-only: displays plan rows in source order; no mutation.
# Plan/journal matching uses plan_id metadata (primary) with 5-field TSV fallback.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
L ← labels.Text

# ── CleanName helper ──────────────────────────────────────
StartsWith ← { 𝕨 ≡ (≠ 𝕨) ↑ 𝕩 }
CleanName ← {
  ( "expenses:" StartsWith 𝕩 ) ? 9 ↓ 𝕩 ;
  ( "income:" StartsWith 𝕩 ) ? 7 ↓ 𝕩 ;
  ( "liabilities:" StartsWith 𝕩 ) ? 12 ↓ 𝕩 ;
  𝕩
}

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

# Extract plan_id from metadata (primary) or use first 5 TSV fields (fallback).
PlanId ← {𝕊 line:
  flds ← loader.SplitTsvKeepEmpty line
  meta ← 5 ↓ flds
  IsPlanId ← {"plan_id=" ≡ 8↑𝕩}
  cand ← IsPlanId¨ meta
  has ← ∨´cand
  id ← ∾ 5↑flds
  id ↩ ({𝕊: 8 ↓ (⊑(cand/↕≠meta)) ⊑ meta}⍟has) id
  id
}

InCycle ← {𝕊 cycleStart‿dayCount‿line:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  day ← proj.ResolveDayFromCycle ⟨0⊑flds, cycleStart⟩
  (day ≥ 0) ∧ (day < dayCount)
}

StatusFor ← {𝕊 planId‿journalPlanIds:
  (∨´ (planId⊸≡¨ journalPlanIds)) ⊑ ⟨ "planned", "paid" ⟩
}

FormatLine ← {𝕊 line‿status:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  date ← 0⊑flds
  memo ← 1⊑flds
  fromAcc ← 2⊑flds
  toAcc ← 3⊑flds
  amount ← 4⊑flds
  "src_next_planned_payment: " ∾ date ∾ " " ∾ status ∾ " " ∾ memo ∾ " " ∾ fromAcc ∾ " " ∾ toAcc ∾ " " ∾ amount ∾ (@+10)
}

# Format: show plan entries with status from context.
Format ← {𝕊 ctx:
  base ← ctx.base
  cy ← ctx.cy
  lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  mask ← { InCycle ⟨cy.start, cy.day_count, 𝕩⟩ }¨ lines
  rows ← mask / lines

  # Sort rows by date (first field in TSV)
  GetDate ← { ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩 }
  rows ↩ (⍋ GetDate¨ rows) ⊏ rows

  journalLines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  journalInCycleMask ← { InCycle ⟨cy.start, cy.day_count, 𝕩⟩ }¨ journalLines
  journalInCycle ← journalInCycleMask / journalLines
  journalPlanIds ← PlanId¨ journalInCycle

  statuses ← { StatusFor ⟨PlanId 𝕩, journalPlanIds⟩ }¨ rows

  out ← "--- SrcNext Planned Payments ---" ∾ (@+10)
  { out ↩ out ∾ ∾ ({ FormatLine ⟨𝕩⊑rows, 𝕩⊑statuses⟩ }¨ ↕ ≠ rows) }⍟(0 < ≠ rows) @
  {𝕊: out ↩ out ∾ "src_next_planned_payment: (none)" ∾ (@+10)}⍟(0 = ≠ rows) @
  out
}

# Latest in-cycle actual journal date.
LatestActualDateInCycle ← {𝕊 base‿cy:
  lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  available_cycle ← (cy.start ≢ "unavailable") ∧ (cy.end_exclusive ≢ "unavailable") ∧ (cy.day_count > 0)
  out ← cy.start
  {𝕊:
    start_dn ← proj.DaysFromEpoch cy.start
    end_dn ← proj.DaysFromEpoch cy.end_exclusive
    dates ← {⊑ loader.SplitTsvKeepEmpty 𝕩}¨ lines
    DateInCycle ← {𝕊 d:
      dn ← proj.DaysFromEpoch d
      (dn ≥ start_dn) ∧ (dn < end_dn)
    }
    in_dates ← (DateInCycle¨ dates) / dates
    {𝕊: out ↩ ¯1 ⊑ (∧ in_dates)}⍟(0 < ≠ in_dates) @
  }⍟(available_cycle ∧ (0 < ≠ lines)) @
  out
}

# FormatHuman: render planned payments as human-readable tables.
FormatHuman ← {𝕊 ctx:
  base ← ctx.base
  cy ← ctx.cy
  lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  mask ← { InCycle ⟨cy.start, cy.day_count, 𝕩⟩ }¨ lines
  rows ← mask / lines

  # Sort rows by date (first field in TSV)
  GetDate ← { ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩 }
  rows ↩ (⍋ GetDate¨ rows) ⊏ rows

  journalLines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  journalInCycleMask ← { InCycle ⟨cy.start, cy.day_count, 𝕩⟩ }¨ journalLines
  journalInCycle ← journalInCycleMask / journalLines
  journalPlanIds ← PlanId¨ journalInCycle

  planIds ← PlanId¨ rows
  statuses ← { StatusFor ⟨𝕩, journalPlanIds⟩ }¨ planIds

  as_of ← LatestActualDateInCycle ⟨base, cy⟩
  as_of_dn ← proj.DaysFromEpoch as_of

  ToNum ← { (0 < ≠ 𝕩) ? (•BQN 𝕩) ; 0 }

  ParsedRow ← {
    flds ← Pad5 loader.SplitTsvKeepEmpty 𝕩
    date ← 0⊑flds
    memo ← 1⊑flds
    fromAcc ← 2⊑flds
    toAcc ← 3⊑flds
    amt ← ToNum 4⊑flds
    ⟨date, memo, fromAcc, toAcc, amt⟩
  }
  parsed ← ParsedRow¨ rows

  CatFor ← {
    from ← 2⊑𝕩 ⋄ to ← 3⊑𝕩
    is_inc ← "income:" ≡ 7 ↑ from
    is_inc ⊑ ⟨to, from⟩
  }
  cats ← CleanName¨ CatFor¨ parsed

  HumanStatusFor ← {
    mstatus ← 0⊑𝕩 ⋄ pdate ← 1⊑𝕩
    p_dn ← proj.DaysFromEpoch pdate
    open_idx ← (p_dn = as_of_dn) + (2 × p_dn > as_of_dn)
    open_status ← open_idx ⊑ ⟨ "overdue", "due", "future" ⟩
    ("paid" ≡ mstatus) ⊑ ⟨ open_status , "completed" ⟩
  }
  hstatuses ← { HumanStatusFor ⟨𝕩⊑statuses, 0⊑(𝕩⊑parsed)⟩ }¨ ↕ ≠ rows

  actuals ← { ("paid" ≡ 𝕩⊑statuses) ? (4⊑(𝕩⊑parsed)) ; 0 }¨ ↕ ≠ rows

  out ← "== Planned Payments ==" ∾ (@+10)
  out ↩ out ∾ (@+10)

  # 1. 未了テーブル
  open_mask ← ¬ "completed"⊸≡¨ hstatuses
  open_indices ← open_mask / ↕ ≠ rows

  w_date ← 10
  w_cat_o ← ⌈´ ⟨ fmt.VWidth "Category" ⟩ ∾ (fmt.VWidth¨ open_mask/cats)
  w_memo_o ← ⌈´ ⟨ fmt.VWidth "Memo" ⟩ ∾ (fmt.VWidth¨ open_mask/{1⊑𝕩}¨ parsed)
  w_amt ← 10
  w_status ← 10

  AlignR ← {𝕊 w‿x:
    s ← (1 = •Type x) ⊑ ⟨x, •Fmt x⟩
    ((0 ⌈ w - ≠ s) ⥊ " ") ∾ s
  }

  out ↩ out ∾ (L "planned.open_title") ∾ (@+10)
  out ↩ out ∾ (fmt.PadV ⟨w_date, "Date"⟩) ∾ " | " ∾ (fmt.PadV ⟨w_cat_o, "Category"⟩) ∾ " | " ∾ (fmt.PadV ⟨w_memo_o, "Memo"⟩) ∾ " | " ∾ (AlignR ⟨w_amt, "Amount"⟩) ∾ " | " ∾ (fmt.PadV ⟨w_status, "Status"⟩) ∾ (@+10)

  {
    idx ← 𝕩
    r ← idx⊑parsed
    cat ← idx⊑cats
    status ← idx⊑hstatuses
    status_padded ← fmt.PadV ⟨w_status, status⟩
    status_colored ← (⊑ ⟨"future","completed","due","overdue"⟩ ⊐ ⟨status⟩) ⊑ ⟨fmt.Future status_padded, fmt.Ok status_padded, fmt.Warn status_padded, fmt.Bad status_padded⟩
    out ↩ out ∾ (fmt.PadV ⟨w_date, 0⊑r⟩) ∾ " | " ∾ (fmt.PadV ⟨w_cat_o, cat⟩) ∾ " | " ∾ (fmt.PadV ⟨w_memo_o, 1⊑r⟩) ∾ " | " ∾ (AlignR ⟨w_amt, 4⊑r⟩) ∾ " | " ∾ status_colored ∾ (@+10)
  }¨ open_indices

  open_amts ← open_mask / {4⊑𝕩}¨ parsed
  open_total ← +´ open_amts
  out ↩ out ∾ (@+10) ∾ (L "planned.open_total") ∾ (•Fmt open_total) ∾ (@+10)
  out ↩ out ∾ (@+10)

  # 2. 完了テーブル
  completed_mask ← "completed"⊸≡¨ hstatuses
  completed_indices ← completed_mask / ↕ ≠ rows

  w_cat_c ← ⌈´ ⟨ fmt.VWidth "Category" ⟩ ∾ (fmt.VWidth¨ completed_mask/cats)
  w_memo_c ← ⌈´ ⟨ fmt.VWidth "Memo" ⟩ ∾ (fmt.VWidth¨ completed_mask/{1⊑𝕩}¨ parsed)
  w_planned ← 10
  w_actual ← 10

  out ↩ out ∾ (L "planned.completed_title") ∾ (@+10)
  out ↩ out ∾ (fmt.PadV ⟨w_date, "Date"⟩) ∾ " | " ∾ (fmt.PadV ⟨w_cat_c, "Category"⟩) ∾ " | " ∾ (fmt.PadV ⟨w_memo_c, "Memo"⟩) ∾ " | " ∾ (AlignR ⟨w_planned, "Planned"⟩) ∾ " | " ∾ (AlignR ⟨w_actual, "Actual"⟩) ∾ (@+10)

  {
    idx ← 𝕩
    r ← idx⊑parsed
    cat ← idx⊑cats
    planned ← 4⊑r
    actual ← idx⊑actuals
    out ↩ out ∾ (fmt.PadV ⟨w_date, 0⊑r⟩) ∾ " | " ∾ (fmt.PadV ⟨w_cat_c, cat⟩) ∾ " | " ∾ (fmt.PadV ⟨w_memo_c, 1⊑r⟩) ∾ " | " ∾ (AlignR ⟨w_planned, planned⟩) ∾ " | " ∾ (AlignR ⟨w_actual, actual⟩) ∾ (@+10)
  }¨ completed_indices
  out ↩ out ∾ (@+10)

  # Status legend
  out ↩ out ∾ "[Status]" ∾ (@+10)
  out ↩ out ∾ (L "planned.future_status") ∾ (@+10)
  out ↩ out ∾ (fmt.Warn "due") ∾ (L "planned.due_status") ∾ (@+10)
  out ↩ out ∾ (fmt.Bad "overdue") ∾ (L "planned.overdue_status") ∾ (@+10)
  out ↩ out ∾ (L "planned.completed_status") ∾ (@+10)
  out ↩ out ∾ (@+10)

  out
}

{ Format ⇐ Format, StatusFor ⇐ StatusFor, FormatHuman ⇐ FormatHuman, LatestActualDateInCycle ⇐ LatestActualDateInCycle, PlanId ⇐ PlanId }
