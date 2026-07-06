# plan_rows.bqn
# Planned-value and temporal attachment over shared plan evidence.

loader ← •Import "loader.bqn"
plan_status ← •Import "plan_status.bqn"
evidence ← •Import "plan_evidence.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }
ToNum ← { (0 < ≠ 𝕩) ? (•BQN 𝕩) ; 0 }

PlanId ← evidence.PlanId
InCycle ← evidence.InCycle
BuildBase ← evidence.Build

ParseRow ← {
  flds ← Pad5 loader.SplitTsvKeepEmpty 𝕩
  ⟨0⊑flds, 1⊑flds, 2⊑flds, 3⊑flds, ToNum 4⊑flds⟩
}

WithValues ← {𝕊 base_view:
  parsed ← ParseRow¨ base_view.rows
  journal_parsed ← ParseRow¨ base_view.journal_rows
  ActualAmountFor ← {𝕊 pid:
    matches ← pid⊸≡¨ base_view.journal_plan_ids
    +´ matches / {4⊑𝕩}¨ journal_parsed
  }
  actuals ← ActualAmountFor¨ base_view.plan_ids

  {
    rows ⇐ base_view.rows,
    parsed ⇐ parsed,
    plan_ids ⇐ base_view.plan_ids,
    completed_mask ⇐ base_view.completed_mask,
    actuals ⇐ actuals
  }
}

WithTemporal ← {𝕊 valued_view‿as_of:
  temporal_statuses ← {
    idx ← 𝕩
    completed ← idx⊑valued_view.completed_mask
    plan_date ← 0⊑(idx⊑valued_view.parsed)
    plan_status.Classify ⟨completed, plan_date, as_of⟩
  }¨ ↕ ≠ valued_view.rows

  {
    rows ⇐ valued_view.rows,
    parsed ⇐ valued_view.parsed,
    plan_ids ⇐ valued_view.plan_ids,
    completed_mask ⇐ valued_view.completed_mask,
    actuals ⇐ valued_view.actuals,
    temporal_statuses ⇐ temporal_statuses
  }
}

Build ← {𝕊 base‿cy‿as_of:
  base_view ← BuildBase ⟨base, cy⟩
  valued_view ← WithValues base_view
  WithTemporal ⟨valued_view, as_of⟩
}

{
  PlanId ⇐ PlanId,
  InCycle ⇐ InCycle,
  BuildBase ⇐ BuildBase,
  WithValues ⇐ WithValues,
  WithTemporal ⇐ WithTemporal,
  Build ⇐ Build
}
