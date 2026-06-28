# Section Status Implementation Handoff

Status: **initial implementation and machine export completed**
Created: 2026-06-22
Updated: 2026-06-22
Related:

```text
docs/SAFETY_PROFILE.md
docs/SAFETY_PROFILE_INVARIANT_MAP.md
docs/REPORT_SECTION_STATUS_POLICY.md
docs/MAIN_SECTIONS.md
docs/REPORT_FIELD_MAP.md
docs/REPORT_CONTRACTS.md
src/reports/report_engine.bqn
src/reports/exporters/export-section-status.bqn
checks/check-section-status.bqn
checks/check-section-status.sh
```

> [!NOTE]
> **Status Note**:
> `check` および `actual-comparison` セクションに対する initial section status slice は完了しました。
> Option A として `report_engine.BuildAt` の return record に `section_status_keys`, `section_status_values`, `section_status_messages` を追加済みです。
> さらに `export-section-status.bqn` により `section<TAB>status<TAB>message` の machine-readable TSV export も追加済みです。
> この文書は履歴兼、次の拡張時の handoff として残します。

## Completed scope

Implemented sections:

```text
check
actual-comparison
```

Implemented public record fields:

```text
section_status_keys
section_status_values
section_status_messages
```

Implemented exporter:

```text
src/reports/exporters/export-section-status.bqn
```

Exporter TSV contract:

```text
section	status	message
```

Implemented checks:

```text
checks/check-section-status.bqn
checks/check-section-status.sh
```

`checks/check.sh` runs both the in-record status check and the TSV exporter consistency check.

## Current behavior

### `check`

Initial rule:

```text
ERROR = strict/readiness error exists
WARN  = no strict/readiness error, but hygiene warnings exist
OK    = no strict/readiness error and no warnings
```

Current `ERROR` is derived from required metadata/readiness failures such as:

```text
check_accounts_missing_role
check_assets_missing_type
check_expenses_missing_spend_class
check_variable_missing_budget
```

Future work may refine generic messages into more specific metadata/readiness messages.

### `actual-comparison`

Initial rule:

```text
OK = actual_comparison_observation_status == "ok"
UNAVAILABLE = actual_comparison_observation_status in ⟨"unavailable", "insufficient_history"⟩
```

Unavailable baseline is not converted to zero.
The table can remain empty when comparison is unavailable, because section status now explains why.

## Non-goals preserved

Do not do these without a separate decision:

- Do not change source TSV data.
- Do not change `BuildCube` meaning.
- Do not retrofit every section in one sweep.
- Do not change existing numeric output values unless a test explicitly requires it.
- Do not revive the deleted `residual` main section.
- Do not make `UNAVAILABLE` mean zero.
- Do not use `WARN` to hide invalid data.
- Do not widen Go editor write scope.

## Review checklist for future section-status expansion

Before adding status to another section, confirm:

- [ ] No source TSV data changes are needed.
- [ ] `BuildCube` behavior does not change.
- [ ] Existing human report output changes only if intentionally tested.
- [ ] Any new public fields are documented in `docs/REPORT_FIELD_MAP.md`.
- [ ] Any new status meaning matches `docs/REPORT_SECTION_STATUS_POLICY.md`.
- [ ] `tools/check.sh` passes.

## Next recommended direction

Do not keep widening section status immediately unless a concrete need appears.

Recommended next canonical-hardening task:

```text
cube shape / layer count invariant
```

If section status work resumes later, prefer one small slice:

```text
planned WARN for plan_id fallback
```

or one fixture class:

```text
additional actual-comparison UNAVAILABLE / WARN coverage
```

## Handoff note

This was a calibration task, not a feature sprint.

```text
First make the status visible.        Done.
Then make it useful.                  Done for machine export.
Then decide whether it belongs everywhere.  Not yet.
```
