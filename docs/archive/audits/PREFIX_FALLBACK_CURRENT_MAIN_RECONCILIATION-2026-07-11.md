# Prefix Fallback Current-Main Reconciliation

Status: audit snapshot
Owner: docs
Canonical: no; current meaning remains owned by current contracts, selected plans, and runtime owners
Exit: archive as evidence after one finite follow-up decision/implementation route is selected or this finding is superseded

Date: 2026-07-11
Current-main baseline reviewed: `f781eaa32b0a0c5e800012f80a2a062ffb8cb500`
Source trigger: `docs/archive/audits/EXTERNAL_STATIC_AUDIT_REASSESSMENT_SOURCE-2026-07-11.md`

## Purpose

Reconcile the external-audit Prefix Fallback finding against current `main` without treating the audit report as implementation authority.

This review asks one narrow question:

```text
When account `role=` metadata is missing, where may an account-name prefix
still influence meaning on current main?
```

This document is evidence and a selected semantic direction. It does not itself change runtime behavior.

## Non-goals

- no source TSV edits;
- no broad `context.bqn` or `envelope_computation.bqn` decomposition;
- no compatibility framework or new helper registry;
- no removal of every use of strings such as `expenses:` or `budget:`;
- no change to Currency Stage 2 B2 semantics;
- no assumption that label trimming or display cleanup is role inference;
- no runtime change in this review slice.

## Executive result

The external-audit finding is `confirmed-current`, but the current state is not one uniform fallback contract.

Three different meanings coexist:

1. **diagnostic observation** of prefix-shaped accounts with missing role metadata;
2. **diagnostic summary classification** that still lets a missing-role prefix contribute to expense-account counts;
3. **runtime/product selection** that still lets a missing-role prefix participate in envelope account selection.

The selected semantic direction is:

```text
explicit role metadata = classification owner
prefix-shaped missing role = diagnostic signal only
prefix fallback != product/accounting/envelope selection authority
```

This is the narrow C-like route from the reassessment discussion: preserve useful visibility where justified, but do not let a prefix silently establish account role for product calculations.

## Current-main evidence

### 1. Long-term roadmap claims full removal

`docs/ENGINEERING_ROADMAP.md` states that Prefix Fallback was completely removed and that `accounts.tsv` `role=` metadata is applied strictly.

That statement is stronger than current runtime reality.

Classification: `confirmed-current drift`.

### 2. Account metadata resolution keeps missing role explicit

`src_next/account_key.bqn` resolves missing role metadata to the empty string.

Its own boundary comment says callers may apply documented fallback only where a fallback is explicitly part of the `src_next` contract.

Therefore `account_key.bqn` itself does not establish prefix-derived role semantics.

Classification: `explicit metadata owner preserved`.

### 3. Readiness treats missing role as missing metadata

`src_next/readiness_check.bqn`:

- excludes `""` from valid roles;
- reports missing-role accounts explicitly;
- derives expense metadata checks from explicit `role=expense`.

This is consistent with an explicit-role policy and fail-visible missing metadata.

Classification: `explicit-role evidence`.

### 4. `household_metadata.bqn` observes fallback candidates but does not use them as expense selection

Current code computes:

- `prefix_fallback_expense`;
- `prefix_fallback_income`;
- `prefix_fallback_asset`;
- `prefix_fallback_liability`;
- `prefix_fallback_budget`.

But its actual expense selection is:

```text
expense_mask <- role_expense
```

The fallback masks feed diagnostic counts, not `expense_mask`.

Classification: `diagnostic-only observation`.

Selected treatment:

- may remain as visibility evidence if tests and wording are truthful;
- must not be described as a working expense-classification fallback;
- stale comments/tests should not claim fallback admission when fixtures use explicit roles.

### 5. `household_policy.bqn` still lets fallback affect summary classification

Current code builds:

```text
expense_accounts <- role_expense OR prefix_fallback
```

That mask affects:

- expense account count;
- expense-with-budget count;
- budget-group counts;
- spend-class counts.

The posting-derived amount totals below use posting `kind` and group metadata rather than this mask, so the observed fallback is not the owner of Posting IR or cube arithmetic.

Classification: `diagnostic/product-summary semantic fallback`.

Selected direction:

- explicit role should own expense classification;
- the separate fallback count may remain as diagnostic visibility;
- fallback should not inflate fields whose names claim expense-account classification.

### 6. `envelope_computation.bqn` still uses fallback in runtime/product selection

Current code defines:

```text
ExpenseAccountMask = explicit role=expense OR missing role + expenses: prefix
BudgetAccountMask  = explicit role=budget  OR missing role + budget: prefix
```

Those masks are consumed by runtime paths including:

- `SelectedExpenseIndices`;
- `UnassignedBudgetAccountIndices`;
- target budget-account selection;
- `BuildEnvelopes` budget index selection.

This is not merely a diagnostic counter. A missing-role account with a matching prefix can still become eligible for envelope/product computation.

Classification: `confirmed-current product/runtime fallback`.

Selected direction:

- do not preserve this as silent role inference;
- remove it only through a separate finite runtime slice with focused negative evidence;
- keep unrelated label extraction and display cleanup out of that slice.

### 7. Current fixtures do not prove fallback necessity

Two inspected tests contain stale fallback-oriented comments:

- `tests/test_src_next_household_metadata.bqn` describes `expenses:fallback` as lacking metadata;
- the same test describes `fixtures/src-next-golden` expense accounts as prefix-fallback accounts.

Current fixture files instead carry explicit roles:

- `fixtures/src-next-household-mapping-policy/accounts.tsv` has `expenses:fallback role=expense`;
- `fixtures/src-next-golden/accounts.tsv` has explicit `role=expense` on expense accounts;
- `fixtures/src-next-envelope-computation/accounts.tsv` uses explicit `role=expense` and `role=budget`.

Therefore current green-path fixtures do not establish a compatibility requirement for runtime fallback.

Classification: `stale test commentary / insufficient fallback-necessity evidence`.

### 8. Repository history records an explicit removal decision

Commit `34692bf15acb1a45f40f819e66582a85f22c4356` is titled:

```text
Remove prefix fallback and enforce explicit roles in accounts
```

Its diff records:

- Prefix Fallback complete-removal status;
- explicit-role fixture migration;
- standard-fixture expectation that prefix fallback count is zero.

Commit `41fc22d0b08a168aa1a88ce8dae09d432138eeb1` later removed prefix fallback from `daily_flow.bqn` and aligned that path with explicit-role policy.

This history strengthens the interpretation that explicit role metadata, not account-name prefix, is the intended classification owner.

Classification: `historical decision evidence supporting explicit ownership`.

## Selected semantic ownership

### Classification owner

```text
resolved.roles / explicit `role=` metadata
```

A missing role remains missing. It must not become `expense`, `budget`, `income`, `asset`, or another role solely because the account name starts with a familiar prefix.

### Diagnostic observation

A read-only diagnostic may report:

```text
missing role + familiar prefix shape
```

provided that:

- the output is clearly diagnostic;
- it does not mutate `resolved.roles`;
- it does not feed product/accounting selection;
- tests describe it as observation, not fallback admission.

### Product/accounting/envelope selection

Prefix shape must not silently establish role eligibility for:

- expense target selection;
- budget/envelope account selection;
- policy summary fields that claim classified expense accounts;
- other accounting or household product calculations.

### Prefix-based label/display operations

Not every `expenses:` / `income:` / `budget:` prefix use is part of this finding.

Examples such as label trimming or presentation cleanup require separate ownership analysis. They are not automatically role inference and must not be swept into a broad deletion.

## Finite follow-up route

Recommended next implementation slice:

```text
Prefix Fallback Product-Selection Removal
```

Scope:

1. remove missing-role prefix admission from `envelope_computation.bqn` product-selection masks;
2. make `household_policy.bqn` classified expense-account counts explicit-role-owned while preserving any separately named diagnostic fallback count that remains useful;
3. keep `household_metadata.bqn` fallback-shaped counters diagnostic-only;
4. correct stale test comments that claim current fixtures exercise fallback admission;
5. add focused negative evidence showing that a missing-role prefixed account is visible as missing/diagnostic but is not admitted to product selection.

Required exclusions:

- no broad envelope refactor;
- no source TSV migration;
- no deletion of prefix-based display/label helpers merely because they inspect strings;
- no Currency B2 changes;
- no new compatibility module;
- no new lint/telemetry/registry.

## Decision status

External audit finding:

```text
confirmed-current
```

Selected semantic direction:

```text
C: diagnostic-only observation may remain;
   product/runtime role inference by prefix should not remain.
```

Runtime implementation status:

```text
not implemented by this audit snapshot
```

## Reassessment trigger

Reopen this decision only if concrete evidence shows one of:

- an intended supported source contract genuinely requires missing-role prefix admission;
- a current canonical contract explicitly assigns role inference to account-name prefixes;
- removing runtime fallback breaks a supported fixture or daily-use path for reasons other than missing metadata that should instead fail visible;
- a later account-role model supersedes explicit `role=` ownership.
