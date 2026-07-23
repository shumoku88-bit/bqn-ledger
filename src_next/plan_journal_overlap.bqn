# plan_journal_overlap.bqn
# Read-only plan/journal overlap diagnostics for src_next Stage 4a.
# Plan/journal matching uses plan_id metadata (primary) with 5-field TSV fallback.
# Does not mutate plan.tsv or journal.tsv.

loader ← •Import "loader.bqn"
proj ← •Import "projection.bqn"
cube ← •Import "cube.bqn"
actual_source ← •Import "actual_source.bqn"

# ── Key extraction ──────────────────────────────────────────
Pad5 ← { 𝕩 ∾ ((5 - (5⌊≠𝕩)) ⥊ ⟨""⟩) }

# Extract plan_id from the first matching metadata token when usable; otherwise use first 5 TSV fields (fallback).
PlanId ← {𝕊 line:
  flds ← loader.SplitTsvKeepEmpty line
  meta ← 5 ↓ flds
  IsPlanId ← {"plan_id=" ≡ 8↑𝕩}
  cand ← IsPlanId¨ meta
  has ← ∨´cand
  id ← ∾ 5↑flds
  id ↩ ({𝕊:
    first ← ⊑(cand/↕≠meta)
    val ← 8 ↓ first ⊑ meta
    (0 < ≠ val) ? val ; id
  }⍟has) id
  id
}

# 5-field key (date, memo, from, to, amount) list for display
Key ← { 5 ↑ Pad5 loader.SplitTsvKeepEmpty 𝕩 }

# ── Cycle membership ───────────────────────────────────────
InCycle ← {𝕊 cycleStart‿dayCount‿line:
  flds ← Pad5 loader.SplitTsvKeepEmpty line
  day ← proj.ResolveDayFromCycle ⟨0⊑flds, cycleStart⟩
  (day ≥ 0) ∧ (day < dayCount)
}

# ── Build overlap diagnostics ───────────────────────────────
Build ← {𝕊 ctx:
  base ← ctx.base
  cy ← ctx.cy

  planLines ← loader.ReadLinesOptional (base ∾ "/plan.tsv")
  planInCycleMask ← { InCycle ⟨cy.start, cy.day_count, 𝕩⟩ }¨ planLines
  planInCycle ← planInCycleMask / planLines
  planPlanIds ← PlanId¨ planInCycle

  completion ← actual_source.CompletionEvidence base
  IsCompletionInCycle ← {𝕊 ev: day←proj.ResolveDayFromCycle ⟨ev.date,cy.start⟩ ⋄ (day≥0)∧day<cy.day_count}
  journalInCycle ← (IsCompletionInCycle¨completion)/completion
  journalPlanIds ← {𝕩.plan_id}¨journalInCycle

  # Strong overlap: plan_id appears exactly once in both plan and journal
  strongMask ← {𝕊 pid:
    planCount ← cube.Sum0 (pid⊸≡¨ planPlanIds)
    journalCount ← cube.Sum0 (pid⊸≡¨ journalPlanIds)
    (planCount = 1) ∧ (journalCount = 1)
  }¨ planPlanIds
  strongCount ← cube.Sum0 strongMask

  # Any match: plan_id appears in journal
  journalMatchMask ← {𝕊 pid:
    cube.Sum0 (pid⊸≡¨ journalPlanIds) > 0
  }¨ planPlanIds

  ambiguousMask ← journalMatchMask ∧ (¬ strongMask)
  ambiguousCount ← cube.Sum0 ambiguousMask

  unmatchedCount ← (≠ planPlanIds) - cube.Sum0 journalMatchMask

  # For display: use plan line keys (5-field lists) for readability
  planDisplayKeys ← Key¨ planInCycle

  {
    plan_rows_checked ⇐ ≠ planInCycle,
    journal_rows_checked ⇐ ≠ journalInCycle,
    strong_overlap_count ⇐ strongCount,
    ambiguous_overlap_count ⇐ ambiguousCount,
    unmatched_plan_count ⇐ unmatchedCount,
    strong_overlap_keys ⇐ strongMask / planDisplayKeys,
    ambiguous_overlap_keys ⇐ ambiguousMask / planDisplayKeys
  }
}

# ── Format overlap diagnostics ──────────────────────────────
Format ← {𝕊 summary:
  out ← "--- SrcNext Plan Journal Overlap ---" ∾ (@+10)
  out ↩ out ∾ "src_next_plan_rows_checked: " ∾ (•Fmt summary.plan_rows_checked) ∾ (@+10)
  out ↩ out ∾ "src_next_journal_rows_checked: " ∾ (•Fmt summary.journal_rows_checked) ∾ (@+10)
  out ↩ out ∾ "src_next_plan_journal_strong_overlap_count: " ∾ (•Fmt summary.strong_overlap_count) ∾ (@+10)
  out ↩ out ∾ "src_next_plan_journal_ambiguous_overlap_count: " ∾ (•Fmt summary.ambiguous_overlap_count) ∾ (@+10)
  out ↩ out ∾ "src_next_plan_journal_unmatched_plan_count: " ∾ (•Fmt summary.unmatched_plan_count) ∾ (@+10)

  {𝕊:
    keys ← summary.strong_overlap_keys
    Join5 ← {𝕊 a‿b‿c‿d‿e: a∾"|"∾b∾"|"∾c∾"|"∾d∾"|"∾e}
    {
      out ↩ out ∾ "src_next_plan_journal_strong_overlap_key: " ∾ (Join5 𝕩) ∾ (@+10)
    }¨ keys
  }⍟(0 < summary.strong_overlap_count) @

  {𝕊:
    keys ← summary.ambiguous_overlap_keys
    Join5 ← {𝕊 a‿b‿c‿d‿e: a∾"|"∾b∾"|"∾c∾"|"∾d∾"|"∾e}
    {
      out ↩ out ∾ "src_next_plan_journal_ambiguous_overlap_key: " ∾ (Join5 𝕩) ∾ (@+10)
    }¨ keys
  }⍟(0 < summary.ambiguous_overlap_count) @

  out
}

{ Build ⇐ Build, Format ⇐ Format, Key ⇐ Key, InCycle ⇐ InCycle, PlanId ⇐ PlanId }
