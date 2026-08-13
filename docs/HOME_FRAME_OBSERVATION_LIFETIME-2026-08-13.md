# Home frame observation lifetime — 2026-08-13

## Follow-up: #746 clean reconstruction

PR #746 is reconstructed on top of the boundary work merged through #758.

Inspect now follows the same observation rule as the ordinary cursor frame:

```text
one canonical Household observation
        |
        +-- Home calendar result
        |      +-- FormatHuman
        |      +-- CellRelation
        |
        +-- selected-date BuildDetail
        |      +-- FormatDetailHuman
        |
        v
one Home detail-frame publication
        |
        v
thin physical frontend
```

The interactive terminal no longer combines an older cached calendar observation with a separately observed selected-date detail. Its `detail-frame` application call publishes calendar text, semantic cells, and complete selected-date detail from the same admitted Household observation. The terminal replaces its cursor-frame cache from that publication before drawing the detail pane.

The detail publication remains complete. Terminal height, clipping, viewport offset, and scrolling are physical frontend concerns. The terminal therefore keeps the complete BQN-owned detail payload and displays the subset that fits below the calendar. This resolves the earlier ambiguity without moving presentation geometry or a synthetic completeness judgment into Home semantics.

A failed `detail-frame` publication is also distinct from Home/back. Canonical diagnostics survive alternate-screen cleanup and the application failure status is propagated; `130` remains the interaction/back signal.

No generic `Frame`, widget tree, renderer, or UI state framework is introduced. The shared boundary remains Home-specific data and logical navigation over `selected_date`.

## Decision

One visible Home calendar frame must not combine calendar text and cursor-cell meaning from different canonical Household observations.

The terminal cursor therefore consumes one application publication for each loaded month:

```text
one canonical Household observation
        |
        +-- Home calendar result
        |      |
        |      +-- FormatHuman
        |      +-- CellRelation
        |
        v
one Home cursor-frame publication
        |
        v
tools/home-calendar
```

`src/application/home_calendar_cli.bqn` exposes the Home-specific `frame` mode. It publishes the existing rendered calendar followed by the existing semantic cursor-cell relation, separated by an application-protocol marker. The marker is not Home, accounting, or frontend semantics.

`tools/home-calendar` uses `frame` for interactive month loads. It no longer launches separate `calendar` and `cells` BQN processes for one visible frame.

## Preserved boundaries

This change does not introduce a generic Frame type, UI state machine, renderer abstraction, or new Home semantic owner.

The existing owners remain:

- `src/sections/home_calendar.bqn` for Home calendar meaning, marker meaning, detail projection, `FormatHuman`, and `CellRelation`;
- `src/application/home_calendar_cli.bqn` for one effectful Household observation and publication;
- `src/application/home_navigation.bqn` for pure selected-date movement;
- `tools/home-calendar` for terminal key decoding, SGR mouse handling, terminal geometry, highlighting, viewporting, and redraw.

The explicit `calendar`, `cells`, `choices`, `detail`, `frame`, and `detail-frame` application modes remain available to non-interactive callers. Interactive cursor loads use `frame`; Inspect uses `detail-frame`.

## Detail lifetime before #746 reconstruction

At #758, selected-date detail was intentionally left separate because ordinary cursor frames do not display detail. Eagerly building detail for every movement would add work and observation surface without user-visible value.

That remains true. #746 does not make ordinary movement eager. Instead, Inspect opens exactly one new observation because its visible frame now contains both calendar and detail. Closing the detail pane can redraw the frame already held by the frontend without another Household observation.

The historical #758 rule was:

> If calendar and detail are later rendered simultaneously in one visible frame, that combined frame should be published by one application observation too.

The reconstructed #746 implements that rule directly.

## Evidence

`checks/check-home-single-observation-frame.sh` protects ordinary cursor frames:

1. explicit `frame` output contains the rendered month and its semantic CellRelation;
2. a q-only interactive TTY session uses exactly one `home_calendar_cli.bqn` process, with mode `frame`, for the first visible calendar.

`checks/check-home-single-observation-detail-frame.sh` protects Inspect frames:

1. explicit `detail-frame` output contains calendar text, CellRelation, and complete selected-date detail;
2. an interactive Inspect session launches exactly `frame` then `detail-frame`, with no independent `detail` observation;
3. the terminal frame simultaneously contains the calendar, selected cell, and visible detail viewport;
4. a detail publication failure retains its diagnostic and failure status instead of becoming `130`.

The durable rule is:

```text
one visible semantic frame
        -> one admitted Household observation
pure navigation
        -> no Household observation
physical drawing/input/viewport
        -> frontend-owned
```
