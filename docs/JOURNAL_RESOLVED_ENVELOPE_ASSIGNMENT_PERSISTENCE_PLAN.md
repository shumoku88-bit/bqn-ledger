# Journal resolved envelope assignment persistence — test-only plan

Status: selected finite characterization plan
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: focused public-synthetic implementation, review, completion record, and explicit return to no selected finite Journal slice
Date: 2026-07-22

## Purpose

The completed Journal split-purchase work proved that one household purchase can preserve native multi-posting structure, source identity, posting order, exact account totals, and report aggregation boundaries.

The next unresolved household question is envelope consumption. Current account metadata can describe a default envelope, but mutable metadata must not be allowed to reinterpret old purchases silently. The durable source therefore needs to retain the envelope assignment that was actually resolved when the purchase was accepted.

This slice selects a narrow event-sourcing boundary:

```text
account metadata at entry time
  -> candidate default envelope
  -> validated resolved assignment
  -> explicit durable budget-layer companion event
  -> later envelope projections
```

Account metadata is an input default. It is not the historical arithmetic owner after the resolved assignment has been persisted.

## Finite question

> Can public synthetic Journal evidence show that account metadata may supply default envelope choices for a split purchase, while the accepted resolved assignment is persisted as an explicit balanced budget-layer companion event linked to the actual purchase, so that later metadata changes affect future resolution only and cannot silently change historical envelope consumption?

## Selected source model

### 1. Actual purchase remains authoritative money evidence

The real purchase is one actual-layer transaction with explicit JPY postings.

```journal
2026-08-03 * Example Market | groceries and household goods
    ; event-id: event-purchase-2026-08-03-001
    expenses:food:daily       1400 JPY
    expenses:food:stock        900 JPY
    expenses:household         500 JPY
    assets:bank              -2800 JPY
```

This event says how money moved. It does not infer or duplicate the envelope arithmetic.

### 2. Account metadata supplies entry defaults

A public synthetic declaration set provides candidate defaults:

```journal
account expenses:food:daily
    ; default-envelope: daily

account expenses:food:stock
    ; default-envelope: daily

account expenses:household
    ; default-envelope: flex
```

These values may help a future editor prepare a preview, but they do not remain the sole owner of historical interpretation.

### 3. Accepted assignment is persisted as linked virtual-account movement

After validation, the durable source contains a separate balanced budget-layer event linked to the actual event:

```journal
2026-08-03 * Household budget | consume envelopes for purchase
    ; event-id: event-envelope-consumption-2026-08-03-001
    ; layer: budget
    ; actual-event-id: event-purchase-2026-08-03-001
    budget:spent:daily        2300 JPY
    budget:daily             -2300 JPY
    budget:spent:flex          500 JPY
    budget:flex               -500 JPY
```

The budget accounts are virtual ledger accounts. This event does not claim that bank assets moved a second time. Its budget-layer postings preserve the accepted envelope effect.

Both events balance independently:

```text
actual row sum = 0
budget row sum = 0
```

## Why a companion event is selected

The current minimal Journal profile assigns one layer to a transaction. Mixing actual-money and budget-layer postings inside one transaction would require a new per-posting layer model and would widen the current Transaction IR and Posting IR contracts.

A linked companion event preserves the desired connection without changing the existing one-layer-per-event boundary:

```text
one real-world purchase
  -> one actual accounting event
  -> one explicitly linked budget-consumption event
```

The companion is a persisted household-budget decision, not a duplicated payment.

## Identity boundary

Because another durable event refers to the purchase, the actual purchase requires an explicit durable `event-id` in this characterization.

The budget event requires:

- its own unique `event-id`;
- `layer: budget`;
- an explicit `actual-event-id` link;
- explicit balanced budget postings.

A physical fallback identity is not sufficient for this cross-event link.

## Metadata-change characterization

The public synthetic evidence must contain two declaration snapshots.

### Defaults V1

```text
expenses:food:daily  -> daily
expenses:food:stock  -> daily
expenses:household   -> flex
```

The accepted purchase resolves to:

```text
daily = 2300
flex  = 500
```

### Defaults V2

A later declaration changes one or more defaults, for example:

```text
expenses:food:daily  -> flex
expenses:food:stock  -> flex
expenses:household   -> flex
```

The characterization must demonstrate both facts:

1. a new purchase resolved under V2 may receive the new default assignment;
2. the persisted budget companion for the earlier purchase remains exactly `daily 2300 / flex 500`.

Historical reports must read the persisted budget postings, not recompute old assignments from the latest declarations.

## Event-sourcing interpretation

This plan does not select a general event-store framework. The human-readable Journal remains the event log.

```text
Journal events
  -> Transaction IR
  -> checked Posting IR
  -> Cube / TBDS / envelope projections
```

The event-sourcing property selected here is narrower:

- store the accepted classification result;
- derive current envelope balances from persisted events;
- do not derive historical classification from only the latest mutable rule;
- treat a later correction as new explicit evidence or a separately governed source edit, not an invisible metadata reinterpretation.

Correction-event syntax and editing policy remain outside this slice.

## Expected public synthetic evidence

Expected fixture family:

```text
fixtures/journal-resolved-envelope-assignment-persistence/
  defaults-v1.journal
  defaults-v2.journal
  persisted-events.journal
  README.md
```

Expected focused test:

```text
tests/test_journal_resolved_envelope_assignment_persistence.bqn
```

A bounded extension to the test-only Stage 1 parser may be made only if required to retain:

- account `default-envelope` declaration metadata;
- transaction `actual-event-id` metadata;
- the exact link between the budget event and the actual event.

Any parser extension must remain test-only and fail closed for missing, duplicate, unknown, or ambiguous envelope evidence.

## Required assertions

### Source structure

- one actual purchase event exists with explicit durable identity;
- one budget companion event exists with distinct durable identity;
- the companion references the exact actual event identity;
- actual postings remain in source order and sum to zero;
- budget postings remain in source order and sum to zero;
- the actual and budget layers remain distinct.

### Resolution under V1

- `expenses:food:daily` resolves to `daily`;
- `expenses:food:stock` resolves to `daily`;
- `expenses:household` resolves to `flex`;
- the resolved totals are exactly `daily 2300` and `flex 500`;
- the persisted companion postings match those totals exactly.

### Historical stability under V2

- changing declaration defaults does not alter the persisted V1 companion event;
- historical envelope totals are read from persisted budget postings;
- no report-time or test-time path silently regenerates the old event from V2 metadata;
- a separate new purchase may resolve according to V2 without affecting V1 history.

### Accounting separation

- actual JPY account totals are unchanged by the companion event when projecting the actual layer;
- budget remaining is changed only in the budget layer;
- no bank, cash, expense, asset, liability, income, or equity posting is duplicated by the budget event;
- each layer remains independently hand-checkable.

### Fail-closed evidence

The focused implementation must reject or fail visibly for at least:

- missing `actual-event-id` on the budget companion;
- reference to an unknown actual event;
- duplicate budget companion for the same actual event, unless a later explicit correction contract is separately selected;
- an undeclared or unknown envelope account;
- an unbalanced budget companion;
- an expense account whose default is missing when no explicit override is supplied.

## Responsibility boundary

### Account metadata owns

- the default proposal used when preparing a new entry;
- no historical arithmetic after acceptance.

### Accepted durable budget event owns

- the resolved envelope assignment for that purchase;
- exact envelope-consumption amounts;
- the durable link to the actual event.

### Actual transaction owns

- payee and household description;
- real monetary postings;
- the accounting effect on asset and expense accounts.

### Later projections own

- envelope balances and spending summaries derived from persisted budget events;
- no authority to rewrite source meaning from current metadata.

## Success criteria

- metadata acts as a default rather than a retroactive rule;
- one accepted resolution becomes explicit durable source evidence;
- actual and budget movements remain separately balanced and separately projectable;
- a later default change affects future resolution only;
- the design does not require per-posting layers or new Cube metadata axes;
- only public synthetic evidence is used;
- production source truth and production behavior remain unchanged.

## Non-goals

- production Journal routing or source activation;
- a production writer, editor, preview UI, or automatic serializer;
- automatic creation of companion events for private data;
- current TSV schema or production source-data changes;
- private-data comparison or migration;
- shadow read, conversion, cutover, or reverse synchronization;
- report or envelope runtime migration;
- changing the canonical Cube or TBDS shape;
- per-posting layer support;
- a general event-store service, message bus, database, or event-sourcing framework;
- correction-event syntax or retroactive editing policy;
- tax allocation, receipt-item parsing, inventory, or product-level classification;
- automatically selecting any later Journal slice.

## Expected changed-file boundary for implementation

The expected implementation should remain within:

```text
fixtures/journal-resolved-envelope-assignment-persistence/**
tests/test_journal_resolved_envelope_assignment_persistence.bqn
src_next/journal_profile_stage1.bqn  # only if the bounded metadata/link extension is required
docs/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN.md
TODO.md
NEXT_SESSION.md
docs/README.md
```

No production loader, production report, writer, editor, source TSV, private fixture, conversion tool, or cutover file is authorized.

If the current one-layer-per-event or identity contracts cannot support this bounded characterization, implementation must stop and report the mismatch rather than widening the model silently.

## Validation required before completion

```text
focused BQN test
relevant existing Journal parser and split-purchase tests
tools/check.sh
checks/check-docs-lifecycle.sh
checks/check-absolute-links.sh
checks/check-repo-index.sh
git diff --check
```

After successful implementation and review, move this plan to a dated completed-plan path, return `TODO.md`, `NEXT_SESSION.md`, and `docs/README.md` to no selected finite Journal slice, and do not select a later stage automatically.
