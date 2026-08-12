# Report Source Adapter review observation — 2026-08-12

## Scope

Review `src/application/report_source_adapter.bqn` after #717 established one caller-owned Account observation for Report companions.

## Existing semantic lifetime

The adapter exposes concrete canonical source capabilities plus two wider Report evidence lifetimes.

`HouseholdContext` intentionally evaluates:

1. Plan from caller-owned admitted Accounts;
2. Budget Policy from the same Accounts;
3. Household Policy only when Budget Policy admission succeeds.

Plan failure does not suppress a valid Budget Policy / Household observation, so diagnostics from independent siblings can still be collected. An invalid Budget Policy does suppress Household evaluation because Household admission requires that policy as typed input.

`Companions` intentionally evaluates Budget movement even when `HouseholdContext` fails, then appends its diagnostics after Context diagnostics. This preserves the readiness/application policy of collecting independent canonical companion failures in stable order while publishing evidence only when the whole requested lifetime succeeds.

Those evaluation boundaries are semantic and must remain.

## Observation

After the shared-Account correction, the remaining complexity was incidental publication state:

- `householdResult↩` after a default unavailable value;
- `diagnostics∾↩` when Household was evaluated;
- mutable failure namespaces followed by `result↩` success publication in both Context and Companions.

The data dependencies are acyclic and can be represented directly without changing which effects evaluate.

## Decision

Retain the existing effect/evidence order and replace result staging with values.

- `Unavailable` represents the deliberately unevaluated Household result when Budget Policy is invalid;
- `ContextFailure` / `ContextSuccess` publish the two Household Context result shapes;
- `CompanionFailure` / `CompanionSuccess` publish the two full companion result shapes;
- Household loading is selected lazily from Budget Policy state;
- success publication is selected lazily so `.facts` / successful context fields are never demanded from failed results;
- diagnostics are derived once as explicit concatenations in the existing public order.

The adapter now contains no mutable `↩` staging.

## Test and fixture classification

No new fixture is introduced.

Existing qualification already covers complementary parts of this boundary:

- `check-ledger-operations.sh` protects caller-owned Account reuse for both Plan and Budget movement and now rejects reintroduction of mutable result staging;
- the reduced-source destination laws added during the Report Destination CLI review prove that Actual-only, Context-only, and Issues-only lifetimes do not acquire unnecessary sibling source dependencies;
- canonical ledger-check, current-report, destination, and cache checks exercise successful and fail-closed companion observations end-to-end.

The source adapter is effectful orchestration over already-tested source adapters; creating a second fixture family for its namespace constructors would duplicate existing canonical topology evidence.

## Protected boundaries

Unchanged:

- canonical eight-file source ownership;
- caller-owned Account observation reuse;
- Plan / Budget Policy sibling observation;
- Household evaluation only after valid Budget Policy;
- Budget movement observation independent of Context success;
- diagnostic ordering;
- fail-closed evidence publication;
- exact arithmetic, identity, provenance, and source order of admitted Facts;
- Report destination behavior;
- writer authority.
