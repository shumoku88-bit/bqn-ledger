# BEHAVIOR_DRIFT_REPORT_PLAN status

Status: **historical discussion / decisions digest archived**
Date: 2026-06-22

`docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` is preserved as long historical reasoning about Plan / Actual / Residual, Envelope boundaries, Scenario placement, and behavior-drift observation.

It should not be used as the current report direction.

## Current report direction

```text
docs/archive/completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md
docs/REPORT_DESIGN.md
```

## Trust order

1. `docs/archive/completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md`
2. `docs/REPORT_DESIGN.md`
3. `docs/BEHAVIOR_DRIFT_REPORT_PLAN.status.md`
4. `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md`
5. `docs/BEHAVIOR_DRIFT_REPORT_PLAN.md` only as long historical reasoning

## Historical decisions digest

Useful preserved decisions now have a shorter archive digest here:

```text
docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_DECISIONS.md
```

Use that digest to understand the decision history without treating the old roadmap as current work.

## Current reconciliation snapshot

The original document already records the current state near its top:

- Plan / Actual / Residual main section was deleted.
- Actual period comparison was introduced as `actual-comparison`.
- Plan fulfillment confirmation mostly belongs to the `planned` section.
- Envelope remains the primary everyday money-management view.
- `plan.tsv` should contain concrete, consciously intended events, not every recurring daily expense.
- Scenario should not be added as a Canonical Daily Cube axis without a separate decision.

Still useful historical decisions preserved by the digest:

- Envelope and Plan answer different questions.
- Residual should be treated as an observation value, not success/failure.
- `actual_only` should not be treated as waste.
- `plan_only` should not be treated as failure.
- Repetitive expenses should not be forced into `plan.tsv` just to make residual reports look complete.
- Scenario experiments should stay outside the Canonical Daily Cube until their meaning is stable.

## Recommended cleanup

Do not delete or rewrite the full original immediately. It is long historical reasoning.

Later, either:

1. Move the full original document to `docs/archive/completed-plans/BEHAVIOR_DRIFT_REPORT_PLAN.md`, if a safe full-file move is practical; or
2. Replace the original document with a shorter historical stub that points here, to the decisions digest, and to `docs/archive/completed-plans/ACTUAL_COMPARISON_REPORT_PLAN.md`.

For now, this status file and the decisions digest mark the document as historical without risking loss of the long original text.

## Non-goals

- Do not edit source TSV data.
- Do not revive the deleted residual main section.
- Do not make `residual` a budget-judgment or failure report.
- Do not add Scenario as a Canonical Daily Cube axis without a separate design decision.
