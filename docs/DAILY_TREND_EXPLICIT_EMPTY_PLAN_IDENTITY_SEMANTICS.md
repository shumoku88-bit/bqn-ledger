# Daily Trend Explicit Empty Plan Identity Semantics

Status: current observation map
Date: 2026-07-07

## Purpose

Map the repo-wide meaning of explicit empty `plan_id=` after PR #107 proved the state is reachable and materially affects Daily Trend reserve.

This is a semantics map only. It does **not** decide product meaning, runtime repair, or validation policy.

## Main finding

Current layers do not assign one consistent meaning to explicit empty identity.

Observed distinctions include:

- **report compatibility identity**
  - metadata absence -> five-field fallback
  - explicit `plan_id=` -> empty identity
- **editor extraction**
  - absence and explicit empty both surface as empty extracted identity
- **plan list**
  - empty extracted identity routes through the `MISSING-ID` status path
- **plan add**
  - generates or validates a non-empty plan ID
  - rejects `plan_id=...` in generic metadata input
- **plan finish**
  - refuses missing identity
  - requires a non-empty, valid `plan_id`
- **shared completion / actual matching**
  - consumes exact identity equality
- **Daily Trend**
  - explicit empty identity reaches the L-sensitive reserve branch characterized in PR #107

## Current layer map

| Layer | Current behavior | What it means today |
|---|---|---|
| `src_next/plan_journal_overlap.bqn` / `PlanId` | metadata `plan_id=` overrides five-field fallback and can yield `""` | report-side identity can be explicitly empty |
| `src_edit/plan_id.bqn` / `ExtractPlanId` | absence and explicit empty both extract as `""` | editor-side extraction collapses both into empty identity |
| `src_edit/plan_list_cmd.bqn` | empty extracted identity is rendered via `MISSING-ID` path | selection UI treats it as missing identity |
| `src_edit/plan_add_cmd.bqn` | plan ID must be non-empty and metadata `plan_id=` is rejected | write path does not accept explicit empty plan_id metadata |
| `src_edit/plan_finish_cmd.bqn` | missing or invalid plan_id is refused | completion requires usable identity |
| `src_next/daily_trend.bqn` | empty-id branch compares plan date with local `last_act_dn` | reserve can depend on report-local frontier `L` |

## Decision boundary

This document does not decide whether explicit empty identity should:

- remain valid
- fall back to five-field identity
- become invalid input
- form a separate semantic regime

## Runtime impact

None.

Docs only.

No changes to:

- Daily Trend runtime
- reserve logic
- `PlanId` implementation
- editor behavior
- source TSV
- fixtures
- Outlook
- K
- shared temporal kernel

## Next finite question

Choose the product meaning of explicit empty plan identity before authorizing any runtime repair.

## Related evidence

- `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
- `docs/PLAN_ID_LIFECYCLE.md`
- `docs/UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`
- PR #107 characterization: empty-id reserve frontier
