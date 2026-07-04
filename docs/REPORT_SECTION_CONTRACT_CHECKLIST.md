# Report Section Contract Checklist

Status: current checklist / reference example
Date: 2026-07-01

Purpose: keep `src_next` report sections from drifting into local, incompatible conventions. This is a checklist for adding or changing one human report section and its related machine-readable summary output.

This document does not replace the implementation sources of truth:

1. `tools/report --list-sections`
2. `src_next/report.bqn`
3. `src_next/summary.bqn`
4. `checks/check-src-next-*.sh` and `tests/test_src_next_*.bqn`

## Section contract checklist

When adding or changing a section, record or verify the following.

### Identity and routing

- [ ] Stable section key used by `tools/report --list-sections` and `tools/report --section <key>`.
- [ ] Owning module under `src_next/`.
- [ ] Human renderer function name, usually `FormatHuman`.
- [ ] Machine/compact renderer function name, if present.
- [ ] Registration in `src_next/report.bqn`.
- [ ] Registration in `src_next/summary.bqn`, if the section has machine-readable output.

### Data ownership

- [ ] Required `ctx` fields are named explicitly.
- [ ] Optional source TSV files are identified as optional, and missing-file behavior is explicit.
- [ ] Required source/config files are identified as required, and failures are fail-closed.
- [ ] The section does not mutate source TSV or derived context.
- [ ] Accounting meaning stays in BQN; shell/UI only selects or displays section output.

### Input and empty-state behavior

- [ ] Empty input behavior is deterministic and visible (`(none)`, `SKIPPED`, `UNAVAILABLE`, warning text, etc.).
- [ ] Invalid rows do not silently become valid-looking numbers.
- [ ] Optional unavailable data is not conflated with zero.
- [ ] Date/as-of assumptions are explicit and reproducible.

### Status and diagnostics

- [ ] If the section emits status, it uses the project vocabulary: `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` or a documented section-local status set.
- [ ] Warnings/errors say which source, line, field, or rule caused the condition when practical.
- [ ] Partial or guarded behavior is labelled rather than presented as final advice.

### Labels and presentation

- [ ] Human-facing labels come from `config/report_labels.tsv` via `src_next/report_labels.bqn`, unless there is a documented exception.
- [ ] Table columns use width helpers when CJK/alignment matters.
- [ ] ANSI color is presentation-only and respects `--no-color` / color-filter paths.
- [ ] Section output can stand alone when called via `tools/report --section <key>`.

### Machine-readable output

- [ ] Compact output keys are stable and grep/query friendly.
- [ ] Machine output preserves enough fields for downstream checks without parsing human tables.
- [ ] Human labels are not treated as machine keys.
- [ ] Summary fields are covered by `tools/query` or check scripts when they become relied upon.

### Fixture/check coverage

- [ ] At least one fixture/check confirms section presence or `--section` extraction.
- [ ] Empty input or missing optional source behavior is checked when relevant.
- [ ] Invalid input/fail-closed behavior is checked when relevant.
- [ ] Machine-readable keys are checked when they are part of the contract.
- [ ] Changes that alter report text intentionally update golden/fixture checks and docs together.

## Reference example: `planned`

This is the reference annotation for applying the checklist to one existing section. It is not a promise that every other section already matches this shape.

### Identity and routing

- Section key: `planned`
- Human section title label key: `planned.section_title`
- Owning module: `src_next/planned_payments.bqn`
- Human renderer: `planned_payments.FormatHuman ctx`
- Compact renderer: `planned_payments.Format ctx`
- Human registration: `src_next/report.bqn` entry `⟨"planned", planned_payments.FormatHuman ctx⟩`
- Compact registration: `src_next/summary.bqn` calls `planned_payments.Format ctx`

### Data ownership

Required context:

- `ctx.base` — base directory for source TSV reads.
- `ctx.cy.start`, `ctx.cy.end_exclusive`, `ctx.cy.day_count` — current cycle boundary.

Source files read by the section:

- `<base>/plan.tsv` via `loader.ReadLinesOptional`.
- `<base>/journal.tsv` via `loader.ReadLinesOptional`.

Both files are optional at read time for this section; missing files produce empty row sets rather than shell fallback parsing. The section is read-only and does not write source TSV.

### Input and matching behavior

- Plan rows are filtered to the current cycle using the cycle start/day count.
- Rows are sorted by date for display.
- Plan/journal matching uses `plan_id=` metadata when present; otherwise it falls back to the first five TSV fields.
- `loader.SplitTsvKeepEmpty` is used for journal-like rows so an empty memo field does not shift columns.

### Empty-state behavior

- Compact output emits `src_next_planned_payment: (none)` when there are no in-cycle plan rows.
- Human output still renders the section title, open/completed table headings, totals, and status legend. Empty open/completed tables are visible as empty tables rather than silently omitting the section.

### Status behavior

Machine/local statuses:

- Compact: `planned` / `paid`.
- Human: `future` / `due` / `overdue` / `completed`.

These are section-local display statuses, not global `OK / WARN / ERROR / SKIPPED / UNAVAILABLE` section statuses. The distinction should remain documented if the status set changes.

### Labels used

Current human labels are loaded from `config/report_labels.tsv`:

- `planned.section_title`
- `planned.open_title`
- `planned.open_total`
- `planned.completed_title`
- `planned.future_status`
- `planned.due_status`
- `planned.overdue_status`
- `planned.completed_status`
- `planned.date_header`
- `planned.category_header`
- `planned.memo_header`
- `planned.amount_header`
- `planned.status_header`
- `planned.planned_header`
- `planned.actual_header`
- `planned.status_legend_title`

### Machine-readable output

#### Compact output
Compact lines use the prefix:

```text
src_next_planned_payment: ...
```

This is consumed by compact summary checks and can be filtered by `tools/query` when needed. Human table labels should not be parsed as machine keys.

#### Structured JSON output
`tools/report --section planned --format json` calls `planned_payments.FormatJson ctx` and outputs ViewModel JSON:

```json
{
  "open_items": [
    {
      "date": "YYYY-MM-DD",
      "category": "category_name",
      "memo": "memo_text",
      "amount": 1000,
      "status": "due|overdue|future",
      "plan_id": "plan-id-metadata"
    }
  ],
  "open_total": 1000,
  "completed_items": [
    {
      "date": "YYYY-MM-DD",
      "category": "category_name",
      "memo": "memo_text",
      "amount": 1000,
      "actual_amount": 1000,
      "status": "completed",
      "plan_id": "plan-id-metadata"
    }
  ]
}
```

### Current checks

- `checks/check-src-next-planned-payments.sh` checks planned payments section behavior across fixtures.
- `checks/check-src-next-report.sh` checks `tools/report --section` extraction behavior for representative sections.
- `checks/check-ui-smoke.sh` checks direct UI section routing for `planned`.
- `checks/check-src-next-compact-summary.sh` checks compact output contains `src_next_planned_payment`.

## Reference example: balances

### Identity and routing
- Section key: `balances`
- Owning module: `src_next/balances.bqn`
- Human renderer: `balances.FormatHuman (balances.Build ctx)`
- Compact renderer: `balances.Format (balances.Build ctx)`
- JSON renderer: `balances.FormatJson ctx`
- Registration: `src_next/report.bqn`

### Structured JSON output
`tools/report --section balances --format json` calls `balances.FormatJson ctx` and outputs ViewModel JSON:

```json
{
  "accounts": [
    {
      "account_key": "assets:liquid:wallet",
      "amount": 5000,
      "role": "asset",
      "type": "liquid"
    }
  ],
  "totals": {
    "liquid_assets_total": 5000,
    "savings_total": 0,
    "investment_total": 0,
    "assets_total": 5000,
    "liabilities_total": -2000,
    "net_worth": 3000
  }
}
```

## How to apply this later

For the next section alignment task:

1. Copy the checklist headings into a short note or module comment.
2. Fill only facts that are true today.
3. Add or update the smallest check that enforces the most important contract point.
4. Avoid broad refactors while documenting the contract.
