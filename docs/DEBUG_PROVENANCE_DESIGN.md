# Design: Debug / Provenance Section


> **Note (2026-06-26):** Old engine has been deleted. References in this doc are historical. Current engine is src_next/.
Status: **Proposed Design / Requesting Feedback**
Date: 2026-06-22

## Objective

Provide a lightweight mechanism to trace the origin (provenance) of critical numbers calculated by the BQN report engine. This helps developers, operators, and LLM reasoning assistants verify exactly which files, coordinate layers, and date windows contributed to a specific metric, without bloating the main human report format.

---

## Minimal Scope of Provenance Labels

We propose adding provenance definitions for the following **four primary metrics**:

### 1. Liquid Assets (`liquid_assets` / `liq_total`)
*   **Formula / Meaning**: Total balance of accounts flagged as liquid assets.
*   **Provenance Coordinates**:
    *   **Source File**: `journal.tsv`
    *   **Cube Layer**: Layer 0 (`actual`)
    *   **Date Window**: From start of history up to `as_of` (inclusive).
    *   **Account Filter**: `accounts.tsv` rows where `type=liquid`.

### 2. Envelope Balances (`envelope_balances`)
*   **Formula / Meaning**: Remaining allocated balance in envelope accounts (budget group).
*   **Provenance Coordinates**:
    *   **Source Files**:
        *   `budget_alloc.tsv` (for initial allocation and top-ups)
        *   `journal.tsv` (for actual envelope/budget consumption)
    *   **Cube Layer**: Layer 2 (`budget`)
    *   **Date Window**: From start of history up to `as_of` (inclusive).
    *   **Account Filter**: `accounts.tsv` rows with prefix `budget:*` and mapped variable expense accounts.

### 3. Planned Spending (`planned_spending_until_cycle_end`)
*   **Formula / Meaning**: Future transactions scheduled to occur before the end of the current cycle.
*   **Provenance Coordinates**:
    *   **Source File**: `plan.tsv`
    *   **Cube Layer**: Layer 1 (`plan`)
    *   **Date Window**: From `as_of` (inclusive) until `cycle_end` (exclusive).

### 4. Cycle Window (`cycle_window`)
*   **Formula / Meaning**: The start and end date boundary used for computing current cycle income/expense summaries.
*   **Provenance Coordinates**:
    *   **Source File**: `cycle.tsv`
    *   **Resolved Coordinates**: `[start, end_exclusive)` half-open interval.

---

## Proposed Output Format (Draft)

When the report is run with a debug flag (e.g., `main.bqn --section debug-provenance`), it will output a section structured like this:

```text
================================================================================
DEBUG & PROVENANCE
================================================================================
[as_of] 2026-06-16
[cycle_window] 2026-06-16 to 2026-07-01 (exclusive)
  source: cycle.tsv

--------------------------------------------------------------------------------
1. liquid_assets: 110,437 yen
  source: journal.tsv (actual layer 0)
  window: from start of history until as_of (2026-06-16)
  filter: accounts.tsv where type=liquid

2. envelope_balances (budget layer 2 total): 45,210 yen
  source: budget_alloc.tsv (alloc) + journal.tsv (consume)
  window: from start of history until as_of (2026-06-16)
  filter: accounts.tsv budget_map & spent_id

3. planned_spending_until_cycle_end: 15,000 yen
  source: plan.tsv (plan layer 1)
  window: from as_of (2026-06-16) until cycle_end (2026-07-01)
================================================================================
```

---

## Implementation Boundaries (Fail Closed & Boundary-Preserving)

- **Read-Only**: The debug section only reads `r.cube_projections` and context metadata. It has absolutely no side effects on the source TSV files.
- **Detached Representation**: We will NOT mix this debug text into standard summaries (e.g., `summary.bqn` or `main.bqn`'s default human layouts) to keep output token sizes small. It will live under a specific section `debug-provenance`.
