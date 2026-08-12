# Source I/O review observation — 2026-08-12

## Scope

Review `src/application/source_io.bqn` as the shared read-only application I/O boundary used by both Report adapters and the upcoming Editor / `src_edit` review.

## Existing responsibility

The owner deliberately sits between pure text parsing and schema/domain admission:

```text
path / raw file effect
  -> preserved raw text or filtered data rows
  -> downstream schema/domain admission
```

It does not own canonical basenames, source discovery, accounting meaning, diagnostics, writers, shell/process control, clocks, or publication.

The neutral parser in `src/text/parse.bqn` remains the owner of split semantics. `source_io.bqn` re-exports the split surfaces that live editor consumers use at the I/O boundary, including empty-field-preserving TSV handling.

## Reachability observation

Repository-wide consumer review found live Phase 6 consumers of:

- `ReadRaw`;
- `ReadLinesOptional`;
- `SplitKeepEmpty`;
- `SplitTsvKeepEmpty`;
- the shared read/path-composition family.

For example, issue/editor command owners use the empty-preserving split surfaces to retain source row shape and line-coordinate evidence. Removing or replacing those exports during the Application closeout would pre-empt the later owner-specific Editor review.

`ResolvePath`, however, has no external consumer. It is an implementation detail of `ReadRaw` and `ReadLinesOptional` and exposes ambient working-directory resolution rather than a domain/application capability.

## Decision

Keep the shared I/O surface conservative and make only the justified subtraction:

- `ResolvePath` remains local and is no longer exported;
- absolute versus relative resolution is selected lazily with `◶`;
- an absolute path therefore does not unnecessarily construct a working-directory-relative candidate;
- `JoinPath`, raw/line reads, optional line reads, and live split helpers remain available to their current consumers.

No generic filesystem abstraction, path object, error wrapper, or Editor migration is introduced here.

## Optional-read boundary

`ReadLinesOptional` keeps its existing meaning:

- a missing path is represented by an empty row axis;
- an existing but unreadable path is still an I/O failure.

That distinction is application/editor behavior, not a generic silent-failure policy, and must not be collapsed while later Editor consumers still depend on it.

## Test and fixture classification

No new fixture is introduced.

`tests/test_source_io_ownership.bqn` already proves:

- pure split semantics remain owned by `src/text/parse.bqn`;
- Source I/O delegates `Split` / `SplitKeepEmpty` rather than implementing another parser;
- `JoinPath` preserves an existing trailing slash;
- CR stripping and data-line filtering remain stable;
- TSV empty fields are preserved.

`checks/check-source-io-ownership.sh` is the architecture law owner. It now also protects that ambient path resolution remains private and that absolute/relative path behavior is selected lazily.

Later Editor owner reviews remain responsible for deciding whether their individual uses of the shared split/read surfaces can be narrowed. The Application closeout does not guess ahead of those reviews.

## Protected boundaries

Unchanged:

- pure parser ownership;
- read-only application I/O ownership;
- source byte/row preservation before admission;
- shared `JoinPath` ownership;
- relative path resolution against the process working directory;
- absolute path identity;
- missing-only optional line reads;
- live editor split/TSV surfaces;
- absence of shell/process/clock/publication behavior;
- writer authority.
