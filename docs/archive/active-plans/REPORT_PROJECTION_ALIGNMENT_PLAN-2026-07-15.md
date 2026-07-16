# Report Projection Alignment Plan

Status: active plan
Owner: report
Canonical: yes; current implementation authorization is `TODO.md`, and current runtime behavior remains owned by `src_next/*.bqn`, `docs/REPORT_CONTRACTS.md`, and executable checks
Exit: archive as completed after the named report slices have independently passed their contract, fixture, and compatibility gates; archive as superseded if a narrower current plan replaces this sequence

## Purpose

Bring report calculations that can be derived from admitted accounting data onto the existing BQN data path without turning the Canonical Daily Cube into a catch-all source store.

```text
source TSV
  -> checked Posting IR
  -> Cube / TBDS for numeric accounting views
  -> report-specific evidence view for identity, memo, completion, and metadata
  -> report
```

The purpose is not "make every report a matrix." It is to stop reports from independently reparsing amount-bearing source rows when the checked Posting IR, Cube, or TBDS already owns the same numeric meaning.

## Current boundaries to preserve

- The Canonical Daily Cube remains `Day × Account × Layer`. Do not add memo, plan ID, category, or arbitrary metadata axes.
- TBDS remains the period/account/layer accounting-state view. Balance reports use `closing`; flow reports use `movement`.
- Posting IR remains the only normalized owner of admitted posting amounts, account resolution, layer mapping, and source identity.
- `plan_rows` / plan-journal evidence remains appropriate for plan ID, completion, due status, memo, and other source-row identity that the Cube intentionally aggregates away.
- `issues`, `recent`, and `planned` are not candidates for forced Cube conversion merely because they are report sections.
- `O` (observation), `D` (event coordinate), `L` (record frontier), and cycle windows retain the distinctions in `docs/TIME_AS_AXIS.md`. This plan does not introduce a report-wide `--as-of` or historical-knowledge replay.

## Admission rule

A report numeric value must have one of these owners:

| Value kind | Owner |
|---|---|
| account balance or period income/expense | TBDS over checked ledger-wide Posting IR |
| in-window daily actual/budget/plan aggregate | Cube or a re-materialized Cube from checked Posting IR |
| aggregate needing a non-cycle period | TBDS or a locally re-based Cube from the same checked Posting IR |
| plan completion, `plan_id`, due status, memo, source row selection | plan evidence / Posting IR identity |

A source-evidence helper may read source text to retain identity or metadata, but it must not independently parse an amount into a report total when the corresponding admitted posting amount exists. Invalid, unsupported-currency, or rejected rows must not become a local `0` that appears as a valid report value.

## Candidate map

### 1. `actual-comparison` — completed

Current amount ownership is checked ledger-wide Posting IR through local TBDS period views. Cycle-anchor identity remains narrow source evidence. The approved compatibility and runtime records are:

- `../completed-plans/ACTUAL_COMPARISON_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-15.md`;
- `../completed-plans/ACTUAL_COMPARISON_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-15.md`.

### 2. `outlook` and `actual_snapshot`

The sequence is split into independent runtime slices:

```text
Slice A: actual_snapshot actual-balance numeric owner — completed
Slice B: Outlook remaining-plan monetary owner and anchor policy — unselected
```

Slice A now:

- preserves caller-owned explicit O and ledger-cumulative inclusive-O balances;
- derives actual balances from checked ledger-wide Posting IR through a local `[O,O+1)` actual-layer TBDS closing view;
- retains pre-cycle history as opening balance and does not use cycle end as an O cutoff;
- fails closed on applicable rejected actual evidence and invalid observation;
- propagates snapshot error through Outlook without deriving normal daily-allowance values;
- preserves record-frontier evidence and the two differently bounded latest-date compatibility helpers.

Current Slice A records:

- `../completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_CHARACTERIZATION-2026-07-16.md`;
- `../completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-16.md`;
- `../completed-plans/OUTLOOK_ACTUAL_SNAPSHOT_NUMERIC_OWNER_RUNTIME_MIGRATION-2026-07-16.md`.

Slice B remains independently selectable. Its approved target is to use admitted plan Posting IR for money, retain plan-ID completion/source evidence, reserve valid anchored outflows when the anchor is unmet, and admit valid anchored inflows only after matching actual income is observed through O. Invalid anchor metadata is error evidence.

Daily Capacity remains untouched: this alignment changes numeric ownership, not asset/obligation policy or adapter selection.

### 3. `daily-trend`

Current issue:

- Actual daily cumulative balances use the Cube, but reserve and plan-completion parts reread and reparse plan/journal source rows.

Target:

- keep actual running values as Cube operations;
- use identity evidence for plan completion at each row coordinate `D`;
- derive plan monetary values from admitted plan Posting IR, joined to that evidence;
- retain the current-source coordinate replay contract: `O_row = D`, with no historical knowledge claim.

Do not replace row-local plan identity with a single global `L` cutoff.

### 4. `envelopes` and `cycle` remaining-plan calculation

Current issue:

- envelope calculations already use valid rows and TBDS for major values, but allocation compatibility paths and cycle remaining-plan amounts reparse source amounts.

Target:

- use Budget-layer admitted postings for allocation and budget movement totals;
- use TBDS for closing/funding values;
- use plan evidence only for unfinished/completed identity and display;
- retain the execution-envelope versus plan coverage diagnostic and its no-double-counting policy.

No automatic adjustment, source migration, or change to envelope backing policy belongs to this plan.

### Already aligned / intentionally non-Cube sections

| Section | Reason |
|---|---|
| `snapshot`, `balances`, `trial-balance`, `expense-breakdown` | already TBDS-led for their accounting values |
| `ytd` | re-materializes a year window from Posting IR and Cube operations |
| `daily-flow` | daily numeric flow is Cube-led; local frontier discovery is evidence-only |
| `recent` | requires row identity and presentation fields; it correctly uses Posting IR rows |
| `planned` | requires plan ID, completion, memo, and due-state evidence |
| `issues` | separate issues-log domain, not accounting postings |
| `check` / readiness | Cube diagnostics are the numeric owner; file counts are source inventory, not accounting totals |

## Delivery order and gates

Work is intentionally one report slice at a time.

1. **Characterization foundation** — complete for Actual Comparison and Outlook Slice A.
2. **Actual Comparison** — completed.
3. **Outlook / actual snapshot Slice A** — completed; Slice B is the next selectable but unselected report candidate.
4. **Daily Trend** — later independent candidate.
5. **Envelopes / Cycle** — later independent candidate.

A slice may proceed only when it has:

- a named report question and value owner;
- explicit time roles (`D`, `O`, `L`, period window) where relevant;
- a fixture for normal behavior and at least one rejected/empty/history-boundary behavior where relevant;
- an intentional output compatibility statement;
- updated report contract/check documentation if a visible contract changes.

## Non-goals

- no Cube shape change;
- no universal projection workbench or generic temporal kernel before two independent consumers prove one is needed;
- no source TSV schema migration;
- no automatic advice, adjustment, or writes;
- no unselected currency, valuation, M4 expense-grouping, or broad UI work;
- no claim that a remaining raw-parser path is production-invalid solely because this plan identifies a future owner migration.

## Completion criteria

The plan is complete only when every named target has either:

1. migrated its eligible numeric calculations to the stated owner with fixture/check coverage; or
2. been explicitly retained as source-evidence-only with a documented reason.

Each completed implementation slice moves its local design/decision record to `docs/archive/completed-plans/`. This plan itself is archived only after the final sequence review confirms there is no remaining unowned amount parsing in the named targets.
