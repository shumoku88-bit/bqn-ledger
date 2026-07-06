# Plan Temporal × Execution Envelope Coverage Join - 2026-07-06

Status: active plan / docs-only / no runtime implementation in this PR
Owner: envelope
Canonical: no; canonical paths: `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`, `docs/REPORT_CONTRACTS.md`
Exit: after one approved aggregate temporal coverage slice is implemented or rejected; then move this plan to completed/historical routing

## Selected from

`TODO.md` active work:

```text
Plan temporal status × envelope coverage
```

Current baseline:

- `src_next/plan_status.bqn` owns pure `future` / `due` / `overdue` / `completed` classification with explicit `as_of`
- `src_next/planned_payments.bqn` builds current-cycle plan rows, completion evidence, compatibility `as_of`, temporal statuses, open rows, and `open_total`
- `src_next/envelope_computation.bqn` already has an optional readonly execution-plan coverage diagnostic
- source TSV remains authoritative and must not be mutated by this work

## Decision

The join has practical value, but the first supported meaning must be **aggregate-only**.

Adopt one first derived view:

```text
Temporal execution coverage snapshot
```

Do **not** claim, with the current schema/config, that an individual plan row is funded by a specific execution envelope.

Rejected first-slice wording:

```text
plan wifi is funded
this overdue plan has reserved money
plan_id=X is covered by envelope Y
```

Those statements require a stronger identity/scope contract than the repository currently has.

Allowed first-slice questions:

```text
At explicit as_of, how much open planned amount is overdue / due / future?
How much remains in the configured execution envelope?
How does that one aggregate remaining amount compare with aggregate temporal buckets?
What plan-selection scope was used for the comparison?
```

## Why this join is useful

The repository already separates two meanings:

```text
plan temporal projection
  what is expected
  when it is expected
  whether completion evidence exists

execution envelope
  how much budget-layer funding remains reserved for execution
```

A readonly join can answer a new operational question without moving ownership:

```text
plan temporal rows
  ×
execution envelope remaining
  ->
aggregate temporal funding snapshot
```

This can reveal cases such as:

```text
overdue amount exists while execution remaining is positive
due amount exists while total execution remaining is short
future amount dominates the configured pool
all open planned amount is collectively covered
```

These are useful observations, but they are not per-plan allocation claims.

## Current implementation evidence

### 1. Temporal status already has an independent owner

`src_next/plan_status.bqn` classifies:

```text
completed
future
due
overdue
```

from:

```text
completed evidence
plan_date
explicit as_of
```

It imports no envelope module and reads no envelope config.

This independence must remain.

### 2. Planned report already builds richer current-cycle rows

`src_next/planned_payments.bqn` currently owns report-side assembly of:

```text
plan_id
parsed row fields
completion matching
compatibility as_of
temporal status
open_mask
open_total
```

Human and JSON renderers consume the same `BuildViewModel` result.

### 3. Envelope coverage already exists, but it is time-blind

`src_next/envelope_computation.bqn` currently supports:

```text
EXECUTION_PLANNED_PAYMENTS_ENVELOPE=<label>
```

and computes:

```text
named envelope remaining
minus
unfinished in-cycle planned total
```

with readonly output:

```text
envelope remaining
planned open total
delta
OK / MISMATCH
planned rows
```

The current coverage rows do not carry `future` / `due` / `overdue` status.

### 4. Current coverage scope is broader than the config name may suggest

This is the most important finding from this review.

Current `BuildExecutionPlannedCoverage`:

1. selects all `plan.tsv` rows in the current cycle
2. selects current-cycle journal rows
3. marks plan rows completed through plan identity matching
4. keeps all unfinished plan rows
5. sums all unfinished amounts
6. compares that total with one configured envelope

There is no current filter by:

```text
plan category
from account
to account
plan metadata
envelope label
explicit plan-to-envelope link
```

Therefore a config such as:

```text
EXECUTION_PLANNED_PAYMENTS_ENVELOPE=固定費予定
```

currently means, operationally:

```text
compare envelope 固定費予定
against
all unfinished in-cycle plan rows
```

It does **not** prove:

```text
compare 固定費予定
against only plans explicitly linked to 固定費予定
```

The current fixture is clean because its unfinished rows are both fixed-payment examples (`wifi`, `povo`). That fixture does not prove safe behavior for a mixed `plan.tsv` containing unrelated open plans.

## Second important finding: open-plan meaning is duplicated

Current repository ownership is not yet singular.

`src_next/planned_payments.bqn` independently does:

```text
PlanId
current-cycle plan selection
current-cycle journal selection
completion matching
open_mask
open_total
```

`src_next/envelope_computation.bqn` independently does:

```text
PlanId
current-cycle plan selection
current-cycle journal selection
completion matching
open rows
planned_open_total
```

This means the repository currently has two implementations of closely related open-plan semantics.

A temporal coverage join must not introduce a third implementation.

## Fixture evidence

Current fixture:

```text
fixtures/src-next-execution-plan-coverage
```

contains:

```text
completed plan:
  2026-01-02 paid_fixed 100 plan_id=paid-fixed

unfinished plans:
  2026-01-05 wifi 3000 plan_id=wifi
  2026-01-06 povo 330 plan_id=povo
```

The journal contains completion evidence only for `paid-fixed`.

The budget allocation contains:

```text
budget:unassigned -> budget:固定費予定 3330
```

and config contains:

```text
EXECUTION_PLANNED_PAYMENTS_ENVELOPE=固定費予定
```

The existing check proves:

```text
envelope remaining = 3330
unfinished planned total = 3330
delta = 0
status = OK
```

But with current planned-report compatibility `as_of`, latest actual date is `2026-01-02`, so `wifi` and `povo` are temporally future rows.

The fixture therefore proves aggregate open-total equality. It does not prove overdue/due coverage semantics or per-plan funding identity.

## First derived view contract

Name:

```text
Temporal execution coverage snapshot
```

Conceptual inputs:

```text
plan rows with one authoritative temporal/open interpretation
explicit as_of used by those rows
configured execution envelope label
configured execution envelope remaining
explicit plan-selection scope
```

Conceptual output:

```text
as_of
envelope_label
envelope_remaining
selection_scope
overdue_total
due_total
future_total
open_total
delta_to_all_open
```

Optional counts may be added only if they come from the same row projection:

```text
overdue_count
due_count
future_count
open_count
```

First-slice `selection_scope` must be explicit.

For compatibility with current behavior:

```text
selection_scope = all_open_in_cycle
```

Do not hide this assumption behind the envelope label.

## Interpretation rules

### `open_total`

Must equal:

```text
overdue_total + due_total + future_total
```

for the same row set and same `as_of`.

### `delta_to_all_open`

```text
envelope_remaining - open_total
```

This is an aggregate comparison only.

A non-negative value may support wording such as:

```text
configured envelope remaining is sufficient for the aggregate selected open-plan total
```

It must not support wording such as:

```text
every plan has its own reserved allocation
```

### Temporal buckets

`overdue_total`, `due_total`, and `future_total` must come from the existing temporal status meaning.

Do not redefine date relations in envelope code.

### No new status vocabulary in the first slice

Do not invent:

```text
FUNDED
UNFUNDED
URGENT_FUNDED
LATE_COVERED
```

The first slice should expose grounded amounts and existing status meanings.

## Ownership decision

### Temporal meaning

Owner remains:

```text
src_next/plan_status.bqn
```

The join must not derive `due` / `overdue` / `future` from envelope state.

### Plan row assembly

Current duplication must be reduced or consumed through one owner before adding another independent open-plan calculation.

Preferred direction:

```text
one reusable current-cycle plan projection
  -> planned report
  -> temporal execution coverage join
```

The exact module name is deferred to Execution.

Possible shape:

```text
current-cycle plan rows
  + completion evidence
  + explicit/caller-owned as_of
  -> rows with plan_id, amount, status
```

The existing `planned_payments.BuildViewModel` is current evidence and may guide extraction, but a report renderer must not silently become the permanent semantic dependency of envelope computation.

### Envelope meaning

Owner remains:

```text
src_next/envelope_computation.bqn
```

for envelope balances and current configured aggregate coverage diagnostic.

The join should consume envelope remaining; it must not move envelope balance calculation into the plan projection.

## Recommended execution sequence after plan review

### Slice A: remove the semantic seam before the join

Behavior-preserving only.

Goal:

```text
one current-cycle plan-row owner
```

Acceptance:

- preserve current plan/journal matching compatibility
- preserve current `as_of` defaulting behavior
- preserve human and JSON planned output
- preserve current open/completed grouping and `open_total`
- preserve existing execution coverage totals
- do not modify source TSV
- do not add link metadata
- do not add new statuses

### Slice B: add the aggregate temporal coverage snapshot

Only after Slice A is stable.

Goal:

```text
overdue / due / future totals
  ×
configured execution envelope remaining
```

Acceptance:

- explicit `as_of`
- explicit `selection_scope=all_open_in_cycle` for compatibility
- no per-plan funded claim
- no source mutation
- no automatic correction
- no plan/envelope auto-generation
- human and machine meanings remain aligned if both surfaces are added

## Explicitly deferred questions

Do not solve these in the first join slice:

```text
explicit plan-to-envelope link metadata
multiple execution envelopes
one plan funded by multiple envelopes
one envelope funding a subset of plans
allocation priority among overdue / due / future rows
partial funding of one plan
recurrence
wall-clock today migration
budget_pool=main implementation
automatic execution-envelope consumption
```

These are real questions, but they should not be hidden inside a small derived view.

## Acceptance criteria for this Planning stage

This docs-only plan is successful if review agrees that:

1. the join has operational value
2. first meaning is aggregate-only
3. row-level funded claims are rejected without stronger linking semantics
4. current `all_open_in_cycle` scope is made explicit
5. duplicated open-plan semantics are recognized as a seam to reduce before adding another calculation
6. the first derived view is exactly one temporal coverage snapshot
7. runtime code, source TSV, live config, fixtures, and checks remain unchanged in this PR

## Non-goals of this PR

Do not modify:

```text
src_next/plan_status.bqn
src_next/planned_payments.bqn
src_next/envelope_computation.bqn
src_edit/
tools/report
source TSV
live config
fixtures
checks
```

Do not add metadata to real data.

## Review question

Approve or reject this narrow direction:

```text
first reduce duplicated open-plan ownership
then add one aggregate temporal execution coverage snapshot
with explicit all_open_in_cycle scope
and no per-plan funded claim
```
