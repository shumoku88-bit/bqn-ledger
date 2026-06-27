# Posting IR Contract

Status: **active contract draft / next ledger engine candidate**
Date: 2026-06-25

This document defines the normalized posting boundary for the next `bqn-ledger` engine path.

The goal is to make source TSV parsing, accounting validation, cube materialization, and report views separable.

```text
source TSV rows
  -> Source Adapter
  -> Posting IR
  -> Posting IR validation
  -> Cube / TBDS
  -> Views / Reports
```

## 1. Scope

Posting IR is an internal, normalized, ledger-like row set.

It is not a new source TSV format. The current source TSV contract remains valid:

```text
journal.tsv / plan.tsv: date, memo, from, to, amount, metadata...
budget_alloc.tsv: current budget allocation schema
accounts.tsv: account metadata
```

Posting IR is allowed to be richer than source TSV, but it must be derived read-only from source files.

## 2. Design goals

- Keep `data/*.tsv` as source of truth.
- Keep source parsing separate from accounting computation.
- Validate account, layer, date, and balance invariants before cube materialization.
- Make future `txn_id` / multi-row grouping support possible without changing report views.
- Make Option 5 TBDS possible by giving it a clean posting input.
- Preserve equivalence with the current cube until an explicit migration decision.

## 3. Non-goals

- Do not change production `data/*.tsv`.
- Do not require a Ledger/Beancount-style source format.
- Do not make UI/editor behavior part of the accounting kernel.
- Do not silently repair invalid rows.
- Do not put household advice concepts such as `daily`, `food`, or `safe` into Posting IR.

## 4. Posting row shape

Each source movement expands to one or more posting rows. For the existing `from/to/amount` source shape, one source row normally expands to two posting rows:

```text
debit:  to account,   +amount
credit: from account, -amount
```

Required fields:

| field | type | meaning |
|---|---|---|
| `source_file` | string | Source file name, e.g. `journal.tsv` |
| `source_row` | number | Zero-based source data row index, excluding header if applicable |
| `source_id` | string | Stable row identifier derived from source row identity |
| `tx_id` | string | Transaction group id; source metadata `txn_id=` if present, otherwise `source_id` |
| `posting_id` | string | Stable id for this posting row, e.g. `source_id:debit` |
| `date` | string | Source date `YYYY-MM-DD` |
| `day_index` | number | Day offset in loaded period / cycle |
| `account_key` | string | Canonical account key string |
| `account_key_index` | number | Index into AccountKey table |
| `layer_name` | string | `actual`, `plan`, `budget`, or `forecast` |
| `layer_index` | number | Layer index used by cube materialization |
| `side` | string | `debit` or `credit` |
| `delta` | number | Signed integer delta; debit positive, credit negative |
| `kind` | string | `income`, `expense`, `transfer`, or `budget` |
| `status` | string | `ok` or fail-closed status |
| `message` | string | Human-readable diagnostic |

Optional fields may be added for provenance, but report views must not depend on optional fields until their contract is documented.

## 5. Identity rules

### `source_id`

`source_id` identifies the source row. If the source row has a stable explicit id, use it. Otherwise derive it deterministically from:

```text
source_file + source_row + date + memo + from + to + amount
```

The exact derivation may be implementation-specific at first, but it must be stable for the same source file content.

### `tx_id`

`tx_id` groups rows that belong to the same real-world transaction.

- If source metadata has `txn_id=...`, use that value.
- Otherwise use `source_id`.
- A single-row transaction is valid.
- Multi-row `txn_id` groups are validated by a separate grouping lint; they do not change per-row posting expansion.

This follows `docs/DECISION_MULTI_POSTING_INVESTIGATION.md` A-1: keep source TSV shape stable, group related source rows using metadata.

### `posting_id`

`posting_id` must be unique within one Posting IR set.

For existing two-sided source rows:

```text
source_id:debit
source_id:credit
```

If a source row later expands to more than two postings, suffixes must remain deterministic.

## 6. Layer mapping

Default mapping:

| source file | layer |
|---|---|
| `journal.tsv` | `actual` |
| `plan.tsv` | `plan` |
| `budget_alloc.tsv` | `budget` |

Unknown source files must fail closed before cube materialization.

## 7. Balance invariants

For every `source_id`, the sum of `delta` over posting rows must be zero unless the row is explicitly rejected before cube materialization.

```text
sum(delta where source_id = X) = 0
```

For every `tx_id`, the sum of `delta` over posting rows should also be zero. With the current two-sided source adapter this should be naturally true. Future multi-row grouping lint may add stricter checks such as date/memo/from consistency.

Posting IR validation must run before cube materialization.

## 8. Fail-closed statuses

Valid rows use:

```text
status = ok
```

Known non-ok statuses:

| status | meaning | cube behavior |
|---|---|---|
| `unknown_account` | `from` or `to` account not found | reject before cube index use |
| `invalid_amount` | amount is missing or not an integer | reject |
| `invalid_date` | date is missing or invalid | reject |
| `unknown_layer` | source file cannot map to a layer | reject |
| `unbalanced_source` | postings for `source_id` do not sum to zero | reject whole source group |
| `out_of_range` | date is outside a selected materialized period/view | keep as valid ledger posting when building ledger-wide state; exclude only from that period view and keep diagnostic |

The engine must not turn these into zero-valued successful rows.

## 9. Cube equivalence requirement

Before replacing the current cube path, the following equivalence must be checked on fixtures:

```text
current source TSV -> current BuildCube
source TSV -> Posting IR -> Cube
```

Expected equality:

- same layer totals
- same per-account actual totals
- same plan totals
- same budget totals where covered
- same skipped / rejected row categories, or documented intentional differences

This check is the first implementation gate for Posting IR adoption.

## 10. TBDS handoff

TBDS consumes validated ledger-wide Posting IR or a cube/index derived from validated Posting IR that preserves enough history to compute opening balances.

TBDS must not parse source TSV directly. If a TBDS field needs source provenance, it should reference Posting IR identity fields (`source_file`, `source_row`, `source_id`, `tx_id`, `posting_id`).

A posting dated before a report period is not invalid. It contributes to TBDS `opening`. A posting inside the report period contributes to `movement`. A posting after the report period is outside that period's accounting report, but remains part of the ledger-wide posting set.

## 11. Current implementation relation

Current `src_next/projection.bqn` already contains a projection row shape close to this contract:

- `source_file`
- `source_row`
- `source_id`
- `tx_id`
- `posting_id`
- `date`
- `side`
- `day_index`
- `account_key`
- `account_key_index`
- `layer_name`
- `layer_index`
- `delta`
- `kind`
- `status`
- `message`

The adoption work is to keep this formal Posting IR boundary stable and add equivalence checks against the current cube path.
