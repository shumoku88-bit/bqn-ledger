# Maintenance

## Daily checks

```sh
tools/doctor
tools/check.sh
```

Use `tools/ledger-check` for strict household readiness and `tools/ledger-inspect` for canonical provenance.

## Change workflow

1. Identify the public behavior or accounting question being changed.
2. Change one coherent slice. An owner and all of its consumers may move together.
3. Run focused evidence, full `tools/check.sh`, coverage, and final current-main review.
4. Remove superseded code, wrappers, tests, and documents in the same slice.

Report code keeps source I/O and clocks in `src/application/`, semantic results in `src/sections/`, and final catalog/composition in `src/report/`. Editors keep preview, stale checks, backup, atomic write, and narrow post-write validation.

## Documentation

Update documentation only when a public command, data format, user-visible result, or ownership boundary changes. Internal algorithm and representation changes do not require README, TODO, architecture, catalog, audit, or code-map edits.

Delete completed plans and observations when they are no longer current. Git history preserves their historical versions when later investigation needs them.
