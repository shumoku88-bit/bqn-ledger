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

## Why the old hierarchy is being retired

The implemented Command Hub currently begins with:

```text
Editor
Reports
Source & System
Exit
```

That arrangement makes implementation categories visible before the Household subject a person actually has in mind. As the hierarchy grew, finding an operation required remembering which branch owned it. Interactive Home/Calendar also remained a distinct entrance, so the user had to carry more than one navigation map.

The new surface makes stable position do the memory work:

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

The catalog now publishes two navigation coordinates:

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

The surface must project these coordinates from the report catalog. It must not create a second list of report keys.

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

The direct CLI routes remain stable. The surface is an additional navigation projection over established owners, not a replacement writer/report implementation.

## Calendar ownership

The selected date remains the durable logical Home coordinate already established by Home navigation work.

Calendar meaning stays BQN-owned:

```text
selected date + logical move -> next selected date
```

Physical terminal index, key packets, mouse coordinates, and drawing geometry remain frontend concerns.

The desired ordinary frame is one Household observation surface, not a Command Hub header plus an unrelated selector underneath it.

## gum and fzf

Neither gum nor fzf owns the primary Household surface.

The matrix is spatial. Flattening it into a one-dimensional fuzzy selector destroys useful positional meaning.

Target architecture:

```text
Calendar + matrix = primary UI
fzf              = optional search / high-cardinality target accelerator
gum              = no required role
plain input       = always sufficient
```

fzf may remain useful when selecting among many Plans, Accounts, transactions, or search results. It must not define the information architecture.

If no independent gum use remains after the surface cutover, gum should be removed rather than retained as a compatibility shell.

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

## Cutover sequence

1. Publish the pure Domain × Operation surface relation.
2. Add `surface_domain / surface_scope` to the existing report catalog and qualify the placement.
3. Build one terminal surface over the existing Home Calendar relation and existing direct command routes.
4. Make the no-argument `bl` entrance use that surface.
5. Keep direct CLI commands stable.
6. Retire the old `Editor / Reports` discovery hierarchy after parity is characterized.
7. Re-evaluate fzf/gum usage from what actually remains, not from historical dependency.

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
