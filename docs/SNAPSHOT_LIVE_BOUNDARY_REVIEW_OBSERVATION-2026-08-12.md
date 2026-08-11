# Snapshot live boundary review observation — 2026-08-12

## Owner and scope

`src/ledger/snapshot.bqn` is the live pure Snapshot composition boundary used by canonical Actual loading.

Its retained production contract is:

```text
already-admitted canonical Accounts
  -> complete Journal admission
  -> Facts projection
  -> fail-closed Snapshot result
```

`src/application/actual_source_adapter.bqn` supplies canonical Account evidence and calls `BuildFromAccounts` directly.

## Characterization first

A focused live-boundary test was added before production subtraction.

It protects:

- successful Snapshot publication from canonical Account Journal evidence;
- durable Transaction identity and Posting identity through Facts projection;
- Journal admission failure remaining fail-closed;
- zero Transaction/Posting Facts on admission failure.

The first run failed only because the test passed `BuildFromAccounts` arguments in the wrong order. The corrected characterization established the actual contract:

```bqn
BuildFromAccounts ⟨admittedAccounts,rawJournal,registry⟩
```

Corrected characterization CI #2762: SUCCESS.

## Reachability finding

The production owner previously exported two entry points:

```text
BuildFromAccounts
Build
```

`BuildFromAccounts` is live in canonical Actual loading.

`Build` first admitted historical `accounts.tsv` rows through `account_admission.bqn`, then forwarded to `BuildFromAccounts`. Code/reachability review found no application production consumer for that legacy entry point. Its practical consumers were test/qualification fixtures.

The repository already classifies `account_admission.bqn` as a legacy `accounts.tsv` seam rather than canonical Account authority. Keeping that dependency inside Snapshot therefore made test convenience part of the production graph.

## Test-only legacy fixture

The historical convenience was moved to:

```text
tests/legacy_snapshot_fixture.bqn
```

That helper retains the old qualification shape only for older tests:

```text
accounts.tsv fixture rows
  -> legacy account_admission
  -> production BuildFromAccounts
```

It does not duplicate Journal admission or Facts projection.

Twenty-nine tests that used `snapshot.Build` were changed only at their import boundary to use the test-only helper. Their `snapshot.Build` calls, input fixtures, and semantic expectations remain unchanged.

A full PR patch audit found and corrected two accidental fixture edits made during the mechanical migration before final qualification. The final test-file diffs are import-only.

## Production subtraction

The final production owner removes:

- the `account_admission.bqn` import;
- the legacy `Build` function;
- the public `Build` export.

It now exports only:

```bqn
{BuildFromAccounts⇐BuildFromAccounts}
```

This makes the source dependency graph match the canonical ownership contract: Snapshot does not admit Account source syntax.

Production/full migration CI #2796: SUCCESS with full `tools/check.sh` and coverage.

## Retained fail-closed staging

`BuildFromAccounts` still performs dependent staging:

```text
Journal admission
  -> only if ok, Facts projection
  -> final Snapshot state/publication
```

This is intentional semantic control flow. Facts projection must not run against rejected Journal evidence, and failed admission must not publish partial Facts. It is not a file-wide traversal or incidental mutable accumulator.

No further runtime array refactor is selected here.

## Preserved boundaries

The review does not change:

- canonical Account admission or writer authority;
- Journal grammar, exact arithmetic, balancing, identity, or provenance;
- Facts projection semantics;
- Transaction or Posting ordering;
- failure diagnostics;
- test fixture semantic expectations.

## Review conclusion

The useful subtraction was not an internal array rewrite. It was removing a legacy source-admission responsibility from a live production owner.

`src/ledger/snapshot.bqn` is now a narrow canonical composition boundary, while historical `accounts.tsv` qualification remains explicitly test-only until broader legacy retirement removes it.
