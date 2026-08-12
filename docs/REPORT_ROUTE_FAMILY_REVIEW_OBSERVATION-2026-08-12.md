# Report Route family review observation — 2026-08-12

## Scope

Review the semantic Report route family as one coherent boundary:

- `src/application/report_route.bqn`
- `src/application/report_route_plan.bqn`
- `src/application/report_route_plan_cli.bqn`
- the `tools/report` consumer of the route-plan protocol

## Route observation

After PR #719 established retained Report catalog coordinates, `report_route.bqn` still represented the twelve route shapes as twelve near-identical functions. Eleven owned only one law: the admitted coordinate count must match a fixed semantic role axis. `Recent` adds one genuine semantic law: LIMIT must be non-empty decimal digits.

The repeated function family hid a static catalog-aligned relation:

```text
catalog coordinate
  -> coordinate roles
  -> usage diagnostic code
  -> usage diagnostic message
```

## Route decision

Expose that relation directly as aligned `coordinateRoles`, `usageCodes`, and `usageMessages` axes.

`ShapePlan` now compares the admitted coordinate count with the selected semantic role cell and returns the existing success/error shape. `RoutePlan` retains only the additional Recent LIMIT validation and evaluates it lazily after shape admission succeeds.

Request admission still owns retained key/surface/catalog meaning. Route admission does not introduce a second catalog.

## Physical source protocol retirement

Canonical Household physical sources are no longer Report request coordinates. They are resolved internally from BASE after semantic route admission. The previous Route result nevertheless retained an always-empty `sources` namespace, and the machine-readable route plan retained:

- a `SOURCE` line formatter that had no reachable successful source row;
- a `source_count` header field that was always `0`;
- shell validation requiring that constant `0`.

Repository reachability showed no production source-plan consumer beyond this closed protocol. Existing canonical-route laws already prove that adding a physical source basename to semantic coordinates fails admission.

The dead protocol shape is therefore retired:

```text
old: ROUTE <key> <surface> <coordinate_count> <source_count>
new: ROUTE <key> <surface> <coordinate_count>
```

`report_route_plan.bqn` no longer owns `SourceLine`, and `tools/report` validates only the semantic coordinate count.

This is subtraction of an impossible state, not relaxation of source ownership.

## Route Plan / CLI decision

Apart from removal of the unreachable physical-source protocol, `report_route_plan.bqn` remains the narrow pure projection from admitted Route result to machine lines and exit code.

`report_route_plan_cli.bqn` remains production-unchanged as an effect-only leaf that prints those lines and applies the returned exit code.

## Test and fixture classification

No new fixture is introduced.

`tests/test_application_report_route.bqn` already enumerates all twelve retained routes in catalog order and protects exact catalog index, key, surface, coordinates, coordinate roles, arity diagnostics, Recent LIMIT admission, request failures, and `all` rejection. It now stops characterizing the retired always-empty source namespace.

`tests/test_application_canonical_actual_report_route.bqn` continues to prove the actual source-boundary law: canonical semantic coordinates succeed and appending `actual.journal` as a coordinate fails.

`tests/test_application_report_route_plan.bqn` updates the machine protocol golden from five to four ROUTE fields while retaining exit/diagnostic behavior.

Existing full Report composition checks qualify the shell consumer and public destination behavior.

## Protected boundaries

Unchanged:

- retained Report key/surface admission;
- catalog coordinate alignment;
- exact semantic coordinate roles and arities;
- Recent LIMIT validation;
- diagnostic codes/messages;
- `all` remaining request-set-only;
- physical Household source basenames remaining invalid query coordinates;
- canonical source resolution after route admission;
- Report destination behavior;
- writer authority.
