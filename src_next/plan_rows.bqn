# plan_rows.bqn
# Reusable current-cycle plan row projection.
#
# Owns:
# - current-cycle plan selection
# - current-cycle completion evidence selection
# - plan identity compatibility (plan_id primary, 5-field fallback)
# - completion matching and matching actual amount
# - optional temporal status attachment with caller-owned as_of
#
# Does not own formatting, envelope comparison, config policy, or source mutation.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
plan_status ← •Import "plan_status.bqn"

Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }
ToNum ← { (0 < ≠ 𝕩) ? (•BQN 𝕩) ; 0 }

# Extract plan_id from metadata (primary) or use first 5 TSV fields (fallback).
# This preserves the compatibility behavior previously duplicated by
# planned_payments.bqn and envelope_computation.bqn.
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

ParseRow ← {
  flds ← Pad5 loader.SplitTsvKeepEmpty 𝕩
  ⟨0⊑flds, 1⊑flds, 2⊑flds, 3⊑flds, ToNum 4⊑flds⟩
}

# BuildBase intentionally has no as_of input.
# It owns row/evidence identity and completion meaning only.
BuildBase ← {𝕊 base‿cy:
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

  parsed ← ParseRow¨ rows
  journal_parsed ← ParseRow¨ journal_rows
  ActualAmountFor ← {𝕊 pid:
    matches ← pid⊸≡¨ journal_plan_ids
    +´ matches / {4⊑𝕩}¨ journal_parsed
  }
  actuals ← ActualAmountFor¨ plan_ids

  {
    rows ⇐ rows,
    parsed ⇐ parsed,
    plan_ids ⇐ plan_ids,
    completed_mask ⇐ completed_mask,
    actuals ⇐ actuals
  }
}

# Attach temporal meaning without changing row/evidence ownership.
# as_of is explicit and caller-owned.
WithTemporal ← {𝕊 base_view‿as_of:
  temporal_statuses ← {
    idx ← 𝕩
    completed ← idx⊑base_view.completed_mask
    plan_date ← 0⊑(idx⊑base_view.parsed)
    plan_status.Classify ⟨completed, plan_date, as_of⟩
  }¨ ↕ ≠ base_view.rows

  {
    rows ⇐ base_view.rows,
    parsed ⇐ base_view.parsed,
    plan_ids ⇐ base_view.plan_ids,
    completed_mask ⇐ base_view.completed_mask,
    actuals ⇐ base_view.actuals,
    temporal_statuses ⇐ temporal_statuses
  }
}

Build ← {𝕊 base‿cy‿as_of:
  WithTemporal ⟨BuildBase ⟨base, cy⟩, as_of⟩
}

{
  PlanId ⇐ PlanId,
  InCycle ⇐ InCycle,
  BuildBase ⇐ BuildBase,
  WithTemporal ⇐ WithTemporal,
  Build ⇐ Build
}
