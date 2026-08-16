# Household Surface Matrix design — 2026-08-16

## Decision

Replace the no-argument hierarchical Command Hub as the ordinary Household entrance with one Calendar-first surface.

The durable interaction coordinates are:

```text
Date × Domain × Operation × Scope
```

The ordinary visible frame is intentionally simpler than that full relation:

```text
Calendar / selected Date

             Observe   Add   Change   Resolve
Actual          •       •       ·        •
Plan            •       •       •        •
Envelope        •       •       ·        ·
Account         •       •       ·        ·
Issue           •       •       ·        •
Household       •       ·       ·        ·
```

`Scope` is projected after an Observe coordinate is chosen. It is not another permanent top-level hierarchy.

## Why the old hierarchy is retired

The historical Command Hub began with:

```text
Editor
Reports
Source & System
Exit
```

That arrangement made implementation categories visible before the Household subject a person actually had in mind. As the hierarchy grew, finding an operation required remembering which branch owned it. Interactive Home/Calendar also remained a distinct entrance, so the user had to carry more than one navigation map.

The Household surface makes stable position do the memory work:

- Plan is always the Plan row;
- Observe is always the Observe column;
- Resolve is always the Resolve column;
- the selected Calendar date is the active time coordinate.

Nested interaction is still allowed after a surface cell is chosen. It is not used for feature discovery.

## Operation vocabulary

The columns are deliberately not `View / Add / Edit / Relate`.

`Actual` demonstrates why. Canonical Actual evidence is not edited in place; correction is a compensating reversal. Therefore the shared verbs are:

- `Observe`: inspect admitted Household meaning;
- `Add`: add new canonical evidence through an established writer;
- `Change`: change mutable lifecycle intent where the domain permits it;
- `Resolve`: perform the domain-specific closing/corrective transition.

Examples:

```text
Actual × Resolve = compensating reversal
Plan × Resolve   = finish / actualize / replenish
Issue × Resolve  = close
```

Empty cells are meaningful. The matrix must not invent generic CRUD operations merely to make every row rectangular.

## Report placement

The twelve retained reports remain owned by `src/report/catalog.bqn`.

The catalog publishes two navigation coordinates:

```text
surface_domain
surface_scope
```

This is presentation/navigation metadata, not accounting semantics.

The first placement is:

| report | surface domain | scope |
|---|---|---|
| Envelope & Backing | Envelope | cycle |
| Account Balances | Account | current |
| Balance Sheet | Household | current |
| Profit and Loss | Household | cycle |
| Recent Journal | Actual | recent |
| Planned Payments | Plan | future |
| Current-cycle Accounts | Account | cycle |
| Cycle Comparison | Household | cycle |
| Monthly Accounts | Account | month |
| Daily Flow | Account | day |
| Daily Target | Household | day |
| Issues | Issue | current |

The surface projects these coordinates from the report catalog. It does not create a second list of report keys.

## Non-report leaves

Existing direct routes remain the implementation owners beneath the surface.

Conceptually:

```text
Actual × Observe
  canonical Journal history
  catalog reports whose surface_domain = actual

Actual × Add
  Expense
  Income
  Transfer / move
  Multi-posting transaction

Actual × Resolve
  Reverse with a compensating transaction

Plan × Observe
  open / overdue / upcoming Plan evidence
  related evidence
  catalog reports whose surface_domain = plan
Plan × Add      -> Add Plan
Plan × Change   -> Edit Plan
Plan × Resolve  -> Finish / actualize / replenish Plan

Envelope × Observe
  catalog reports whose surface_domain = envelope
Envelope × Add
  Budget movement

Account × Observe
  canonical Account inventory
  catalog reports whose surface_domain = account
Account × Add
  Add Account

Issue × Observe
  open Issue inventory
  catalog reports whose surface_domain = issue
Issue × Add     -> Add Issue
Issue × Resolve -> Close Issue

Household × Observe
  catalog reports whose surface_domain = household
```

The direct CLI routes remain stable. The surface is a navigation projection over established owners, not a replacement writer/report implementation.

## Calendar ownership

The selected date remains the durable logical Home coordinate already established by Home navigation work.

Calendar meaning stays BQN-owned:

```text
selected date + logical move -> next selected date
```

Physical terminal index, key packets, mouse coordinates, and drawing geometry remain frontend concerns.

At cutover, the selected Date is carried into date-bearing writer leaves as UI context. This prevents a user from selecting one date in the Calendar and then being asked to choose the same date again inside a writer. The context does not become canonical authority: writer and admission owners still validate and publish the resulting explicit date.

Date consumption is domain-specific rather than mechanically attached to every cell:

- Actual Add and Resolve consume the selected date;
- Plan Add, Change observation, and Resolve consume the selected date where applicable;
- Envelope movement consumes the selected date;
- Issue Add and close consume the selected date when the source schema can represent it;
- Account Add is atemporal and does not consume a Calendar date.

Standalone writer entry remains unchanged when no Household selected-date context exists.

## gum, fzf, and report paging

Neither gum nor fzf owns the primary Household surface.

The matrix is spatial. Flattening it into a one-dimensional fuzzy selector destroys useful positional meaning.

Current architecture:

```text
Calendar + matrix = primary UI
fzf              = optional search / high-cardinality target accelerator
gum              = no required primary-surface role
plain input       = always sufficient
less -S           = wide report reading / horizontal scrolling
```

fzf may remain useful when selecting among many Plans, Accounts, transactions, or search results. It must not define the information architecture.

Wide report navigation is a separate presentation capability. `tools/main-ui.sh` uses `less -SRFX` in an interactive terminal when `less` is available. The `-S` option keeps long lines unwrapped so the user can move horizontally. Removing gum therefore does not imply losing horizontal report scrolling.

If no independent gum use remains after the surface cutover, gum should be removed rather than retained as a compatibility shell. That decision should come from an actual remaining-use audit, not from preserving the historical selector stack.

## Source & System

Source and maintenance operations are intentionally outside the Domain × Operation matrix.

They are not ordinary Household facts or lifecycle actions. Keep them at the edge of the surface behind a stable shortcut such as:

```text
s  Source & System
```

This includes canonical source opening, Household check, provenance inspection, diagnosis, export, compact query, and repository development checks.

## Frontend boundary

Do not build a generic widget framework.

The durable boundary remains:

```text
physical input
      |
      v
logical Household action
      |
      v
Date × Domain × Operation × Scope
      |
      v
existing semantic / writer owner
      |
      v
thin physical frontend
```

A future terminal implementation, native BQN presentation, or raylib frontend should consume the same logical coordinates without reimplementing accounting, date arithmetic, report placement, or lifecycle meaning.

## Cutover status

The cutover sequence is now represented directly in repository owners rather than left as a future migration plan:

1. **complete** — pure Domain × Operation surface relation is published;
2. **complete** — `surface_domain / surface_scope` are catalog-owned and qualified;
3. **complete** — terminal surface consumes Home Calendar navigation and direct action routes;
4. **complete in #780** — no-command `bl` enters the Household surface directly;
5. **preserved** — explicit direct CLI commands remain stable;
6. **complete in #780** — the old `Editor / Reports` discovery hierarchy is removed from `tools/bl` rather than retained as duplicate navigation authority;
7. **next audit** — re-evaluate actual remaining fzf/gum use and remove only dependencies whose independent role has disappeared.

## Non-goals

This design does not change:

- canonical Household source authority;
- Actual, Plan, Envelope, Account, or Issue accounting meaning;
- exact arithmetic;
- identity or provenance;
- writer publication safety;
- historical routing;
- report calculation semantics;
- direct CLI compatibility.

The change is a new map over the same Household, not a new Household.
