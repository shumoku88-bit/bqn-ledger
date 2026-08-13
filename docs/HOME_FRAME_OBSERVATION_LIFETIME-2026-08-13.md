# Home frame observation lifetime — 2026-08-13

## Follow-up: Home closeout after #746

The Home observation/navigation lane is now closed enough to return to the normal BQN-native production review.

The final audit after #746 found no Household/accounting meaning leaking back into shell. It did identify a few local residues, which this closeout removes:

- independent Home validation diagnostics are represented as ordered BQN collections and joined with `∾´` where evaluation is genuinely independent;
- fixed-width calendar cell text has one Home presentation owner, `CellText`, shared by human calendar rendering and cursor publication;
- the selector-era `choices` publication and its dedicated test are retired because the direct matrix cursor consumes `CellRelation` / `CellText` instead;
- explicit logical movement with a supplied focus date no longer observes the application clock;
- cursor-frame publication failures retain their BQN diagnostic and original non-130 status, matching the existing detail-frame failure contract;
- the terminal disables autowrap only for its alternate-screen session, so long physical detail lines cannot invalidate vertical viewport row geometry; cleanup restores terminal autowrap.

These changes do not create a generic UI framework or move physical terminal behavior into BQN semantics. The durable split remains:

```text
Home relation / CellRelation / CellText / selected detail -> BQN
logical selected-date movement                         -> pure BQN
observation lifetime / publication                     -> BQN application
keys / mouse / ANSI / viewport / clipping              -> physical frontend
```

### Documentation status

Several nearby documents are intentionally historical evidence rather than current execution plans:

- `HOME_UI_BOUNDARY_OBSERVATION-2026-08-13.md` records the pre-#757/#758/#746 audit and its old remote state;
- `HOME_NAVIGATION_BOUNDARY_OBSERVATION-2026-08-13.md` records the pre-#757 decision process, with its implementation follow-up at the top;
- `HOME_CALENDAR_INTERACTION_DESIGN-2026-08-12.md` is the design baseline from which the current Home was implemented;
- `COMMAND_HUB_DRILLDOWN_DESIGN-2026-08-12.md` is the design rationale for the hierarchy implemented in #733;
- this document records the current Home observation-lifetime and closeout rules.

Do not treat future-tense implementation sections in the historical design/observation documents as an active roadmap. `TODO.md` remains the production BQN-native review queue; the separate selector/UI consolidation items remain cross-cutting work rather than a reason to keep extending Home now.

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

- `src/sections/home_calendar.bqn` for Home calendar meaning, marker meaning, detail projection, fixed-width cell presentation, `FormatHuman`, and `CellRelation`;
- `src/application/home_calendar_cli.bqn` for one effectful Household observation and publication;
- `src/application/home_navigation.bqn` for pure selected-date movement;
- `tools/home-calendar` for terminal key decoding, SGR mouse handling, terminal geometry, highlighting, viewporting, clipping, and redraw.

The explicit `calendar`, `cells`, `detail`, `frame`, and `detail-frame` application modes remain available to non-interactive callers. The historical selector-specific `choices` mode is retired. Interactive cursor loads use `frame`; Inspect uses `detail-frame`.

## Detail lifetime before #746 reconstruction

At #758, selected-date detail was intentionally left separate because ordinary cursor frames do not display detail. Eagerly building detail for every movement would add work and observation surface without user-visible value.

That remains true. #746 does not make ordinary movement eager. Instead, Inspect opens exactly one new observation because its visible frame now contains both calendar and detail. Closing the detail pane can redraw the frame already held by the frontend without another Household observation.

The historical #758 rule was:

> If calendar and detail are later rendered simultaneously in one visible frame, that combined frame should be published by one application observation too.

The reconstructed #746 implements that rule directly.

## Evidence

`checks/check-home-single-observation-frame.sh` protects ordinary cursor frames:

1. explicit `frame` output contains the rendered month and its semantic CellRelation;
2. a q-only interactive TTY session uses exactly one `home_calendar_cli.bqn` process, with mode `frame`, for the first visible calendar;
3. cursor-frame application failures keep their diagnostic and original failure status instead of becoming Home/back or a generic wrapper error.

`checks/check-home-single-observation-detail-frame.sh` protects Inspect frames:

1. explicit `detail-frame` output contains calendar text, CellRelation, and complete selected-date detail;
2. an interactive Inspect session launches exactly `frame` then `detail-frame`, with no independent `detail` observation;
3. the terminal frame simultaneously contains the calendar, selected cell, and visible detail viewport;
4. a detail publication failure retains its diagnostic and failure status instead of becoming `130`.

`checks/check-home-logical-navigation.sh` protects source- and clock-free movement when the selected date is explicit.

`checks/check-home-narrow-terminal.sh` protects the physical no-autowrap viewport contract and terminal-state restoration on a narrow PTY.

The durable rule is:

```text
one visible semantic frame
        -> one admitted Household observation
pure navigation
        -> no Household observation or clock read when focus is explicit
physical drawing/input/viewport/clipping
        -> frontend-owned
```
