# Home calendar interaction design — 2026-08-12

## Status

Design baseline for the next Command Hub read-only surface. This document does not move accounting, admission, writer, or source authority into shell UI code.

The current `tools/bl` interaction split remains authoritative:

```text
Editor          change admitted Household evidence
Reports         inspect semantic Household results
Source & System inspect or directly handle physical/system boundaries
```

Home sits before those choices as a compact observation surface. It is not a fourth domain owner and it is not a new writer.

## Purpose

The initial screen should answer a smaller daily question before asking the user to choose a command:

> What dates around me contain Household evidence or obligations, and is yesterday/today actually recorded as expected?

The calendar is therefore an index over existing canonical meaning, not a new source of facts.

## Calendar shape

Use a conventional month matrix with fixed-width day cells.

Do not color whole dates in the first version. Color can be reconsidered later, but the initial signal should be a marker so the calendar keeps its visual geometry and remains usable in terminals with different palettes.

Each day has exactly one marker position. The marker position must never widen the cell.

Representative rendering:

```text
August 2026
Mo Tu We Th Fr Sa Su
                1  2
 3  4  5  6  7  8  9
10 11 12! 13 14$ 15 16
17 18 19 20 21 22 23
24 25 26* 27 28 29 30
31
```

The concrete placement may change when the renderer is implemented, but every row must retain the same column geometry whether a date has a marker or not.

## Initial marker meanings

The first version needs only three semantic marker sources:

- cycle end;
- Plan/payment due date;
- Issue due date.

These meanings are already owned elsewhere. Home consumes their admitted/derived dates and must not infer new lifecycle semantics from source text.

Suggested defaults use printable ASCII so terminal width is deterministic:

```text
cycle end        *
Plan/payment due $
Issue due        !
multiple facts   +
```

The defaults are presentation choices only.

## Marker collision

A date may be both a cycle boundary and a payment or Issue date.

Do not silently choose one semantic marker by priority. That would make the calendar lie by omission.

When two or more marker meanings occur on one date, render the fixed-width `multiple` marker. Selecting the date reveals all underlying facts in the detail pane.

This preserves both truths:

```text
calendar geometry stays fixed
calendar does not pretend only one fact exists
```

## `report.toml` ownership

Calendar glyphs are presentation policy, so they belong in canonical `report.toml`, not in Household accounting policy and not in shell environment variables.

Proposed optional section:

```toml
[presentation.calendar]
cycle-end-marker = "*"
plan-due-marker = "$"
issue-due-marker = "!"
multiple-marker = "+"
```

All four values should initially admit exactly one printable ASCII character. This is intentionally stricter than arbitrary Unicode because the Home calendar is a fixed-width terminal matrix and East Asian ambiguous-width glyphs can make otherwise-correct cells drift.

The section should remain optional with the defaults above so existing canonical Household roots remain valid until the user chooses to customize presentation.

`report_policy_admission.bqn` remains the only owner that admits this `report.toml` policy. Home must consume the admitted presentation result rather than reparsing TOML independently.

## Selected-date detail pane

Selecting a date opens a small read-only detail pane next to or below the calendar.

The pane should show canonical facts associated with that exact date, grouped by meaning rather than by physical file:

```text
2026-08-11

Actual
  - supermarket  ¥2,140
  - train          ¥220

Plans due
  - none

Issues due
  - refund follow-up

Cycle
  - inside current cycle
```

For a past date, this makes missing daily recording visually obvious without inventing a separate bookkeeping-completeness flag. If the selected date has no Actual transactions, the pane says so explicitly.

For a future date, the same pane naturally becomes an obligation view: Plans, Issues, and cycle boundaries can be present while Actual is empty.

## Source/semantic ownership

Home must consume existing owners rather than scan canonical files in shell.

- Actual date evidence comes from the admitted Journal/transaction owner used by current Journal/report surfaces.
- Plan due dates come from the Plan owner and its current due/temporal semantics.
- Issue due dates come from the Issue owner, including the due-aware compatibility work already landed on `main`.
- cycle dates come from the existing cycle resolution owner.
- calendar marker configuration comes from admitted `report.toml` presentation policy.

A shell renderer may compose these results for display, but it must not become a second parser for `actual.journal`, `plan.journal`, `issues.tsv`, `household.toml`, or `report.toml`.

## Navigation

Home becomes the ordinary zero-command entrance to `tools/bl`.

The user may then enter the existing interaction hierarchy from Home:

```text
Home
  Editor
  Reports
  Source & System
  Exit
```

Selecting a date remains read-only. A later shortcut from a selected date to an Editor action may prefill a date, but such a shortcut must still delegate publication to the existing writer UI and is not part of the first slice.

## Interaction laws

1. Home is read-only.
2. No canonical source is parsed directly by the shell Home renderer.
3. A calendar cell has fixed display width independent of its facts.
4. Marker collisions are explicit through a multiple-facts marker, not resolved by hidden priority.
5. Marker glyphs are presentation policy in `report.toml`.
6. Existing Household roots remain valid when the calendar presentation section is absent.
7. Selecting a date shows exact admitted/derived evidence for that date rather than a cached narrative guess.
8. Past dates with no Actual evidence are stated plainly.
9. Future dates do not imply missing Actual evidence merely because no Actual transaction exists yet.
10. Home does not duplicate writer authority, report semantics, Plan lifecycle, Issue lifecycle, or cycle resolution.

## First implementation slice

The first code slice should be deliberately narrower than the whole Home screen:

1. extend strict `report.toml` admission with optional `[presentation.calendar]` marker policy and defaults;
2. expose the admitted marker policy in the existing presentation result;
3. add admission tests for defaults, customization, unsupported keys, multi-character values, and non-ASCII width-risk values;
4. do not yet alter `tools/bl` navigation.

After that slice is green, build one read-only BQN Home observation result containing calendar-date relations. Only then should shell rendering/selection be added.

This ordering keeps the user-visible shell thin and makes the semantic date relation testable before terminal interaction is involved.
