# TODO History - 2026-07-06

Status: Historical completion snapshot created during TODO structure cleanup.

This file records completed items removed from `TODO.md` when the active queue was split from continuous maintenance.

## Envelope hybrid backing policy work completed before this cleanup

- `docs/LIQUID_ASSETS_TERMINOLOGY_RENAME_PLAN.md` reorganized the human-facing term `流動資産` to `可用資金`; `type=liquid` and machine keys remained compatible.
- `docs/ENVELOPE_FUNDING_BASE_INVARIANT.md` separated `封筒対象資金`, `予算台帳未割当`, and `現金裏付け未割当`.
- `src_next/envelope_computation.bqn` gained readonly backing diagnostics, provenance, and budget movement provenance.
- Short-term hybrid policy C was adopted: `budget_alloc.tsv` remains the allocation-ledger source of truth, cash-backing unassigned remains readonly diagnostic, `MISMATCH` remains diagnostic rather than a strong warning, and only `OVER_ALLOCATED` is a strong warning.
- Adjustment-row operation design was completed in `docs/ENVELOPE_ADJUSTMENT_ROW_POLICY.md`.
- Cycle-seed basis was designed in `docs/ENVELOPE_CYCLE_SEED_POLICY.md`.
- Reserve / savings / investment envelopes were classified as execution envelopes in `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`.
- Fixed-cost envelope versus planned-payment reservation double-counting risk was documented in `docs/ENVELOPE_EXECUTION_AND_PLAN_POLICY.md`.
- `budget_pool=main` metadata need and fixture/check direction were decided docs-only as a future direction while preserving current fallback behavior in `docs/ENVELOPE_BUDGET_POOL_METADATA_POLICY.md`.
- Human `envelopes` output was separated into Dynamic / Execution / Unassigned / Backing diagnostic while preserving existing machine keys and avoiding automatic correction.
- Real-data `envelope_role=` candidates were inventoried and applied after moko review with backup.
- Unknown `envelope_role` fixture/check coverage was added and unknown roles were excluded from active total.
- Unknown / kind mismatch diagnostics were added to readiness diagnostics.

## Plan temporal status work completed before this cleanup

- Execution-envelope `DUE` / `LATE` / `MISSING` candidates were reframed as an envelope-independent temporal projection in `docs/archive/active-plans/PLAN_TEMPORAL_STATUS_PROJECTION_PLAN-2026-07-05.md`.
- Existing `future` / `due` / `overdue` / `completed` meaning was behavior-preservingly extracted from `planned_payments.BuildViewModel` into an explicit-`as_of` projection.

## Structured report output foundation completed before this cleanup

- `tools/report --section <key> --format json` dispatch entry was implemented.
- `planned` ViewModel JSON output was implemented.
- `balances` ViewModel JSON output was implemented.
- `snapshot` ViewModel JSON output was implemented.
- `envelopes` ViewModel JSON output was implemented, with design in `docs/ENVELOPES_SECTION_JSON_EXPORT_DESIGN.md`.
- JSON helpers were centralized in `src_next/json.bqn`.
- The boundary that UI must not parse human report strings was guarded by `checks/check-structured-ui-boundary.sh` while preserving `FormatHuman`.

## Configuration externalization workstream status at cleanup

- A4 config resolution was closed as `complete enough for now`.
- Raw config behavior had been characterized.
- Typed sparse override had a real runtime proof.
- Raw/effective separation existed for LIFE / RESERVE group configuration.
- Remaining config questions were intentionally left as independent future problems rather than an automatically continuing key-by-key migration.

## Docs hygiene work completed before this cleanup

- Docs lifecycle contract was added in `docs/DOCS_LIFECYCLE_CONTRACT.md`.
- `checks/check-docs-lifecycle.sh` was added to inspect new-doc `Status:` presence and changed archive docs that incorrectly claim current status.
- `docs/README.md` was moved toward a canonical routing table by topic.

## Why these items moved

`TODO.md` is for current work, next candidates, and continuous maintenance loops. Completed work should remain discoverable through canonical docs and historical snapshots instead of accumulating as permanent checked boxes in the active queue.
