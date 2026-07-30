# Maintenance

## Daily checks

```sh
tools/doctor
tools/check.sh
```

Strict household readiness is checked separately with `tools/ledger-check`; canonical provenance is inspected with `tools/ledger-inspect`.

## Report changes

1. Identify the narrow Fact or accounting capability required by the question.
2. Keep source I/O and clock access in `src/application/`.
3. Implement the semantic result in `src/sections/` without reading files or another section result.
4. Add only approved renderers.
5. Register a final key/surface in `src/report/catalog.bqn` when it is a retained user question.
6. Update human/compact manifest source and nonvolatile policy explicitly when their meaning changes; do not advance daily observation dates for Command Hub, which resolves them through the current profile.
7. Test positive, empty, invalid, provenance, direct/all/cache, and supported structured surfaces.

Do not introduce broad contexts, source-shape fallbacks, old-key aliases, or forwarding modules. Operational diagnostics belong in `tools/ledger-check` or `tools/ledger-inspect`, not the report catalog.

## Editor changes

Use preview, stale checks, backup, atomic write, and a narrow post-write validator. Editors consume canonical strict admission where the same source is read by reports. Private household changes stay in the private data repository.

## Documentation

Keep `README.md`, `TODO.md`, `docs/ARCHITECTURE.md`, and `docs/AI_CODEMAP.md` current. Move historical plans to `docs/archive/` or delete them when Git history is sufficient.
