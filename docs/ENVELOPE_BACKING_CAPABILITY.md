# Retained Envelope & Backing report

Status: Portfolio P7 complete under [`DESTINATION_QUALITY_GATE.md`](DESTINATION_QUALITY_GATE.md).

Owners:

- `src/accounting/envelope_backing.bqn` — strict evidence composition and exact Statement arithmetic;
- `src/sections/envelope_backing.bqn` — retained human/compact/JSON semantic owner.

`src/accounting/envelope_backing.bqn` composes strict Budget, Actual, and Plan Facts over explicit `[start,end_exclusive)`, observation, domain, and explicit funding Account indices. The parallel application route resolves those indices only from explicit unique same-domain `role=asset` Account keys through `src/application/funding_scope.bqn`; Account names/prefixes never imply funding ownership.

Envelope ownership requires admitted `role=budget kind=envelope budget=...`; unassigned requires exactly one admitted `role=budget kind=unassigned`. Funding ownership is supplied explicitly and validated as selected-domain asset Accounts. Account names are never interpreted.

The result keeps entitlement, consumption, refunds, ledger remaining, open Plan reserve, and post-Plan headroom separate. It also keeps funding balance, signed envelope total, positive backing requirement, backing surplus, Budget unassigned, and reconciliation delta separate. Completion uses durable `plan_id` Join and rejects duplicate, ambiguous, currency-mismatched, or direction-mismatched evidence.

P1 defines consumption as positive expense-debit evidence and `actual_refunds` as the positive projection of expense-credit evidence. The latter is an accounting-sign coordinate, not a proven economic classification: an expense reclassification may also produce a credit. Exact Posting/Transaction provenance is retained specifically so a future selected consumer can distinguish external refund, reclassification, and other credit through an explicit counterpart/classification contract. No such distinction may be inferred from Account names. The current human label `Refunds` is shorthand for this documented “expense credits / refunds” boundary.

All arithmetic normalizes exactly to one scale and fails closed. Budget, Actual, Plan, funding, and unassigned contributors are source-qualified. Missing ownership is unavailable rather than numeric zero.

The strict public proof currently establishes entitlement `60`, consumption `30`, remaining `30`, completed Plan reserve `0`, funding `965`, backing requirement `30`, surplus `935`, unassigned `40`, and reconciliation delta `895`, plus missing/invalid funding behavior.

The accounting owner now has named purpose-specific stages for input validation, ownership resolution, prepared evidence, exact normalization, per-envelope terms, aggregate backing, table publication, and final orchestration. Maximum physical line length is 162 characters, down from the initial 1,636-character publication block. The auditability/readability gate is green without introducing a generic pipeline framework or widening the public API.

Synthetic proof covers open and completed Plan, refund, overspent remaining, under-backed funding, empty Plan, duplicate completion conflict, invalid/missing funding, unknown domain/range, cross-source normalization overflow, and source-qualified contributors.

The section verifies strict date text against accounting ordinals and renders one result as:

- human bounded Statement with envelope terms and a separately labelled backing evidence table;
- compact `ledger_envelope_*` keys only, including `ledger_envelope_item` rows;
- exact-number JSON without float conversion.

Backed and under-backed renderer states are tested. Deterministic public human/compact/JSON goldens are owned by `fixtures/ledger-facts-phase1-proof/`. Production routing remains unchanged until atomic cutover.
