# Strict config and cycle admission

Status: Phase 2B pure admission proof
Owners: `src/ledger/config_admission.bqn`, `src/ledger/cycle_admission.bqn`
Public proof: `fixtures/ledger-facts-phase1-proof/`

## Boundary

Both modules accept already-read lines and return typed evidence plus diagnostics. They perform no I/O, path fallback, clock read, Actual/Plan resolution, report construction, or private-source migration. Invalid input returns no admitted table or typed definition.

This separates three concerns that the current runtime still combines:

1. **ledger source coordinate** — `DEFAULT_CURRENCY` selects a default domain view but never supplies missing row currency;
2. **report policy** — budget/risk/cadence/group labels remain non-accounting configuration;
3. **cycle definition** — an admitted unresolved period rule, distinct from resolving it against facts and an explicit as-of coordinate.

`ACTUAL_JOURNAL_FILE`, when present, is admitted only as a safe `.journal` basename. The pure ledger roots still receive raw source content, never a path. Repository/default path selection remains an infrastructure concern and is not copied into canonical facts.

## Public fixture inventory

Readonly repository-fixture inventory found 36 `config.tsv` files and 81 `cycle.tsv` files. It was an inventory only; Phase 2B does not declare all historical fixtures strict or rewrite them.

Config keys used by current report/editor consumers are:

- source selection: `DEFAULT_CURRENCY`, `ACTUAL_JOURNAL_FILE`;
- budget identity/policy: `BUDGET_PREFIX`, `BUDGET_ID_OPENING`, `BUDGET_ID_UNASSIGNED`, `BUDGET_ID_SPENT`, `POLICY_BUDGET_STYLE`;
- report grouping/risk: `HOUSEHOLD_GROUP_LIFE`, `HOUSEHOLD_GROUP_RESERVE`, `HOUSEHOLD_GROUP_ORDER`, `POLICY_RISK_STYLE`, `POLICY_INCOME_CADENCE`;
- editor/report coverage: `EXECUTION_PLANNED_PAYMENTS_ENVELOPE`.

Observed historical keys `THEME`, `CYCLE_START_DAY`, `DEFAULT_PAYMENT_DUE`, `MAIN_CYCLE_ANCHOR`, and a synthetic `key` row are not canonical accounting/report coordinates and are rejected by the strict destination admission. Existing runtime behavior is unchanged until explicit fixture/source migration.

Cycle keys observed are `mode`, `start`, `end_exclusive`, `income_account`, `start_day`, and `offset`. Historical `monthly` and `none` modes currently produce compatibility/unavailable behavior and are rejected by the destination rather than becoming canonical modes.

## Config contract

- rows use exactly one tab or one equals separator;
- comments and blank lines are ignored;
- keys are closed and unique; values are nonempty;
- `DEFAULT_CURRENCY` is mandatory and registry-supported;
- optional policy enums are closed;
- optional group lists contain no empty or duplicate items;
- optional `ACTUAL_JOURNAL_FILE` is a path-separator-free `.journal` basename;
- no repository default is consulted by admission.

The result separates `source` from `report_policy` while retaining an aligned key/value/source-row table.

## Cycle contract

Supported unresolved definitions are:

- `fixed`: strict valid `start` and `end_exclusive`, with `start < end_exclusive`;
- `incomeAnchor`: explicit admitted Account with role `income`, plus optional integer `offset`;
- `calendarMonth`: `start_day` from 1 through 28 so the recurring coordinate exists in every month.

Mode-specific fields are closed. A fixed cycle may retain an optional validated `income_account`, but resolution does not infer boundaries from it. Cycle admission does not inspect transactions, choose an as-of date, read today's date, or read Plan. Those operations belong to a later accounting capability with explicit fact inputs.

## Proof

`tests/test_ledger_config_cycle_admission.bqn` proves:

- the strict public fixture;
- tab and equals config rows;
- JPY/USD registry selection;
- fixed, incomeAnchor, and calendarMonth definitions;
- missing, duplicate, unsupported, malformed, invalid range/date/day, unsafe path, unknown Account, and wrong Account role rejection;
- all-or-nothing empty results.

Private source audit or migration still requires a separate explicit human instruction.
