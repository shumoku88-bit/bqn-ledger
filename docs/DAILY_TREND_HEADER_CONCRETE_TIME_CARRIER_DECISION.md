# Daily Trend Header Concrete Time Carrier Decision

Status: current decision / docs-only product contract
Owner: report
Canonical: no; canonical temporal principle remains `docs/TIME_AS_AXIS.md`
Selected product: `docs/DAILY_TREND_CURRENT_SOURCE_COORDINATE_REPLAY_DECISION.md`
Current dependency observation: `docs/DAILY_TREND_TEMPORAL_DEPENDENCY_MAP.md`
Exit: revise or archive after a runtime slice implements this decision and subsequent review confirms the chosen direction

## 0. Purpose

PR #115 characterized human-header sensitivity.
PR #116 selected the report observation `O` as the semantic owner of the Daily Trend header's days-remaining count.
PR #117 synchronized current routing.
However, the concrete carrier for transporting `O` to the Daily Trend header remains unresolved, and the runtime implementation is still driven by `L` (LatestActualDateInCycle).

This document evaluates the potential concrete carriers for `O` and selects a single concrete carrier for Daily Trend header `O` without modifying the runtime behavior in this slice.

## 1. Characterization of Current Report-Entry Observation Paths

When executing `tools/report [base] [args]`, the program calls `src_next/report.bqn`'s `Main`.

1. **Context Resolution**: `ctx ← BuildContext base` resolves `ctx.as_of`.
   - In `src_next/context.bqn`, `BuildContext` defaults `ctx.as_of` from the selected default cycle start (`cy_default.start`).
   - Thus, `ctx.as_of` is not a clean observation clock defaulted from the external system today.
2. **Outlook-Specific Observation**: `report.bqn` parses `--outlook-as-of YYYY-MM-DD`.
   - If present, `outlook_as_of` is set to the parsed value.
   - Otherwise, `outlook_as_of` defaults to the system date `date.Today` read once at entry.
   - This value is passed explicitly to `outlook.BuildAt ⟨ctx, outlook_as_of⟩`.
3. **Daily Trend Section**: `report.bqn` calls `daily_trend.Build ctx` (without passing any observation date).
   - In `src_next/daily_trend.bqn`, `Build` resolves a local `as_of` date from `LatestActualDateInCycle ⟨base, cy⟩` representing record-frontier context `L`.
   - In `FormatHuman`, `days_left` is computed from `C.end_exclusive - vm.as_of`.
   - Consequently, the Daily Trend header remains `L`-driven.

## 2. Vocabulary and Distinctions

To ensure clarity, we preserve the following distinct meanings and roles:

*   **Selected Semantic Owner `O`**: The abstract clock of the observation/replay frame that drives the header days-remaining presentation.
*   **Concrete `O` Carrier**: The programming interface argument/variable that carries `O` from report-entry down to the Daily Trend consumer boundary.
*   **Current `ctx.as_of`**: The cycle-resolution parameter stored in the context namespace. It defaults to cycle start and is not a pure observation clock.
*   **Outlook-specific `O`**: The specific `outlook_as_of` resolved at report entry and sent to the Outlook module.
*   **General CLI Design**: Decisions regarding generic CLI flags (like `--as-of`).
*   **`K`**: Historical knowledge boundary (not claimed/unavailable).

## 3. Concrete Carrier Candidate Evaluation

At minimum, we evaluate four potential concrete carriers for Daily Trend header `O`:

### Candidate A: Report-entry selected general O, passed explicitly to Daily Trend consumer boundary
*   **Meaning**: At report entry, a general observation date `O` is determined (e.g. from a generic `--as-of` CLI flag or system today) and passed explicitly to `daily_trend.BuildAt ⟨ctx, O⟩`.
*   **Reason for rejection**:
    - Adding a general `--as-of` CLI option or establishing a universal report-wide `O` is premature.
    - Other report sections (YTD summary, TBDS, balances) do not yet share a unified observation contract.
    - Introducing a generic `--as-of` CLI option or a report-wide `O` would imply a universal observation model that has not yet been designed or validated, violating our constraint: *Do not add generic `--as-of` merely because it seems convenient*.

### Candidate B: Daily-Trend-specific O / CLI source
*   **Meaning**: Parse a Daily-Trend-specific CLI option (e.g., `--daily-trend-as-of`) at the report entry and pass it specifically to Daily Trend.
*   **Reason for rejection**:
    - Adds unnecessary complexity to the CLI interface.
    - Since both Outlook and Daily Trend are human-oriented presentation sections meant to represent "the status of the household as of today", having separate CLI flags for them is confusing for daily usage.

### Candidate C: Reuse current `ctx.as_of`
*   **Meaning**: Pass `ctx.as_of` to Daily Trend or let Daily Trend use `ctx.as_of` as the observation clock.
*   **Reason for rejection**:
    - `ctx.as_of` defaults to the cycle start date (`cy_default.start`).
    - If reused for the header, the header's days remaining would lock to the cycle length (e.g., 31 days remaining) rather than representing the actual days remaining from today (the observer's clock). This would cause a semantic lie in the presentation.
    - Reusing `ctx.as_of` by name alone violates the constraint: *Do not reuse `ctx.as_of` by name alone* and *Do not assume current `ctx.as_of` is `O`*.

### Candidate D: Reuse or generalize current Outlook-specific observation value (Selected)
*   **Meaning**: Reuses/generalizes the observation clock resolved at report entry (which is currently named `outlook_as_of` and defaults to `date.Today` or the explicit `--outlook-as-of`) to serve as the concrete carrier for the Daily Trend human header `O`.
*   **Justification**:
    - The resolved report-entry variable (either explicitly set via `--outlook-as-of YYYY-MM-DD` or defaulted to `date.Today` read once at entry) represents the natural, single "clock of the run" for human presentation sections.
    - Reusing this value under the hood to also drive `daily_trend` (via a new signature `daily_trend.BuildAt ⟨ctx, O⟩`) provides a concrete, reliable carrier for the Daily Trend human header.
    - It avoids introducing a premature generic `--as-of` CLI flag, while still keeping the daily trend consumer boundary explicit (`BuildAt ⟨ctx, O⟩`).
    - It avoids duplicating clock-reading logic (`date.Today` is read once at the report entry and passed down).
    - It preserves CLI compatibility (no new flags are added).

## 4. Decision

The concrete `O` carrier for the Daily Trend header `O` shall be:

```text
The report-entry resolved variable (derived from explicit `--outlook-as-of` or defaulted to system_today)
```

This resolved value will be passed explicitly to the Daily Trend consumer boundary via a new `daily_trend.BuildAt ⟨ctx, O⟩` signature.

## 5. Smallest Authorized Next Runtime Slice

The next runtime slice is authorized to implement the selected concrete carrier via the following minimal changes:

1.  **Interface Evolution**:
    - Introduce `daily_trend.BuildAt ⟨ctx, O⟩` in `src_next/daily_trend.bqn` where `as_of` is set to `O`.
    - Retain `daily_trend.Build ctx` as a compatibility wrapper that defaults `O` using `LatestActualDateInCycle ⟨ctx.base, ctx.cy⟩` (preserving existing behavior for non-human/test callers if any).
2.  **Report Entry Update**:
    - Update `src_next/report.bqn` to call `daily_trend.BuildAt ⟨ctx, outlook_as_of⟩`.
3.  **Behavioral Validation**:
    - Update `tests/test_src_next_daily_trend.bqn` or add focused tests asserting that `daily_trend.BuildAt` behaves correctly under different `O` values.
    - Asserts that row-local calculations (including `LatestActualDateInCycle` used inside `BuildAt` for matching/frontier logic if needed) must NOT be rewritten or conflated.

No other code or CLI option changes are authorized in the next slice.
