# planned_payments.bqn
# Compact current-cycle plan source rows for src_next Stage 4 trial.
# Read-only: displays plan rows in source order; no mutation.
# Plan/journal matching uses plan_id metadata (primary) with 5-field TSV fallback.

loader ← •Import "loader.bqn"
fmt ← •Import "format.bqn"
labels ← •Import "report_labels.bqn"
json ← •Import "json.bqn"
plan_rows ← •Import "plan_rows.bqn"
actual_source ← •Import "actual_source.bqn"
actual_observation ← •Import "actual_observation.bqn"
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

# Compatibility export. Identity ownership lives in plan_rows.bqn.
PlanId ← plan_rows.PlanId

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

# Pure semantic core. Current-cycle source selection, completion identity, and
# temporal attachment are prepared by plan_rows before entering this boundary.
BuildViewModelFromPrepared ← {𝕊 shared:
  rows ← shared.rows
  parsed ← shared.parsed
  planIds ← shared.plan_ids
  completed_mask ← shared.completed_mask
  actuals ← shared.actuals
  hstatuses ← shared.temporal_statuses

  statuses ← { 𝕩 ⊑ ⟨"planned", "paid"⟩ }¨ completed_mask

  CatFor ← {
    from ← 2⊑𝕩 ⋄ to ← 3⊑𝕩
    is_inc ← "income:" ≡ 7 ↑ from
    is_inc ⊑ ⟨to, from⟩
  }
  cats ← CleanName¨ CatFor¨ parsed

  open_mask ← ¬ completed_mask
  open_indices ← open_mask / ↕ ≠ rows
  open_total ← +´ open_mask / {4⊑𝕩}¨ parsed

  completed_indices ← completed_mask / ↕ ≠ rows

  {
    rows ⇐ rows,
    parsed ⇐ parsed,
    cats ⇐ cats,
    plan_ids ⇐ planIds,
    statuses ⇐ statuses,
    human_statuses ⇐ hstatuses,
    actuals ⇐ actuals,
    open_mask ⇐ open_mask,
    open_indices ⇐ open_indices,
    open_total ⇐ open_total,
    completed_mask ⇐ completed_mask,
    completed_indices ⇐ completed_indices
  }
}

# Context adapter for the human/JSON semantic view.
BuildViewModel ← {𝕊 ctx:
  as_of ← actual_observation.LatestInCycleOrStart ⟨actual_source.DatesFromContext ctx, ctx.cy⟩
  BuildViewModelFromPrepared (plan_rows.BuildFromContext ⟨ctx, as_of⟩)
}

# Compact output intentionally uses only cycle selection and completion state;
# it does not acquire the human/JSON observation or temporal projection.
BuildCompactViewModelFromPrepared ← {𝕊 shared:
  {
    rows ⇐ shared.rows,
    statuses ⇐ { 𝕩 ⊑ ⟨"planned", "paid"⟩ }¨ shared.completed_mask
  }
}

BuildCompactViewModel ← {𝕊 ctx:
  BuildCompactViewModelFromPrepared (plan_rows.BuildBaseFromContext ctx)
}

FormatCompactViewModel ← {𝕊 vm:
  rows ← vm.rows
  statuses ← vm.statuses
  out ← "--- SrcNext Planned Payments ---" ∾ (@+10)
  { out ↩ out ∾ ∾ ({ FormatLine ⟨𝕩⊑rows, 𝕩⊑statuses⟩ }¨ ↕ ≠ rows) }⍟(0 < ≠ rows) @
  {𝕊: out ↩ out ∾ "src_next_planned_payment: (none)" ∾ (@+10)}⍟(0 = ≠ rows) @
  out
}

# Compatibility entrypoint: adapt context, then render only the compact VM.
Format ← {𝕊 ctx: FormatCompactViewModel (BuildCompactViewModel ctx)}

# Pure human renderer.
FormatHumanViewModel ← {𝕊 vm:
  parsed ← vm.parsed
  cats ← vm.cats
  hstatuses ← vm.human_statuses
  actuals ← vm.actuals
  open_indices ← vm.open_indices
  completed_indices ← vm.completed_indices

  out ← (L "planned.section_title") ∾ (@+10)
  out ↩ out ∾ (@+10)

  # 1. Open items table
  OpenRow ← {𝕊 idx:
    r ← idx⊑parsed
    status ← idx⊑hstatuses
    status_text ← (⊑ ⟨"future","completed","due","overdue"⟩ ⊐ ⟨status⟩) ⊑ ⟨fmt.Future status, fmt.Ok status, fmt.Warn status, fmt.Bad status⟩
    ⟨0⊑r, idx⊑cats, 1⊑r, fmt.HumanNumber 4⊑r, status_text⟩
  }
  open_rows ← OpenRow¨ open_indices
  open_headers ← ⟨L "planned.date_header", L "planned.category_header", L "planned.memo_header", L "planned.amount_header", L "planned.status_header"⟩

  out ↩ out ∾ (L "planned.open_title") ∾ (@+10)
  out ↩ out ∾ fmt.RenderTable ⟨open_headers, open_rows, ⟨0, 0, 0, 1, 0⟩⟩
  out ↩ out ∾ (@+10) ∾ (L "planned.open_total") ∾ (fmt.HumanNumber vm.open_total) ∾ (@+10) ∾ (@+10)

  # 2. Completed items table
  CompletedRow ← {𝕊 idx:
    r ← idx⊑parsed
    ⟨0⊑r, idx⊑cats, 1⊑r, fmt.HumanNumber 4⊑r, fmt.HumanNumber idx⊑actuals⟩
  }
  completed_rows ← CompletedRow¨ completed_indices
  completed_headers ← ⟨L "planned.date_header", L "planned.category_header", L "planned.memo_header", L "planned.planned_header", L "planned.actual_header"⟩

  out ↩ out ∾ (L "planned.completed_title") ∾ (@+10)
  out ↩ out ∾ fmt.RenderTable ⟨completed_headers, completed_rows, ⟨0, 0, 0, 1, 1⟩⟩
  out ↩ out ∾ (@+10)

  # Status legend
  out ↩ out ∾ (L "planned.status_legend_title") ∾ (@+10)
  out ↩ out ∾ (L "planned.future_status") ∾ (@+10)
  out ↩ out ∾ (fmt.Warn "due") ∾ (L "planned.due_status") ∾ (@+10)
  out ↩ out ∾ (fmt.Bad "overdue") ∾ (L "planned.overdue_status") ∾ (@+10)
  out ↩ out ∾ (L "planned.completed_status") ∾ (@+10)
  out ↩ out ∾ (@+10)

  out
}

# Compatibility entrypoint: adapt context, then render only the semantic VM.
FormatHuman ← {𝕊 ctx: FormatHumanViewModel (BuildViewModel ctx)}

# Pure JSON renderer over the same semantic view model.
FormatJsonViewModel ← {𝕊 vm:
  BuildOpenItem ← {
    idx ← 𝕩
    r ← idx⊑vm.parsed
    ⟨
      ⟨"date", 0⊑r⟩,
      ⟨"category", idx⊑vm.cats⟩,
      ⟨"memo", 1⊑r⟩,
      ⟨"amount", 4⊑r⟩,
      ⟨"status", idx⊑vm.human_statuses⟩,
      ⟨"plan_id", idx⊑vm.plan_ids⟩
    ⟩
  }
  open_items ← BuildOpenItem¨ vm.open_indices
  open_items ↩ {𝕊: (0 = ≠ open_items) ? 0 ⥊ 0 ; open_items } @

  BuildCompletedItem ← {
    idx ← 𝕩
    r ← idx⊑vm.parsed
    ⟨
      ⟨"date", 0⊑r⟩,
      ⟨"category", idx⊑vm.cats⟩,
      ⟨"memo", 1⊑r⟩,
      ⟨"amount", 4⊑r⟩,
      ⟨"actual_amount", idx⊑vm.actuals⟩,
      ⟨"status", idx⊑vm.human_statuses⟩,
      ⟨"plan_id", idx⊑vm.plan_ids⟩
    ⟩
  }
  completed_items ← BuildCompletedItem¨ vm.completed_indices
  completed_items ↩ {𝕊: (0 = ≠ completed_items) ? 0 ⥊ 0 ; completed_items } @

  root ← ⟨
    ⟨"open_items", open_items⟩,
    ⟨"open_total", vm.open_total⟩,
    ⟨"completed_items", completed_items⟩
  ⟩

  json.Serialize root
}

# Compatibility entrypoint: adapt context, then render only the semantic VM.
FormatJson ← {𝕊 ctx: FormatJsonViewModel (BuildViewModel ctx)}

{
  Format ⇐ Format,
  StatusFor ⇐ StatusFor,
  BuildViewModel ⇐ BuildViewModel,
  BuildViewModelFromPreparedForTest ⇐ BuildViewModelFromPrepared,
  BuildCompactViewModelFromPreparedForTest ⇐ BuildCompactViewModelFromPrepared,
  FormatCompactViewModelForTest ⇐ FormatCompactViewModel,
  FormatHumanViewModelForTest ⇐ FormatHumanViewModel,
  FormatJsonViewModelForTest ⇐ FormatJsonViewModel,
  FormatHuman ⇐ FormatHuman,
  FormatJson ⇐ FormatJson,
  PlanId ⇐ PlanId
}
