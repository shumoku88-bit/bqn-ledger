# plan_rows.bqn
# Shared source evidence with planned-value and temporal attachment.

loader ← •Import "../src/application/source_io.bqn"
dt ← •Import "date.bqn"
proj ← •Import "projection.bqn"
plan_status ← •Import "../src/accounting/plan_temporal_status.bqn"
actual_source ← •Import "actual_source.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }
ToNum ← { (0 < ≠ 𝕩) ? (•BQN 𝕩) ; 0 }

# Source evidence
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

InCycle ← {𝕊 cy‿line:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  day ← proj.ResolveDayFromCycle ⟨0⊑flds, cy.start⟩
  (day ≥ 0) ∧ (day < cy.day_count)
}

BuildBaseFromCompletionEvidence ← {𝕊 base‿cy‿completion_evidence0:
  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  plan_mask ← { InCycle ⟨cy, 𝕩⟩ }¨ plan_lines
  rows ← plan_mask / plan_lines
  GetDate ← { ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩 }
  rows ↩ (⍋ GetDate¨ rows) ⊏ rows
  InCycleEvidence ← {𝕊 ev:
    ok ← dt.IsValidDateText ev.date
    inside ← 0
    {𝕊: day←proj.ResolveDayFromCycle ⟨ev.date,cy.start⟩ ⋄ inside↩(day≥0)∧day<cy.day_count}⍟ok @
    inside
  }
  completion_evidence ← (InCycleEvidence¨completion_evidence0)/completion_evidence0
  journal_plan_ids ← {𝕩.plan_id}¨completion_evidence
  plan_ids ← PlanId¨ rows
  completed_mask ← { (0<≠𝕩) ∧ ∨´ 𝕩⊸≡¨ journal_plan_ids }¨ plan_ids
  {
    rows ⇐ rows,
    plan_ids ⇐ plan_ids,
    completed_mask ⇐ completed_mask,
    completion_evidence ⇐ completion_evidence,
    journal_plan_ids ⇐ journal_plan_ids
  }
}

BuildBaseFromContext ← {𝕊 ctx:
  completion ← actual_source.CompletionEvidenceFromContext ctx
  BuildBaseFromCompletionEvidence ⟨ctx.base, ctx.cy, completion⟩
}

# Value attachment
ParseRow ← {
  flds ← Pad5 loader.SplitTsvKeepEmpty 𝕩
  ⟨0⊑flds, 1⊑flds, 2⊑flds, 3⊑flds, ToNum 4⊑flds⟩
}

WithValues ← {𝕊 base_view:
  parsed ← ParseRow¨ base_view.rows
  ActualAmountFor ← {𝕊 pid:
    matches ← pid⊸≡¨ base_view.journal_plan_ids
    +´ matches / {𝕩.amount}¨ base_view.completion_evidence
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

# Temporal attachment
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

BuildFromContext ← {𝕊 ctx‿as_of:
  base_view ← BuildBaseFromContext ctx
  valued_view ← WithValues base_view
  WithTemporal ⟨valued_view, as_of⟩
}

# Public exports
{
  PlanId ⇐ PlanId,
  InCycle ⇐ InCycle,
  BuildBaseFromCompletionEvidence ⇐ BuildBaseFromCompletionEvidence,
  BuildBaseFromContext ⇐ BuildBaseFromContext,
  WithValues ⇐ WithValues,
  WithTemporal ⇐ WithTemporal,
  BuildFromContext ⇐ BuildFromContext
}
