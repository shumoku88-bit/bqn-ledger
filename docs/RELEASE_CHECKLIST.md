# Release / Maintenance Checklist

Status: current maintainer checklist
Date: 2026-06-29

This repository is not packaged as a general consumer product.  A "release" means a maintainer-visible checkpoint: a tag, a GitHub release note, or a small public snapshot of the current personal-ledger engine state.

## Before a release note or tag

1. Confirm the working tree is clean except for intended changes.

   ```bash
   git status --short
   ```

2. Run the full check suite.

   ```bash
   bash tools/check.sh
   ```

3. Confirm fixture-only demo paths still work.

   ```bash
   tools/report fixtures/src-next-golden
   tools/report-next-summary fixtures/src-next-golden
   ```

4. Confirm the effective data directory guidance is still current.

   ```bash
   tools/doctor
   ```

5. If CBQN policy changed, update all of these together:

   - `README.md`
   - `CONTRIBUTING.md`
   - `docs/CBQN_REPRODUCIBILITY.md`
   - `docs/THIRD_PARTY_DEPENDENCIES.md`
   - `.github/workflows/check.yml`

6. Do not include private household data, private paths, real balances, real account names, or screenshots of real reports in public release notes.

## Release note skeleton

```markdown
## Summary

- 

## User-visible changes

- 

## Safety / data boundary

- Source TSV write behavior:
- Report number changes:
- Fixture/golden changes:

## Checks

- `bash tools/check.sh`: 

## Dependency notes

- CBQN:
- Go:
```

## After release

- Check open GitHub issues for follow-up items.
- Keep large roadmap changes in issues or active-plan docs, not in release notes.
