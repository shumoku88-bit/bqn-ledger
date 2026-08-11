# Plan Journal relation review observation — 2026-08-12

## Owner and scope

`src/ledger/plan_journal_admission.bqn` is a deliberately thin Plan-specific semantic owner over already admitted complete Journal accounting.

The complete Journal path owns:

- transaction grammar and source partitioning;
- exact decimal arithmetic and balance;
- Account/currency proof;
- elided Posting completion;
- Posting order;
- source coordinates;
- ordinary structural and semantic admission.

The Plan owner adds only:

- one `plan-id` value per transaction;
- Plan-id lexical validity;
- Plan-id uniqueness across the Plan source;
- Plan source-layer publication;
- durable relation identity derived from `plan-id`;
- Posting ids derived from the remapped Plan relation identity.

## Characterization

A focused law protects the diagnostic frontier:

```text
transaction-local Plan diagnostics
  -> whole-source Plan-id uniqueness diagnostic
  -> fail-closed Plan publication
```

The mixed-invalid source proves exact public order:

```text
plan_id_invalid    transaction 1
plan_id_missing    transaction 2
plan_id_duplicate  aggregate line 0
```

The duplicate diagnostic remains aggregate-last.

A successful two-transaction source protects:

- source transaction order;
- original `plan_id` values;
- `identity_kind = durable_relation`;
- `source_event_id = plan.journal:plan_id:<plan-id>`;
- Posting order;
- Posting ids derived from the Plan relation identity.

Characterization-only CI #2751: SUCCESS.

## Transaction diagnostic cells

The previous owner walked the admitted transaction axis and appended directly into shared diagnostics.

The reviewed form maps one Plan-specific diagnostic cell over that axis:

```text
admitted transaction
  -> plan-id
  -> missing diagnostic cell
  -> invalid diagnostic cell
  -> local concatenation
```

Then:

```text
transaction diagnostic cells
  -> source-order flatten
  -> whole-source duplicate Plan-id diagnostic
```

This preserves the previous missing-before-invalid local order and transaction-major order without shared traversal mutation.

Production CI #2752: SUCCESS with full `tools/check.sh` and coverage.

## Duplicate relation retained unchanged

Plan-id uniqueness remains a whole-source relation over the complete `planIds` axis:

```bqn
(≠planIds)≠≠⍷planIds
```

This review does not redefine which invalid/missing values participate in the duplicate relation. Diagnostic behavior remains unchanged.

## Identity remap retained

`MapTransaction` and `MapPosting` remain explicit domain owners.

```text
plan-id
  -> plan.journal:plan_id:<plan-id>
  -> durable_relation Transaction identity
  -> Posting ids under the same identity
```

This is the principal Plan-specific transformation and should not be hidden behind a generic identity mapper.

## Publication boundary

The owner continues to fail closed:

- accounting admission failure is propagated;
- any Plan-specific diagnostic clears Plan transactions and declared domains;
- only a fully admitted Plan source publishes remapped Plan Transactions.

## Review conclusion

The retained owner is intentionally small:

```text
complete Journal admission
  -> Plan-id relation
  -> local Plan diagnostics
  -> aggregate Plan-id uniqueness
  -> Plan durable-relation identity remap
  -> fail-closed Plan publication
```

No second accounting parser, Plan-specific arithmetic, or generic abstraction is warranted.

No exact arithmetic, Account proof, source provenance, complete-Journal diagnostic ownership, Plan identity meaning, Posting shape, or writer/source authority changed.
