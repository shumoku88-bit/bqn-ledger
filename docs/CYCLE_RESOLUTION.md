# Pure cycle resolution

Status: Phase 3G capability proof

Owners:

- `src/accounting/cycle_result.bqn` — one result shape;
- `src/accounting/cycle_fixed_resolution.bqn`;
- `src/accounting/cycle_calendar_month_resolution.bqn`;
- `src/accounting/cycle_income_anchor_resolution.bqn`.

## Why mode-specific resolvers

The three modes require materially different evidence:

```text
fixed          admitted definition only
calendarMonth  admitted definition + explicit as-of
incomeAnchor   admitted definition + explicit as-of + Actual Facts + Plan Facts
```

There is no universal cycle context and no dispatcher that forces unused Facts into fixed/calendar calls. All mode resolvers return the same typed period result, so an outer use case may dispatch after admission without changing consumers.

No resolver performs source I/O, reads a clock, parses source rows, formats report text, or imports `src_next`.

## Result states

Every mode returns one shape with:

```text
state: ok | unavailable | error
mode, observation, reason
start, end_exclusive
start_ordinal, end_exclusive_ordinal, day_count
start_contributors, end_contributors
diagnostics
```

- `ok` has strict half-open period coordinates;
- `unavailable` has a stable reason and no numeric/date coordinates;
- `error` has diagnostics and no partial period;
- fixed/calendar boundaries have no fabricated contributors;
- incomeAnchor boundaries retain source-qualified durable Transaction references.

Unavailable and rejected evidence never becomes a zero-day or sentinel-date period.

## Fixed

The resolver returns the already-admitted strict `start` and `end_exclusive`. It does not accept observation or Facts because they cannot change a fixed definition.

## Calendar month

The resolver uses explicit strict `as_of` and admitted `start_day` 1–28:

- if as-of day is on/after `start_day`, start is in the same month;
- otherwise start is in the previous month;
- end is the same day in the following month.

The 1–28 admission rule guarantees both coordinates exist in every month. Gregorian conversion is owned by `src/ledger/date_ordinal.bqn`; no shell date command is used.

## Income anchor

The resolver validates:

- `actual.journal` and `plan.tsv` Source facts are not swapped;
- income Account key, explicit role, currency, Domain, and Layer evidence agree;
- Actual evidence is bounded by explicit as-of;
- only credit/negative postings to the admitted income Account are anchors;
- Plan boundary evidence occurs after the latest observed Actual transaction frontier;
- empty Plan facts are valid but produce `planned_income_anchor_missing`.

Resolution preserves current minimal semantics:

```text
start = latest observed Actual income date
end   = earliest planned income date after latest observed Actual transaction
```

Boundary contributors are source-qualified records:

```text
{ source, transaction_id }
```

Snapshot-local Actual and Plan indices are never compared or merged.

## Offset decision

Historical destination admission accepted any integer `offset` even though current `src_next` resolution ignores it. The strict destination now admits only absent/`0`. Nonzero offset is rejected as `income_anchor_offset_unsupported` instead of being silently ignored or given speculative semantics. A future historical-cycle feature requires its own explicit contract and consumers.

## Source table gate

IncomeAnchor is the first canonical consumer that reads Actual and Plan facts together. Accordingly, Phase 3G adds the previously deferred one-row Source table and aligned `source_index` to every Transaction/Posting fact result. This is provenance, not a broad merged snapshot or cross-domain arithmetic permission.

## Proof

`tests/test_accounting_cycle_resolution.bqn` proves:

- strict public fixed period;
- calendarMonth before/on start day and invalid observation;
- Actual+Plan incomeAnchor dates, day count, and source-qualified contributors;
- explicit as-of filtering;
- missing Actual observation and missing Plan anchor as unavailable;
- swapped sources as error;
- no partial coordinates for unavailable results;
- Gregorian parts/text roundtrip.
