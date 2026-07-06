loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

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

Build ← {𝕊 base‿cy:
  plan_lines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  plan_mask ← { InCycle ⟨cy, 𝕩⟩ }¨ plan_lines
  rows ← plan_mask / plan_lines
  GetDate ← { ⊑ Pad5 loader.SplitTsvKeepEmpty 𝕩 }
  rows ↩ (⍋ GetDate¨ rows) ⊏ rows
  journal_lines ← loader.ReadLinesOptional (base ∾ "/journal.tsv")
  journal_mask ← { InCycle ⟨cy, 𝕩⟩ }¨ journal_lines
  journal_rows ← journal_mask / journal_lines
  journal_plan_ids ← PlanId¨ journal_rows
  plan_ids ← PlanId¨ rows
  completed_mask ← { ∨´ 𝕩⊸≡¨ journal_plan_ids }¨ plan_ids
  {
    rows ⇐ rows,
    plan_ids ⇐ plan_ids,
    completed_mask ⇐ completed_mask,
    journal_rows ⇐ journal_rows,
    journal_plan_ids ⇐ journal_plan_ids
  }
}

{ PlanId ⇐ PlanId, InCycle ⇐ InCycle, Build ⇐ Build }
