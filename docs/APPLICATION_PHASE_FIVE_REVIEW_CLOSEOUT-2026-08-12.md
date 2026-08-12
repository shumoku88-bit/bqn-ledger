# Application Phase 5 review closeout — 2026-08-12

## Scope

Close the dense-array / ownership review of every production BQN owner under `src/application/`.

The phase reviewed source adapters, current-report orchestration, editor-facing read observations, Report request/route/destination boundaries, policy/domain resolution, operational ledger CLIs, and the shared read-only Source I/O boundary.

## End-state

Phase 5 now has no unchecked production BQN owner.

The application layer has converged on this shape:

```text
canonical source/request admission
  -> caller-owned evidence lifetime
  -> pure semantic selection / resolution
  -> catalog-coordinate application dispatch
  -> effect-only CLI/process adapter
```

Application owners no longer need to rediscover Report identity from strings after catalog admission, reconstruct sibling Account observations independently, or stage ordinary result publication through shared mutable accumulators.

## Main decisions

### Source and evidence lifetime

- canonical source basenames remain named physical identities;
- shared read-only path composition belongs to `source_io.bqn`;
- wider application observations can reuse caller-owned admitted Accounts rather than re-reading `accounts.journal` independently;
- Actual-only, Household Context, full Companion, and Issues-only Report evidence lifetimes are explicit;
- Household admission remains lazy on successful Budget Policy admission;
- Budget movement remains independently observable so sibling diagnostics are preserved;
- Source I/O keeps live Editor-facing read/split capabilities but hides ambient `ResolvePath` implementation detail.

### Report catalog coordinates

The retained Report catalog coordinate now survives the whole individual request path:

```text
request admission
  -> route coordinate schema
  -> destination evidence lifetime
  -> semantic destination dispatch
```

Repeated key-string dispatch in application destinations was removed. Route arity/role policy is one catalog-aligned relation rather than twelve near-identical functions.

The obsolete physical-source route protocol was retired. Report routes now carry semantic coordinates only; canonical Household source files are resolved internally after admission.

### Pure resolution boundaries

- Report domain selection is explicit versus inferred classification;
- Report Policy resolution separates input diagnostics, successful symbolic date resolution, and dynamic range diagnostics;
- invalid dates cannot reach ordinal calculation because the validation boundary remains lazy;
- Report metadata format selection is direct lazy value selection;
- cycle and Daily Scope application selectors expose their semantic relations without collapsing meaningful evaluation guards.

### Boundary leaves

Several owners were deliberately retained unchanged after review because they were already narrow:

- clock/date leaf;
- Household source leaf;
- Report Policy source leaf;
- Report Presentation / Request / Selection CLIs;
- Route Plan CLI.

A checked review does not require a production rewrite. Where the boundary was already correct, architecture laws and existing integration evidence were preferred over manufactured abstractions.

### Retirement and subtraction

The phase also retired compatibility or unreachable application machinery, including:

- unused Funding Scope;
- legacy editor Account/config/default seams;
- Actual config wrapper;
- dead application surfaces with no production consumers;
- route `SOURCE` publication and permanently-zero physical source count.

## Test and fixture result

The review confirmed that test/fixture cleanup can proceed naturally with owner review instead of becoming a separate rewrite project.

The useful classification that emerged is:

1. **semantic law tests** — exact identity/order/domain/date/fail-closed rules;
2. **effect-lifetime laws** — prove an owner does not read sibling sources it does not require;
3. **golden/characterization checks** — preserve public Report/CLI bytes while internals change;
4. **architecture/reachability guards** — prevent legacy source ownership, key redispatch, mutable staging, or dead compatibility seams from returning;
5. **legacy fixture adapters** — retained only where an explicit migration/qualification role still exists and left for owner-specific retirement.

Examples from this phase:

- no new persistent fixture was needed for destination evidence lifetimes; temporary reductions of the existing canonical fixture proved Actual-only / Context-only / Issues-only reads;
- Report Policy Resolution was characterized on the old implementation before production transformation, then the same laws qualified the relation-based implementation;
- metadata, presentation, request, and selection leaves reused existing checks instead of adding duplicate fixtures;
- Route tests stopped characterizing an always-empty `sources` namespace and instead protect the real law that physical source basenames are invalid semantic coordinates;
- Source I/O retains split helpers because upcoming Editor consumers demonstrably use them rather than deleting them speculatively.

The remaining cross-cutting test/fixture audit stays in the repository queue because later Editor / writer owners will reveal additional topology residue in context.

## Representative PR sequence

The latter half of this phase closed through:

- #719 Report destination catalog-coordinate dispatch;
- #720 catalog-coordinate evidence lifetime dispatch;
- #721 Report domain selection classification;
- #722 Report metadata format classification;
- #723 Report Policy resolution relations;
- #724 Report Policy source boundary law;
- #725 Request / Presentation boundary leaf review;
- #726 Report route schema relation and physical-source protocol retirement;
- #727 Report Selection leaf boundary law;
- #728 Report source result relations;
- #729 Source I/O boundary narrowing and Phase 5 closeout.

Earlier Phase 5 decisions remain recorded in the per-owner observation documents and Git history referenced by `TODO.md`.

## Protected system contracts

Across the phase, the following remained non-negotiable:

- exact arithmetic;
- stable Transaction / Posting / Plan identity;
- source provenance and order;
- canonical Household source authority;
- fail-closed admission/publication;
- meaningful diagnostic ordering;
- safe writer authority boundaries;
- public Report destinations and retained CLI protocols unless a protocol state was proven unreachable and explicitly retired.

## Next cursor

Phase 6 begins at:

`src/editor/friend_travel_source_event.bqn`

The next review should read that owner together with its direct consumers, tests, fixtures, and any `src_edit`/shell adapter that depends on its event/source shape before deciding whether to transform or retain it.
