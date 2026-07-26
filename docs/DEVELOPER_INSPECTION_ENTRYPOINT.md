# Developer inspection entrypoint

Status: current diagnostic entrypoint contract
Owner: developer inspection / diagnostics
Canonical: yes for the low-level inspection entrypoint
Updated: 2026-07-26

## Purpose

The named low-level diagnostic entrypoint is:

```text
src_next/developer_inspection.bqn
```

It is a read-only developer surface for inspecting:

- resolved AccountKeys;
- checked Posting IR rows;
- source-group balance diagnostics;
- Canonical Daily Cube shape and numeric sanity;
- selected household-policy and metadata diagnostics.

It is not the production human report path.

```text
production: tools/report -> src_next/report.bqn
diagnostic: tools/report-next -> src_next/developer_inspection.bqn
```

## `main.bqn` compatibility wrapper

`src_next/main.bqn` no longer owns diagnostic implementation. It only:

1. imports `developer_inspection.bqn`;
2. delegates its explicit base-directory argument to the exported `Run` function.

The wrapper exists because the repository is public and an unknown clone may still call:

```text
bqn src_next/main.bqn <base>
```

Current checks require the wrapper and named entrypoint to return identical:

- exit status;
- stdout bytes;
- stderr bytes.

New code, tools, tests, and current documentation must use `developer_inspection.bqn` directly. No implementation may move back into `main.bqn`.

## Removal condition

The wrapper is not permanent architecture. It may be removed at an explicit stability boundary after all of the following are true:

- current repository callers use the named entrypoint;
- a release note or compatibility note announces the removal;
- the repository has a defined internal-module stability policy;
- no current supported command depends on the old filename;
- the removal is performed as its own finite slice with CI and documentation synchronization.

Absence of visible third-party callers is not proof that no clone uses the filename. It is also not a reason to retain a misleading implementation owner forever. The thin wrapper keeps those concerns separate.

## Verification

- `checks/check-developer-inspection-entrypoint.sh` checks byte-equivalent old/new behavior and the thin-wrapper source shape.
- `checks/check-projection-diagnostic-presentation.sh` keeps presentation ownership outside `projection.bqn` and production `report.bqn`.
- `checks/check-src-next-golden.sh` runs the named entrypoint over public fixtures.
- `tools/check.sh` runs the complete evidence gate.
