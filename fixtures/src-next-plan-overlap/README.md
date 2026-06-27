# src-next-plan-overlap fixture

Plan/journal overlap diagnostics fixture for src_next Stage 4a.

**plan.tsv:**
- Row 0: `2026-06-16 Shared expenses:food expenses:rent 30` — exact match with journal row 0
- Row 1: `2026-06-20 UniqueP expenses:rent expenses:food 40` — unmatched plan row

**journal.tsv:**
- Row 0: `2026-06-16 Shared expenses:food expenses:rent 30` — exact match with plan row 0
- Row 1: `2026-06-18 UniqueJ equity:opening expenses:food 50` — journal-only row

**Expected overlap diagnostics:**
- plan_rows_checked: 2
- journal_rows_checked: 2
- strong_overlap_count: 1 (Shared: exact 1:1 match)
- ambiguous_overlap_count: 0
- unmatched_plan_count: 1 (UniqueP has no journal match)
