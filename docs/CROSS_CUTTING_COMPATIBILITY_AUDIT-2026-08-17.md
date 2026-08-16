# Cross-cutting migration / compatibility audit — 2026-08-17

## Scope

This audit follows the production BQN review and the frontend, writer, report, and dead-surface passes.

The question is not whether the repository still contains the word `legacy`. The question is whether an older shape/path is:

```text
retired migration topology
  -> must not remain reachable

current bounded read compatibility
  -> retain while current admitted data/commands depend on it

historical observation profile
  -> retain as explicit evidence reader, not writer authority
```

Old terminology is therefore insufficient evidence for deletion.

## Retired source topology remains retired

The canonical Household cutover is already enforced by repository checks.

Production must not regain the older source authorities such as:

```text
accounts.tsv
plan.tsv
budget_alloc.tsv
config.tsv
cycle.tsv
daily_target_scope.tsv
report_manifests.tsv
```

`check-canonical-household-read-cutover.sh` and related topology checks treat those as retired source paths, not fallback inputs.

This is fundamentally different from bounded compatibility inside a current source owner.

## Current Issue physical-shape compatibility — retain

`src/ledger/issue_admission.bqn` currently admits exactly three `issues.tsv` physical headers:

```text
8 columns: original lifecycle shape
9 columns: explicit due coordinate
10 columns: explicit due + closed lifecycle
```

The owner normalizes all three into one current semantic relation containing:

```text
date
due
closed
status
category
title
amount/currency
source_row
```

The older shapes do not become alternate semantic authorities. Missing lifecycle coordinates are normalized conservatively (`undetermined` / `none`) and current lifecycle laws are still validated.

This compatibility is active:

- Issue Add preserves the admitted physical schema when appending;
- Issue Close preserves the source shape it is permitted to update;
- Issue List consumes the normalized admitted relation;
- `check-issue-due-compatibility.sh` exercises eight-, nine-, and ten-column readers.

Removing eight/nine-column admission merely because they are older would be a source migration, not cleanup. No such migration is authorized by this audit.

## Current Plan relation fallback — retain

`src_edit/plan_related_cmd.bqn` builds one read-only relation key in this order:

1. canonical `series` metadata when present;
2. series parsed from a valid `plan-YYYY-MM-DD-series` identity shape;
3. exact description/from/to/amount fallback.

The second/third steps are compatibility for older admitted Plan observations whose explicit relation metadata is absent. They do not write new legacy data or change Plan identity authority.

This fallback was already law-reviewed in the canonical Plan command review and remains current behavior guarded by the Plan Related checks.

A future migration may decide that every retained Plan has enough explicit relation metadata to remove the fallback. Current evidence does not establish that precondition, so this audit does not manufacture it.

## Historical Journal profile — retain as explicit evidence reader

`src/editor/journal_profile.bqn` owns bounded historical Journal parsing profiles, including the historical external-Plan shape used by old Journal evidence.

This profile is deliberately separate from current canonical writer admission:

```text
current writers
  -> current canonical Journal admission / candidate validation

historical observation tools
  -> explicit historical profile when old evidence requires it
```

The historical parser is not a hidden production fallback chosen from current configuration. Callers select the profile explicitly.

Its parser/failure-order law was reviewed in Phase 6 and no concrete defect justified replacing the state machine merely to remove historical vocabulary.

## Current Plan retirement is not migration residue

`cancelled-on`, `superseded-on`, and `superseded-by` in `plan.journal` describe current Plan lifecycle meaning.

`src/ledger/plan_journal_admission.bqn` projects those coordinates without rewriting the historical Plan transaction and validates:

- duplicate retirement metadata;
- cancellation/supersession conflicts;
- valid retirement dates;
- known/non-self supersession targets;
- no supersession cycles.

This is current domain history, not a compatibility shim. `test_ledger_plan_retirement_admission.bqn` directly guards it.

## No hidden current-config reconstruction

The compatibility retained above has a common boundary:

```text
older physical evidence
  -> explicit current admission / normalization
```

It does **not** mean:

```text
current config
  -> infer what old records must have meant
```

That distinction remains important for Envelope/Household history as well as Issue/Plan/Journal observations. Current policy does not retroactively become historical evidence.

## Decision

No additional runtime compatibility removal is justified in this lane.

The earlier audits already removed actual migration/runtime residue:

- completed one-shot Journal identity migration runtime;
- dead TSV Plan-ID readers;
- promoted experiment runtimes;
- retired `src_next` diagnostic surface;
- no-caller legacy safe-write APIs.

The remaining compatibility reviewed here is either current bounded admission behavior or an explicit historical observation profile.

## Existing guards

The current compatibility boundary is already covered by focused repository evidence:

```text
check-canonical-household-read-cutover.sh
check-canonical-household-source-topology.sh
check-issue-due-compatibility.sh
check-edit-bqn-plan-related.sh
tests/test_editor_journal_profile.bqn
tests/test_ledger_plan_retirement_admission.bqn
```

Adding a second generic compatibility framework/check would duplicate those owners rather than clarify them.

## Next cursor

```text
checks/tests classification: current law guard vs historical characterization vs obsolete topology assumption
```
