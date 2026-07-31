# AI code map

## Start here

1. `TODO.md` — current direction.
2. `docs/ARCHITECTURE.md` — production ownership and data flow.
3. `docs/BQN_SIMPLIFICATION.md` — default rule for BQN code shape and cleanup.
4. The target owner and its focused tests.
5. `README.md` only when command usage is relevant.

Read a specialized contract only when the change touches that boundary. Do not read `docs/archive/` as current instruction.

## Runtime map

- `src/ledger/` — strict source admission, exact decimal/date values, canonical Transaction and Posting Facts, identity, and provenance.
- `src/accounting/` — presentation-neutral accounting transformations over admitted Facts.
- `src/sections/` — one retained semantic result per user question.
- `src/report/` — final request catalog, composition, and renderer dispatch.
- `src/application/` — source adapters, current-profile resolution, CLIs, and other effectful boundaries.
- `src/editor/` and `src_edit/` — pure rewrite semantics and command adapters.
- `tools/` — thin operational entry points and write orchestration.

## Change rules

- Keep dependencies one-way from admission to accounting to sections to composition.
- Preserve one authoritative writer and strict household-data boundaries.
- Prefer standalone BQN while it remains sufficient.
- For simplification, move an owner and all consumers together, then delete the old path. Do not leave forwarding modules or aliases.
- Internal modules, namespaces, stages, and local representations are not contracts merely because they already exist.
- New functionality is a correctness decision. A meaning-preserving rewrite may freely replace incidental structure.
- Update current documentation only when a public command, data format, user-visible result, or ownership boundary changes.