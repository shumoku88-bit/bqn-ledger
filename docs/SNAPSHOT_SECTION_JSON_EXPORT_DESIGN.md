# Snapshot Section JSON Export Design

Status: proposed design slice
Date: 2026-07-04

## Purpose

This document defines the design slice for the `snapshot` report section JSON output.

The goal is to expose a stable, structured JSON view of the daily financial dashboard (observation date, cycle progress, cash totals, income/expense actuals, and data quality check markers) to enable UI tools to render rich dashboards without parsing human report stdout.

## Target Section

- Section key: `snapshot`
- Owning module: `src_next/snapshot.bqn`
- Human renderer: `snapshot.FormatHuman (snapshot.Build ctx)` (This is a simplified BS/net worth view)
- Compact renderer: `snapshot.Format (snapshot.Build ctx)` (This is a diagnostic key-value report)
- JSON renderer: `snapshot.FormatJson ctx` (To be added)

## Non-goals

- Altering the default terminal human rendering of the snapshot.
- Introducing a write path or state modification inside BQN report modules.
- Introducing new household calculation algorithms (we use the clean TBDS-derived fields established in Stage 4a).

## Proposed CLI Boundary

Same as previous sections, structured JSON export is explicitly requested:

```bash
tools/report --section snapshot --format json
```

If `--format json` is requested for `snapshot`, the dispatcher in `report.bqn` immediately redirects to `snapshot.FormatJson ctx` and exits.

## JSON ViewModel Schema

```json
{
  "as_of": "2026-06-30",
  "status": "stable",
  "cycle": {
    "start": "2026-06-15",
    "end_exclusive": "2026-08-15",
    "available": true
  },
  "remaining_days": 45,
  "days_elapsed": 15,
  "totals": {
    "liquid_assets": 65297,
    "savings": 5000,
    "investments": 5600,
    "assets_total": 75897,
    "liabilities_total": -197706,
    "net_worth": -121809
  },
  "cycle_summary": {
    "income_actual": 446292,
    "expense_actual": 204300,
    "net_actual": 241992,
    "plan_expense": 128000
  },
  "readiness": {
    "valid_projection_rows": 142,
    "skipped_projection_rows": 0,
    "unknown_account_count": 0,
    "out_of_cycle_skipped_count": 12
  }
}
```

### Type Constraints

- `as_of`, `status`, `cycle.start`, `cycle.end_exclusive`: Strings (`YYYY-MM-DD` or descriptive status strings like `"stable"`/`"caution"`).
- `cycle.available`: Boolean.
- `remaining_days`, `days_elapsed`: Integers. If cycle dates are unavailable or invalid, these should resolve to `null` rather than a fake zero or negative value.
- All totals and cycle summary fields: Numbers (integers in local currency, negative values preserved).
- Readiness check counters: Non-negative integers.

## Error and Unavailable State Handling

- If the cycle metadata is missing or unresolvable, `"cycle.available"` will be `false`, and `"remaining_days"` / `"days_elapsed"` must be `null` in the JSON payload rather than missing from the keys or defaulting to `0`.
- Missing values should not be omitted; they must explicitly resolve to `null` to preserve schema stability.

## Verification Checklist

The implementation PR must ensure:

1. `tools/report --section snapshot --format json` produces valid JSON matching the schema contract.
2. An automated check in `checks/check-src-next-report.sh` validates the output against the schema using python3 parsing rules.
3. Test fixtures cover both valid data (with full numbers) and empty/unresolvable states (confirming `null` fallback outputs).
4. The default human report `tools/report --section snapshot` is completely unaffected.

## Related Documents

- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`
- `docs/PLANNED_SECTION_JSON_EXPORT_DESIGN.md`
- `src_next/snapshot.bqn`
