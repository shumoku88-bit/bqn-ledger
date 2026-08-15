# Canonical Budget Journal admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review base: `e78430d9709f716f2c59d98c55311be8b2c577b5`
- active owner: `src/ledger/budget_journal_admission.bqn`
- focused review PR: #648

## Ownership

`budget_journal_admission.Admit` is a Budget-semantic refinement over already admitted canonical Journal accounting.

The upstream `journal_complete_admission` / `journal_single_domain_admission` path already owns:

- Journal syntax and transaction boundaries;
- exact decimal parsing and currency precision;
- Account resolution and Account/Commodity compatibility;
- one transaction currency domain;
- amount elision and exact inference;
- normalization to one exact transaction calculation scale;
- exact transaction balance;
- Posting source order and source coordinates;
- base Transaction metadata, identity evidence, and diagnostics.

The Budget owner therefore needs only the additional Household Budget movement relation:

1. every admitted transaction has exactly two Postings;
2. both Postings resolve to Accounts whose role is `budget`;
3. the already-preserved Posting source order is a negative `from` followed by a positive `to` and is published as `from -> to`.

No legacy Budget allocation row and no writer policy belong here.

## Reachability and consumers

Canonical Budget Journal admission was introduced during the canonical Budget evidence cutover in #558. Current application loading reaches this owner through `src/application/budget_source_adapter.bqn`, which first admits canonical Accounts and the canonical Journal root, then admits Budget movements before Facts projection. Canonical Budget movement candidate publication re-admits the complete proposed `budget.journal` through this same owner.

The writer-side candidate owner accepts a positive movement amount, renders the source-ordered `from` Posting negative and `to` Posting positive, then proves that the parsed candidate exactly matches the rendered intent. PR #770 follow-up made the corresponding direction a read-admission law as well, so downstream Entitlement can classify admitted endpoints without rediscovering Journal structure.

## Exact-opposite ownership observation

The previous Budget owner checked, after proving a transaction was binary:

```text
same Commodity
AND
from.normalized_coefficient + to.normalized_coefficient = 0
```

and emitted `budget_movement_postings_not_exact_opposites` when false.

That condition is not independently reachable under the current upstream contract.

For any transaction published by complete Journal admission:

- the transaction has exactly one admitted currency domain;
- every returned Posting is normalized at the transaction calculation scale;
- exact balance has already been checked by summing normalized coefficients and rejecting nonzero totals with `event_unbalanced`.

Therefore, once a returned transaction has exactly two Postings, those two normalized coefficients are necessarily exact opposites and their Commodities belong to the same transaction domain. Rechecking that relation in the Budget owner duplicates upstream semantic ownership rather than protecting a separate Budget invariant.

## Characterization first

The focused law was strengthened before production change to prove two things:

1. an unbalanced two-Budget-Posting source fails upstream with `event_unbalanced` and never reaches the historical Budget exact-opposite diagnostic;
2. mixed Budget-specific failures preserve transaction-major source order, so a non-Budget binary transaction followed by a non-binary transaction publishes diagnostics in that same transaction order.

Characterization-only CI #2605 succeeded.

## Previous successful-path shape

The previous owner walked `sourceTransactions` and mutated the shared `diagnostics` vector inside the transaction loop:

```text
for transaction
  classify binary
  append binary diagnostic
  if binary
    resolve roles
    append Budget-role diagnostic
    recheck exact opposites
    append exact-opposite diagnostic
```

This was correct for reachable behavior, but it mixed relation classification, inherited validation, and diagnostic publication in one procedural-looking loop.

## BQN-native relation shape

The production form first exposes aligned transaction relations:

```text
sourceTransactions
  -> postingRows
  -> binary
  -> budgetOnly
  -> negative-from / positive-to
```

`postingRows`, `binary`, and `budgetOnly` share the same transaction axis. Budget-specific diagnostic cells are then derived from those aligned relations and flattened once in transaction/source order.

The exact-opposite recheck is removed because exact single-domain balance remains owned upstream.

The empty transaction axis remains valid: diagnostic flattening is seeded with one empty cell, so an admitted transaction-free Budget Journal does not introduce a special mutation path.

## Failed probe retained as evidence

The first production spelling attempted to concatenate two inline `AddIf` expressions directly across a line break. CI #2606 failed during BQN import with `Second-level parts of a train must be functions` at that expression. This was a syntax/parse-shape failure, not a semantic or law failure.

The retained form names the two diagnostic cells explicitly and concatenates those names. This keeps the aligned relation design unchanged while making the BQN parse shape unambiguous. CI #2608 then passed the full repository check and coverage.

No temporary debug instrumentation or alternate semantic path remains in the branch.

## Protected contracts

Keep unchanged:

- canonical `budget.journal` source ownership;
- exact arithmetic and upstream exact-balance admission;
- exactly-two-Postings Budget movement law;
- both Postings must resolve to Budget Accounts;
- negative-source / positive-destination `from -> to` publication meaning;
- physical-fallback movement identity based on source start line;
- Posting identities and source coordinates;
- Transaction metadata and domain/calculation-scale evidence;
- transaction-major diagnostic order;
- fail-closed publication of transactions and domains;
- canonical writer authority and writer-side exact intent round trip.

## Qualification

- merged-main amount-text CI #2604: SUCCESS before this branch was cut;
- Budget relation characterization-only CI #2605: SUCCESS;
- CI #2606: FAILED on the discarded inline-concatenation spelling with a BQN train parse error;
- CI #2608: SUCCESS after making diagnostic-cell construction explicit, with full repository check and coverage;
- final documented PR-head CI #2609: SUCCESS;
- PR #648 squash merged as main `9ab7c8ae9becdff4d87cff6fe290298ea014152f`;
- merged `src/ledger/budget_journal_admission.bqn` was reread on that main and retains the aligned `postingRows / binary / budgetOnly` relation with source-ordered diagnostic cells and no exact-opposite recheck;
- merged-main CI #2610: SUCCESS, including full repository check and coverage.

## Review decision

Treat exact opposite normalized amounts as an inherited Journal invariant, not a second Budget admission rule. Retain Budget admission as a thin semantic refinement whose visible kernel is the aligned `binary / Budget-role / negative-from / positive-to` transaction relation, with diagnostic publication derived structurally from that relation.

## Closeout

The owner is finally reviewed on main `9ab7c8ae9becdff4d87cff6fe290298ea014152f`. The Phase 2 queue may mark `src/ledger/budget_journal_admission.bqn` complete and advance to `src/ledger/budget_policy_admission.bqn`.
