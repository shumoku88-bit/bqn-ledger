# Cycle Remaining-Plan Numeric-Owner Compatibility Decision

Status: completed decision record / docs-only
Owner: report
Canonical: no; current paths: `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`, `TODO.md`, `docs/REPORT_CONTRACTS.md`, and future runtime checks
Exit: retain as the approved preimplementation compatibility decision; a runtime migration may implement it only when independently selected

## Decision scope

This record decides the compatibility contract required before Cycle Summary `plan_expense_remaining` can move away from its current local `plan.tsv` amount parser. It follows the executable characterization in `CYCLE_REMAINING_PLAN_NUMERIC_OWNER_CHARACTERIZATION-2026-07-16.md`.

This slice changes no runtime, BQN module, fixture expectation, check, source/config schema, report output, or private data. The runtime migration remains unselected.

## Decision summary

A future runtime migration must:

1. exclude completed plans from `plan_expense_remaining` using the existing cycle-local `plan_id` completion evidence;
2. preserve the current remaining window `O <= D < C.end_exclusive`;
3. derive money from admitted `plan.tsv` Posting IR joined locally by stable source identity;
4. fail Cycle Summary closed when applicable plan evidence is invalid, rejected, missing, or structurally unjoinable;
5. expose section state, reason, and source diagnostics, and emit no normal Cycle Summary numeric rows on error;
6. preserve valid empty and no-actual behavior as real `ok` results rather than inventing an `unavailable` state.

## 1. Completed plans are excluded from remaining expense

`plan_expense_remaining` means unfinished expense plans in the remaining cycle window. A plan that is completed under the existing cycle-local completion evidence does not contribute.

The completion boundary is intentionally narrow:

- plan identity remains source evidence through the existing `plan_rows.PlanId` meaning;
- completion remains exact-any-match against cycle-local journal plan identities;
- the current five-field fallback identity remains compatible when explicit `plan_id` metadata is absent;
- duplicate plan IDs are not redesigned in this slice;
- completion identity does not become a Cube axis and does not independently parse money;
- this decision does not redesign plan finishing, metadata inheritance, or actual-entry workflow semantics.

The characterization showed that the current local parser includes a completed plan. The target runtime intentionally changes that result.

## 2. Preserve the current temporal boundary

The target remaining window remains:

```text
O <= D < C.end_exclusive
```

where:

```text
C = selected cycle [start, end_exclusive)
O = latest valid actual date inside C
D = plan event coordinate
```

Compatibility rules:

- a plan on `O` remains included when unfinished;
- a plan before `O` is outside the remaining window;
- a plan on `C.end_exclusive` is outside the cycle;
- if no actual row exists in `C`, `O` remains `C.start`, so valid plans from cycle start onward are eligible;
- rows outside `C` do not move `O`;
- system today, report generation time, record frontier `L`, and a report-wide observation clock do not replace this boundary.

A future local remaining-plan helper should receive explicit `O`, for example:

```text
cycle remaining-plan helper BuildAt ⟨ctx, O⟩
```

Cycle Summary may continue to own its existing local latest-actual-date selection for this runtime slice. Helper extraction, helper renaming, or a shared temporal kernel is not authorized.

An invalid plan date has no trustworthy `D`. Its applicability cannot be proved outside the remaining window, so it fails the Cycle Summary section closed.

## 3. Select a local Posting IR join as numeric owner

The target numeric owner is a report-local join from plan source evidence to admitted checked Posting IR using stable source identity:

```text
plan source evidence
  -> source_file = plan.tsv + source_row
  -> exactly one admitted debit/credit plan Posting IR pair
  -> expense-side debit movement
  -> remaining total
```

The join must verify at least:

- source file and source row identity;
- exactly one debit/credit pair for the source plan row;
- admitted `plan` layer and matching event coordinate;
- no rejected posting status in the pair;
- an expense-role debit contribution for rows selected as expense plans.

Money comes only from the admitted posting movement. The future helper must not:

- reparse source column 5;
- substitute `0` for invalid amount text;
- infer money from memo, metadata, account names, or plan identity;
- aggregate a partially joined posting pair.

This owner preserves registry-backed exact-decimal meaning. For example, a supported source amount such as `49.99` must use its checked normalized coefficient rather than the current raw integer parser's zero substitution.

### Why not the existing Cube

The Canonical Cube intentionally aggregates away source-row identity and plan completion evidence. Adding metadata axes would violate the fixed `Day × Account × Layer` contract.

### Why not a new TBDS plan API in this slice

The value is selected per source plan row before aggregation because completion, rejection, and applicability are row-local. A new generic TBDS-family plan-movement API would be broader than the one current consumer requires.

A later second independent consumer may justify extracting a shared checked plan projection. This decision does not start Projection Workbench or a generic query layer.

## 4. Applicable rejected plan evidence fails Cycle Summary closed

Cycle Summary must not show a normal-looking partial aggregate when applicable plan evidence is invalid or cannot be joined safely.

The section is `error` when any of these apply to a source plan row whose applicability is in the remaining window, or cannot be determined safely:

- invalid date text;
- invalid or unsupported amount evidence retained at the consumer boundary;
- unknown or invalid account evidence;
- rejected plan Posting IR;
- missing Posting IR evidence for an applicable source row;
- a source row that does not join to exactly one debit/credit plan pair;
- a structurally inconsistent joined pair.

Section-local applicability rules:

- a rejected row with a valid `D` fails this section only when `O <= D < C.end_exclusive`;
- a valid-coordinate rejected row outside that window does not by itself fail Cycle Summary;
- an invalid-date row is applicability-unknown and therefore fails closed;
- non-expense and income plans that are valid and admitted are normally excluded, not errors.

Checked projection may expose two rejected posting rows for one rejected source row. Diagnostics must be grouped by stable source identity, at minimum `source_file + source_row`, so one invalid source row does not appear twice merely because Posting IR has debit and credit sides.

Snapshot-wide authorization failures that stop context construction retain precedence. This decision does not require a new nonfatal context carrier.

## 5. Section result and output contract

The future Cycle Summary result gains explicit section evidence:

```text
state
reason
diagnostics
```

The selected runtime vocabulary is:

```text
ok
error
```

There is no selected `unavailable` state for this value:

- an empty valid `plan.tsv` is `ok` with remaining amount `0`;
- no actual row in the cycle is `ok` with `O = C.start`;
- a valid cycle with no remaining expense plan is `ok` with amount `0`;
- invalid source evidence is `error`, not `unavailable`.

### `ok`

When all applicable evidence is valid:

- existing actual income, actual expense, net, total plan expense, and days-remaining semantics remain available;
- `plan_expense_remaining` is the sum of unfinished admitted expense plans in the target window;
- the existing scalar machine field may remain for the valid numeric result;
- diagnostics are empty.

### `error`

When applicable evidence fails:

- human output shows a visible Cycle Summary error and diagnostic context;
- machine output exposes nonempty state/reason and source diagnostics;
- no normal Cycle Summary numeric rows are emitted;
- no partial `plan_expense_remaining`, local zero substitution, or unaffected-looking table is presented as a trustworthy Cycle Summary.

This is a deliberate section-level fail-closed contract consistent with the current report status policy. Independently valid accounting evidence remains available to other report sections; it is not silently reused to make this section appear successful.

### No-base compatibility boundary

The characterized direct-call fallback that returns `fallback_total` when `ctx.base` is absent remains compatibility evidence for module/test callers only. It is not promoted into a public runtime contract and must not justify retaining raw source parsing in the normal base-backed report path.

A runtime implementation may preserve that narrow direct-call fallback if doing so avoids unrelated test churn, provided the production base-backed path always uses the checked owner.

## 6. Intentional compatibility changes

When the runtime migration is independently selected, at least these changes are approved:

1. A completed plan no longer contributes to `plan_expense_remaining`.
2. Supported exact-decimal plan amounts use admitted checked money instead of becoming local zero.
3. Applicable unknown-account or otherwise rejected plan rows produce section `error` instead of silent exclusion or partial totals.
4. Invalid plan dates produce section `error` instead of an uncontrolled crash.
5. Structurally missing Posting IR evidence produces section `error` instead of allowing the raw source parser to continue.
6. Error output contains no normal Cycle Summary numeric rows.

The characterization fixture and its current-behavior assertions remain unchanged as pre-migration evidence. A runtime PR should add target-contract fixtures or explicitly revise expectations while citing both the characterization and this decision.

## 7. Future runtime boundary: selectable, not selected

The next selectable finite slice is a Cycle Summary remaining-plan runtime migration that may:

- add one focused local checked remaining-plan helper;
- join plan source evidence to `ctx.posting_rows` by `source_row`;
- retain existing `plan_id` completion identity behavior;
- preserve `O <= D < C.end_exclusive`;
- add section state/reason/diagnostics and fail-closed formatting;
- add focused public fixtures, unit tests, and check integration;
- update current report contracts for the visible status/output change.

That runtime slice remains unselected after this decision.

## Non-goals

- no `src_next/*.bqn` change;
- no test, fixture, check, golden, or report output change;
- no runtime migration;
- no Cube shape or metadata-axis change;
- no generic TBDS plan API, Projection Workbench, or query framework;
- no shared temporal kernel, helper rename, or report-wide `--as-of`;
- no envelope allocation or execution-plan coverage change;
- no Daily Capacity connection;
- no source TSV, config, metadata, currency policy, editor, or plan-completion workflow change;
- no automatic advice, adjustment, or write path;
- no private production-data access.
