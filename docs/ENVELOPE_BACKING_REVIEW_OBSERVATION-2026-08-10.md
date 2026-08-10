# Envelope Backing review observation — 2026-08-10

## Final baseline

Final reread performed on `main` `0002c7b9acb133974c19b158a147980290c47a54` after PRs #596–#602.

The review began from the pre-#596 ownership/control-shape observation, was revalidated after #596–#599 in PR #600, proved the remaining local relation laws in PR #601, and applied the proven subtraction in PR #602.

This record now closes the `src/accounting/envelope_backing.bqn` owner review and advances the normal cursor to `src/accounting/fact_reference.bqn` once the closeout documentation is merged.

## Ownership findings resolved

The earlier ownership questions are closed:

- PR #596 proved that every supported ownership failure publishes `error`; there is no diagnostics-free partial ownership path requiring a separate `unavailable` state.
- PR #597 removed the unreachable `unavailable / envelope_or_funding_ownership_missing` branch while preserving the public result shape.
- PR #598 changed Household allocation and unassigned resolution from admission-time numeric Account coordinates to stable Account keys resolved against the current Actual Facts axis.
- PR #599 expressed funding and unassigned row resolution as aligned vector index-of operations and removed the scalar `IndexOf` helper used only for those lookups.

The final owner therefore has one current-Facts ownership authority: admitted Budget/Household policy supplies Account keys and semantic relations, and `ResolveOwnership` re-resolves and validates those relations against the current Facts Account axis before numeric publication.

The retained whole-Household Backing aggregation, exact arithmetic, Plan reserve separation, contributor order, provenance, fail-closed publication, source authority, and writer boundaries remain protected.

## Control-shape decision: KEEP

`Build` composes:

```text
ValidateInputs
  -> ResolveOwnership
  -> PrepareEvidence
  -> BuildEnvelopeTerms
  -> BuildBacking
  -> public result
```

The nested conditional execution is visually deeper than `date_category_flow`'s `Admit -> Kernel -> Result` shape, but the stages correspond to real failure boundaries. Ownership resolution, completion evidence, exact Envelope term construction, and Backing totals each produce inputs that are not meaningful downstream after failure.

The review therefore rejects a cosmetic control-flow rewrite. Flattening this owner merely to imitate Date Flow would either duplicate staging, weaken exact-operation failure locality, or require a generic pipeline abstraction with less domain meaning than the current names.

Classification: **KEEP**.

## Local relation subtraction: PROVED and APPLIED

The strongest remaining subtraction candidates were local to `BuildEnvelopeTerms`.

### Generated Envelope ids

`expenseEnvelopeIds` is constructed by repeating values from the admitted Envelope axis for the corresponding Expense Account relation. The former code then revalidated those generated ids against the same category axis and filtered unmatched rows.

PR #601 proved that every generated `expenseEnvelopeId` maps to a valid `categories` coordinate. PR #602 removed the redundant `matched` category filter while preserving selected-domain projection of the Expense relation.

### Plan eligibility

The former code mapped `joined.rows.planned_to_account` to the already-resolved selected-domain Expense relation and then separately rechecked current Account currency, role, and category-coordinate validity.

PR #601 proved that when a Plan destination is `assigned` to that resolved relation it already inherits:

- current role `expense`;
- the selected domain after the retained Expense-domain projection;
- a valid Envelope coordinate generated from the admitted Envelope axis.

The same law proves that an unmatched Plan destination remains merely ineligible for Envelope reserve rather than becoming a new ownership error.

PR #602 therefore removed the duplicate Plan role/domain/category eligibility checks and now forms the reserve mask directly from open Plan status and `assigned`.

Classification: **SUBTRACTED**.

## What remains intentionally protected

The final owner still retains:

- strict source checks for Budget, Actual, Plan, Budget policy, and Household policy;
- a shared Budget/Actual/Plan Account-key axis requirement;
- current-Facts key existence and role checks for policy-owned Accounts;
- selected-domain projection where a policy relation may legitimately span Commodities;
- Household Envelope-allocation uniqueness and selected-domain Budget role checks;
- Plan completion duplicate/ambiguous/currency/direction conflict rejection before numeric publication;
- exact normalization and reduction failures at the exact operation that can fail;
- stable grouping, contributor ordering, and source-qualified provenance;
- whole-Household Backing semantics rather than invented pool-specific shortage/surplus semantics.

These checks protect semantic, evidence, authority, or exactness laws rather than incidental implementation topology.

## Documentation correction

`docs/ENVELOPE_BACKING_CAPABILITY.md` previously described the retired Envelope Backing route in terms of explicit funding Account indices resolved through `src/application/funding_scope.bqn`, and said missing ownership was `unavailable`.

The final capability contract instead states that:

- `budget.toml` owns Envelope/Expense/Backing-pool key relations;
- `household.toml` owns Envelope allocation and unassigned Budget Account keys;
- Envelope Backing re-resolves those keys against the current Actual Facts axis;
- `src/application/funding_scope.bqn` is not the ownership authority or input route for this accounting owner;
- required ownership failures publish `error` rather than `unavailable` or numeric zero.

The capability document is corrected in the same closeout slice so active documentation describes the retained contract rather than an intermediate architecture.

## Deferred public-shape residue

The public result still contains an always-empty `reason` field after the unreachable `unavailable` state was removed.

That field is no longer an Envelope Backing accounting-kernel decision. Removing it would require a public result/consumer compatibility review across report and section owners, so it is deliberately deferred to the later result/section reachability audit. It does not block this accounting-owner review from completing.

## Final classification

`src/accounting/envelope_backing.bqn` is **REVIEW-COMPLETE** under the current dense-array/subtraction policy.

The completed sequence is:

```text
observe ownership/control shape
  -> make ownership failure semantics explicit
  -> resolve ownership by stable keys
  -> align row lookup
  -> revalidate the remaining local candidates
  -> prove relation laws
  -> subtract only the proven duplicate guards
  -> retain meaningful staged failure boundaries
```

The next normal review cursor is `src/accounting/fact_reference.bqn`.
