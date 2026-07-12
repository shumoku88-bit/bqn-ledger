# Publication manifests

This directory contains the machine-readable contract for exporting a separate public repository from the private canonical repository.

The manifests do not authorize publication by themselves. Every export remains fail-closed and must pass the complete-tree pre-sync audit defined in `docs/PUBLIC_SYNC_BOUNDARY.md`.

## Files

- `allowlist.txt`: candidate paths that may enter the exported tree. Anything not matched is denied.
- `fixtures.tsv`: fixture-level publication registry. Only rows with `public_status=approved` and `review_state=audited` may be exported.

## Current state

All fixture rows begin as `candidate` / `needs-audit`. Therefore no fixture is yet authorized for publication.

The allowlist is also provisional until dependency closure and exclusion checks prove that the resulting public tree is complete, runnable, and free of private material.

## Invariants

1. Synchronization is one-way: private canonical repository to separate public repository.
2. The public repository receives a clean exported tree, not private Git history.
3. `data/**`, private logs, snapshots, backups, credentials, tokens, personal paths, and household source data are never exported.
4. A missing, malformed, stale, or ambiguous manifest causes the export to stop.
5. Human review is required before the first public push and after any publication-boundary change.
