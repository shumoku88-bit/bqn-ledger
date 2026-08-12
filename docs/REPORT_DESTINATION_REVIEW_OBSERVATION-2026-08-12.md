# Report Destination review observation — 2026-08-12

## Scope

Review `src/application/report_destination.bqn` at the Phase 5 cursor together with its direct application callers, route law, destination checks, and existing fixtures.

## Observation

Individual report request admission already resolves a retained report key to the canonical catalog coordinate. `report_route.bqn` consumed that coordinate to choose one route-admission function, but discarded it before publication. `report_destination.bqn` then received the admitted key text and repeated twelve guarded string comparisons to rediscover the semantic destination.

That split duplicated an identity decision already made by the retained report catalog. It also staged the selected composition through mutable `composition↩` state.

## Decision

Preserve the admitted catalog coordinate across the route boundary.

The retained flow is now:

```text
request catalog admission
  -> route catalog coordinate
  -> semantic coordinate admission
  -> published catalog_index
  -> catalog-aligned destination function axis
  -> lazy destination selection
  -> composition
```

`report_destination.bqn` therefore arranges its twelve semantic destination functions in the same order as the retained report catalog and dispatches with `catalogIndex◶destinations`.

Daily Target still has two meaningful lazy gates:

1. Household Daily Scope admission must succeed before scope evidence is built;
2. Daily Scope evidence must succeed before `compose.DailyTarget` evaluates.

Those gates remain explicit. Only incidental outer composition mutation is removed.

## Test and fixture classification

No new fixture was needed.

`tests/test_application_report_route.bqn` already enumerates every retained individual report in catalog order. It is strengthened into a law guard by asserting the exact admitted `catalog_index` for every case and asserting that failed admissions publish no coordinate.

`checks/check-report-destination-route-admission.sh` is an architecture/reachability guard. It now requires coordinate propagation from route admission and rejects reintroduction of destination key-string redispatch.

Existing destination and current-batch checks remain characterization/golden evidence for public report bytes and source/effect lifetime. Their fixtures are retained because they exercise current canonical behavior rather than obsolete topology.

No new fixture builder, alternate catalog, or destination-specific characterization dataset is introduced.

## Protected boundaries

Unchanged:

- retained report catalog order and public keys;
- request and route diagnostics;
- route coordinate roles and semantic arguments;
- canonical Household source ownership and evidence lifetime;
- exact arithmetic, identity, provenance, and ordering;
- Daily Target fail-closed evaluation;
- report composition result keys;
- Human / Compact / JSON rendering bytes;
- writer authority.

`src/application/report_route.bqn` is not considered fully reviewed by this change. It only gains the concrete coordinate-publication capability required by the current destination owner; its normal Phase 5 cursor remains later.
