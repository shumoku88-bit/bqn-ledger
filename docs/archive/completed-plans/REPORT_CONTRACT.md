# Report Contract

Status: draft
Branch: `refactor/cycle-ledger-core`
Scope: report behavior and public report-state rules for the cycle-ledger refactor

## 1. Purpose

This document defines what the first report surface must guarantee before implementation changes begin.

The goal is not to list every possible report.

The goal is to keep the user-facing report small, stable, and useful while allowing the internal model to remain a clear BQN array engine.

## 2. Report stance

The system is a cycle-oriented household-accounting report engine.

The first report should answer practical living-cycle questions before it becomes a general accounting dashboard.

The report surface should be smaller than the internal model.

The first-phase internal model is:

```text
Day × AccountKey × Layer
```

`AccountKey` may be a plain account for JPY-only data, or an `(Account, Currency)` pair when currency-separated balances are required.

See also:

```text
docs/AXIS_CONTRACT.md
```

The first user-facing report should stay compact.

## 3. First report surface

The first report contract covers these sections:

```text
1. current cycle summary
2. remaining amount until next income date
3. food / daily remaining amount
4. plan vs actual difference
5. incomplete planned items
6. checks / warnings / unavailable sections
```

These are the sections that should be protected first when refactoring.

Other reports may exist, but they are not the first-phase contract unless added here later.

## 4. Section status

Every report section should have an explicit status.

Recommended statuses:

```text
ok           computed safely
warning      computed, but data may indicate a problem
unavailable  cannot be computed safely from current data
error        contract violation or impossible state
```

The report should not silently hide missing or unsupported data.

Examples:

- no planned items may be `ok` with an empty result
- unknown account names should be `error`
- mixed-currency totals without conversion support may be `warning` or `unavailable`
- missing optional future data may be `unavailable`

## 5. Public report state

The report engine may build a report state from canonical data.

The current engine has hardening notes about `BuildAt` returning a very large Record with many fields.

This refactor should avoid treating one giant namespace as the public report API.

Preferred public state shape:

```text
state.cube
state.snapshot
state.cycle
state.plan
state.budget
state.envelopes
state.checks
state.meta
```

Names may change, but the principle should remain:

- group fields by meaning
- each report section receives only the groups it needs
- avoid hidden global state disguised as a convenient Record
- keep the public field schema inspectable

## 6. Section inputs

Each section should declare its required inputs.

Example:

```text
current_cycle_summary:
  needs: cycle, snapshot, checks

remaining_until_next_income:
  needs: cycle, plan, snapshot

food_daily_remaining:
  needs: cycle, budget, actual, account_keys

plan_vs_actual_difference:
  needs: plan, actual, account_keys

incomplete_planned_items:
  needs: plan, actual, cycle

checks_warnings_unavailable:
  needs: checks, meta
```

This is a conceptual contract, not necessarily the exact function signature.

The point is to make dependencies visible.

## 7. Output stability

Refactoring should not change the meaning of existing report values unless the change is explicitly documented.

For behavior-preserving internal restructuring:

```text
existing golden output should not change
```

If output changes are intentional, the change should be described in a migration note.

## 8. Display vs computation

Computation and display should remain separable.

Recommended split:

```text
canonical data
  -> projections
  -> internal arrays
  -> report state
  -> SectionResult values
  -> display formatting
```

Formatting should not decide financial meaning.

Report sections should be testable before final text formatting.

The conceptual `SectionResult` shape is defined in:

```text
docs/REPORT_VALUE_CONTRACT.md
```

## 9. Reader layers

The BQN core should produce trustworthy report data.

Reader layers may consume that data and provide different reading experiences.

The first required reader is the minimum CLI text report.

Optional readers may include:

```text
Pluto.jl notebook
static HTML report
other visualization or exploration tools
```

Reader layers may read derived TSV files such as `out/*.tsv` or a documented report-state export.

Reader layers must not become canonical data.

Reader layers must not be required for the minimum report path.

Recommended responsibility split:

```text
BQN core:
  canonical TSV -> derived TSV / report state / minimum CLI report

optional reader layer:
  derived TSV / report state -> interactive or visual reading surface
```

This allows a richer reading surface without making Pluto.jl, HTML generation, or visualization tools part of the core dependency contract.

## 10. BQN array contract

A BQN reader should be able to identify the array shape used by the report engine.

The report contract should encourage code where the major shape decisions are visible:

```text
Day
AccountKey
Layer
```

Reports should not be produced only by ad-hoc scalar calculations scattered across the code.

When a report is derived from the cube, the path from axis data to section value should be visible enough to inspect.

Dense BQN is acceptable only when the shape remains understandable.

## 11. Checks and warnings

Checks are first-class report output, not afterthoughts.

At minimum, checks should be able to report:

- unknown account
- missing required canonical file
- malformed TSV row
- unsupported currency
- impossible cycle boundary
- unavailable report section
- plan / actual mismatch when detectable
- mixed-currency total requested without conversion support

Warnings should be useful for daily life, not merely technical.

Examples:

- spending pace above safe daily amount
- upcoming planned payment is near
- no recent journal entry
- budget data exists but cannot be safely projected

## 12. Multi-currency report behavior

The first phase does not implement full currency conversion or exchange-rate accounting.

The first phase may still preserve currency-separated balances by using:

```text
AccountKey = (Account, Currency)
```

If records are JPY-only or implicitly JPY, reports may compute normally.

If foreign-currency balances exist, reports may display them separately by AccountKey or currency group.

Reports must not silently collapse different currencies into one total.

Acceptable first-phase behavior for mixed-currency totals:

```text
section status: warning or unavailable
message: mixed currencies detected; conversion not supported in first phase
```

## 13. Dependency behavior

The minimum report path should aim for:

```text
BQN + canonical TSV files -> minimum report
```

Shell, Go, gum, fzf, and other tools may help with orchestration, input, or convenience.

They should not be required to compute the first report surface unless documented as a deliberate dependency.

External process calls should be visible and named as I/O boundaries.

Optional reader layers may add their own dependencies, but those dependencies must remain outside the minimum report path.

## 14. Relationship to current hardening notes

The current `main` branch hardening notes identify two report-contract concerns:

1. `BuildAt` returns a very large public Record, making section dependencies hard to see.
2. `report_engine.bqn` mixes implementation code with a long public field listing.

This document treats both as design signals.

The next architecture should make the report state smaller, grouped, and documented before changing the code.

## 15. First-phase non-goals

The report contract does not yet require:

- all historical report sections
- public YouTube-safe report output
- tax export reports
- double-entry export reports
- full forecast reports
- currency conversion
- separate Currency axis
- event-first projections
- Pluto.jl or HTML as required runtime dependencies

These can be added later if they become active goals.

## 16. Open questions

- Should public report schema live in a separate file such as `report_schema.bqn`?
- Should the first report output be intentionally shorter than the current output?
- Which existing report sections are essential for daily use, and which are research or debugging aids?
- Which derived TSV files should be considered stable reader inputs?
- Should the first optional reader be Pluto.jl or static HTML?
- Should currency-separated AccountKeys be declared in `accounts.tsv` or derived during loading?
