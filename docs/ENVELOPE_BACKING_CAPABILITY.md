# Retained Envelope & Backing report

Status: retained capability; `src/accounting/envelope_backing.bqn` architecture review completed after PRs #596–#602.

Owners:

- `src/accounting/envelope_backing.bqn` — strict evidence composition, Envelope terms, and exact Backing arithmetic;
- `src/sections/envelope_backing.bqn` — retained human/compact/JSON semantic owner.

## Inputs and ownership

`src/accounting/envelope_backing.bqn` composes admitted Budget, Actual, and Plan Facts over explicit `[start,end_exclusive)`, observation, and domain together with admitted `budget.toml` and `household.toml` policy.

Ownership is key-based and re-resolved against the statement's current Actual Facts Account axis:

- `budget.toml` owns Envelope ids, Envelope Expense Account keys, and Backing-pool Asset Account keys;
- `household.toml` owns Envelope allocation Account keys and unassigned Budget Account keys;
- current-Facts role and Account existence are revalidated before numeric publication;
- Backing-pool membership may span Commodities, then the current Account axis is projected to the selected domain while preserving policy order.

The former `src/application/funding_scope.bqn` capability was retired during the Application review after confirming it had no production consumer. It was not the ownership authority or an input route for Envelope Backing. Envelope Backing resolves its Backing Account relation from admitted `budget.toml` policy itself.

Missing, duplicate, unknown, wrong-role, or otherwise invalid required ownership fails closed with diagnostics. There is no supported diagnostics-free `unavailable` ownership state and missing ownership is never published as numeric zero.

## Accounting shape

The accounting owner retains named purpose-specific stages:

```text
ValidateInputs
  -> ResolveOwnership
  -> PrepareEvidence
  -> BuildEnvelopeTerms
  -> BuildBacking
  -> public result
```

This staged control shape is intentional. Ownership resolution, Plan completion evidence, exact Envelope term construction, and aggregate Backing each have independent failure boundaries, so the review did not flatten them merely to resemble another kernel or introduce a generic pipeline framework.

`BuildEnvelopeTerms` keeps the array relations visible:

- Envelope allocation closing balances become entitlement;
- selected-domain Expense Accounts are grouped onto the Envelope axis for consumption and expense-credit evidence;
- open Plan destinations are matched against the already-resolved Expense Account relation and grouped onto the same Envelope axis for reserve;
- remaining and post-Plan headroom are exact aligned reductions.

PR #601 added the focused relation law proving that generated Envelope ids already map to valid category coordinates, that an assigned Plan destination inherits the resolved Expense role/domain/category relation, and that an unmatched Plan destination remains simply ineligible. PR #602 then removed only those proven duplicate guards from `BuildEnvelopeTerms`.

The result keeps entitlement, consumption, expense-credit/refund evidence, ledger remaining, open Plan reserve, and post-Plan headroom separate. It also keeps funding balance, signed Envelope total, positive Backing requirement, Backing surplus, Budget unassigned, and reconciliation delta separate.

Completion uses durable `plan_id` Join and rejects duplicate, ambiguous, currency-mismatched, or direction-mismatched evidence before numeric publication.

P1 defines consumption as positive expense-debit evidence and `actual_refunds` as the positive projection of expense-credit evidence. The latter is an accounting-sign coordinate, not a proven economic classification: an expense reclassification may also produce a credit. Exact Posting/Transaction provenance is retained so a future selected consumer can distinguish external refund, reclassification, and other credit through an explicit counterpart/classification contract. No such distinction is inferred from Account names. The current human label `Refunds` remains shorthand for this documented “expense credits / refunds” boundary.

## Exactness and evidence

All arithmetic normalizes exactly to one scale and fails closed at the operation that can fail. Budget, Actual, Plan, funding, and unassigned contributors remain source-qualified and deterministic.

Backing remains a whole-Household selected-domain statement: current funding evidence is compared with positive Envelope remaining, then surplus, Budget unassigned, and reconciliation delta are published separately. The review did not invent pool-specific shortage/surplus semantics.

Focused and synthetic proof covers grouped Expense ownership, Account-order invariance, opening position, open and completed Plan, unmatched Plan destination, refunds/expense credits, overspent remaining, under-backed funding, empty Plan, duplicate completion conflict, ownership failures, unknown domain/range, exact normalization overflow, and source-qualified contributor order.

## Publication

The section verifies strict date text against accounting ordinals and renders one accounting result as:

- a human bounded Statement with Envelope terms and a separately labelled Backing evidence table;
- compact `ledger_envelope_*` keys, including `ledger_envelope_item` rows;
- exact-number JSON without float conversion.

Backed and under-backed renderer states remain tested. Production report composition continues to call the accounting owner directly; selector and terminal UI concerns remain outside this accounting capability.

## Review decision

The Envelope Backing accounting owner is review-complete under the current dense-array/subtraction policy. The successful path now exposes the retained whole-array relations without the local guards proven redundant by #601, while the staged failure boundaries, exactness, source authority, identity, provenance, and whole-Household Backing semantics are retained.

The always-empty public `reason` field is not an Envelope Backing accounting-kernel law. Removing or reshaping it would be a public result/consumer compatibility decision and is deferred to the later result/section reachability audit rather than mixed into this owner review.
