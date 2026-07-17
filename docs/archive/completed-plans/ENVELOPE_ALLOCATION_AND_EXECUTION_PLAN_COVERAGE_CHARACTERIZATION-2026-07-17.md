# Envelope Allocation and Execution-Plan Coverage Characterization

Status: completed characterization / no runtime behavior change
Owner: report
Canonical: yes
Exit: completed; next step is a compatibility decision candidate

## Purpose

Characterize the current `src_next/envelope_computation.bqn` and `src_next/plan_rows.bqn` allocation, spending, backing checks, and execution-envelope planned-payment coverage behaviors before changing their monetary or representation owners.

This work is preparation evidence for a later single-journal source migration. It does not select or implement any next runtime behavior.

## Current data flow under observation

```text
Build (or BuildCtx)
  ├── LoadConfig base -> cfg
  ├── BuildEnvelopes (for active envelopes and target)
  │    ├── LatestActualDateInCycle -> as_of (reads journal.tsv directly)
  │    └── For each budget account in accounts.tsv:
  │         ├── allocated: Layer 2 (layer_budget) of Cube (derived from budget_alloc.tsv)
  │         ├── spent: Layer 0 (layer_actual) debits of Cube (derived from journal.tsv)
  │         ├── drawn: Layer 0 (layer_actual) credits of Cube (derived from journal.tsv)
  │         ├── remaining: allocated - (spent - drawn)
  │         └── future_planned_spent: Layer 1 (layer_plan) debits of Cube where date > as_of
  ├── CalcUnassignedRemaining (for unassigned budget pool)
  │    └── remaining: Layer 2 (layer_budget) sum for kind=unassigned budget accounts
  ├── CalcEnvelopeBacking (for backing checks)
  │    ├── funding_base: Layer 0 (layer_actual) closing balance in TBDS (from liquid assets)
  │    ├── allocated_total: sum of remaining of active envelopes
  │    ├── cash_backed_unassigned: funding_base - allocated_total
  │    └── ledger_cash_delta: cash_backed_unassigned - unassigned.remaining
  └── BuildExecutionPlannedCoverage (for execution planned coverage)
       ├── retrieves ExecutionPlannedPaymentsEnvelope from config -> env_label
       ├── env_remaining: envelope.remaining from envelopes list
       ├── plan_rows.BuildBase: reads plan.tsv and journal.tsv directly (source evidence)
       │    └── completed_mask: checks if plan_id exists in journal.tsv
       ├── planned_total: sum of unfinished plan rows (completed_mask = 0)
       └── delta: env_remaining - planned_total
```

## Numeric Owner Table

| Value | Numeric Owner | Primary Data Source | Type of Source |
|---|---|---|---|
| **envelope allocation** | `envelope_computation.bqn` (via `BuildEnvelopes`) | Cube (Layer 2) / `budget_alloc.tsv` | checked Posting IR |
| **envelope allocation (fallback target)** | `envelope_computation.bqn` (via `CalcAllocated`) | `budget_alloc.tsv` (direct parse) | direct TSV reparsing |
| **actual envelope spending** | `envelope_computation.bqn` (via `BuildEnvelopes`) | Cube (Layer 0) / `journal.tsv` | checked Posting IR + Account Metadata |
| **remaining envelope balance** | `envelope_computation.bqn` (via `BuildEnvelopes`) | Derived (`allocated - (spent - drawn)`) | checked Posting IR |
| **future planned spent** | `envelope_computation.bqn` (via `BuildEnvelopes`) | Cube (Layer 1) / `plan.tsv` | checked Posting IR |
| **unassigned budget pool** | `envelope_computation.bqn` (via `CalcUnassignedRemaining`) | Cube (Layer 2) / `budget_alloc.tsv` | checked Posting IR |
| **funding base** | `envelope_computation.bqn` (via `CalcEnvelopeBacking`) | TBDS (closing actual Layer 0) | TBDS closing actuals |
| **envelope planned coverage** | `envelope_computation.bqn` (via `BuildExecutionPlannedCoverage`) | Derived (`env_remaining - planned_open_total`) | Cube + direct TSV reparsing |
| **unfinished planned total** | `plan_rows.bqn` (via `BuildBase` and `WithValues`) | `plan.tsv` and `journal.tsv` (direct parse) | direct TSV reparsing |

## Source-Evidence Owner Table

| Semantic Link / Rule | Primary Owner | Evaluated On | Source of Truth |
|---|---|---|---|
| **envelope name / label mapping** | `account_key.bqn` | `accounts.tsv` | configuration or account metadata |
| **envelope role (`dynamic`/`execution`/`unassigned`)** | `envelope_computation.bqn` | `accounts.tsv` (`envelope_role=` or fallback) | configuration or account metadata |
| **unassigned budget account role** | `envelope_computation.bqn` | `accounts.tsv` (`role=budget`, `kind=unassigned`) | configuration or account metadata |
| **liquid funding accounts selection** | `envelope_computation.bqn` | `accounts.tsv` (`role=asset`, `type=liquid`) | configuration or account metadata |
| **planned payment completion** | `plan_rows.bqn` | `plan_id` existence in `journal.tsv` | source evidence |
| **configured execution envelope** | `config.bqn` | `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` | configuration or account metadata |

## Observed Status / Error Behavior

We characterized the behavior of the current BQN engine across 12 specific test cases:

1. **Normal allocation and spending**:
   - Allocation sums Layer 2 (`layer_budget`) of the Cube (from `budget_alloc.tsv`).
   - Spending sums debits (minus credits) in Layer 0 (`layer_actual`) of the Cube (from `journal.tsv`) where the account's resolved budget matches the envelope's label.
   - Remaining is allocated minus actual spending. Verified correctly.
2. **Empty allocation source**:
   - `budget_alloc.tsv` is empty. Layer 2 is zero, allocation is 0, remaining is `-spending`.
   - Backing diagnostics unassigned remaining is 0. Does not crash the engine.
3. **Completed planned payment**:
   - Excluded from execution planned coverage, but still included in `future_planned_spent` (Layer 1 of Cube) if plan date > `as_of`. The Cube/Layer 1 itself has no completion awareness.
4. **Unfinished planned payment**:
   - Included in both execution planned coverage and `future_planned_spent` (if date > `as_of`).
5. **Unknown account in allocation evidence**:
   - Row is skipped (placed in `skipped_rows` of the Cube) during projection/materialization due to `"unknown_account"` status. It does not affect envelope computation (allocation is not recorded), but can cause backing mismatch warning. No engine exit.
6. **Rejected or invalid amount**:
   - Amount parse fails (`parsed.state ≢ "ok"`), row evidence state is `"error"`, arithmetic proof state is `"unsupported"`, fails proof authorization, `context.bqn` prints `ERROR:` to stdout and exits with status 1.
7. **Missing or structurally unjoinable Posting IR**:
   - Missing fields that are essential (e.g. date, amount) result in `invalid_date` or `invalid_amount` and fail closed (exit 1).
   - Missing or unknown account names result in `unknown_account` status, which is placed in `skipped_rows` but does NOT fail closed (does not exit 1).
   - Length mismatch between evidence and normalized coefficients returns `"normalized_coefficient_length_mismatch"` diagnostic and fails closed (exit 1).
   - Missing required `journal.tsv` source prints `ERROR: posting source missing` and exits 1.
8. **Execution envelope with no matching planned payment**:
   - If there are no planned payments, execution planned status is `"MISMATCH"` (since the envelope remaining is > 0 but unfinished planned total is 0). Rendered as warning, does not crash.
9. **Planned payment with no configured execution envelope**:
   - If there's no configured execution envelope (or config is empty), execution planned status is `"disabled"` or `"unavailable/missing_execution_envelope"`. No engine exit.
10. **Over-allocation**:
    - If unassigned remaining budget is `< 0`, status is `"OVER_ALLOCATED"`. This triggers a warning: `WARNING: 未割当がマイナスです。`. No engine exit.
11. **Insufficient funding/backing**:
    - If `funding_base < allocated_total` (i.e. liquid assets are less than remaining active envelope balances), `cash_backed_unassigned` becomes `< 0`, and the backing status becomes `"OVER_ALLOCATED"`.
    - If `ledger_cash_delta` (the difference between `cash_backed_unassigned` and `unassigned.remaining`) is not 0, status is `"MISMATCH"`.
    - In both cases, the report displays warnings/mismatches, but the engine does NOT fail or exit.
12. **Duplicate or repeated plan identity where applicable**:
    - Duplicate `plan_id` values do not cause error, but are both marked completed or both open, and accumulated in the Cube.

## Compatibility Hazards for a Future Single-Journal Migration

If we migrate to a future single-journal layout, the following behaviors present hazards or require design decisions:

1. **Completion Semantics**:
   - The current Cube (Layer 1) does not check plan completion evidence and sums future plan rows regardless of whether they have already been completed early. A future single-journal layout must define how completion is marked or if completed plans should be projected to a different layer (or omitted).
2. **Direct TSV Parsing vs Checked Posting IR**:
   - The execution planned coverage checks and fallback targets read and parse `plan.tsv` and `journal.tsv` directly using `loader.SplitTsvKeepEmpty`, duplicating the monetary interpretation and validation rules of the checked Posting IR.
   - If we migrate to a single-journal model, these components must transition to querying the checked Posting IR or the Cube.
3. **Mismatches in Backing Checks**:
   - Because `envelope_computation.bqn` performs backing checks between `funding_base` (liquid assets closing balance) and active envelopes, any mismatch in timing or double-entry mapping will result in a `"MISMATCH"` warning.
   - In a single-journal model, the relationship between actual asset accounts and budget/envelope accounts should be structurally verified (e.g. companion transactions) to prevent false warnings.

## Unanswered Design Questions

1. **Durable Budget Declarations**: How should budget allocations (e.g. allocating X to food envelope) be represented in the journal? As non-monetary events, or as balance sheet adjustments to a budget liability/equity?
2. **Plan Completion**: Should plan completion be represented as a metadata tag on actual transactions, or as a state change event in the journal?
3. **Execution Linkage**: How should configured execution envelopes be bound to plans? Currently it is configured globally in `config.tsv` by envelope name. Should this be a property of the plan or the envelope declaration in the journal?

## Explicit Non-goals

- No journal parser implementation.
- No `ledger.journal` file creation.
- No source data migration or conversion.
- No editor changes or source TSV schema changes.
- No automatic envelope repair or writes.
- No production-data access or modification.

## Exact Validation Commands

To execute and verify the characterization results:

```bash
# Run unit tests
bqn tests/test_src_next_envelope_characterization.bqn

# Run the focused check script
bash checks/check-src-next-envelope-characterization.sh

# Run the full check suite
bash tools/check.sh
```

## Verification Evidence

- **Public Fixture Family**: [fixtures/envelope-characterization/](file:///Users/user/Projects/moko/bqn-ledger/fixtures/envelope-characterization/)
- **Unit Tests**: [tests/test_src_next_envelope_characterization.bqn](file:///Users/user/Projects/moko/bqn-ledger/tests/test_src_next_envelope_characterization.bqn)
- **Check Script**: [checks/check-src-next-envelope-characterization.sh](file:///Users/user/Projects/moko/bqn-ledger/checks/check-src-next-envelope-characterization.sh) (integrated into [tools/check.sh](file:///Users/user/Projects/moko/bqn-ledger/tools/check.sh))
