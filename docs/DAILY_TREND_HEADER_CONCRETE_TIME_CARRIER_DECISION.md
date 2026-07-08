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

This document evaluates potential concrete carriers for Daily Trend header `O` and selects a single concrete carrier without modifying the runtime behavior in this slice.

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

At minimum, we evaluate five potential concrete carriers for Daily Trend header `O`:

### Candidate A: Universal report-wide O contract (generic `--as-of` CLI option)
*   **Meaning**: Implement a generic `--as-of` flag for all report sections and pass it globally.
*   **Reason for rejection**:
    - Premature. Other report sections (YTD summary, TBDS, balances) do not yet share a unified observation contract.
    - Introducing a generic `--as-of` CLI option or a report-wide `O` would imply a universal observation model that has not yet been designed or validated, violating our constraint: *Do not add generic `--as-of` merely because it seems convenient*.

### Candidate B: Daily-Trend-specific CLI source (`--daily-trend-as-of`)
*   **Meaning**: Parse a Daily-Trend-specific CLI option at the report entry and pass it specifically to Daily Trend.
*   **Reason for rejection**:
    - Adds unnecessary complexity to the CLI interface.
    - Since both Outlook and Daily Trend are human-oriented presentation sections meant to represent "the status of the household as of today", having separate CLI flags for them is confusing for daily usage.

### Candidate C: Reuse current `ctx.as_of`
*   **Meaning**: Pass `ctx.as_of` to Daily Trend or let Daily Trend use `ctx.as_of` as the observation clock.
*   **Reason for rejection**:
    - `ctx.as_of` defaults to the cycle start date (`cy_default.start`).
    - If reused for the header, the header's days remaining would lock to the cycle length (e.g., 31 days remaining) rather than representing the actual days remaining from today (the observer's clock). This would cause a semantic lie in the presentation.
    - Reusing `ctx.as_of` by name alone violates the constraint: *Do not reuse `ctx.as_of` by name alone* and *Do not assume current `ctx.as_of` is `O`*.

### Candidate D: Reuse or generalize current Outlook-specific observation value (`--outlook-as-of`)
*   **Meaning**: Reuses the observation clock resolved at report entry for Outlook (derived from explicit `--outlook-as-of` or defaulted to `date.Today`) to also serve as the Daily Trend header `O`.
*   **Reason for rejection**:
    - Silently widens the narrow, consumer-specific promise of `--outlook-as-of` (established in PR #95) to also control the Daily Trend header.
    - This constitutes a semantic behavior change under the same CLI flag syntax, violating decoupling rules.

### Candidate E: Neutral report-entry clock source (`report_today`) passed explicitly only to Daily Trend header consumer boundary (Selected)
*   **Meaning**: Read `date.Today` once at the report entry to establish a neutral clock value `report_today`. This value is passed explicitly to the Daily Trend consumer boundary to drive the header `O`, while `--outlook-as-of` remains strictly Outlook-specific (i.e. setting `--outlook-as-of` does NOT affect the Daily Trend header).
*   **Justification**:
    - Preserves PR #95 narrow `--outlook-as-of` contract (Outlook override only).
    - Avoids a generic `--as-of`.
    - Avoids reusing `ctx.as_of`.
    - Reads system today once at report entry.
    - Keeps consumer boundaries explicit.
    - Does not claim all report sections share one observation contract.
    - Does not alter reserve semantics or `O_row = D`.

## 4. Decision

The concrete `O` carrier for the Daily Trend header `O` shall be:

```text
The neutral report-entry clock source (report_today = date.Today read once at report entry)
```

This value will be passed explicitly to the Daily Trend consumer boundary via a new `daily_trend.BuildAt ⟨ctx, header_O⟩` signature (or equivalent explicit argument).

*   **Outlook-specific O** remains isolated: `--outlook-as-of` overrides only Outlook and does not affect the Daily Trend header.
*   **Daily Trend internal L** remains isolated: the header `O` is not substituted for internal calculations like reserve logic that depend on the record-frontier `L`.

## 5. Smallest Authorized Next Runtime Slice

The next runtime slice is authorized to implement the selected concrete carrier via the following minimal changes:

1.  **Report Entry Update**:
    - Resolve/read `report_today` from `date.Today` once at `src_next/report.bqn` entry.
    - Resolve Outlook-specific `O` separately, preserving the explicit `--outlook-as-of` override behavior.
2.  **Daily Trend Engine Update**:
    - Introduce an explicit header observation carrier in the `daily_trend` module interface, conceptually:
      `daily_trend.BuildAt ⟨ctx, header_O⟩`
    - Retain `daily_trend.Build ctx` as a compatibility wrapper that defaults `header_O` using `LatestActualDateInCycle ⟨ctx.base, ctx.cy⟩`.
    - Keep the existing `L`-derived internal dependencies intact: **do not globally replace `as_of` or `as_of_dn` with `header_O`**. Use `header_O` only for human header days-remaining presentation.
3.  **Behavioral Validation**:
    - Update `tests/test_src_next_daily_trend.bqn` or add focused tests asserting that:
      - Changing header `O` changes header days remaining.
      - Rendered Daily Trend rows remain unchanged.
      - Row-local values remain unchanged.
      - Reserve remains unchanged.
      - `--outlook-as-of` does not change Daily Trend header behavior.
      - Existing `O_row = D` and `K` as unavailable are preserved.

No other code or CLI option changes are authorized in the next slice.
