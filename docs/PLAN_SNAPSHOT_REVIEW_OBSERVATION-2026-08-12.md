# Plan snapshot review observation — 2026-08-12

## Classification

`src/ledger/plan_snapshot.bqn` is a retained legacy/qualification seam, not the canonical Plan runtime owner.

Its current source shape is explicit:

```text
plan.tsv rows
  -> companion_admission
  -> facts.Project
  -> qualification result
```

The module policy names `source_name = "plan.tsv"` and depends on `companion_admission.bqn`.

## Current canonical runtime

Production Plan reads now use the canonical Journal path:

```text
plan_source_adapter
  -> canonical Journal root admission
  -> plan_journal_admission
  -> facts.Project
```

`plan_snapshot.bqn` has no canonical application consumer. Its remaining reachability is focused qualification/test evidence, including `tests/test_ledger_plan_snapshot.bqn` and the older ledger-facts qualification family.

This matches the earlier classification of `companion_admission.bqn`: the two belong to one legacy fixed-width TSV retirement surface.

## Decision

Do not spend a local array-native refactor on `plan_snapshot.bqn`.

Its relevant architectural decision is retirement classification, not beautification. The file remains only while the old TSV qualification evidence is retained. Removing it should be done coherently with `companion_admission`, legacy Plan TSV fixtures/checks, and canonical Household recovery closeout, rather than manufacturing a new adapter or duplicating canonical Journal semantics here.

## Preserved boundaries

No production reader, canonical source, writer authority, Plan identity, exact arithmetic, provenance, or Facts semantics change in this review.

## Review conclusion

`src/ledger/plan_snapshot.bqn` is reviewed under the dense-array-kernel policy as a legacy/qualification seam delegated to the repository-wide legacy/reachability retirement work.
