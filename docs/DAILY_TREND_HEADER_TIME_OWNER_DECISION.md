# Daily Trend Header Time Owner Decision

Status: current decision / docs-only product contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Selected product: `docs/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
Current dependency observation: `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
Exit: revise or archive after a runtime slice implements this decision and subsequent review confirms the chosen direction

## 0. Purpose

PR #115 proved a narrow independent sensitivity in the Daily Trend formatted output:
- Holding the cycle, rendered rows, row coordinates `D`, and row-local values fixed, moving only `vm.as_of` (representing `L = LatestActualDateInCycle`) from `2026-01-03` to `2026-01-06` changes the human header days-remaining presentation from `8` to `5` (`8 -> 5`).
- The rendered table rows remained byte-for-byte identical.

This confirms that the section header clock moves independently of all rendered row content. 

This document records the product decision resolving what semantic owner the human header days-remaining text (currently shaped like `(現在 N 日残)`) should use.

Decision question:
```text
What semantic owner should the Daily Trend human header days-remaining presentation use?
```

This PR is docs-only; it establishes the product contract without changing the runtime.

## 1. Vocabulary

```text
S = source snapshot supplied to this run
D = Daily Trend row coordinate
O = report-level observation time / date (supplied via `--as-of` or defaulting to system_today)
O_row = Daily Trend row observation rule, currently D
C = cycle / period boundary
L = local last-recorded coordinate frontier from LatestActualDateInCycle
K = historical knowledge boundary; unavailable / not claimed
```

Important distinctions remain unchanged:

```text
O_row = D
L != O_row
L != K
O_row != K
historical coordinate != historical knowledge state
```

## 2. Current runtime shape

The current implementation in `src_next/daily_trend.bqn` sets:
```text
as_of = LatestActualDateInCycle(base, cy)
```
which represents the record-frontier context `L`.

The formatted human output in `FormatHuman` computes days remaining as:
```text
days_left = cycle_end_exclusive - vm.as_of
```
This is presented in the section header as:
```text
サイクル: 2026-01-01 〜 2026-01-11  (現在 8 日残)
```
This conflates record-frontier context `L` (the date of the latest actual transaction in the cycle) with "current" (`現在`) observation time `O`.

## 3. Candidate evaluation

### Candidate A: Keep L as owner
- **Meaning**: The header reports remaining days relative to the latest recorded actual transaction coordinate `L`.
- **Reason for rejection**: Conflates observation time with transaction coordinates. If no transactions occur for several days, `L` remains stale, causing the header to overstate the remaining days in the cycle relative to "now". Labeling it as `現在` (current) becomes a semantic lie.

### Candidate B: Use report observation O (Selected)
- **Meaning**: The header reports remaining days relative to the report's general observation date `O` (which defaults to `system_today` on standard runs, or the user-supplied `--as-of` date).
- **Justification**:
  - The phrase `現在` (current) is fundamentally an observation-time concept. It asks: "as of the date this report is being run, how many days remain in the cycle?"
  - This matches the canonical temporal principles of `docs/TIME_AS_AXIS.md`, where `system_today` or `--as-of` supplies the observer's clock `O` at report entry.
  - This cleanly separates the observer's clock `O` (driving the header) from row-local coordinates `O_row = D` (driving the table rows).

### Candidate C: Use latest rendered D
- **Meaning**: The header reports remaining days relative to the latest rendered Daily Trend row coordinate.
- **Reason for rejection**: Conflates the set of transaction coordinates with observation time. Sparse or empty cycles would cause the header to lock onto arbitrary coordinate dates (like the empty-state anchor `cycle.start`), failing to represent the actual remaining time.

### Candidate D: Preserve L-derived calculation but change presentation
- **Meaning**: Keep the calculation relative to `L` but rename the label from `現在` to a term explicitly representing the record frontier (e.g. `(最終記帳から N 日残)`).
- **Reason for rejection**: While it avoids the semantic lie of Candidate A, it fails to provide the user with the most useful information for cycle planning: how many days are actually left in the cycle relative to today (the observer's clock).

## 4. Decision

The Daily Trend human header days-remaining presentation shall use:

```text
report observation O
```

as its semantic owner. 

## 5. Protected semantic property

```text
separation of L and O in presentation
```

The human header is a report-level presentation element and should be driven by the report's general observation clock `O`, while the table rows present coordinate-local projections driven by `O_row = D`.

## 6. Runtime consequences

In a future runtime implementation slice:
1. `daily_trend.Build` will receive `ctx.as_of` (representing `O`) and assign it to `vm.as_of`.
2. The local call to `LatestActualDateInCycle` (representing `L`) will no longer drive `vm.as_of` for header days-left calculations (though it may still be returned or used for freshness indicators if explicitly justified).
3. `FormatHuman` will compute days remaining using this `O`-driven `vm.as_of`.

## 7. Non-goals

Do not:
- Modify `src_next/daily_trend.bqn` or any runtime code in this branch.
- Modify tests or fixtures in this branch.
- Change report labels or wording in this branch.
- Unify `LatestActualDateInCycle` or introduce a generic `BuildAt` API.
- Claim that `as_of` reconstructs historical knowledge `K`.

## 8. Next finite slice

A subsequent PR will align the runtime by passing `ctx.as_of` into `daily_trend.Build` and updating `tests/test_src_next_daily_trend_header_as_of_sensitivity.bqn` to characterize the new `O`-driven header behavior.
