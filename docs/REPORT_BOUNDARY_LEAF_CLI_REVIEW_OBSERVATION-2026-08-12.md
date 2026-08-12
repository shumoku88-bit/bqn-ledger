# Report boundary leaf CLI review observation — 2026-08-12

## Scope

Review these adjacent application leaves as one coherent shell/BQN boundary family:

- `src/application/report_presentation_cli.bqn`
- `src/application/report_request_cli.bqn`

Both are consumed by `tools/report` before or around the effectful destination path. Neither owns accounting meaning, source discovery, route coordinates, rendering semantics, or writer authority.

## Report Presentation CLI

The production owner is already a bounded adapter:

```text
BASE
  -> canonical Report Policy source adapter
  -> fail-closed admission
  -> negative_style / negative_color / daily_flow_max_date_columns rows
```

It contains no mutable staging, fallback source selection, environment override policy, accounting coordinate, or formatter logic to subtract.

`checks/check-report-presentation-policy.sh` already provides strong integration evidence:

- exact three-value CLI publication from canonical policy;
- minus versus parentheses Human rendering;
- Compact/JSON machine surfaces remaining presentation-independent;
- canonical Report color policy taking precedence over pre-existing environment values;
- `NO_COLOR` remaining terminal-layer policy;
- table/calendar/color-filter presentation behavior;
- invalid Human presentation policy failing closed while machine surfaces remain usable where allowed.

A duplicate focused CLI fixture would not add a distinct law.

## Report Request CLI

The production owner is likewise already a bounded pre-I/O leaf:

```text
KEY + SURFACE argv
  -> exact argv arity
  -> pure retained Report request admission
  -> diagnostics or OK
```

It has no source import, source coordinate, mutable traversal, compatibility path, or second Report catalog.

`checks/check-report-composition.sh` exercises this boundary through the production `tools/report` caller and proves:

- all retained report paths continue to their public golden destinations;
- an unknown key fails before a missing Household root matters;
- an unsupported surface fails through Report request admission;
- physical source basenames are rejected as semantic route coordinates;
- retired request manifests are rejected rather than revived as execution input.

The already-reviewed pure `src/report/request.bqn` remains the semantic law owner. The CLI should remain only process adaptation.

## Decision

Retain both production files unchanged.

Do not add another helper, generic CLI framework, fixture, or characterization test merely to mark the cursor complete. Existing pure laws and integration checks already separate:

- semantic request admission;
- canonical presentation policy admission;
- process adaptation;
- public destination behavior;
- terminal presentation concerns.

## Protected boundaries

Unchanged:

- Report catalog/request ownership;
- pre-I/O request admission;
- canonical Report Policy ownership;
- presentation policy publication shape;
- Human versus machine presentation separation;
- diagnostics and exit behavior;
- source independence of request admission;
- physical source/manifest retirement;
- writer authority.
