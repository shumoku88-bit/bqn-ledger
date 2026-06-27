# GENERALIZATION_TODO status

Status: **completed phases archive note created / active remainder pending**
Date: 2026-06-22

`docs/GENERALIZATION_TODO.md` is still useful as the design background for lifestyle configuration, but many phase checkboxes are stale compared with `TODO.md` and the current repository state.

Do not treat the whole document as a fresh TODO list.

## Current task truth

```text
TODO.md
docs/DOCS_HYGIENE_AUDIT-2026-06-22.md
docs/GENERALIZATION_TODO.status.md
```

## Trust order

1. `TODO.md` for current next actions.
2. `docs/DOCS_HYGIENE_AUDIT-2026-06-22.md` for docs cleanup status.
3. `docs/GENERALIZATION_TODO.status.md` for current reading guidance.
4. `docs/GENERALIZATION_TODO.md` as planning background until compressed.
5. `docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md` for completed / mostly completed phase history.

## Completed phases archive note

Completed / mostly completed phase details now have a digest here:

```text
docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md
```

Use that archive digest to understand completed generalization work without rereading the old roadmap as current TODOs.

## Current reconciliation snapshot

From `TODO.md`, these lifestyle-configuration items are already complete or mostly complete:

- `role=` contract and Prefix fallback documented.
- non-Prefix account fixture added.
- Phase 4 Base-aware Context completed.
- Legacy compatibility cleanup completed.
- Real data `accounts.tsv` migration is treated as a separate confirmed phase, and real data already has explicit `role=` according to current notes.
- Prefix fallback use counts are now explicitly tracked in `src_next_household_metadata_prefix_fallback_total_count`.
- Conditions for fully removing the Prefix fallback are documented in `docs/ACCOUNT_ROLE_CONTRACT.md`.
- `check-src-next-lint.sh` is now active and checks for duplicate values, unknown values, and missing mandatory values before fail-closed or warnings.

Still current or still needs a separate decision:

- Any next configuration-externalization candidate must respect the Safety Profile.
- Canonical Daily Cube shape and Layer contracts must not become user configuration.
- New coordinates or meanings should become separate projections/views rather than extra Daily Cube axes.

## Recommended cleanup

Do not delete or rewrite the original plan immediately if the replacement would be large. The completed-phases archive note now exists, so the next optional cleanup is to shorten the active file later if needed.

Suggested future active shape:

```text
# bqn-ledger: lifestyle configuration active remainder

Status: active remainder / compressed

Current active work:

1. Prefix fallback removal decision.
2. Configuration boundary policy.
3. Safety Profile compatibility.

Historical completed phase details:

- docs/archive/completed-plans/GENERALIZATION_COMPLETED_PHASES.md
```

## Non-goals

- Do not edit source TSV data.
- Do not change Canonical Daily Cube shape or Layer meaning.
- Do not remove Prefix fallback without a separate explicit decision.
- Do not turn configuration into a DSL for arbitrary accounting computation.
