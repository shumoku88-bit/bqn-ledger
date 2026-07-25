# TBDS Contract

Status: current purpose-specific accounting-state contract
Owner: accounting projection / report
Updated: 2026-07-25

TBDS means **Trial Balance Dataset**. It is a period-aware accounting-state view built from checked ledger-wide Posting IR alongside, not underneath, the Canonical Daily Cube.

```text
checked ledger-wide Posting IR
  -> TBDS(period, as_of)
       -> opening
       -> debit movement
       -> credit movement
       -> net movement
       -> closing
  -> accounting reports and household views
```

A period or cycle is a report query boundary, not a source loading boundary.

## Purpose

TBDS gives report consumers one structured account-state relation instead of requiring each report to recompute opening, movement, and closing semantics.

TBDS owns accounting-state meaning. It does not own source parsing, editor behavior, report text layout, advice, valuation, FX, or country-specific tax rules.

## Input and admission

Input is checked ledger-wide posting facts plus an explicit period and resolved AccountKey domain.

TBDS admission currently requires:

- `status = ok`;
- a resolved `account_key_index`;
- a valid current Layer coordinate.

Temporal treatment differs from Cube admission:

- rows dated before `period_start` contribute to `opening`;
- rows inside `[period_start, period_end_exclusive)` contribute to movement;
- later rows do not contribute to this TBDS period.

Therefore Cube out-of-period exclusion and TBDS period splitting must not be collapsed into one undifferentiated rejection policy.

## Row shape

One TBDS row represents one `Period × AccountKey × Layer` state.

| field | meaning |
|---|---|
| `period_id` | Stable selected-period label |
| `period_start` | Inclusive start |
| `period_end_exclusive` | Exclusive end |
| `as_of` | Observation boundary |
| `account_key` / `account_key_index` | Resolved account coordinate |
| `account_name` | Human account name |
| `currency` | Account commodity code |
| `type` / `role` | Accounting metadata |
| `layer_name` / `layer_index` | Current Layer coordinate |
| `opening` | Sum of valid deltas before the period |
| `debit_movement` | Debit-side delta sum in the period |
| `credit_movement` | Credit-side delta sum in the period |
| `movement` | `debit_movement + credit_movement` |
| `closing` | `opening + movement` |
| `status` / `message` | Availability and diagnostics |

Policy metadata such as `budget`, `budget_group`, and `spend_class` may accompany rows, but they are not automatically core accounting axes.

## Measures and invariants

Amount is a scalar measure, not an axis.

```text
Period × AccountKey × Layer × Measure -> exact amount
```

Current measures are `opening`, `debit_movement`, `credit_movement`, `movement`, and `closing`.

For every successful row:

```text
opening  = sum(delta where date < period_start)
movement = debit_movement + credit_movement
closing  = opening + movement
```

For a balanced layer across all admitted accounts:

```text
sum(movement) = 0
```

Numeric zero means zero. It must not stand in for missing, invalid, or unavailable evidence.

## Provenance

Current TBDS rows summarize contributor identity away. Source-level provenance remains reachable through checked posting rows. A report requiring posting IDs, source lines, rejection evidence, or transaction linkage must retain or join that evidence explicitly rather than treating TBDS as its owner.

## Exact sparse grouping experiment

`src_next/exact_sparse_grouping.bqn` can reproduce TBDS-like layer/account/side movement grouping from explicit exact keys and values. This is evidence that Cube and TBDS share a small accumulation pattern.

It does **not** make their semantics identical:

- TBDS owns pre-period opening and period split;
- debit and credit movement are distinct measures;
- AccountKey and Layer admission remain TBDS concerns;
- commodity compatibility must be decided before grouping or included in the key;
- contributor identity remains a separate sidecar.

No production `tbds.Build` replacement is made by the experiment.

## Relationship to Canonical Daily Cube

The Canonical Daily Cube is a dense selected-period `Day × AccountKey × Layer` view useful for daily replay and trend consumers. TBDS is a long accounting-state relation useful for balances and period reports.

Both are purpose-specific projections from checked posting facts:

```text
checked Posting IR
  -> dense Day Cube
  -> TBDS period state
  -> direct evidence-sensitive calculations
```

A cycle-bounded dense Cube cannot by itself reconstruct opening balances after pre-period facts have been discarded.

## Report use

| Report kind | TBDS measure |
|---|---|
| Trial Balance | opening, debit movement, credit movement, movement, closing |
| Balance Sheet / Snapshot / Balances | closing |
| Income Statement / Cycle Summary | movement |

Views may filter by period, account metadata, Layer, or an explicitly selected compatible domain. They should not silently recompute coordinates or add values across commodities.

## Failure behavior

Allowed states remain:

- `ok`: validated value is available;
- `warn`: value is available with a non-blocking diagnostic;
- `error`: value must not be presented as successful;
- `unavailable`: required input is absent or not implemented.
