# Unfinished Plan Entries Export Contract

Status: current contract
Date: 2026-07-01

## Purpose

Define the structured export surface for choosing unfinished plan entries in UI
tools.

This contract covers the existing BQN editor export:

```text
tools/edit plan list --format tsv
```

The export is used by shell UI tools such as `tools/add-ui.sh` and
`tools/plan-finish-replenish-ui.sh` so they can select plans without reading
`plan.tsv` directly or parsing human report text.

## Entry points

Stable public wrapper:

```text
tools/edit --base <base> plan list --format tsv
tools/edit --base <base> plan list --all --format tsv
```

BQN-backed implementation path:

```text
tools/edit-bqn --base <base> plan list --format tsv
src_edit/plan_list_cmd.bqn
```

## Ownership boundary

BQN owns:

- reading and validating `<base>/plan.tsv`
- reading `<base>/journal.tsv` to identify completed `plan_id=` values
- validating accounts against `<base>/accounts.tsv`
- extracting and validating `plan_id=` metadata
- deciding whether a plan row is open, closed, missing an ID, or has an invalid ID
- rendering the stable TSV protocol rows

Shell/UI owns:

- displaying rows
- filtering/selecting one row
- prompting for follow-up user input
- passing `--id` or `--index` to later BQN editor commands

Shell/UI must not:

- read `plan.tsv` directly to derive plan status
- match `plan.tsv` against `journal.tsv` itself
- parse human report output to find plans
- parse the display field as data when a structured field exists

## Output shape

Format: TSV without a header row.

Default mode exports unfinished/open plan candidates. `--all` includes closed
rows as well.

Each row has exactly 9 fields:

| # | Field | Meaning | Stability |
|---|---|---|---|
| 1 | `number` | 1-based selection number within the emitted result set | stable for one invocation only |
| 2 | `plan_id` | extracted `plan_id=` metadata, or empty when missing | stable data when present |
| 3 | `date` | source plan date | stable |
| 4 | `memo` | source plan memo | stable |
| 5 | `from` | source from account | stable |
| 6 | `to` | source to account | stable |
| 7 | `amount` | source amount string | stable |
| 8 | `status` | machine status word, see below | stable vocabulary |
| 9 | `display` | human/UI display label for pickers | presentation helper only |

Current status vocabulary:

| Status | Meaning |
|---|---|
| empty string | open row with valid `plan_id` |
| `MISSING-ID` | open row without `plan_id=` metadata |
| `INVALID-ID` | open row with malformed `plan_id=` metadata |
| `CLOSED` | row whose `plan_id` appears in journal metadata; only emitted with `--all` |

Consumers should use field 2 (`plan_id`) when present and field 1 (`number`) as
the fallback selector. Do not parse field 9 to recover date, accounts, amount, or
status.

## Ordering and empty output

Rows are emitted in source `plan.tsv` order after filtering.

If no rows match, the TSV output is empty and exits successfully. Consumers
should treat empty output as "no candidates" rather than as an error.

## Error behavior

Invalid command arguments or invalid source rows fail closed with a non-zero exit
status. Errors are emitted as:

```text
ERROR<TAB>message
```

A failing export must not write source TSV and must not create backups.

## Compatibility expectations

This export is a UI protocol. Changes to field count, field order, status words,
or default filtering are contract changes and require check/doc updates.

Human report formatting and `FormatHuman` wording are not part of this contract.

## Checks

Current contract check:

```text
checks/check-edit-bqn-plan-list.sh
```

The check verifies read-only behavior, TSV field count, invalid format failure,
and representative status/filtering behavior.

## Related documents

- `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`
- `docs/PLAN_ID_LIFECYCLE.md`
- `docs/EDIT_BQN_DISPATCHER.md`
- `src_edit/plan_list_cmd.bqn`
