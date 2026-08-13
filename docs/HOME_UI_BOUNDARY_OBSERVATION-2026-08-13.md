# Home UI boundary observation — 2026-08-13

## Status

Observation and architectural guardrail only. No runtime, writer, canonical Household, accounting, identity, provenance, or exact-arithmetic behavior is changed by this document.

This observation follows the Home work merged through #745 and reviews open PR #746 before merge. It is deliberately separate from the Phase 6 editor review lane.

At the time of observation:

- `main`: `66754c758ebef95d64571df7916a23d87e9601ee`;
- #746 `feat(home): keep selected-date detail beside calendar`: open, Ready, mergeable;
- #746 head: `ea0e8bbcb9ce1164d0c3e8842e83752592b9a295`;
- #746 CI run #3008: SUCCESS.

The purpose is not to choose a future UI toolkit. Native BQN terminal presentation, the current shell terminal adapter, raylib, or another frontend may all remain possible. The goal is to prevent Home meaning and interaction behavior from being reimplemented for each frontend.

## Preserved invariants

Home remains read-only.

The following remain outside frontend ownership:

- canonical Household source authority;
- source admission;
- Actual, Plan, Issue, and Cycle semantics;
- writer authority and safe publication;
- transaction identity and provenance;
- exact amount arithmetic;
- calendar marker policy admission.

A frontend may present or navigate admitted meaning. It must not become a second parser, accounting owner, lifecycle owner, or writer.

## Current strengths

`src/sections/home_calendar.bqn` is already close to the desired semantic center.

Its month is represented as relations and arrays rather than a terminal screen model:

- date / ordinal axes;
- a 7-column calendar matrix relation;
- per-day Actual, Plan, and Issue indices;
- independent marker meanings;
- explicit collision handling;
- selected-date detail projected from existing relations rather than source rescanning.

Day and month arithmetic also remains BQN-owned. The shell asks BQN for adjacent focus dates rather than reimplementing Gregorian rules.

These properties should be preserved even if the current terminal UI is replaced.

## Boundary pressure found during the audit

### 1. Cell presentation has more than one contract

The current Home path has several related output forms:

- `FormatHuman`;
- `FormatChoices`;
- application-owned cursor-cell output;
- shell-owned terminal highlighting and placement.

These are not currently conflicting semantic owners, but they repeat pieces of the same display relation. A later frontend must not require yet another independent reconstruction of calendar meaning.

`FormatChoices` was introduced for an earlier selector interaction and remains after the terminal interaction moved to a direct matrix cursor. Its continued public value should be classified explicitly rather than retained automatically as historical topology.

### 2. The shell has become a small terminal UI runtime

`tools/home-calendar` now owns physical terminal concerns including:

- escape-sequence decoding;
- arrow and PageUp/PageDown input;
- SGR mouse protocol parsing;
- alternate-screen entry/exit;
- cursor visibility;
- terminal row/column placement;
- mouse hit testing;
- redraw sequencing;
- terminal-local selected-index state.

This does not move Household semantics into shell, but it is more than a passive process wrapper. Further interaction features should not be added by assuming this shell state machine is the permanent Home architecture.

### 3. Semantic coordinates and physical coordinates are different things

The semantic calendar can legitimately expose a matrix coordinate such as row 3 / column 1.

A frontend-specific coordinate such as terminal line 6 / column 5 or an `(x, y)` pixel rectangle belongs to the frontend.

The durable boundary is:

```text
semantic coordinate -> shared Home relation
physical coordinate -> frontend
```

This permits a terminal frontend, raylib frontend, or another renderer to consume the same calendar structure without sharing terminal geometry or pixel layout.

### 4. One visible frame can currently combine multiple process observations

The terminal adapter currently obtains calendar text, cursor-cell relations, and selected-date detail through separate BQN process calls.

Each individual call uses the canonical owners correctly, but source evidence could change between calls. A visible Home frame can therefore theoretically combine results from different Household observations.

This is not a writer-authority violation, but it matters for a screen whose purpose includes visually confirming what the canonical Household currently says.

A future shared Home boundary should make the observation lifetime explicit. When one frame combines semantic evidence, that evidence should preferably come from one admitted Household observation. Pure navigation arithmetic does not need to open a Household observation.

### 5. Command Hub Home and interactive Home are currently distinct interaction surfaces

The zero-command Command Hub displays Home as a read-only header above the top-level choices.

The cursor, mouse, month navigation, and selected-date inspection live in the direct TTY `tools/home-calendar` interaction.

This is not necessarily wrong, but it is now an architectural fact rather than an implementation detail. Future work should decide intentionally whether these remain two surfaces or whether the ordinary Home entrance becomes the interactive Home surface.

The decision must not be made accidentally by adding more shell behavior.

## Frontend-independent responsibility map

The desired direction is not a generic UI framework. It is a small shared vocabulary with multiple thin frontends.

Conceptually:

```text
canonical Household observation
        |
        v
Home semantic relation
        |
        +---- calendar/date evidence
        +---- selected-date evidence
        +---- marker meanings
        |
        v
Home interaction state + logical action
        |
        v
frontend-neutral frame/relation
        |
        +---- terminal frontend
        +---- native BQN presentation
        +---- raylib frontend
        +---- another future frontend
```

The concrete record/function names are intentionally undecided. The architecture should emerge from existing BQN data shapes rather than inventing an object-oriented UI abstraction in advance.

## Shared candidates

The following meanings are reasonable candidates for shared Home data or logical actions because they do not depend on a rendering technology:

- current focus date;
- selected date;
- month matrix coordinate;
- day/date/ordinal relation;
- marker meaning or marker code;
- Actual / Plan / Issue / Cycle evidence for a selected date;
- move one day backward/forward;
- move one week backward/forward where the interaction requires it;
- move one month backward/forward;
- inspect selected date;
- return/back.

A logical action is not a physical key binding. For example:

```text
terminal Right Arrow -> move-next-day
raylib KEY_RIGHT      -> move-next-day
```

The physical event changes by frontend; the Home action does not.

## Frontend-only concerns

The following should remain outside shared Home semantics:

- ANSI escape sequences;
- raw terminal key decoding;
- SGR mouse reports;
- terminal line/column offsets;
- pixel coordinates;
- font metrics;
- window dimensions;
- raylib key constants;
- raylib textures or drawing primitives;
- terminal alternate-screen handling;
- frontend-specific scrolling, clipping, and pane geometry.

A frontend may maintain the minimum ephemeral state required to present these concerns, but that state must not become a second definition of calendar dates, markers, lifecycle meaning, or selected-date evidence.

## Avoiding duplicate implementations

Adding another frontend should mean implementing only two translations:

```text
physical input -> shared logical Home action
shared Home frame/relation -> physical drawing
```

It should not require reimplementing:

- Gregorian navigation;
- marker collision semantics;
- Actual/Plan/Issue date association;
- selected-date detail selection;
- Cycle membership;
- amount semantics;
- canonical source observation.

This is the principal portability requirement.

## Avoiding the opposite trap

Frontend independence does not justify building a speculative universal UI toolkit in BQN.

Do not introduce a large `Widget`, `Component`, `Renderer`, or generic event framework merely because raylib or another UI might be used later.

The preferred sequence is:

1. preserve semantic relations already present in Home;
2. identify the smallest logical interaction vocabulary actually used by more than one frontend boundary;
3. expose data rather than terminal-formatted text where sharing removes duplication;
4. leave physical rendering and device input in each frontend;
5. generalize only after two real consumers demonstrate the same stable relation.

## #746 merge observation

#746 does not change BQN production semantics, but it extends the shell terminal runtime and therefore sits directly on this boundary.

Before merge, two local issues deserve resolution or an explicit decision:

1. a selected-detail BQN failure must not be collapsed into the same `130` path used for ordinary Home/back navigation; canonical diagnostics should remain observable;
2. the claim that calendar and complete selected-date detail remain visible in one frame must account for detail larger than the available terminal height, or the contract should be stated more narrowly.

Beyond those local issues, the larger question is whether more interaction behavior should continue to accumulate in the shell before a frontend-independent Home interaction boundary is identified.

Until that is decided, #746 is a useful stopping point rather than evidence that the current shell loop should become the permanent Home UI architecture.

## Documentation synchronization observation

Two existing design documents describe earlier future work that has now substantially landed:

- `docs/HOME_CALENDAR_INTERACTION_DESIGN-2026-08-12.md`;
- `docs/COMMAND_HUB_DRILLDOWN_DESIGN-2026-08-12.md`.

They remain useful as historical design rationale, but their future-tense implementation sections should not be treated as the current execution plan. Current repository state and this observation supersede those future-tense portions.

`TODO.md` currently marks `src/sections/home_calendar.bqn` and `src/application/home_calendar_cli.bqn` reviewed at their introduction points. Later Home work materially extended both surfaces. Those check marks should be interpreted as completed BQN-native owner reviews at those points in history, not as a claim that every later Home interaction change has been architecture-audited.

The broader TODO cross-cutting item for terminal selector/input duplication and UI change locality is the correct lane for the remaining frontend-boundary work. It should stay separate from the Phase 6 editor cursor.

## Current conclusion

No Home semantic rewrite is justified by this audit.

The current BQN semantic relations are a strong base for multiple frontends. The architecture risk is concentrated at the interaction/rendering boundary, especially if shell behavior keeps growing or if later frontends reconstruct Home meaning independently.

The durable rule is:

```text
one Home meaning
one logical interaction vocabulary where sharing is real
multiple thin physical frontends
```

Do not choose raylib now. Do not choose the current shell forever. Preserve enough frontend-independent data and actions that either choice remains cheap.
