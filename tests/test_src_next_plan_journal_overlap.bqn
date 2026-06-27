# test_src_next_plan_journal_overlap.bqn
# Unit tests for plan_journal_overlap.bqn.
#
# Covers:
#   - overlap なし
#   - exact match overlap あり
#   - unmatched plan row あり
#   - empty plan / empty journal でも落ちない

pjo ← •Import "../src_next/plan_journal_overlap.bqn"

Assert ← {𝕊 expected‿actual‿msg:
  result ← expected ≡ actual
  {𝕊:
    •Out "FAIL: " ∾ msg ∾ " expected: " ∾ (•Fmt expected) ∾ " actual: " ∾ (•Fmt actual)
  }⍟(¬result) @
  result
}

AllOk ← ∧

# ── Build: fixture src-next-plan-overlap (has overlap) ─────
cy ← {start⇐"2026-06-15", day_count⇐7}
summary ← pjo.Build { base ⇐ "fixtures/src-next-plan-overlap", cy ⇐ cy }

r1 ← Assert ⟨2, summary.plan_rows_checked, "plan_rows_checked = 2"⟩
r2 ← Assert ⟨2, summary.journal_rows_checked, "journal_rows_checked = 2"⟩
r3 ← Assert ⟨1, summary.strong_overlap_count, "strong_overlap_count = 1"⟩
r4 ← Assert ⟨0, summary.ambiguous_overlap_count, "ambiguous_overlap_count = 0"⟩
r5 ← Assert ⟨1, summary.unmatched_plan_count, "unmatched_plan_count = 1"⟩

# ── Build: fixture src-next-golden (no overlap) ────────────
summary2 ← pjo.Build { base ⇐ "fixtures/src-next-golden", cy ⇐ cy }

r6 ← Assert ⟨1, summary2.plan_rows_checked, "golden: plan_rows_checked = 1"⟩
r7 ← Assert ⟨2, summary2.journal_rows_checked, "golden: journal_rows_checked = 2"⟩
r8 ← Assert ⟨0, summary2.strong_overlap_count, "golden: strong_overlap_count = 0"⟩
r9 ← Assert ⟨0, summary2.ambiguous_overlap_count, "golden: ambiguous_overlap_count = 0"⟩
r10 ← Assert ⟨1, summary2.unmatched_plan_count, "golden: unmatched_plan_count = 1"⟩

# ── Build: fixture src-next-missing-plan (no plan.tsv) ─────
summary3 ← pjo.Build { base ⇐ "fixtures/src-next-missing-plan", cy ⇐ cy }

r11 ← Assert ⟨0, summary3.plan_rows_checked, "missing-plan: plan_rows_checked = 0"⟩
r12 ← Assert ⟨2, summary3.journal_rows_checked, "missing-plan: journal_rows_checked = 2"⟩
r13 ← Assert ⟨0, summary3.strong_overlap_count, "missing-plan: strong_overlap_count = 0"⟩
r14 ← Assert ⟨0, summary3.ambiguous_overlap_count, "missing-plan: ambiguous_overlap_count = 0"⟩
r15 ← Assert ⟨0, summary3.unmatched_plan_count, "missing-plan: unmatched_plan_count = 0"⟩

# ── Build: fixture src-next-empty-projection (empty plan, empty journal) ─
summary4 ← pjo.Build { base ⇐ "fixtures/src-next-empty-projection", cy ⇐ cy }

r16 ← Assert ⟨0, summary4.plan_rows_checked, "empty: plan_rows_checked = 0"⟩
r17 ← Assert ⟨0, summary4.journal_rows_checked, "empty: journal_rows_checked = 0"⟩
r18 ← Assert ⟨0, summary4.strong_overlap_count, "empty: strong_overlap_count = 0"⟩
r19 ← Assert ⟨0, summary4.ambiguous_overlap_count, "empty: ambiguous_overlap_count = 0"⟩
r20 ← Assert ⟨0, summary4.unmatched_plan_count, "empty: unmatched_plan_count = 0"⟩

# ── Build: fixture src-next-unknown-account (unknown account, no overlap) ─
summary5 ← pjo.Build { base ⇐ "fixtures/src-next-unknown-account", cy ⇐ cy }

r21 ← Assert ⟨0, summary5.plan_rows_checked, "unknown-acct: plan_rows_checked = 0"⟩
r22 ← Assert ⟨2, summary5.journal_rows_checked, "unknown-acct: journal_rows_checked = 2"⟩
r23 ← Assert ⟨0, summary5.strong_overlap_count, "unknown-acct: strong_overlap_count = 0"⟩

# ── Build: fixture src-next-out-of-cycle-journal (out of cycle, no overlap) ─
summary6 ← pjo.Build { base ⇐ "fixtures/src-next-out-of-cycle-journal", cy ⇐ cy }

r24 ← Assert ⟨0, summary6.plan_rows_checked, "out-of-cycle: plan_rows_checked = 0"⟩
r25 ← Assert ⟨1, summary6.journal_rows_checked, "out-of-cycle: journal_rows_checked = 1 (one in-cycle)"⟩
r26 ← Assert ⟨0, summary6.strong_overlap_count, "out-of-cycle: strong_overlap_count = 0"⟩

# ── Format output check ────────────────────────────────────

text ← pjo.Format summary
r27 ← Assert ⟨1, 0 < ≠ text, "Format returns non-empty string"⟩
r28 ← Assert ⟨1, ∨´ "SrcNext Plan Journal Overlap"⊸⍷ text, "Format contains section header"⟩
r29 ← Assert ⟨1, ∨´ "src_next_plan_rows_checked"⊸⍷ text, "Format contains plan_rows_checked"⟩
r30 ← Assert ⟨1, ∨´ "src_next_plan_journal_strong_overlap_key"⊸⍷ text, "Format contains strong_overlap_key"⟩

# All results
results ← r1‿r2‿r3‿r4‿r5‿r6‿r7‿r8‿r9‿r10‿r11‿r12‿r13‿r14‿r15‿r16‿r17‿r18‿r19‿r20‿r21‿r22‿r23‿r24‿r25‿r26‿r27‿r28‿r29‿r30

{𝕊:
  •Out "All tests passed (" ∾ (•Fmt (+´results)) ∾ "/" ∾ (•Fmt (≠results)) ∾ ")"
}⍟(AllOk results) @

{𝕊:
  •Out "FAILED: " ∾ (•Fmt ((≠results) - (+´results))) ∾ " test(s)"
  •Exit 1
}⍟(¬ AllOk results) @
