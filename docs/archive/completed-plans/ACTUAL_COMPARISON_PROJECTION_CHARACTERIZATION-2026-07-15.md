# Actual Comparison Projection Characterization

Status: completed
Owner: report
Canonical: no; current paths: `src_next/actual_comparison.bqn`, `docs/REPORT_CONTRACTS.md`, and `docs/archive/active-plans/REPORT_PROJECTION_ALIGNMENT_PLAN-2026-07-15.md`
Exit: retain as the pre-migration evidence record; supersede only with a later compatibility decision that cites these fixtures

## Scope

This slice characterizes the current `src_next/actual_comparison.bqn` source-parser path before any numeric-owner migration. It changes no report runtime, display, accounting value, Cube shape, source schema, config, or metadata.

Public synthetic evidence:

- `fixtures/actual-comparison-projection-normal/`
- `fixtures/actual-comparison-history-boundary/`
- `tests/test_src_next_actual_comparison.bqn`
- `checks/check-src-next-actual-comparison.sh`

No private production data was accessed.

## Fixed current contract

For a successful comparison, the fixture fixes:

- `period_kind=current_cycle_elapsed`;
- current window `[current_start, as_of + 1 day)`;
- baseline window beginning at the previous income anchor and having the same elapsed-day length;
- `income`, `recurring_fixed`, and `variable` lanes;
- account-level amount, event count, amount/count differences, floored integer percentage ratio, row status, and observation status;
- `baseline=0,current>0 -> ratio=n/a,status=new`;
- `baseline>0,current=0 -> ratio=0%,status=stopped`;
- asset-to-asset transfers and asset-to-liability principal transfers do not create comparison rows;
- the baseline exclusive-end journal row is not aggregated.

The history-boundary fixture fixes missing previous-anchor behavior as `observation_status=unavailable`, unavailable baseline bounds, and an empty table.

## Source-parser dependencies found

The current implementation does not consume `ctx.posting_rows`, `ctx.cube`, or `ctx.tbds` for comparison amounts. It rereads:

- `cycle.tsv` for `income_account`;
- `journal.tsv` for anchor discovery, local observation-date discovery, classification input, amount parsing, and aggregation;
- `plan.tsv` for future income-anchor discovery.

It parses journal amounts with `•BQN` and classifies source fields against `ctx.resolved`. This is characterization only; it is not evidence that local amount parsing is a desirable owner.

### Rejected Posting IR is not an exclusion boundary

The normal fixture contains `unknown:ghost -> expenses:food 7`. The checked Posting IR marks both posting sides `unknown_account`, so Cube/TBDS reject them. The current Actual Comparison parser nevertheless recognizes the destination expense account and adds 7 to `food`.

Therefore current raw-parser output is **not** claimed equivalent to checked Posting IR, Cube, or TBDS output. A migration must make this compatibility difference explicit rather than silently calling it parity.

### Caller observation is not a hard cutoff

The normal test builds context with `ctx.as_of=2026-03-05`, then includes a journal expense dated `2026-03-07`. Actual Comparison independently chooses the maximum journal date at or after `current_start`, with no upper cycle bound, and returns `vm.as_of=2026-03-07`; the later expense is aggregated and both current and baseline windows are lengthened.

Consequently the requested property “journal rows after the observation cutoff are not aggregated” is not true when “observation cutoff” means caller-owned `ctx.as_of`. The only current cutoff is the module's own maximum journal coordinate, so no journal row can be later than it by construction. This is a characterized runtime defect/ownership gap, not fixed in this slice.

### `insufficient_history` is not reachable from valid source

The code contains an `insufficient_history` branch when `earliest_journal_date > baseline_start`. Under the current valid-source anchor algorithm:

1. a journal-derived previous anchor is itself a journal date, so the earliest journal date cannot be later; and
2. a plan-derived previous anchor is admitted only after the maximum journal date, so the earliest journal date is again earlier.

No valid synthetic fixture can therefore produce `observation_status=insufficient_history` without malformed-date behavior or changing runtime logic. This slice does not manufacture invalid date ordering to fake coverage. It records the unreachable status as a runtime defect; `unavailable` and `ok` remain executable fixture states.

## Compatibility evidence

The normal fixture produces these account rows:

| unit | lane | current | baseline | diff | current count | baseline count | count diff | ratio | status |
|---|---|---:|---:|---:|---:|---:|---:|---|---|
| salary | income | 120 | 100 | 20 | 1 | 1 | 0 | 120% | increased |
| rent | recurring_fixed | 120 | 100 | 20 | 1 | 1 | 0 | 120% | increased |
| food | variable | 88 | 50 | 38 | 4 | 1 | 3 | 176% | increased |
| new | variable | 30 | 0 | 30 | 1 | 0 | 1 | n/a | new |
| stopped | variable | 0 | 40 | -40 | 0 | 1 | -1 | 0% | stopped |

`food=88` intentionally includes the checked-projection-rejected 7 and the post-`ctx.as_of` 11. These values lock current behavior for later compatibility review; they are not target values for a checked projection.

## Next selectable runtime slice

The next independently selectable slice is Actual Comparison numeric-owner migration to checked ledger-wide Posting IR and locally periodized TBDS views. Before implementation it must decide, with explicit compatibility treatment:

- whether rejected Posting IR amounts disappear or make the report unavailable/error;
- whether observation ownership remains local maximum journal date or becomes an explicit caller-owned cutoff;
- whether `insufficient_history` is removed, made reachable through explicit history evidence, or otherwise redefined;
- how current and previous-cycle same-elapsed period views preserve lanes, counts, ratios, and visible output.

That runtime slice is not selected by this record. Outlook, Actual Snapshot, Daily Trend, Envelopes, shared temporal kernels, generic period abstractions, and Projection Workbench remain out of scope.
