# Plan Completion Workflow Design Intake

Status: active intake / design candidate
Date: 2026-07-08

## Context

On 2026-07-08, the command-hub path for plan completion was found to be misleading:

- `tools/plan-finish-replenish-ui.sh` already implemented the intended workflow: finish one open plan into `journal.tsv`, then optionally create/extend a follow-up plan.
- `tools/add-ui.sh plan-finish`, reached from `tools/bl` -> `add`, still used a separate incomplete path.
- A small wiring fix redirected `add-ui` plan-finish to `tools/plan-finish-replenish-ui.sh` and updated labels/docs.

This made the daily workflow usable again, but it should be treated as a tactical routing fix, not a complete design decision.

## Problem to design

Define a durable contract for “予定の実績化” as a workflow spanning:

- `tools/edit plan finish` — low-level safe append of actual journal row
- `tools/plan-finish-replenish-ui.sh` — completion + optional future plan replenishment
- `tools/add-ui.sh` — write-operation menu entry
- `tools/bl` — command hub entry point
- docs/checks — user-visible behavior and regression coverage

## Design questions

1. **Responsibility boundary**
   - Keep `tools/edit plan finish` minimal: plan -> journal only?
   - Keep replenishment as orchestration UI, or promote more of it into BQN editor commands?

2. **Actual date vs planned date**
   - If a withdrawal happens earlier/later, should the user edit `plan.tsv` date first, or should `actual-date` alone capture reality?
   - Should plan date remain the original expected date for variance/history, or be allowed to track revised expectation?

3. **Actual amount variance**
   - Should completion allow overriding amount at finish time?
   - How should planned-vs-actual variance be represented and reported?

4. **Follow-up plan date rule**
   - Current helper offers `1m`, `2m`, and manual.
   - Decide whether next date should default from finished plan date, actual date, latest related open plan, or an account/series rule.
   - Consider fixed bill day, income-anchor, pension/even-month cadence, and manual-only cases.

5. **Metadata inheritance**
   - `plan_id` must never be copied.
   - Decide which metadata should be copied or regenerated: `series=`, `recur=`, anchor metadata, notes, etc.
   - Avoid putting domain semantics in shell; BQN/editor or config should own meaning.

6. **Failure and recovery**
   - If journal append succeeds but follow-up plan add is cancelled or fails, what should the UI say?
   - Should the workflow summarize resulting journal row, closed plan, and next open plan?
   - What backup/post-check evidence should be surfaced?

7. **Duplicate / related-plan detection**
   - Current duplicate check is exact date/memo/from/to/amount.
   - Related plan detection is BQN-owned via `tools/edit plan related`.
   - Decide whether this is sufficient or needs a structured contract/check.

## Suggested next slice

Docs-only design slice:

1. Write `docs/PLAN_COMPLETION_WORKFLOW_CONTRACT.md` or equivalent.
2. Specify responsibility boundaries, date/amount/meta rules, and failure behavior.
3. Add/adjust checks only after the contract is stable.
4. Do not migrate source TSV or change real data as part of the design slice.

## Priority note

This is a next-candidate item, not urgent active work. It can wait behind the separate multi-currency PR/workstream.
