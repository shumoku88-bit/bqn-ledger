# Home navigation boundary observation - 2026-08-13

## Follow-up: #757 implementation decision

The observation below records the pre-implementation boundary. PR #757 resolves its first open semantic decision and implements the smallest shared boundary it proposed.

Current Home navigation is now:

- `src/application/home_navigation.bqn` owns the pure admitted move vocabulary and `selected date + move -> next selected date` relation;
- previous/next day use continuous `AddDays +/-1`;
- previous/next week deliberately use continuous `AddDays +/-7`, including month and year boundaries;
- previous/next month retain the existing `AddMonths +/-1` clipping behavior;
- no preferred day-of-month state is introduced, so `2026-01-31 -> 2026-02-28 -> 2026-03-28` remains the date-only path;
- `tools/home-calendar` treats `selected_date` as the logical coordinate and `selected_index` only as a cached projection into the current `CellRelation` for rendering;
- physical keys, SGR mouse packets, and terminal geometry remain frontend-owned;
- pure movement returns from `home_calendar_cli.bqn` before canonical Household/report/Home presentation owners are imported or observed.

The sections below that describe week movement as month-local or undecided are historical observation evidence for why this change was made. The unresolved month-clipping question remains intentionally unresolved beyond preserving the existing date-only behavior.

## Scope

This note observes the Home calendar after the frontend-neutral `CellRelation` work.
It does not implement a new state machine, event framework, renderer, or navigation API.

The question is narrower:

> Which part of Home movement is durable logical interaction meaning, and which part is only physical terminal input mapping?

This follows `HOME_UI_BOUNDARY_OBSERVATION-2026-08-13.md` and keeps the same rule:

```text
one Home meaning
one logical interaction vocabulary where sharing is real
multiple thin physical frontends
```

## Current ownership

The current stack already separates several concerns well.

```text
Gregorian date coordinate
        |
        v
src/ledger/date_ordinal.bqn
        |
        +-- AddDays
        +-- AddMonths
        |
        v
src/application/home_calendar_cli.bqn
        |
        +-- day-prev / day-next
        +-- month-prev / month-next
        +-- CellRelation
        |
        v
tools/home-calendar
```

`date_ordinal.bqn` owns exact Gregorian arithmetic. `home_calendar_cli.bqn` exposes adjacent day/month focus without opening a Household observation. `CellRelation` owns semantic date, row, column, and marker coordinates for a visible month.

The terminal shell still owns the active selection and the policy that maps physical keys to changes in that selection.

## Current movement relation

The current terminal behavior is not one uniform navigation rule.

| Physical input | Current logical effect | Month boundary |
|---|---|---|
| Left / `h` | previous date | crosses continuously |
| Right / `l` | next date | crosses continuously |
| Up / `k` | selected month index `-7` | stops at visible-month edge |
| Down / `j` | selected month index `+7` | stops at visible-month edge |
| PageUp / `[` | previous calendar month | crosses using `AddMonths` |
| PageDown / `]` | next calendar month | crosses using `AddMonths` |
| mouse click | select cell hit by terminal coordinates | only visible cells |

Horizontal movement has already been deliberately characterized as a continuous date walk across month and year boundaries.

Vertical movement is different. It is implemented only as arithmetic on the visible month's `selected_index`. It therefore stops when `index +/- 7` would leave the current month's cell vector.

That difference is not imposed by terminals. A raylib frontend, native BQN frontend, or another terminal frontend would face the same question. It is Home interaction policy that currently happens to live in shell.

## Logical state: selected date, not selected index

`selected_index` is useful for drawing a cursor in the current `CellRelation`, but it is a month-local projection.

A durable logical state is closer to:

```text
selected_date
```

The visible month and selected cell index can be derived from that date plus the BQN-owned month relation.

This gives a cleaner direction:

```text
selected date + logical action
              |
              v
       next selected date
              |
              v
      visible CellRelation
              |
              v
       frontend projection
```

The terminal can still keep a cached index for rendering efficiency. The index should not become the semantic owner of movement.

## Candidate logical actions

The smallest shared vocabulary worth considering is Home-specific, not generic UI infrastructure.

Conceptually:

```text
MovePreviousDay
MoveNextDay
MovePreviousWeek
MoveNextWeek
MovePreviousMonth
MoveNextMonth
FocusDate <date>
Inspect
Back
```

Physical frontends can map into that vocabulary independently:

```text
terminal Left Arrow  -> MovePreviousDay
terminal k           -> MovePreviousWeek
raylib KEY_RIGHT     -> MoveNextDay
mouse cell release   -> FocusDate <date>
```

No universal `Event`, `Widget`, `Component`, or renderer abstraction is required.

## Candidate pure BQN boundary

A small Home-specific pure function is the strongest current candidate:

```text
selected_date + HomeMove -> next_selected_date
```

Day movement can reuse `AddDays +/-1`.
Month movement can reuse `AddMonths +/-1`.
Week movement could reuse `AddDays +/-7` if continuous week navigation is chosen.

This can remain independent of canonical Household I/O. Movement does not need Actual, Plan, Issue, Cycle, or report observations.

That matters for observation lifetime: changing focus should not require opening source data merely to calculate the next date.

## Open semantic decision 1: should week movement cross months?

The current shell says no because it moves a month-local index.

A date-centered interpretation naturally says yes:

```text
MovePreviousWeek = AddDays -7
MoveNextWeek     = AddDays +7
```

That would make vertical movement continuous in the same sense as horizontal movement.

This looks more frontend-neutral, but it is a behavior change. It should be chosen deliberately and characterized before implementation rather than smuggled in as a refactor.

No existing Home characterization currently requires vertical movement to stop at a month edge.

## Open semantic decision 2: repeated clipped month movement

`AddMonths` preserves the day of month when possible and clips when the target month is shorter.

For a single move this is explicit and already characterized:

```text
2026-01-31 + 1 month -> 2026-02-28
```

Repeated movement has a further interaction question:

```text
2026-01-31
  -> 2026-02-28
  -> 2026-03-28
```

With only `selected_date` as state, the clipped date becomes the next operation's input. If Home should instead remember an intended day such as 31 and return to March 31, that would require additional interaction state such as a preferred day-of-month.

There is not yet evidence that this extra state is needed. Do not introduce it speculatively. The current path-dependent clipping should simply be recognized as part of the decision before a shared month-move owner is implemented.

## Why not put neighbors into CellRelation?

Another possible design would add fields such as:

```text
left_date
right_date
up_date
down_date
```

to every calendar cell.

This is less attractive at the current boundary.

`CellRelation` answers what each visible calendar cell *is*: date, day, row, column, marker. Neighbor targets answer what an interaction *does*. Mixing those would make a presentation relation carry navigation policy, and month movement would still require separate semantics.

Keep these meanings separate unless a real consumer demonstrates that a neighbor relation is the more natural BQN representation.

## Mouse boundary

Mouse support already illustrates the split well.

Terminal line/column geometry and SGR mouse packets are physical frontend concerns. Once a hit resolves to a semantic Home cell, the durable meaning is simply:

```text
FocusDate <cell.date>
```

A future pixel frontend should not need to copy calendar arithmetic or marker semantics. It only needs its own physical coordinate-to-cell hit test.

## Current conclusion

The Home boundary after `CellRelation` is healthy enough to stop and observe.

The next coherent implementation, if chosen, should be smaller than a UI framework:

1. treat selected date as the durable Home navigation coordinate;
2. define a Home-specific pure logical move boundary in BQN;
3. keep key names, escape sequences, SGR mouse packets, and pixel coordinates in frontends;
4. decide continuous `+/-7 day` week movement explicitly before changing current behavior;
5. do not invent preferred-day month state until repeated month navigation demonstrates the need;
6. keep `#746` selected-date detail-pane repair separate from this navigation work.

The target remains:

```text
physical input
      |
      v
logical Home action
      |
      v
selected date
      |
      v
Home semantic relations
      |
      v
thin frontend
```
