# Next session

Status: selected finite slice
Owner: journal source migration
Canonical: no; canonical routing remains `TODO.md`
Exit: implement and review the selected public-synthetic characterization, archive the completed plan, and return routing to no selected finite Journal slice

## Selected slice

Journal resolved envelope assignment persistence.

Canonical plan:

`docs/JOURNAL_RESOLVED_ENVELOPE_ASSIGNMENT_PERSISTENCE_PLAN.md`

## Finite question

Can public synthetic Journal evidence show that account metadata may supply default envelope choices for a split purchase, while the accepted resolved assignment is persisted as an explicit balanced budget-layer companion event linked to the actual purchase, so that later metadata changes affect future resolution only and cannot silently change historical envelope consumption?

## Selected boundary

```text
account metadata at entry time
  -> candidate default envelope
  -> validated resolved assignment
  -> explicit durable budget-layer companion event
  -> later envelope projections
```

The actual transaction remains authoritative real-money evidence. The linked budget event records virtual-account movement only and must balance independently.

## Expected implementation

- public synthetic defaults V1 and V2;
- one actual split-purchase event with explicit durable `event-id`;
- one distinct budget-layer companion event linked by `actual-event-id`;
- persisted `daily 2300 / flex 500` assignment under V1;
- proof that V2 defaults may affect a new purchase but do not reinterpret the persisted V1 event;
- focused fail-closed evidence for missing, unknown, duplicate, or unbalanced linkage;
- bounded Stage 1 test-only metadata/link extension only if required.

## Guard rails

- no production Journal routing;
- no writer, editor, preview UI, or automatic serialization;
- no production envelope/report runtime migration;
- no private data, source TSV conversion, shadow read, cutover, or reverse sync;
- no per-posting layer model or Cube/TBDS shape change;
- no later slice selected automatically.
