# Plan Completion Workflow Design Intake

Status: observation hold; concrete execution-envelope linkage slice completed
Owner: workflow / editor
Canonical: no; completed finite path: `../completed-plans/ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md`
Exit: keep as intake until remaining workflow questions are resolved, rejected, or archived
Date: 2026-07-08

## Context

On 2026-07-08, the command-hub path for plan completion was found to be misleading:

- `tools/plan-finish-replenish-ui.sh` already implemented the intended workflow: finish one open plan into `journal.tsv`, then optionally create/extend a follow-up plan.
- `tools/add-ui.sh plan-finish`, reached from `tools/bl` -> `add`, still used a separate incomplete path.
- A small wiring fix redirected `add-ui` plan-finish to `tools/plan-finish-replenish-ui.sh` and updated labels/docs.

This made the daily workflow usable again, but it should be treated as a tactical routing fix, not a complete design decision.

Two later finite slices were then merged:

- PR #124 added optional actual-amount override at finish time while preserving the planned amount in `plan.tsv`.
- PR #125 added an explicit finish postcondition guard so follow-up replenishment is offered only when the selected plan is explicitly CLOSED.

Current product stance:

```text
plan = expectation
actual = observed fact
process exit 0 != proof that actual append happened
```

The workflow is now returned to daily-use observation rather than continuing automatically into a broader redesign.

## Observation boundary

Do not continue this work merely because unresolved design questions exist.

Reopen only when concrete daily-use evidence shows a real problem such as:

- metadata loss or incorrect inheritance;
- confusing partial success after actual append / follow-up failure;
- next-date suggestions that produce wrong or unsafe future plans;
- responsibility confusion between `tools/edit plan finish`, replenish UI, `tools/add-ui.sh`, and `tools/bl`;
- another reproducible workflow defect.

When reopened, select one finite slice from the evidence. Do not automatically launch a broad Plan Completion Workflow campaign.

## Selected reopening

A completed planned-payment workflow produced a real backing mismatch because the actual payment and execution-envelope consumption were separate manual actions. The narrow response was completed in `../completed-plans/ENVELOPE_EVENT_LINKAGE_AUTOMATION_PLAN-2026-07-14.md`.

That completed slice covers only a confirmation-gated, idempotent plan-completion budget companion and retry path. It does not reopen replenishment rules, metadata inheritance, generic multi-file transactions, or ordinary-income automation.

## Remaining design questions

1. **Responsibility boundary**
   - Keep `tools/edit plan finish` minimal: plan -> journal only?
   - Keep replenishment as orchestration UI, or promote more of it into BQN editor commands?

2. **Actual date vs planned date**
   - Current workflow can capture `actual-date` separately from planned date.
   - Observe whether revised expectations need a distinct contract rather than editing away historical plan meaning.

3. **Actual amount variance**
   - PR #124 now allows actual amount override at finish time.
   - Observe whether planned-vs-actual variance needs an explicit report or contract beyond preserving both source facts.

4. **Follow-up plan date rule**
   - Current helper offers `1m`, `2m`, and manual.
   - If evidence appears, decide whether next date should default from finished plan date, actual date, latest related open plan, or an account/series rule.
   - Consider fixed bill day, income-anchor, pension/even-month cadence, and manual-only cases only when a concrete consumer needs them.

5. **Metadata inheritance**
   - `plan_id` must never be copied.
   - Decide which metadata should be copied or regenerated only after evidence: `series=`, `recur=`, anchor metadata, notes, etc.
   - Avoid putting domain semantics in shell; BQN/editor or config should own meaning.

6. **Failure and recovery**
   - If journal append succeeds but follow-up plan add is cancelled or fails, observe what recovery evidence users actually need.
   - Consider whether the workflow should summarize resulting journal row, closed plan, and next open plan only after a concrete failure mode is seen.

7. **Duplicate / related-plan detection**
   - Current duplicate check is exact date/memo/from/to/amount.
   - Related plan detection is BQN-owned via `tools/edit plan related`.
   - Revisit only if daily use shows this is insufficient.

## Reopen rule

A future slice should start from one concrete observation and one narrow question.

Examples:

```text
metadata inheritance evidence
  -> characterize one lost meaning
  -> decide one owner
  -> add one narrow check/fix

partial failure evidence
  -> characterize resulting state
  -> decide one recovery contract
  -> add one narrow check/fix
```

Do not migrate source TSV or change real data as part of reopening unless a later explicit contract requires it.

## Priority note

Current priority is the separate Currency Awareness workstream, beginning with Stage 0 current JPY / single-amount assumption mapping.

This intake remains available as an observation record, not urgent active work.
