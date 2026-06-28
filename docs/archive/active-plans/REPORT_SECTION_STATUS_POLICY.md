# Report Section Status Policy


Status: **current policy / src_next implementation partial**
Created: 2026-06-22
Related:

```text
docs/SAFETY_PROFILE.md
docs/SAFETY_PROFILE_INVARIANT_MAP.md
docs/REPORT_CONTRACTS.md
docs/AI_CODEMAP.md
src_next/report.bqn
src_next/summary.bqn
```

This document defines how report sections should use status labels when data is invalid, incomplete, intentionally skipped, or normally unavailable.

This policy document does not change report calculations.
It does not approve hiding errors behind pretty output.

## Purpose

Safety Profile defines these future report states:

```text
OK / WARN / ERROR / SKIPPED / UNAVAILABLE
```

This policy gives those labels a stable meaning before or alongside implementation.

The goal is:

```text
Do not turn bad input into a beautiful report.
Do not turn normal absence into an error.
Do not turn disabled work into fake zeroes.
```

## Implementation status

Current `src_next` status implementation is partial.

Current implementation paths include:

```text
src_next/actual_comparison.bqn
src_next/envelope_computation.bqn
src_next/readiness_check.bqn
src_next/summary.bqn
checks/check-src-next-actual-comparison.sh
checks/check-src-next-envelope-computation.sh
checks/check-src-next-readiness.sh
checks/check-src-next-compact-summary.sh
```

Current machine-readable output is section-specific key/value text from `src_next/summary.bqn`, not a uniform `section<TAB>status<TAB>message` TSV export.

Examples:

```text
src_next_actual_comparison_status
src_next_actual_comparison_reason
src_next_envelope_status
src_next_readiness_*
```

The old `section_status_keys` / `section_status_values` / `section_status_messages` record and `export-section-status.bqn` exporter belonged to the deleted old engine. They are historical, not current guards.

Do not infer that every section has implemented machine-readable status just because this policy exists.

## Status vocabulary

| status | meaning | section may show numbers? | exit behavior idea |
|---|---|---:|---|
| `OK` | The section contract was satisfied. | yes | normal output |
| `WARN` | Output is possible, but compatibility fallback or noteworthy limitation was used. | yes, with warning | normal output + warning |
| `ERROR` | Source data or section precondition is invalid. The section is not trustworthy. | no | fail closed / non-zero for strict mode |
| `SKIPPED` | The section is intentionally disabled or not requested. | no | omit intentionally |
| `UNAVAILABLE` | Inputs are valid, but the value is not defined, usually because history or baseline is missing. | no or partial context only | normal output with unavailable marker |

## Global rules

### Invalid source data means `ERROR`

Use `ERROR` when the source data violates a contract.

Examples:

- invalid date format,
- non-integer amount,
- unknown account,
- future row in `journal.tsv`,
- budget account used outside `budget_alloc.tsv`,
- required metadata missing for a section that cannot compute without it,
- cycle configuration that cannot define a safe current cycle.

Do not render a normal-looking numeric table for that section.

### Compatibility fallback means `WARN`

Use `WARN` when a documented fallback or compatibility path is used and the output remains meaningful.

Examples:

- old `plan.tsv` row without `plan_id` using documented fallback behavior,
- missing optional display metadata with a documented display fallback,
- older data layout accepted temporarily with an explicit warning.

Do not silently hide fallback behavior.

### Normal missing baseline means `UNAVAILABLE`

Use `UNAVAILABLE` when input is valid but a comparison cannot be defined.

Examples:

- previous cycle history is absent for `actual-comparison`,
- forecast-derived section is requested before forecast has a contract,
- baseline amount is zero and ratio is not mathematically meaningful,
- not enough elapsed days exist for a comparable window.

Do not coerce this to zero.

### Intentional non-output means `SKIPPED`

Use `SKIPPED` when a section or feature is intentionally disabled, removed, not requested, or outside current scope.

Examples:

- deleted `residual` main section,
- disabled consultation export,
- future debug/provenance section not enabled in a normal report,
- optional section omitted by `--section` selection.

Do not present skipped work as an empty successful report.

### Contract satisfied means `OK`

Use `OK` only after the section’s required input contract is satisfied.

A section can be `OK` even if values are zero, as long as zero is the real computed value.

## Section policy table

| section key | normal status | `WARN` cases | `ERROR` cases | `UNAVAILABLE` cases | `SKIPPED` cases |
|---|---|---|---|---|---|
| `snapshot` | `OK` | optional display metadata fallback | invalid accounts, invalid journal rows, internal asset invariant failure | none expected | not requested |
| `ytd` | `OK` | legacy naming/display fallback | invalid journal rows, invalid dates, unknown accounts | none expected | not requested |
| `balances` | `OK` | display-only fallback | invalid accounts or broken actual layer | none expected | not requested |
| `cycle` | `OK` | documented cycle default/fallback if accepted | cycle cannot be resolved, cycle config invalid | insufficient historical cycle only if requested as comparison | not requested |
| `envelopes` | `OK` | optional health label limitation | missing required budget mapping, budget row boundary violation, broken budget layer | no active budget envelopes only if treated as normal absence | not requested |
| `planned` | `OK` | `plan_id` missing fallback, if documented and accepted | invalid plan row, unknown account, invalid plan anchor | no open plans is normal `OK` with empty list | not requested |
| `recent` | `OK` | none expected | invalid journal rows | empty journal can be `OK` with empty list | not requested |
| `check` | `OK` | hygiene warnings found | strict error in source data | none expected | not requested |
| `outlook` | `OK` | lag/context warning, documented fallback | invalid cycle, invalid future plan inputs, broken daily divisor contract | no future horizon only if horizon becomes optional | not requested |
| `daily-trend` | `OK` | sparse history limitation | invalid journal/cycle inputs | insufficient trend data if no meaningful trend exists | not requested |
| `actual-comparison` | `OK` | ratio display caveat such as `new` / `n/a` | invalid actual data or invalid cycle window | previous comparable cycle missing, insufficient history, baseline unavailable | not requested |
| `debug` | `OK` | diagnostic-only warnings | invariant failure | requested provenance unavailable because not implemented | not requested / disabled in normal output |

## Section-specific notes

### `snapshot`

`summary`, `overview`, and `snapshot` aliases must share one status result.

`assets_total`, `liabilities_total`, and derived totals should not render as normal values if the basic accounting invariant fails.

### `cycle`

The current cycle is a time-window view, not a source data mutation.

If the current cycle cannot be safely resolved, the section should be `ERROR`, not a guessed cycle.

Historical comparison absence belongs to `UNAVAILABLE`, not `ERROR`, when current-cycle computation itself is valid.

### `envelopes`

Envelope absence and envelope invalidity are different.

- No configured envelope activity can be `UNAVAILABLE` or `OK` with an empty table, depending on the final contract.
- Variable expense without required budget mapping is `ERROR`.
- Budget rows outside `budget_alloc.tsv` are `ERROR`.

### `planned`

Completed plan rows remain source history and may appear in plan status views.

Missing `plan_id` is not automatically fatal while the documented fallback exists. It should be `WARN` when shown, because it is a compatibility path.

### `check`

`check` is allowed to show warnings and errors directly.

Its own section status should distinguish:

```text
OK   = no strict errors, no warnings
WARN = no strict errors, warnings exist
ERROR = strict errors exist
```

Current implementation note:

- `src_next/readiness_check.bqn` and compact summary readiness fields expose current readiness diagnostics.
- Current `ERROR`-like readiness failures include required metadata/readiness failures such as missing account role, missing asset type, missing expense spend class, or missing variable budget mapping.
- A uniform `section<TAB>status<TAB>message` export is not currently present in `src_next`.

### `actual-comparison`

`actual-comparison` must distinguish invalid input from missing baseline.

- Invalid current actual/cycle data is `ERROR`.
- Missing previous comparable cycle is `UNAVAILABLE`.
- Baseline zero ratio cases should use documented row-level statuses such as `new`, `n/a`, or equivalent labels, not fake percentages.

Current implementation note:

- `src_next/actual_comparison.bqn` exposes status/reason through compact output keys such as `src_next_actual_comparison_status` and `src_next_actual_comparison_reason`.
- `ok` maps to `OK`-like behavior.
- `unavailable` / `insufficient_history` map to `UNAVAILABLE`-like behavior.
- Unavailable baseline is not converted to zero.

### `debug`

`debug` can expose invariant failures and provenance context.

It should not become a normal user-facing section that hides failure behind diagnostics.

## Relationship to existing checks

Existing current guards support part of this policy:

- `tools/check.sh` runs BQN unit tests, Go editor tests, `src_next` golden fixtures, section checks, repo-index check, and disabled-feature guard.
- `checks/check-src-next-actual-comparison.sh` checks actual-comparison status/reason output.
- `checks/check-src-next-readiness.sh` checks readiness diagnostics.
- `checks/check-src-next-envelope-computation.sh` and `check-src-next-envelope-production-guard.sh` check envelope status behavior and guard against production advice leakage.
- `checks/check-src-next-golden.sh` fixtures protect stable compact diagnostic output, including skipped rows and validation summaries.
- `tests/test_src_next_*.bqn` cover pure module behavior.

## Implementation guidance

When implementation continues, prefer small steps:

1. Treat `actual-comparison`, readiness, and envelope status fields as current partial slices.
2. Add fixture coverage for one additional `WARN` or `UNAVAILABLE` case before expanding to more sections.
3. Only then expand status reporting to another section.
4. Do not retrofit every section in one large change.

## Next TODOs

1. Add or confirm an `actual-comparison` unavailable fixture if existing historical-cycle fixtures are not enough.
2. Add a `planned` warning case for `plan_id` fallback if this warning is desired.
3. Add a section-level strict error fixture for a source-data failure that would otherwise produce pretty output.
4. Update `docs/REPORT_CONTRACTS.md` only when status output becomes part of a report/export contract.

## Non-goals

- Do not change section calculations.
- Do not edit source TSV data.
- Do not revive deleted `residual` main section.
- Do not make `UNAVAILABLE` mean zero.
- Do not make `WARN` a way to ignore invalid data.
