# Journal resolved envelope assignment persistence — completed test-only characterization

Status: completed
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: completed; no later Journal slice selected automatically
Date: 2026-07-22

## Completion record

The finite public-synthetic characterization succeeded.

Account declaration metadata may supply an entry-time default envelope, while the accepted assignment is persisted as a separate balanced budget-layer companion event linked to the durable actual event by `actual-event-id`. Later metadata changes can affect a newly resolved purchase without silently changing the earlier persisted envelope effect.

## Finite question answered

> Can public synthetic Journal evidence show that account metadata may supply default envelope choices for a split purchase, while the accepted resolved assignment is persisted as an explicit balanced budget-layer companion event linked to the actual purchase, so that later metadata changes affect future resolution only and cannot silently change historical envelope consumption?

Answer: yes, within the bounded test-only profile implemented here.

## Implemented evidence

Fixture family:

```text
fixtures/journal-resolved-envelope-assignment-persistence/
  defaults-v1.journal
  defaults-v2.journal
  persisted-events.journal
  README.md
```

Focused test:

```text
tests/test_journal_resolved_envelope_assignment_persistence.bqn
```

Bounded parser extension:

```text
src_next/journal_profile_stage1.bqn
```

## Exact successful scenario

The first actual purchase has durable identity:

```text
event-purchase-2026-08-03-001
```

Its actual-layer postings are:

```text
expenses:food:daily   +1400
expenses:food:stock    +900
expenses:household     +500
assets:bank           -2800
row sum                   0
```

Defaults V1 resolve the positive expense postings to:

```text
daily = 2300
flex  = 500
```

The accepted effect is persisted in a distinct budget-layer event:

```text
event-envelope-consumption-2026-08-03-001
actual-event-id: event-purchase-2026-08-03-001

budget:spent:daily   +2300
budget:daily         -2300
budget:spent:flex     +500
budget:flex           -500
row sum                  0
```

The budget companion contains only virtual budget accounts. It does not duplicate the bank payment or expense postings.

## Metadata-change result

Defaults V2 change all three expense-account defaults to `flex`.

Under V2:

- a newly resolved purchase produces `flex = 2800`;
- re-running default resolution against the old actual purchase would also propose `flex = 2800`;
- the already persisted companion remains exactly `daily = 2300 / flex = 500`.

This makes the boundary explicit:

```text
current account metadata = proposal for a new resolution
persisted budget event   = historical arithmetic owner
```

Historical envelope interpretation is therefore not regenerated from only the newest mutable declaration state.

## Stage 1 extension result

The test-only parser now retains recognized account declaration metadata:

- `role`;
- `kind`;
- `default-envelope`.

Unrelated account comment metadata remains permissive and is not promoted into this contract.

Transaction metadata now supports `actual-event-id` on budget events. A budget event must carry exactly one of:

- `allocation-id`; or
- `actual-event-id`.

Cross-event validation requires `actual-event-id` to match exactly one durable actual event. This characterization permits at most one budget companion for one actual event because correction-event policy remains unselected.

A pure test-only `ResolveEnvelopeDefaults` seam resolves positive expense postings through declaration defaults and verifies that both `budget:<envelope>` and `budget:spent:<envelope>` accounts are declared.

## Fail-closed evidence

The focused test verifies visible failure for:

- missing budget link;
- unknown actual-event target;
- duplicate budget companion;
- unbalanced budget companion;
- missing expense-account default;
- default referencing undeclared envelope accounts.

## Evaluation-order correction

The first CI run exposed one BQN right-to-left evaluation error in the two account-existence checks inside `ResolveEnvelopeDefaults`. Explicitly parenthesizing the first function application restored the intended boolean conjunction. No design boundary or result semantics changed.

## Validation evidence

GitHub Actions check run #1122 succeeded after the focused correction.

Successful paths include:

```text
focused Journal persistence test
relevant existing Journal parser and migration tests
tools/check.sh
coverage
repository documentation and link checks reached through tools/check.sh
```

## Changed implementation boundary

The implementation remains limited to:

```text
fixtures/journal-resolved-envelope-assignment-persistence/**
src_next/journal_profile_stage1.bqn
tests/test_journal_resolved_envelope_assignment_persistence.bqn
```

Completion routing changes are limited to this completed record, `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md`, plus removal of the former selected-plan path.

## Non-change boundary

This completion does not connect or authorize:

- production Journal loading or source activation;
- a writer, editor, preview UI, or automatic serializer;
- production envelope or report runtime migration;
- private data or production source changes;
- conversion, shadow read, cutover, or reverse synchronization;
- per-posting layers;
- Cube or TBDS shape changes;
- correction-event syntax;
- a general event-store service or message bus;
- any automatically selected later Journal slice.

## Resulting architectural statement

```text
account metadata at entry time
  -> candidate default envelope
  -> validated accepted assignment
  -> explicit balanced budget-layer companion event
  -> stable historical envelope evidence
```

The human-readable Journal remains the event log. The selected event-sourcing property is narrow: persist the accepted classification result and do not rewrite historical meaning from only the latest mutable rule.
