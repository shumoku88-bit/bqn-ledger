# Daily Trend Header Time Owner Decision

Status: current decision / implemented product decision
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

This decision was implemented by PR #120.

## 1. Vocabulary

```text
S = source snapshot supplied to this run
D = Daily Trend row coordinate
O = report-level observation date selected by this decision as the header owner.
    In current runtime (post-#120), this is carried by the neutral report-entry `report_today` value, passed down to Daily Trend.
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
selected owner O != current ctx.as_of by assumption
```

## 2. Pre-#120 characterized runtime shape

Before PR #120, the runtime implementation had the following characteristics:
1. **Header calculation**: The implementation in `src_next/daily_trend.bqn` set `as_of = LatestActualDateInCycle(base, cy)` which represented the record-frontier context `L`. The formatted human output in `FormatHuman` computed days remaining as `days_left = cycle_end_exclusive - vm.as_of`. This conflated record-frontier context `L` with "current" (`現在`) observation time.
2. **Context as_of default**: In `src_next/context.bqn`, `BuildContext` defaulted `ctx.as_of` from the selected cycle start, not a general report-wide observation date `O` defaulted from `system_today`.
3. **Report CLI options**: In `src_next/report.bqn`, there was no general `--as-of` option. There was only an Outlook-specific `--outlook-as-of` flag.

## 2b. Current post-#120 runtime truth

Under the current runtime:
1. **Header calculation**: The human header days-remaining is now observation-driven. The formatted human output computes days remaining as:
   ```text
   days_left = cycle_end_exclusive - vm.header_O
   ```
   where `vm.header_O` carries the report-level observation date `O`.
2. **Distinct variables**: `vm.as_of` remains L-derived and is distinct from `vm.header_O`.
3. **Observation carrier**: No generic report-wide `--as-of` exists, and `ctx.as_of` is not reinterpreted as O.
4. **Outlook isolation**: Outlook-specific O remains separate, and `K` remains unavailable / not claimed.

## 3. Candidate evaluation

### Candidate A: Keep L as owner
- **Meaning**: The header reports remaining days relative to the latest recorded actual transaction coordinate `L`.
- **Reason for rejection**: Conflates observation time with transaction coordinates. If no transactions occur for several days, `L` remains stale, causing the header to overstate the remaining days in the cycle. Labeling it as `現在` (current) becomes a semantic lie.

### Candidate B: Use report observation O (Selected)
- **Meaning**: The header reports remaining days relative to the report's general observation date `O` (which conceptually defaults to `system_today` on standard runs, or the user-supplied `--as-of` date).
- **Justification**:
  - The phrase `現在` (current) is fundamentally an observation-time concept. It asks: "as of the date this report is being run, how many days remain in the cycle?"
  - This matches the canonical temporal principles of `docs/TIME_AS_AXIS.md`.
  - This cleanly separates the observer's clock `O` (driving the header) from row-local coordinates `O_row = D` (driving the table rows).
  - Note: This selects the semantic owner as `O`, but does NOT assume that `ctx.as_of` currently represents this `O`, nor that the general report-wide observation wiring has been implemented yet.

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

The human header is a report-level presentation element and should be driven by the report's general observation clock `O`, while the table rows present coordinate-local projections driven by `O_row = D`. We explicitly preserve `selected owner O != current ctx.as_of by assumption`.

## 6. Runtime consequences

PR #120 implemented the product decision as follows:
1. Resolved a neutral `report_today` from `date.Today` once at report entry.
2. Passed `report_today` explicitly to the Daily Trend consumer boundary as `header_O` via `daily_trend.BuildAt ⟨ctx, report_today⟩`.
3. Retained `vm.as_of` as L-derived, keeping `header_O` and `vm.as_of` distinct.

## 7. Non-goals

The implementation adhered to the following constraints:
- Did not unify `LatestActualDateInCycle` or introduce a generic `BuildAt` API for all sections.
- Did not claim that `as_of` reconstructs historical knowledge `K`.
- Did not add general `--as-of` CLI options or change Outlook's specific clock behavior.

## 8. Next finite slice

The implementation of the concrete carrier is complete. The next step is a campaign closure review:
```text
Review whether the Daily Trend temporal semantics campaign can now close.
```
