# Daily Trend Explicit Empty Plan Identity Semantics

Status: current observation map
Date: 2026-07-07
Owner: report / semantics map only

## Purpose

Map the repo-wide meaning of explicit empty `plan_id=` after PR #107 proved the state is reachable and materially affects Daily Trend reserve.

This document is a **meaning map**, not a product decision.
It does **not** authorize runtime repair, validation-policy change, or identity redesign.

## Scope

This map spans the layers that currently mention `plan_id` or consume the extracted identity:

- report-side plan/journal overlap and reserve logic
- editor-side plan list / plan add / plan finish behavior
- shared completion / matching behavior
- Daily Trend reserve edge behavior
- diagnostics that compare plan and journal identities

It does **not** change:

- Daily Trend runtime
- `PlanId` implementation
- editor behavior
- source TSV schemas
- fixtures
- Outlook
- K
- shared temporal kernel

## Core finding

Current layers do **not** assign one consistent meaning to explicit empty identity.

The same textual form can be observed as:

- report-side empty identity
- editor-side missing identity
- UI `MISSING-ID`
- reserved-but-empty candidate in Daily Trend

That is the inconsistency this map records.

## Identity-state taxonomy

The relevant states are:

1. metadata absent
2. explicit empty metadata (`plan_id=`)
3. explicit non-empty metadata
4. malformed / invalid non-empty metadata

Those four states are not handled uniformly across layers.

## Current evidence summary

Observed distinctions include:

- **report compatibility identity**
  - metadata absence -> five-field fallback
  - explicit `plan_id=` -> empty identity
- **editor extraction**
  - absence and explicit empty both surface as empty extracted identity
- **plan list**
  - empty extracted identity routes through the `MISSING-ID` status path
- **plan add**
  - generates or validates a non-empty plan ID
  - rejects `plan_id=...` in generic metadata input
- **plan finish**
  - refuses missing identity
  - requires a non-empty, valid `plan_id`
- **shared completion / actual matching**
  - consumes exact identity equality
- **Daily Trend**
  - explicit empty identity reaches the L-sensitive reserve branch characterized in PR #107

## Current layer map

| Layer | Current behavior | Current meaning |
|---|---|---|
| `src_next/plan_journal_overlap.bqn` / `PlanId` | metadata `plan_id=` overrides five-field fallback and can yield `""` | report-side identity can be explicitly empty |
| `src_edit/plan_id.bqn` / `ExtractPlanId` | absence and explicit empty both extract as `""` | editor-side extraction collapses both into empty identity |
| `src_edit/plan_list_cmd.bqn` | empty extracted identity is rendered via `MISSING-ID` path | selection UI treats it as missing identity |
| `src_edit/plan_add_cmd.bqn` | plan ID must be non-empty and metadata `plan_id=` is rejected | write path does not accept explicit empty plan_id metadata |
| `src_edit/plan_finish_cmd.bqn` | missing or invalid plan_id is refused | completion requires usable identity |
| `src_next/plan_journal_overlap.bqn` diagnostics | exact identity equality is used for overlap counting | empty identity can participate in exact equality diagnostics |
| `src_next/daily_trend.bqn` | empty-id branch compares plan date with local `last_act_dn` | reserve can depend on report-local frontier `L` |

## State-by-state map

### 1. Metadata absent

Observed shape:

- no `plan_id=` metadata token exists
- report-side `PlanId` uses the five-field fallback identity
- editor-side `ExtractPlanId` returns empty identity because there is no metadata token to extract

Implications:

- report-side compatibility uses the row’s visible five-field identity
- editor-side lifecycle views this as missing identity
- plan list renders it through `MISSING-ID`
- plan finish refuses it
- Daily Trend ordinary reserve does **not** use this state as evidence for the empty-id branch

### 2. Explicit empty metadata (`plan_id=`)

Observed shape:

- metadata token exists
- extracted value is empty string
- report-side fallback is **suppressed** because metadata exists and is selected first

Implications:

- report-side `PlanId` returns `""`
- editor-side `ExtractPlanId` also returns `""`
- plan list routes it through `MISSING-ID`
- plan add rejects generic metadata input containing `plan_id=...`
- plan finish refuses missing identity
- Daily Trend reserve can reach the empty-id branch and consume local `L`

This is the reachable edge characterized in PR #107.

### 3. Explicit non-empty metadata

Observed shape:

- metadata token exists
- extracted identity is non-empty
- if syntactically valid, editor tools treat it as usable identity
- if syntactically invalid, editor tools classify it as invalid

Implications:

- report-side extraction returns the explicit identity string
- shared matching and overlap diagnostics compare exact equality
- plan finish uses the identity when appending to journal
- Daily Trend ordinary reserve uses identity-sensitive evidence, not the empty-id branch

### 4. Malformed / invalid non-empty metadata

Observed shape:

- metadata token exists
- extracted identity is non-empty
- format validation fails in editor-facing checks

Implications:

- `plan list` can label it `[INVALID-ID]`
- `plan finish` refuses it
- `plan add` rejects it when explicitly supplied
- report-side extraction may still return the string as an identity value
- overlap diagnostics may still count exact string equality if it is present on both sides

This is a key asymmetry:

- editor layers classify invalidity
- report-side extraction is more permissive and only observes the string

## Report-side fallback semantics

The report-side extractor in `src_next/plan_journal_overlap.bqn` is intentionally different from the editor-side extractor.

Current behavior:

- if metadata is absent, use five-field fallback
- if metadata contains `plan_id=`, select that metadata token first
- if the value after `plan_id=` is empty, the extracted identity is empty

That means:

- ordinary 5-field plans are **not** evidence for the empty-id reserve edge
- explicit empty metadata is the only observed path to the empty-id branch
- this branch exists only because metadata presence suppresses fallback

This is the exact distinction PR #107 tested.

## Editor-side collapse of empty and missing

The editor-side extractor in `src_edit/plan_id.bqn` is intentionally narrower for lifecycle use.

Current behavior:

- absence and explicit empty both extract as `""`
- `plan list` uses that extracted value to decide `MISSING-ID`
- `plan finish` requires a usable non-empty `plan_id`
- `plan add` never writes an explicit empty identity through the generic metadata path

So the editor surface collapses two states that the report surface keeps distinct:

- metadata absent
- explicit empty metadata

That collapse is part of the current repo-wide inconsistency this document records.

## Plan add / list / finish behavior

### plan add

Current behavior:

- generates a non-empty plan ID when none is supplied
- validates an explicitly supplied ID
- rejects generic metadata containing `plan_id=...`

Meaning today:

- empty identity is not a write-path target
- explicit empty metadata is not accepted by the normal add path

### plan list

Current behavior:

- reads `plan.tsv`
- reads `journal.tsv` to determine completed IDs
- empty extracted identity is shown via `MISSING-ID`
- malformed non-empty IDs are shown as `INVALID-ID`
- closed rows are shown only with `--all`

Meaning today:

- missing and explicit empty are not distinguished in the list UX
- list is a lifecycle view, not a report-side compatibility view

### plan finish

Current behavior:

- refuses missing identity
- refuses invalid identity
- appends journal rows with the plan identity preserved when finishing

Meaning today:

- plan finish is not a path for explicit empty identity
- completion requires usable identity
- empty identity is excluded from the write path

## Shared completion / actual matching implications

There are two related but distinct uses of extracted identities:

1. **Completion detection**
   - `completedIDsAll ← plan_id.ExtractPlanId¨ journalLines`
   - empty extracted identities are filtered out before downstream use

2. **Identity equality matching**
   - exact equality is used when comparing plan and journal identities
   - overlap diagnostics count exact matches / ambiguous matches / unmatched plans

Implications:

- empty identity is not a completion key in the editor lifecycle path
- exact equality remains the comparison rule where an identity is present
- report-side exact matching can still observe empty string equality if a caller supplies it

This is a structural reason the repo can observe empty identity in report calculations while refusing to treat it as a normal write-path identity.

## Overlap diagnostic implications

`src_next/plan_journal_overlap.bqn` owns read-only diagnostics for plan/journal identity overlap.

Current behavior:

- `PlanId` extracts report-side identity, including explicit empty
- plan/journal rows are partitioned by cycle membership first
- strong overlap counts exact identity equality on the extracted IDs
- ambiguous overlap counts exact match presence without uniqueness
- unmatched counts plans whose extracted ID is not found in journal IDs

Implications:

- explicit empty identity is visible to overlap diagnostics
- the diagnostic layer does not itself decide whether empty is valid
- empty identity can exist as a comparable string in diagnostics even if editor paths reject or collapse it

This is one of the reasons the map must keep report semantics separate from editor semantics.

## Daily Trend empty-identity reserve branch

Current Daily Trend reserve logic has a separate branch for empty plan identity.

Relevant current structure:

- `plan_pids` = identities extracted from plan rows
- `j_pids_all` = identities extracted from journal rows visible through row coordinate `D`
- `j_pids_clean` = non-empty journal identities only
- `last_act_dn` = last journal date `<= D`, falling back to local `as_of_dn`
- `IsOpen` branches on whether `pid` is empty

Current branch shape:

```text
if pid is non-empty:
  open iff pid not found in j_pids_clean

if pid is empty:
  open iff plan.date >= last_act_dn
```

That means the explicit empty branch consumes local frontier `L` via `last_act_dn`.

PR #107 confirmed this branch is reachable.

## PR #107 characterization evidence

The test-only characterization used the following fixture pair:

- before: `fixtures/src-next-daily-trend-empty-id-reserve-before`
- after: `fixtures/src-next-daily-trend-empty-id-reserve-after`

Held fixed:

- cycle `C = [2026-01-01, 2026-01-11)`
- historical row `D = 2026-01-02`
- accounts
- plan row
- plan amount `300`
- plan date `2026-01-05`
- explicit empty plan identity (`plan_id=`)
- accepted actual projection coordinates
- accepted actual state at `D`
- final row set/order

Moved only:

- raw journal frontier `L`

### Fixture contents

Plan row (both fixtures):

```text
2026-01-05  future_fixed  assets:cash  expenses:fixed  300  plan_id=
```

Before journal rows:

```text
2026-01-02  initial           income:test      assets:cash   1000
2026-01-03  unrelated_before   assets:other     expenses:other 1
```

After journal rows:

```text
2026-01-02  initial           income:test      assets:cash   1000
2026-01-03  unrelated_before   assets:other     expenses:other 1
2026-01-06  unknown_frontier   unknown:ghost    expenses:other 1
```

### Empty-identity proof

The characterization asserted:

```text
overlap.PlanId(plan_line) = ""
```

That proves the plan reached empty identity semantics rather than merely matching the text of the metadata.

### Observed result

Before:

- `vm.as_of = 2026-01-03`
- reserve at `D = 2026-01-02` was `300`

After:

- `vm.as_of = 2026-01-06`
- reserve at `D = 2026-01-02` was `0`

Held-fixed invariants also remained equal:

- accepted actual coordinates: `⟨2026-01-02, 2026-01-03⟩`
- final row set/order: `⟨2026-01-02, 2026-01-03⟩`
- liquid at `D`: `1000`
- days_left at `D`: `9`

Mechanical downstream consequence:

- fund / daily / delta moved because reserve moved

The semantic target remained reserve, not downstream fields.

### What this proves

Only this:

- the explicitly empty-identity reserve edge is reachable
- that edge currently consumes local `L`
- row membership and coordinate-local actual state can remain fixed while reserve changes

It does **not** prove:

- the behavior is wrong
- explicit empty `plan_id=` is valid product input
- empty identity should use `D`
- empty identity should use `O_row`
- the branch should be deleted
- ordinary reserve depends directly on `L`

## Candidate semantics comparison

The current repo leaves several candidate meanings unresolved.

### A. Intentional empty identity

- explicit `plan_id=` is a valid semantic token
- report-side extraction may preserve it as empty
- lifecycle consumers would need an explicit policy

### B. Absent identity falls back, empty is a special missing state

- metadata absence uses five-field fallback
- explicit empty is a distinct state and must be handled specially
- this is the current report-side extractor shape, but not a product decision

### C. Invalid input

- explicit empty metadata should fail closed
- this would align lifecycle tools more tightly
- not yet authorized here

### D. Separate identity-less regime

- explicit empty identity would be its own regime
- report-side and editor-side semantics would need a shared contract
- also not yet authorized here

This document records the comparison boundary only.
It does **not** select one of A/B/C/D.

## Decision boundary

This document does not decide whether explicit empty identity should:

- remain valid
- fall back to five-field identity
- become invalid input
- form a separate semantic regime

## Non-goals

This document does not:

- repair runtime behavior
- redesign `PlanId`
- delete the empty branch
- broaden ordinary reserve semantics
- authorize `L -> D`
- authorize `L -> ctx.as_of`
- change product meaning
- change validation policy
- change source TSV
- change fixtures
- change tests
- change docs outside this file

## Invariant reminders

Preserve these distinctions:

```text
S = source snapshot
D = row coordinate
O_row = D
C = cycle boundary
L = local record frontier
K = unavailable / not claimed
```

And preserve:

```text
L != O_row
L != K
O_row != K
historical coordinate != historical knowledge state
```

## Why this map exists at all

The repo now has three separate observations:

1. explicit empty identity is reachable
2. the empty-id reserve branch is L-sensitive
3. the repo does not yet agree on what explicit empty identity *means*

That is why a product decision is now needed **before** any runtime repair.

## Related evidence and contracts

- `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
- `docs/PLAN_ID_LIFECYCLE.md`
- `docs/UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`
- PR #107 characterization: empty-id reserve frontier
- PR #105 runtime row-membership alignment

## Next finite question

Choose the product meaning of explicit empty plan identity before authorizing any runtime repair.
