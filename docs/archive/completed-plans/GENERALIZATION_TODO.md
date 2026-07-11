# bqn-ledger: lifestyle configuration boundary decision

Status: completed / superseded planning record
Owner: config
Canonical: no; current routing: `TODO.md`, `docs/SAFETY_PROFILE.md`, `config/meta_schema.tsv`, and current feature contracts
Exit: retained for rationale; do not use as an active migration queue

Date: 2026-06-27
Reclassified: 2026-07-11

## Decision

The A4 configuration-resolution workstream is `complete enough for now`.

Remaining configuration questions are independent future problems. They do not authorize automatic key-by-key migration from BQN code into TSV configuration.

## Current boundary

### Explicit role owns semantic classification

Accounting and product selection use explicit account metadata such as `role=expense`, `role=income`, and `role=budget`.

Familiar account-name prefixes may still be observed when a role is missing, but that observation is diagnostic evidence only. It must not silently provide the missing accounting role.

```text
explicit role
  -> semantic classification

missing role + familiar prefix
  -> readiness / migration diagnostic
  -> not semantic fallback
```

Presentation-only helpers that shorten labels such as `expenses:food` to `food` are a separate display concern.

There is no active blanket "Prefix fallback removal" campaign.

### Configuration is not a DSL

Any future configuration-externalization candidate must first identify the correct semantic owner:

- configuration;
- account or source metadata;
- `cycle.tsv`;
- a source-schema contract;
- or a fixed code invariant.

User configuration must remain simple and diagnosable. Do not externalize arbitrary accounting computation or turn configuration into a household-accounting language.

### Failure behavior must be designed first

A new setting requires explicit decisions for:

- unknown values;
- missing values;
- duplicate declarations;
- empty values;
- fallback or no-fallback behavior;
- fixture, lint, and check ownership.

Do not modify real source TSV data first.

### Canonical Daily Cube remains fixed

Canonical Daily Cube shape, axis meaning, and Layer contracts are not user configuration.

New coordinates or meanings must be expressed as separate projections or views derived from the same posting/event representation.

## Current routing

Use `TODO.md` for selected finite work.

Use the `Configuration externalization` continuous-maintenance lane in `TODO.md` when reviewing a new life rule, date, category, policy, or display setting.

Use `docs/archive/audits/EXTERNAL_STATIC_AUDIT_REASSESSMENT_SOURCE-2026-07-11.md` for the post-B3 audit and repository shelf classification.

## Historical completed phases

Detailed completed phase history remains in:

- `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md`

This file records the boundary learned from those phases; it is not a list of unfinished mandatory work.