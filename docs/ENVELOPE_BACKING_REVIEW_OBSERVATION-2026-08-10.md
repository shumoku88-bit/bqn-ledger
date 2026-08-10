# Envelope Backing review observation — 2026-08-10

## Baseline

Revalidated on `main` `20ee55f6f2ae2632e4ed59730c6beb4aebfc71f5` after PRs #596–#599.

The active review cursor remains `src/accounting/envelope_backing.bqn`. This note supersedes the pre-#596 observation recorded in Draft PR #595; it does not advance the cursor or classify the owner review-complete.

## Resolved findings from the earlier observation

The earlier ownership questions are no longer open:

- PR #596 proved that every supported ownership failure publishes `error`; there is no diagnostics-free partial ownership path requiring a separate `unavailable` state.
- PR #597 removed the unreachable `unavailable / envelope_or_funding_ownership_missing` branch while preserving the public result shape.
- PR #598 changed Household allocation and unassigned resolution from admission-time numeric Account coordinates to stable Account keys resolved against the current Actual Facts axis.
- PR #599 expressed funding and unassigned row resolution as aligned vector index-of operations and removed the scalar `IndexOf` helper used only for those lookups.

The retained whole-Household Backing aggregation, exact arithmetic, Plan reserve separation, contributor order, provenance, fail-closed publication, source authority, and writer boundaries remain protected.

## Current control-shape judgment

`Build` still composes:

```text
ValidateInputs
  -> ResolveOwnership
  -> PrepareEvidence
  -> BuildEnvelopeTerms
  -> BuildBacking
  -> public result
```

The nested conditional execution is visually deeper than `date_category_flow`'s `Admit -> Kernel -> Result` shape, but the current stages are not merely presentation wrappers. Ownership resolution, completion evidence, exact Envelope term construction, and Backing totals each have independent failure boundaries whose downstream inputs are not meaningful after failure.

Therefore this review does **not** currently recommend reshaping `Build` merely to imitate Date Flow. The burden of proof is on any future control-flow rewrite to make the successful path materially clearer without duplicating staging, weakening exact-operation locality, or introducing a generic pipeline abstraction.

Classification: **KEEP for now**.

## New subtraction candidate: generated Envelope ids are revalidated against their source axis

Inside `BuildEnvelopeTerms`, `expenseEnvelopeIds` is constructed by repeating each value from `ownership.categories` for the corresponding admitted Expense Account keys. The code then computes:

```text
expenseCoordinates <- categories index-of expenseEnvelopeIds
matched <- expenseCoordinates < envelopeCount
expenseIndices <- matched / expenseIndices
expenseCoordinates <- matched / expenseCoordinates
```

Because every `expenseEnvelopeId` is generated from `categories` itself, the `matched` filter appears structurally redundant once `ResolveOwnership` has succeeded. This is narrower and better evidenced than a broad `Build` rewrite.

Classification: **SUBTRACT candidate**, pending a focused law or direct construction proof.

## New subtraction candidate: Plan eligibility appears to repeat admitted/current-Facts guarantees

For open Plan reserve, the current code first maps `joined.rows.planned_to_account` to the already-resolved `expenseIndices` relation:

```text
assignmentRows <- expenseIndices index-of planAccountRows
assigned <- assignmentRows < length expenseIndices
planEnvelopeIds <- assignmentRows select expenseEnvelopeIds
planCoordinates <- categories index-of planEnvelopeIds
```

It then additionally checks current Account currency, Account role, and category coordinate validity before `openMask` is formed.

After successful `ResolveOwnership`:

- each retained Budget policy Expense key has been re-resolved against the current Facts axis;
- each resolved Expense Account has current role `expense`;
- `expenseEnvelopeIds` is generated from the admitted unique Envelope axis;
- `assignmentRows < length expenseIndices` means the Plan destination matched that resolved Expense relation.

This suggests that, for `assigned` rows, the later role/domain/category checks may be consequences of the already-established relation rather than independent safety laws.

Classification: **SUBTRACT candidate**, not yet accepted.

## Required proof before production subtraction

Before removing any of the candidate guards, prove on current main that:

1. every generated `expenseEnvelopeId` maps to a valid `categories` coordinate after successful ownership resolution;
2. every `assigned` Plan destination inherits the resolved Expense Account role, selected domain, and valid Envelope coordinate from the admitted relation;
3. unmatched Plan destinations remain simply ineligible for Envelope reserve and do not gain a new error state;
4. duplicate/ambiguous/mismatched Plan completion evidence still fails in `PrepareEvidence` before numeric publication;
5. grouped Envelope values, contributor order, exact failure behavior, result shape, and diagnostics remain unchanged.

Prefer one focused law test before production subtraction. Do not introduce a shared validation helper or a generic admission/kernel framework for this proof.

## Documentation residue

`docs/ENVELOPE_BACKING_CAPABILITY.md` still teaches the retired explicit funding-scope route and says missing ownership is `unavailable`. Those statements are stale after canonical Budget/Household ownership and PRs #596–#599.

Do not update that capability document in this observation-only slice. Update it together with the final Envelope Backing review decision so the active documentation describes the final retained contract rather than an intermediate state.

## Current classification

`src/accounting/envelope_backing.bqn` remains **OBSERVE / SUBTRACT candidate** and is not review-complete.

The next coherent slice is a focused law proving or rejecting the two local redundancy candidates above. Only after that result should production code be changed or the review cursor advance to `src/accounting/fact_reference.bqn`.
