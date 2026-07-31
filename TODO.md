# Notes and open directions

## Current state

- Strict Native Journal plus Plan, Budget, Account, Cycle, Issues, and Daily Target admission is production.
- Canonical Transaction and Posting Facts live under `src/ledger`; reusable calculations live under `src/accounting`.
- Retained reports share the explicit catalog, composition, and current-profile boundaries.
- Canonical household data remains in the private data repository.

## Current direction

Simplify before adding more structure.

- remove row-object assembly, repeated whole-evidence scans, append loops, and deep success-condition nesting;
- expose the relevant axes, coordinates, grouping, and reductions directly;
- validate at the public boundary, keep the pure kernel small, and publish once;
- move an owner and all affected consumers together, then delete the old path;
- do not require exploration records, audits, or documentation updates for an internal algorithm rewrite;
- do not add universal contexts, generic query layers, compatibility wrappers, or speculative integration protocols.

Correctness changes remain explicit decisions. Meaning-preserving simplification should reduce incidental machinery rather than preserve it.