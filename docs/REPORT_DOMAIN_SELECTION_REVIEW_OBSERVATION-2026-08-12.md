# Report Domain selection review observation — 2026-08-12

## Scope

Review `src/application/report_domain_cli.bqn` and `src/application/report_domain_selection.bqn` as one coherent current-Report domain-selection boundary.

## Observation

The effectful CLI has one small responsibility after canonical Registry and Actual admission: distinguish an omitted DOMAIN argument from one explicit DOMAIN and delegate to the pure selector. It previously staged the optional argument through mutable `requested↩` state.

The pure selector implements exactly two semantic cases:

1. **Explicit**: the requested domain must occur exactly once on the admitted Actual domain axis;
2. **Inferred**: omission is valid only when the admitted Actual domain axis contains exactly one domain.

The previous implementation expressed those two cases as two guarded mutation blocks over shared `diagnostics` and `domain` variables. No traversal accumulation is necessary because every request belongs to exactly one of the two classifications and each classification has one success or one failure result.

## Decision

Make the classification explicit.

`report_domain_selection.bqn` now has concrete `Explicit` and `Inferred` functions plus `Success` / `Failure` result constructors. `Resolve` selects lazily between the two semantic cases.

`report_domain_cli.bqn` likewise classifies the optional second argument lazily instead of mutating an initially empty requested-domain value.

The effect order remains:

```text
argv shape
  -> canonical Currency Registry admission
  -> canonical Actual admission
  -> pure Report-domain selection
  -> output / diagnostics
```

No domain identity is moved into Report policy or UI configuration. Canonical Actual Facts remain the source of available accounting domains.

## Test and fixture classification

No new fixture is introduced.

`tests/test_application_report_domain_selection.bqn` already contained the five meaningful law cases:

- one available domain + omission => infer that domain;
- multiple available domains + explicit admitted domain => accept it;
- multiple available domains + omission => `report_domain_required`;
- explicit unavailable domain => `report_domain_unknown`;
- no available domains + omission => `report_domain_required`.

The test is tightened so successful results must have zero diagnostics and failed results must publish an empty domain and exactly one expected diagnostic.

`checks/check-current-report-profile.sh` already owns a complete canonical current-report fixture and exercises `main-ui.sh --domain JPY`. It now directly proves both CLI paths without creating another fixture: omitted-domain inference returns JPY, explicit JPY returns JPY, and explicit USD fails through the exact `report_domain_unknown` diagnostic.

The shell check is effect-boundary qualification; the focused BQN test remains the pure semantic law owner.

## Protected boundaries

Unchanged:

- canonical Registry admission;
- canonical Actual source and Facts ownership;
- available-domain identity/order;
- explicit-domain precedence;
- single-domain inference law;
- diagnostic codes/messages;
- fail-closed behavior;
- current Report/UI domain semantics;
- writer authority.
