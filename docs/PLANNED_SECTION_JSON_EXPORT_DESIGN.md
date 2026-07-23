# Planned Section JSON Export Design

Status: design slice / docs-only
Date: 2026-07-03

## Purpose

This document defines the first small design slice for report section JSON output.

The goal is not to turn the whole report into JSON. The goal is to choose one safe report section, define its structured output contract, and keep the existing human report path stable.

## First target

The first target section is `planned`.

Reasons:

- `planned` already has a documented section checklist example in `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`.
- It already has a clear human renderer: `planned_payments.FormatHuman ctx`.
- It already has a compact renderer: `planned_payments.Format ctx`.
- It has a useful UI and automation surface: unfinished planned payments, completed planned payments, totals, and row status.
- It is smaller and less policy-heavy than `envelopes`.

`envelopes` remains a good later candidate, but it has more diagnostic states and policy-specific meanings. It should not be the first JSON ViewModel export.

## Non-goals

This design does not require or authorize:

- full report JSON output
- JSON output for every section
- changing `tools/report` default human output
- removing or weakening `FormatHuman`
- parsing human report strings to produce JSON
- source TSV schema changes
- shell-side reimplementation of planned payment meaning
- automatic writes to the configured native Journal, `plan.tsv`, `budget_alloc.tsv`, or `accounts.tsv`

## Proposed CLI boundary

Future implementation should start with this narrow shape:

```bash
tools/report --section planned --format json
```

Initial constraints:

- `--format json` requires `--section`.
- Only `--section planned --format json` is supported in the first implementation slice.
- Calling `tools/report --format json` without a section should fail closed with a clear message until full-report JSON is explicitly designed.
- Human output remains the default when `--format` is omitted.

This keeps the first implementation from accidentally promising a stable full-report API.

## JSON shape

The first JSON output should be a top-level object, not a top-level array.

A top-level object leaves room for section identity, status, cycle metadata, warnings, and totals without changing the row shape later.

Example shape:

```json
{
  "section": "planned",
  "status": "OK",
  "as_of": "2026-07-03",
  "cycle": {
    "start": "2026-06-15",
    "end_exclusive": "2026-08-15"
  },
  "open": [
    {
      "date": "2026-07-10",
      "memo": "example",
      "from": "assets:bank",
      "to": "expenses:food",
      "amount": 1200,
      "status": "future",
      "plan_id": "p-001"
    }
  ],
  "completed": [],
  "totals": {
    "open_amount": 1200,
    "completed_amount": 0
  },
  "warnings": []
}
```

## Required top-level fields

Required fields for the first contract:

- `section`: stable section key. For this slice, always `planned`.
- `status`: section-level status.
- `open`: array of unfinished in-cycle planned payment rows.
- `completed`: array of completed in-cycle planned payment rows.
- `totals`: object containing numeric totals.
- `warnings`: array. Empty when there are no warnings.

Recommended but implementation-dependent fields:

- `as_of`: report observation date in `YYYY-MM-DD`.
- `cycle`: object containing `start` and `end_exclusive` when cycle context is available.

If `as_of` or `cycle` cannot be exported in the first implementation without broad refactoring, they may be deferred. Do not fake them.

## Planned row fields

Required row fields:

- `date`: source planned date in `YYYY-MM-DD`.
- `memo`: source memo string. Empty memo stays an empty string.
- `from`: source from account key.
- `to`: source to account key.
- `amount`: integer yen amount.
- `status`: row-level planned payment status.

Optional row fields:

- `plan_id`: string when present, otherwise `null` or omitted according to the concrete implementation contract.
- `actual_date`: completed row actual date, when known.
- `actual_amount`: completed row actual amount, when known.
- `source_row`: source row number, if exposing it is useful for diagnostics and does not create a brittle public contract.

The first implementation should choose either `null` or omitted for absent optional values and document the choice. Do not mix both for the same field.

## Status vocabulary

Section-level status and row-level status are separate.

Section-level status:

- `OK`: the section computed normally.
- `WARN`: the section computed with visible non-fatal warnings.
- `ERROR`: required source data or parsing failed and the output cannot be trusted.
- `UNAVAILABLE`: optional data needed for a requested field is unavailable.
- `SKIPPED`: the section was intentionally not computed.

Row-level status for `planned`:

- `future`
- `due`
- `overdue`
- `completed`

Do not use human labels as machine status words. Human labels may be translated or reformatted later.

## Empty and unavailable behavior

Empty planned rows are not an error.

Recommended empty output:

```json
{
  "section": "planned",
  "status": "OK",
  "open": [],
  "completed": [],
  "totals": {
    "open_amount": 0,
    "completed_amount": 0
  },
  "warnings": []
}
```

Important rules:

- No open plans means `open: []`, not `UNAVAILABLE`.
- No completed plans means `completed: []`, not `UNAVAILABLE`.
- Missing optional information must not be silently converted into numeric zero.
- Invalid rows must not become valid-looking JSON rows.
- If an implementation cannot safely distinguish empty from unavailable, it should fail closed rather than emit misleading JSON.

## Boundary rules

JSON must be produced from BQN-owned interpretation, ViewModel data, or section-owned calculation results.

JSON must not be produced by:

- grepping human report prose
- splitting aligned human tables
- interpreting Japanese or English human labels
- relying on terminal layout or spacing
- reimplementing planned payment matching rules in shell

`FormatHuman` remains the daily human report renderer. JSON output is a structured export sibling, not a replacement.

## Check direction

The first implementation PR should add the smallest checks that protect the contract.

Minimum useful checks:

- `tools/report --section planned --format json` emits valid JSON.
- top-level `section` is `planned`.
- required fields exist: `section`, `status`, `open`, `completed`, `totals`, `warnings`.
- `amount` and totals are numbers, not formatted strings.
- dates use `YYYY-MM-DD`.
- an empty planned fixture emits empty arrays and zero totals.
- the default human `tools/report --section planned` output remains available.

The check may use the project’s existing shell check style. It should not require a new heavyweight dependency unless there is a separate dependency decision.

## Implementation notes for later

Open questions for the implementation PR:

- whether to place JSON helpers in `src_next/json.bqn` or keep them local to the first section
- whether absent optional fields use `null` or are omitted
- whether `as_of` and `cycle` are available without expanding `ctx`
- whether `completed` rows should expose actual values in the first slice or defer them
- whether `source_row` is useful enough to become part of the contract

These should be decided in the implementation PR only as far as needed for the first `planned` JSON slice.

## Related documents

- `docs/STRUCTURED_UI_EXPORT_CONTRACT.md`
- `docs/REPORT_CONTRACTS.md`
- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`
- `docs/UNFINISHED_PLAN_ENTRIES_EXPORT_CONTRACT.md`
- `src_next/planned_payments.bqn`
- `src_next/report.bqn`
- `src_next/summary.bqn`
