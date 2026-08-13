# Home frame observation lifetime — 2026-08-13

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
- `tools/home-calendar` for terminal key decoding, SGR mouse handling, terminal geometry, highlighting, and redraw.

The explicit `calendar`, `cells`, `choices`, and `detail` application modes remain available to non-interactive callers. The interactive terminal path alone changes from two observation calls to one `frame` call.

## Detail lifetime

Selected-date detail remains intentionally separate in this slice.

Ordinary cursor frames do not display detail, so eagerly building detail for every movement would add work and observation surface without user-visible value.

When the user chooses Inspect, the current terminal UI still opens a new detail observation. If calendar and detail are later rendered simultaneously in one visible frame, that combined frame should be published by one application observation too. This is the appropriate prerequisite for repairing or replacing open PR #746; #746 should not be merged merely by placing independently observed detail text beside an older calendar frame.

## Evidence

`checks/check-home-single-observation-frame.sh` protects both halves of the contract:

1. explicit `frame` output contains the rendered month and its semantic CellRelation;
2. a q-only interactive TTY session uses an instrumented `bqn` shim and must launch exactly one `home_calendar_cli.bqn` process, with mode `frame`, for the first visible calendar.

The durable rule is:

```text
one visible semantic frame
        -> one admitted Household observation
pure navigation
        -> no Household observation
physical drawing/input
        -> frontend-owned
```
