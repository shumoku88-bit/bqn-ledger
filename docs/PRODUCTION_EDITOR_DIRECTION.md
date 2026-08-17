# Production Editor Direction

Status: current policy / architecture direction
Owner: editor / frontend boundary
Canonical: yes
Exit: revise if production write-path or logical frontend ownership changes.

## Core decision

The durable write path is:

```text
frontend interaction
  -> existing direct command
  -> tools/edit
  -> dedicated writer / src_edit semantic candidate
  -> shell safe-write publication
  -> mandatory post-write admission
```

BQN owns admitted meaning and candidate validation. Shell owns bounded byte movement and physical terminal interaction. Frontends do not parse canonical sources or acquire writer authority.

## Current Household frontends

There is no separate `tui/` implementation owner.

The current frontend portfolio is intentionally plural over shared logical coordinates:

### `tools/bl`

- canonical Household entrypoint and direct-command router;
- no command enters the Calendar-first Household surface;
- explicit commands remain stable for scripts, direct use, and frontend delegation;
- does not own accounting or publication meaning.

### `tools/household-surface`

- primary spatial terminal frontend;
- displays Calendar + Domain × Operation;
- consumes `HouseholdSurface` metadata and selected-date context;
- physical key reading, alternate-screen drawing, and terminal geometry stay shell-owned;
- must not reconstruct accounting/report semantics.

### `tools/household-hub-gum`

- optional flat searchable Command Palette;
- consumes the same `HouseholdSurface.Actions` relation as the spatial frontend;
- Calendar, reports, logical actions, and Source & System utilities are sibling palette destinations rather than a second taxonomy;
- gum is a physical delivery choice, not semantic authority.

### `tools/household-action`

- shared logical Household action dispatcher;
- validates `ACTION_KEY` against `HouseholdSurface.Actions` before routing;
- maps logical command/report actions to existing direct owners;
- owns no canonical source, accounting, or write semantics.

A physical frontend should delegate through this action boundary rather than maintain a second logical-action routing catalog.

## Writer interaction leaves

### `tools/add-ui.sh`

- interaction helper for existing writer leaves;
- explicit modes are used by Household/direct routing;
- standalone no-mode selection remains a writer-shortcut menu, not the primary Household information architecture;
- account/Plan/Issue candidate data comes from BQN/editor exports;
- calls `tools/edit` and does not own Journal/TSV write semantics.

### `tools/plan-finish-replenish-ui.sh`

- optional orchestration of existing `plan finish` and `plan add` commands;
- relation semantics remain BQN-owned;
- not a new write primitive.

## Editor owners

### `tools/edit`

Stable user-facing editor command surface. Delegates to `tools/edit-bqn`.

### `tools/edit-bqn`

Active BQN + shell editor dispatcher. Applies admitted machine-readable append/replace protocols and stays free of ad-hoc accounting policy.

### `src_edit/`

Owns command-level validation, semantic candidate construction, exact source-coordinate evidence where required, and post-write validation leaves. It does not own report/UI architecture.

### `tools/lib/safe-write.sh`

Owns backup/temp/stale guards/atomic replacement/post-check mechanics. It must not own ledger meaning.

## Selector adapters

`tools/lib/ui-choice.sh` exposes one opaque-line selection boundary. `fzf`, `gum`, and plain numbered input are interchangeable physical backends selected through `tools/lib/ui-preferences.sh`.

Current roles are distinct:

```text
Calendar-first Household surface
  raw-terminal spatial navigation

gum Command Palette
  optional flat searchable frontend

fzf / gum / plain selector
  nested or high-cardinality opaque-line choice
```

Neither fzf nor gum defines Household information architecture. Their presence is justified only by a current physical interaction role.

Finished reports use `tools/main-ui.sh`; interactive `less -SRFX` remains the wide-report reader independently of selector backend.

## Writer classes

Append-only:

- Account Add
- native Journal Add / Multi Add
- native Entitlement StockOrigin / Transfer
- Plan Add
- Issue Add
- Travel friend/exchange source events

Derived append:

- Plan Finish -> Actual completion evidence
- Journal Reverse -> compensating Actual transaction

Exact replace:

- Plan Edit
- Issue Close where the Issue physical shape permits it

Interactive orchestration is not a new writer class. It composes the established primitives above.

## Safety model

1. Observe canonical/admitted source state through the owning BQN/application boundary.
2. Build and validate the intended candidate before publication.
3. Publish only through the bounded shell safe-write owner.
4. Re-admit/validate after write where the command contract requires it.
5. Keep corrections and provenance visible rather than hiding them behind silent mutation.

## UI replaceability

A future terminal implementation, native BQN presentation, raylib frontend, HTML client, or conversational client should consume current logical/action surfaces and direct command protocols rather than reproduce source parsing, accounting, report placement, date arithmetic, or writer logic.

Frontend replacement therefore should usually change only:

```text
physical input / drawing / choice
  + logical-action adapter
```

not:

```text
canonical sources / accounting / writer authority
```

## Acceptance criteria

- no-command `tools/bl` remains one Calendar-first Household entrance;
- direct commands remain stable;
- multiple physical frontends may consume the same logical action relation;
- logical actions do not gain duplicate routing owners without an explicit reason;
- selectors remain opaque-line adapters rather than semantic parsers;
- canonical source writes remain BQN-centered and shell-safe;
- `tools/check.sh` passes.
