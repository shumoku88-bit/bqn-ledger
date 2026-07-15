# Actual Comparison Numeric-Owner Runtime Migration

Status: completed runtime migration
Owner: report
Canonical: no; current paths: `src_next/actual_comparison.bqn`, `docs/REPORT_CONTRACTS.md`, and executable checks
Exit: retain as the implementation and compatibility record for this finite slice

## Completed boundary

Actual Comparison now exposes only:

```text
actual_comparison.BuildAt ⟨ctx, O⟩
```

`O` is explicit and owns `vm.as_of`. The current half-open window is
`[ctx.cy.start, min(O + 1 day, ctx.cy.end_exclusive))`. It is a hard cutoff:
actual journal events with `D > O` do not enter current amounts or counts.
`ctx.as_of`, journal maximum date, record frontier `L`, cycle end, and generation
time do not substitute for `O`.

The human report passes its one captured `report_today`. The machine summary
captures today once through `src_next/date.bqn` at summary entry and passes it
to `BuildAt`. No report-wide `as_of`, section CLI option, or compatibility
`Build` wrapper was added.

## Numeric and count owners

Current and baseline amounts now follow:

```text
checked ledger-wide Posting IR
  -> positive semantic actual posting sides
  -> local half-open TBDS period views
  -> account/lane debit or credit movement
```

The baseline starts at the previous comparable income anchor and uses the same
elapsed length as the current window. It is not derived from the existing
cycle-bounded Cube. Income uses positive income-account credit contribution;
recurring fixed and variable expenses use positive expense-account debit
contribution, split by `spend_class=fixed`. Transfers, liability principal,
expense credits/refunds, income debits, and non-positive reversed sides are
excluded. Canonical Cube shape remains unchanged.

Event counts use admitted posting evidence from the same checked Posting IR and
identity `source_file + source_row + lane + account`. Selecting only the
semantic posting side removes debit/credit-pair duplication without globally
deduplicating a source row across output keys. A direct income-to-expense row
can therefore count once in each distinct key.

## Anchor evidence dependency

Previous-anchor discovery is separate from amount ownership. It uses admitted
journal/plan income-credit posting identity and date. The configured
`income_account` is still read narrowly from `cycle.tsv` as anchor identity
evidence. Existing journal-derived anchors and the plan-derived
future-after-journal-frontier behavior remain. No amount text is read or parsed
on this evidence path, and it contributes no numeric aggregate.

## Rejected actual evidence

Consumer-observable rejected journal source rows fail the section closed:

- valid-date rejection in current or baseline window -> `error`;
- valid-date rejection outside both windows -> no section-local failure;
- invalid-date rejection -> `error`, because applicability cannot be proven;
- error -> empty numeric table.

Diagnostics deduplicate the debit/credit pair by `source_file + source_row`,
separately from numeric event-count identity. Snapshot-wide invalid
amount/currency authorization still stops before context construction and was
not converted into a nonfatal section carrier.

## Status and output compatibility

The runtime vocabulary is now `ok / unavailable / error`.
`insufficient_history` was removed from runtime, machine output, human output,
and focused checks. Missing previous anchor and empty current window are
`unavailable`; invalid observation/cycle and applicable rejected evidence are
`error`. A valid zero-event baseline remains `ok`. Row behavior remains
`new/n/a`, `stopped/0%`, and `no_activity`.

Intentional changes from the PR #261 characterization
`ACTUAL_COMPARISON_PROJECTION_CHARACTERIZATION-2026-07-15.md`, as approved by
`ACTUAL_COMPARISON_NUMERIC_OWNER_COMPATIBILITY_DECISION-2026-07-15.md`, are:

1. `fixtures/actual-comparison-projection-normal` with `O=2026-03-05` is now
   `error` because its in-window unknown-account row is rejected; its table is
   empty and the old raw-parser `food=88` value is not preserved.
2. The `2026-03-07` event is after `O` and excluded.
3. `vm.as_of` is `2026-03-05`, not the maximum journal date.
4. `insufficient_history` is no longer a status.

The PR #261 fixture files themselves were not deleted or rewritten.

## Fixtures and checks

- existing pre-migration normal fixture -> `error`;
- new `fixtures/actual-comparison-numeric-owner-target` -> explicit-O `ok`,
  three lanes, counts, row statuses, transfer/post-O exclusions, outside-window
  rejection, and dual contribution;
- existing history-boundary fixture -> `unavailable`;
- new invalid-date rejected fixture -> `error` with one source-row diagnostic;
- focused BQN tests cover observation start/before/end clamp and invalid O/cycle;
- shell checks reject removed status/call sites and enforce empty numeric output
  for `error` and `unavailable`.

No private production data was accessed.

## Non-goals retained

No report-wide `--as-of`, Actual Comparison CLI option, generic temporal kernel,
generic period-query abstraction, Projection Workbench, Cube/source schema
change, nonfatal context carrier, arithmetic/currency authorization change, or
Outlook / `actual_snapshot` / Daily Trend / Envelopes / Daily Capacity migration
was included.
