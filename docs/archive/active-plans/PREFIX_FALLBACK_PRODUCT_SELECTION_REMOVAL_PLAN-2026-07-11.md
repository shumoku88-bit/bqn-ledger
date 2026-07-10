# Prefix Fallback Product-Selection Removal Plan

Status: active plan
Owner: envelope
Canonical: no; semantic decision: `../audits/PREFIX_FALLBACK_CURRENT_MAIN_RECONCILIATION-2026-07-11.md`
Exit: retire after the selected runtime slice is merged, post-implementation evidence confirms the boundary, and routing returns to Currency Stage 2 B2

Date: 2026-07-11

## Purpose

Implement the narrow current-main decision that explicit `role=` metadata owns account-role classification while prefix-shaped missing-role accounts remain diagnostic evidence only.

This plan authorizes one finite runtime safety slice before returning to the already authorized Currency Stage 2 B2 route.

It does not reopen the broad Household Policy campaign and does not demote or replace B2.

## Selected meaning

```text
explicit role metadata = classification owner
prefix-shaped missing role = diagnostic signal only
prefix fallback != product/accounting/envelope selection authority
```

Missing role stays missing. A familiar account-name prefix must not silently establish role eligibility for product calculations.

## Prerequisite evidence

Current-main reconciliation:

- `docs/archive/audits/PREFIX_FALLBACK_CURRENT_MAIN_RECONCILIATION-2026-07-11.md`

Key evidence already established:

- roadmap/history claim full Prefix Fallback removal;
- `account_key.bqn` preserves missing role as empty metadata;
- `readiness_check.bqn` reports missing role explicitly;
- `household_metadata.bqn` can observe prefix-shaped missing-role accounts without using them as its actual expense mask;
- `household_policy.bqn` still lets fallback influence classified expense summary counts;
- `envelope_computation.bqn` still lets fallback influence runtime/product selection;
- inspected green-path fixtures use explicit roles;
- stale test comments still describe fallback admission that current fixture data does not exercise.

## Authorized runtime slice

### 1. `envelope_computation.bqn`: remove product-selection fallback

Change only the role-eligibility masks used for product selection.

Required result:

```text
ExpenseAccountMask = explicit role=expense only
BudgetAccountMask  = explicit role=budget only
```

The following consumers must therefore stop admitting missing-role accounts solely by prefix shape:

- `SelectedExpenseIndices`;
- `UnassignedBudgetAccountIndices`;
- target budget-account selection;
- `BuildEnvelopes` budget index selection.

### 2. `household_policy.bqn`: make classified expense counts explicit-role-owned

Required result:

```text
expense_accounts = explicit role=expense only
```

A separate `prefix_fallback_expense_account_count` diagnostic may remain if it continues to provide truthful visibility.

The fallback diagnostic must not inflate fields whose names claim classified expense accounts, including:

- expense account count;
- expense-with-budget count;
- budget-group counts;
- spend-class counts.

Posting-derived amount totals remain out of scope unless a focused test shows they are coupled to the fallback mask.

### 3. `household_metadata.bqn`: preserve diagnostic-only observation

Do not convert diagnostic counters into role classification.

Expected stance:

```text
prefix-shaped missing role may be counted
expense_mask remains explicit role=expense
```

Code change is not required unless necessary to make comments/naming truthful.

### 4. Correct stale test commentary

At minimum, correct comments that currently claim:

- `expenses:fallback` lacks role metadata when the fixture supplies `role=expense`;
- `fixtures/src-next-golden` expense accounts are prefix-fallback accounts when they carry explicit roles.

Do not change fixture data merely to preserve stale comments.

### 5. Add focused negative evidence

Add the smallest fixture/test evidence that proves the selected boundary.

Required cases:

1. **missing-role prefixed expense candidate**
   - account name starts with `expenses:`;
   - `role=` is absent;
   - other metadata may make it look selectable;
   - it remains visible as missing role / fallback-shaped diagnostic evidence;
   - it is not admitted by envelope expense selection.

2. **missing-role prefixed budget candidate**
   - account name starts with `budget:`;
   - `role=` is absent;
   - `kind=` may look envelope-like or unassigned;
   - it remains visible as missing role / fallback-shaped diagnostic evidence;
   - it is not admitted as a budget/envelope account through role selection.

Prefer one compact fixture that covers both cases if it stays readable.

## Allowed files

Primary runtime owners:

- `src_next/envelope_computation.bqn`
- `src_next/household_policy.bqn`

Diagnostic owner only if needed:

- `src_next/household_metadata.bqn`

Focused tests/checks/fixtures as required:

- `tests/test_src_next_envelope_computation.bqn`
- `tests/test_src_next_household_policy.bqn`
- `tests/test_src_next_household_metadata.bqn`
- one narrow fixture under `fixtures/`
- an existing focused check if its assertions need truthful updates

Routing/docs only where required by repository policy:

- this plan
- post-implementation verification snapshot
- plan inventory / TODO routing if touched

## Forbidden scope

Do not:

- edit real source TSV or `LEDGER_DATA_DIR` data;
- broadly refactor `envelope_computation.bqn`;
- split `context.bqn`;
- create a compatibility module;
- remove every string-prefix operation;
- change `BudgetLabel`, `CleanName`, or presentation trimming merely because they inspect prefixes;
- change Posting IR, Cube, TBDS, projection authorization, or currency proof;
- change Currency Stage 2 B2 semantics;
- add telemetry, JSONL operation logging, lint, registry, or CI gate;
- migrate all fixtures mechanically.

## Acceptance criteria

### Semantic

- explicit `role=` is the only owner of expense/budget role eligibility in the touched product-selection paths;
- missing-role prefixed accounts are not silently admitted;
- diagnostic visibility for prefix-shaped missing-role accounts remains available where intentionally preserved;
- missing role remains fail-visible through existing readiness/diagnostic surfaces.

### Regression

- current explicit-role envelope fixture behavior remains unchanged;
- current household-policy explicit-role counts remain unchanged for explicit-role fixtures;
- no source TSV schema change;
- no Currency B2 behavior change.

### Negative evidence

- focused fixture/test proves missing-role `expenses:` candidate is not selected;
- focused fixture/test proves missing-role `budget:` candidate is not selected;
- diagnostic/readiness evidence still exposes the missing-role condition.

### Verification

Run at minimum:

```text
rtk bash ./tools/check.sh
```

Also run the directly affected BQN unit tests / focused checks before the full suite when practical.

## Actual-diff self-review requirement

Before the first push / PR, compare intended scope with the actual proposed diff.

Confirm:

- no broad envelope refactor;
- no unrelated prefix helper deletion;
- no source TSV changes outside fixtures;
- no B2 changes;
- no diagnostic counter removal unless explicitly justified;
- negative evidence exists for both expense and budget product-selection paths.

## Completion and routing

After merge:

1. perform one post-implementation claim-to-evidence verification;
2. retire this plan as completed;
3. update routing so this audit-promoted safety slice is no longer active;
4. return to the already authorized next Currency Stage 2 route:

```text
Currency Stage 2 Slice B2: Snapshot Arithmetic Evidence
```

unless new concrete evidence from this implementation requires a separate explicit decision.
