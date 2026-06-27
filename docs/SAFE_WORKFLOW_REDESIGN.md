# Safe Workflow Redesign

Status: plan completion apply mode implemented (safe append to journal.tsv, dynamic resolution on plan_id)
Updated: 2026-06-20 (Implemented and verified plan finish apply in Go editor)

This document resets the design for two features:

- completing a planned row into `journal.tsv` (Decided: keep in plan.tsv, filter in UI)
- viewing historical cycles (Design Proposal: config-driven dynamic resolution using as_of)

Neither feature may be re-enabled until its acceptance criteria and fixtures pass.

## 1. Safety boundary

### Plan completion

`tools/finish.go` is preview-only.

The current implementation:

- selects one exact `plan.tsv` data row
- requires an explicit actual date
- validates the date, integer amount, and account names
- prints a proposed `journal.tsv` row
- removes `recur`, `months`, `anchor`, and `offset` from that proposal
- preserves `series` and other tax/receipt/note metadata
- leaves `journal.tsv` and `plan.tsv` unchanged

Usage:

```sh
go run tools/finish.go
go run tools/finish.go --index 1 --actual-date 2026-06-11
go run tools/finish.go --list
```

It must not write either source-of-truth file until the transaction and
recovery behavior is designed.

### Historical cycles

`past-cycle`, its aliases, and `--offset` are disabled.

The previous prototype treated missing income anchors as sentinel dates. That
could turn an unavailable historical cycle into an all-history total. A missing
boundary must produce an explicit unavailable result, never a wider interval.

### Zero-sum validation

Runtime warnings inside report generation are not the validation boundary.
Machine-oriented stdout must remain clean. Zero-sum failures belong in strict
validation or dedicated checks that exit nonzero and identify the source event.

## 2. Historical cycle contract (Design Proposal)

The resolved cycle period (start, end_exclusive) must be determined dynamically based on the observer point `as_of` and the default or overridden `offset` using configurations in `cycle.tsv`.

### Configuration in cycle.tsv

`cycle.tsv` defines:
- `mode`: `incomeAnchor` | `calendarMonth` | `fixed`
- `income_account`: Account name used as anchor (e.g. `income:年金`)
- `offset`: Default fallback offset (usually `0`)

### BQN Resolver Signature Change

Change [cycle.bqn](file:///Users/user/Projects/moko/bqn-ledger/src/core/cycle.bqn)'s signature to explicitly accept `as_of_dn` (8-digit integer date):

```bqn
ResolveFrom ← { cycle_file ResolveFrom args }
# args: ⟨jr_rows, pl_rows, as_of_dn, offset_override⟩
```

### Resolution Logic

- **`incomeAnchor` Mode**:
  1. Combine journal income anchors `jr_dns` (where `date <= as_of_dn`) and future plan anchors `pdns` (where `date > max(jr_dns)`) to form a complete timeline `all`.
  2. Filter `all` to contain only dates `all <= as_of_dn`.
  3. Sort `all` descending. The 0-th element is the start of the current cycle (`offset=0`).
  4. The start date of the target cycle is the `offset`-th element in the filtered list.
  5. The end date (exclusive) is the `(offset - 1)`-th element in the timeline `all` (or `99999999` if it extends to infinity).
  6. If the target index is out of bounds (insufficient history), return an explicit `unavailable` status instead of falling back to default values.
- **`calendarMonth` Mode**:
  1. Resolve the year and month of `as_of_dn` (`base_ym`).
  2. Subtract `offset` months from `base_ym` to find the target month.
  3. `start` is the 1st day of the target month.
  4. `end_exclusive` is the 1st day of the immediately following month.

### Required fixtures:

- `fixtures/historical-cycle`:
  - Contains two complete historical cycles bounded by three income-anchor events (e.g., `2026-02-13`, `2026-04-15`, `2026-06-15`).
  - Verify that running report with `--as-of 2026-03-01` resolves the current cycle window to `[2026-02-13, 2026-04-15)`.
  - Verify that running report with `--as-of 2026-05-01 --offset 1` resolves to the same past cycle.
- only one known anchor
- offset beyond available history
- duplicate income rows on one anchor date
- `as_of` before, inside, and after recorded cycles
- end-exclusive transaction on the next anchor date

## 3. Plan completion contract

### Decided Workflow: Complete plans remain in plan.tsv
To resolve the conflict between ToDo-like completion and Residual history, the plan lifecycle is managed as follows:
- **No deletion**: Plans are **never** deleted from `plan.tsv` upon completion.
- **Automatic Match**: When a matching `plan_id` is found in `journal.tsv` (actual record), the engine marks the plan as `completed`.
- **Filtering**:
  - The human report section `planned` (future payments) automatically filters out `completed` plans, keeping it clean as a ToDo list of active plans.
  - The Go editor CLI/UI will similarly filter out completed plans by checking `plan_id` presence in `journal.tsv` by default.
  - The `residual` view retains these completed plans to correctly calculate planned vs. actual differences.

### Apply mode contract (For future Go editor implementations)
Before an apply mode is implemented:
- Validate all proposed files before replacement
- Write temporary files in the same filesystem
- Preserve file permissions
- Refuse stale inputs
- Provide a recoverable operation record
- Be safe to retry without duplicate journal entries
- Pass failure-injection tests after each write/rename step

## 4. Implementation order

1. Keep both features disabled.
2. Update BQN `ResolveFrom` signature in [cycle.bqn](file:///Users/user/Projects/moko/bqn-ledger/src/core/cycle.bqn) to accept `as_of` and implement dynamic anchor/calendar month resolving.
3. Update callers in `report_engine.bqn` and views to pass `as_of` to the cycle resolver.
4. Remove dormant prototype calculations after the public quarantine is stable.
5. Add historical-cycle fixtures and verify the pure resolver.
6. [x] Keep the preview-only plan completion command covered by output and no-mutation fixture checks.
7. [x] Two-file transaction avoidance: Adopt dynamic resolution using plan_id existence in journal.tsv. This avoids mutating plan.tsv completely, simplifying transaction safety to a single-file append on journal.tsv.
8. [x] Add apply mode to plan finish (delegating to safe append infrastructure).

## 5. Re-enable gate

Re-enabling requires:

- `./tools/check.sh` passes
- dedicated fixture checks are included in `tools/check.sh`
- docs and public-field drift checks pass
- no source-of-truth mutation occurs in preview mode
- [x] apply mode has recovery and retry tests (accomplished via Go editor's robust atomic write, backup, and stale check tests)

