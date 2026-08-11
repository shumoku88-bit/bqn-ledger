# Fixed-width companion admission review — 2026-08-11

## Baseline

- repository: `shumoku88-bit/bqn-ledger`
- review main: `7355b43bfc1555e88e557ef123bcd7a8cad5c5dc`
- owner: `src/ledger/companion_admission.bqn`
- next normal Phase 2 item after canonical Journal root admission

## Decision first: reachability before algorithm polish

`companion_admission.bqn` is a strict pure admission owner for the older fixed-width Plan/Budget TSV companion shape. It contains substantial row-local parsing and validation machinery and could superficially invite the same classify-once review used elsewhere.

Current reachability says not to do that.

## Current runtime ownership

Canonical Plan loading no longer reaches this owner.

`src/application/plan_source_adapter.bqn` now reads the canonical Plan Journal root, qualifies canonical root topology, admits it through `plan_journal_admission.bqn`, and projects canonical Facts. The production path is therefore:

```text
canonical plan.journal
  -> canonical Journal root gate
  -> Plan Journal admission
  -> Facts
```

It does not import `plan_snapshot.bqn` or `companion_admission.bqn`.

Repository search for the companion admission call finds the retained `src/ledger/plan_snapshot.bqn` owner. Search for `planSnapshot.Build` and the exact plan-snapshot import finds the focused plan-snapshot test rather than a production application/report/editor consumer.

That focused test still constructs evidence from the old fixture pair:

```text
accounts.tsv
plan.tsv
```

through `account_admission.bqn` and `plan_snapshot.bqn`.

No current `budget.tsv` policy consumer was found in production search either.

## Historical transition

This reachability is consistent with the canonical Plan cutover history.

PR #556, merged as `60f59324c8684e686cba637037a12c6a3f00fd3b`, explicitly routed Plan read consumers to canonical Facts. Its change history includes report Plan reads, completion join, cycle resolution, planned payments, Envelope consumption, Daily Target/report composition, current-profile Plan resolution, and related qualification moving onto the canonical Plan universe.

The old fixed-width companion path therefore survives as qualification/compatibility evidence after the live read graph moved away from it.

## Classification

Treat `src/ledger/companion_admission.bqn` as a **legacy/qualification seam**, not as a current canonical semantic owner.

This is the same subtraction rule used for `src/ledger/account_admission.bqn`: visible procedural structure is not a reason to invest in a local BQN-native refactor when the retained runtime architecture no longer depends on that owner.

The correct follow-up is reachability/retirement work, including the status of:

- `src/ledger/plan_snapshot.bqn`;
- `tests/test_ledger_plan_snapshot.bqn`;
- the `ledger-facts-phase1-proof` TSV fixture evidence;
- old `accounts.tsv / plan.tsv` qualification surfaces;
- any checks/docs that still require that topology.

Those removals should be performed only under the dedicated legacy-source/repository-reachability closeout, where the remaining evidence contract can be retired coherently. They should not be mixed into this owner review merely to make the Phase 2 queue move faster.

## Why no local algorithm rewrite is selected

The owner contains real validation rules such as exact amount admission, date admission, Account/currency compatibility, Plan identity requirements, metadata parsing, and fail-closed publication. Rewriting its row loop into masks or aligned columns would spend design effort preserving an obsolete source contract rather than simplifying the retained canonical architecture.

Likewise, extracting generic TSV/parser helpers would deepen abstraction around a retiring seam.

Therefore:

- do not array-polish `companion_admission.bqn` locally;
- do not make it the shared owner for canonical Journal logic;
- do not delete it here without retiring its qualification consumers/evidence together;
- record it as reviewed and delegated to legacy/reachability retirement.

## Protected boundary until retirement

While the seam remains in the repository, existing focused qualification must continue to preserve:

- exact integer/decimal admission;
- date admission;
- Account and currency compatibility;
- Plan ID requirement under the Plan policy;
- metadata diagnostics;
- identity/provenance shapes consumed by `plan_snapshot.bqn`;
- fail-closed Facts publication in its focused qualification path.

No runtime or test change is selected by this review.

## Review decision

`src/ledger/companion_admission.bqn` is reviewed as a legacy/qualification seam on main `7355b43bfc1555e88e557ef123bcd7a8cad5c5dc`.

Do not refactor it for BQN aesthetics. Delegate its eventual removal, together with `plan_snapshot` and old TSV proof evidence, to the legacy-source/repository-reachability retirement work.

The normal Phase 2 cursor may advance to `src/ledger/config_admission.bqn`.
