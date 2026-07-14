# Envelope event linkage automation plan

Status: completed
Owner: envelope / editor
Canonical: no; current policies remain `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`, `docs/ENVELOPE_FUNDING_BASE_INVARIANT.md`, and `docs/PRODUCTION_EDITOR_DIRECTION.md`
Exit: archived completion record; ordinary-income linkage must be separately selected through `TODO.md`

## Evidence

Daily use exposed a reproducible synchronization gap:

- an actual fixed planned payment reduced the liquid funding base;
- the configured execution envelope did not decrease;
- an ordinary income increased the funding base but did not enter budget-ledger unassigned;
- the readonly backing diagnostic correctly reported `OVER_ALLOCATED`;
- a human and pit could explain and append adjustment rows, but repeating that reconciliation manually is error-prone.

This evidence reopens one narrow part of `PLAN_COMPLETION_WORKFLOW_DESIGN_INTAKE-2026-07-08.md`. It does not authorize a broad workflow redesign.

## Decision

Automate **event-linked budget proposals**, not unexplained delta balancing.

```text
observed journal/plan event
  -> BQN-owned linkage decision
  -> exact budget row preview
  -> human confirmation
  -> existing checked single-file append
  -> report postcondition
```

The system must not turn an arbitrary backing delta into `budget:opening` adjustment rows. A proposal needs explicit source evidence and a stable identity.

## Selected first implementation slice

Only completed planned payments are selected initially.

When `tools/edit plan finish` successfully appends an actual row:

1. BQN determines whether the selected plan belongs to the configured `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` linkage policy.
2. If linked, BQN emits an exact companion candidate:

   ```text
   budget:<configured execution envelope> -> budget:<configured spent sink>
   ```

3. The candidate carries the same `plan_id` for durable identity.
4. The UI/editor previews the companion and asks for confirmation.
5. Applying the companion uses the existing checked append path for `budget_alloc.tsv`.
6. A retry command can apply a pending companion after the journal append has already succeeded.
7. A matching `plan_id` already present in `budget_alloc.tsv` makes the operation an idempotent no-op, not a duplicate append.

The first slice does not require an atomic rename across `journal.tsv` and `budget_alloc.tsv`. It uses a recoverable saga:

```text
journal append committed
  -> budget companion pending
  -> budget append committed
```

A failure after the journal append must be explicit as `BUDGET_SYNC_PENDING` and leave a retryable proposal. It must never report all work complete merely because the journal append succeeded.

## Why not a generic two-file transaction first

A crash-safe multi-file transaction would require a manifest, two source fingerprints, staged bytes, ordered commit, checked rollback, retry semantics, and failure injection. That is valid future work but is larger than the observed need.

Stable `plan_id` makes a one-file retryable companion safer and smaller:

- journal remains the observed-fact source;
- budget append remains append-only;
- partial completion is visible and recoverable;
- no silent rollback of a valid observed payment is needed because budget synchronization failed.

## Ownership

### BQN

- decide whether a plan completion is linkable;
- resolve configured execution envelope and spent sink;
- validate source plan, completed journal evidence, account/currency compatibility, and existing budget linkage;
- render the exact candidate row;
- return `PENDING`, `APPLIED`, `NOT_LINKED`, or `ERROR` with privacy-safe diagnostics.

### Shell/editor

- invoke the BQN command;
- display preview and confirmation;
- append the exact BQN-rendered row through `safe_append_checked`;
- run the existing report post-check;
- display pending recovery instructions.

Shell must not infer `fixed`, inspect account prefixes, calculate amounts, or construct budget account names.

### UI

- offer the companion after a verified `plan finish` postcondition;
- allow cancellation without claiming synchronization completed;
- keep a standalone retry path available.

## Linkage contract

The first slice is fail-closed.

A proposal is available only when all of the following hold:

- `EXECUTION_PLANNED_PAYMENTS_ENVELOPE` resolves to exactly one execution envelope;
- the configured spent sink resolves;
- the plan has one valid `plan_id`;
- exactly one completed journal actual with that `plan_id` supplies the observed date and amount;
- the source plan is eligible under an explicit BQN-owned policy;
- no budget row already carries the same `plan_id` linkage;
- currency is explicit/resolvable and consistent.

Unknown, duplicate, mismatched, or ambiguous evidence returns `ERROR` and zero candidate rows.

## Income boundary

Ordinary income-to-unassigned linkage is a separate second slice because many legacy income rows lack durable `txn_id` identity. It must not be folded into the first implementation by memo/date/amount guessing.

A later slice may:

- require or generate a stable `txn_id` at journal-add prepare time;
- propose `budget:opening -> budget:<unassigned>` for a confirmed budgetable income event;
- distinguish ordinary income from expense refunds and asset transfers;
- use the same idempotent companion protocol.

Expense refunds already restore a mapped dynamic envelope when recorded as a current-date expense credit. They must not also create an income-to-unassigned companion.

## Non-goals

- no generic `delta -> balancing row` automation;
- no account creation or production metadata migration;
- no silent write or confirmation bypass;
- no automatic linkage by memo text, amount coincidence, or account prefix;
- no change to Canonical Daily Cube shape;
- no broad plan replenishment redesign;
- no ordinary-income automation in the first slice;
- no multi-file atomic writer in the first slice.

## Verification

Use synthetic fixtures only for implementation checks.

Required cases:

1. eligible completed plan produces one exact budget companion;
2. actual amount override is used instead of planned amount;
3. existing matching `plan_id` returns idempotent applied/no-op;
4. missing/duplicate plan ID fails closed;
5. missing/duplicate completed journal evidence fails closed;
6. missing/invalid execution envelope or spent sink fails closed;
7. dry-run changes neither source file;
8. journal-success/budget-failure leaves a visible retryable pending state;
9. retry appends once and the envelope backing/report postcondition is checked;
10. unrelated plan completion remains `NOT_LINKED` with zero writes.

## Implementation result

Completed on 2026-07-14:

- `src_edit/plan_budget_sync_cmd.bqn` owns the fail-closed proposal and idempotency decision;
- `tools/edit plan budget-sync --id ...` provides dry-run, confirmation, apply, and retry;
- `tools/plan-finish-replenish-ui.sh` invokes the companion only after the CLOSED postcondition;
- cancellation/failure remains visible as `BUDGET_SYNC_PENDING`;
- `checks/check-edit-bqn-plan-budget-sync.sh` covers actual-amount use, dry-run, idempotent retry, unrelated plans, ambiguity, and stale failure followed by retry;
- current editor/envelope/code-map docs route the operational behavior;
- ordinary-income linkage remains unselected.

## Completion criteria

The selected slice is complete when:

- the BQN proposal owner and synthetic command-level checks exist;
- a public editor retry command exists;
- plan-finish UI offers the confirmed companion after verified completion;
- duplicate/retry and injected failure checks pass;
- `docs/BQN_EDITOR_USAGE.md`, `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`, `docs/AI_CODEMAP.md`, and the relevant checks are updated;
- `rtk bash ./tools/check.sh` passes;
- the plan is archived and `TODO.md` routes ordinary-income linkage as a separate unselected candidate.
