# Design: Envelopes Section JSON Export Slice

This document defines the structured JSON ViewModel schema, contract, type constraints, and fallback rules for the `envelopes` report section. 

## CLI Interface & Routing

The structured JSON output is requested using the existing CLI pattern:

```bash
tools/report --section envelopes --format json
```

This request is dispatched in [src_next/report.bqn](file:///Users/user/Projects/moko/bqn-ledger/src_next/report.bqn) to `envelope_computation.FormatJson ctx`, returning a single structured JSON payload on stdout and exiting with status `0`.

## JSON Schema Design

```json
{
  "target_id": "fixture_food_like",
  "label": "食費目安",
  "selector": "budget=食費",
  "status": "computed",
  "has_policy": true,
  "allocated": 20000,
  "actual_spent": 5000,
  "remaining": 15000,
  "envelopes": [
    {
      "account_index": 4,
      "account_name": "budget:食費",
      "label": "食費",
      "group": "生活",
      "envelope_role": "dynamic",
      "allocated": 20000,
      "actual_spent": 5000,
      "remaining": 15000,
      "avg_spend": 333,
      "days_until_empty": 45,
      "status": "SAFE"
    }
  ],
  "unassigned": {
    "account_count": 1,
    "remaining": 10000,
    "status": "ok"
  },
  "backing": {
    "funding_base": 25000,
    "allocated_total": 15000,
    "cash_backed_unassigned": 10000,
    "ledger_cash_delta": 0,
    "status": "OK"
  },
  "execution_planned": {
    "envelope_label": "特別支出",
    "envelope_remaining": 5000,
    "planned_open_total": 3000,
    "delta": 2000,
    "status": "OK",
    "rows": [
      {
        "date": "2026-06-20",
        "memo": "planned payment",
        "category": "expenses:rent",
        "amount": 3000,
        "plan_id": "plan-2026-06-20"
      }
    ]
  }
}
```

### Type Constraints

- `target_id`, `label`, `selector`, `status`, `unassigned.status`, `backing.status`, `execution_planned.envelope_label`, `execution_planned.status`: Strings.
- `has_policy`: Boolean (`true`/`false`).
- `allocated`, `actual_spent`, `remaining`: Numbers.
- `envelopes`: Array of object items, where:
  - `account_index`, `allocated`, `actual_spent`, `remaining`, `avg_spend`: Numbers.
  - `account_name`, `label`, `group`, `envelope_role`, `status`: Strings.
  - `days_until_empty`: Number (integer) or `null`. If average spend is `0` (or cycle is unresolvable), this must be `null` rather than a magic number like `999`.
- `unassigned`: Object containing:
  - `account_count`: Integer.
  - `remaining`: Number.
  - `status`: String.
- `backing`: Object containing:
  - `funding_base`, `allocated_total`, `cash_backed_unassigned`, `ledger_cash_delta`: Numbers.
  - `status`: String.
- `execution_planned`: Object containing:
  - `envelope_label`, `status`: Strings.
  - `envelope_remaining`, `planned_open_total`, `delta`: Numbers.
  - `rows`: Array of objects containing:
    - `date`, `memo`, `category`, `plan_id`: Strings.
    - `amount`: Number.
  - If execution plan policy is disabled or unconfigured, `envelope_label` should be `null`, numeric values should be `null`, and `rows` should be `[]` (empty list).

## Error and Unavailable State Handling

- If the cycle metadata is missing/unresolvable, or if there is no data in the cycle:
  - `"days_until_empty"` and `"avg_spend"` in all envelopes must be `null`.
  - `"status"` in all envelopes must fall back to `"unknown_role"` (or descriptive status if uncomputable).
- If the policy budget style is disabled (`PolicyBudgetStyle = "none"`), or the base configuration does not support backing diagnostics:
  - All backing numbers (`funding_base`, `cash_backed_unassigned`, etc.) must be `null` (or appropriate empty defaults) and `backing.status` must be `"disabled"`.
- Under no circumstances should unresolvable calculations default to zero when that zero implies an actual computed balance. They must resolve to JSON `null`.

## Verification Checklist

The implementation PR must ensure:

1. `tools/report --section envelopes --format json` produces valid JSON matching the schema contract.
2. An automated check in `checks/check-src-next-report.sh` validates the output against the schema using python3 parsing rules.
3. Test fixtures cover both valid data (checking complete values) and unresolvable states (confirming `null` fallback outputs for cycle-dependent metrics like `days_until_empty`).
4. The default human report `tools/report --section envelopes` is completely unaffected.

## Related Documents

- `docs/REPORT_SECTION_CONTRACT_CHECKLIST.md`
- `docs/SNAPSHOT_SECTION_JSON_EXPORT_DESIGN.md`
- `src_next/envelope_computation.bqn`
