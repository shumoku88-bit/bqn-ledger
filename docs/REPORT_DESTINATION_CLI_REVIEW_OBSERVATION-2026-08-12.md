# Report Destination CLI review observation — 2026-08-12

## Scope

Review `src/application/report_destination_cli.bqn` together with its direct route/destination boundaries and the existing destination integration check.

## Observation

After individual route admission, the CLI still rediscovered evidence requirements from report key strings:

- `actualKeys` selected reports that require Actual;
- `contextKeys` selected reports that require Plan/Budget-policy/Household context;
- special key guards selected the full companion lifetime for Envelopes and Issue lines for Issues;
- shared outer variables were then mutated to assemble one evidence namespace.

PR #719 already made the admitted retained-report catalog coordinate available at this point. The key lists therefore duplicated a classification that can be aligned directly with that coordinate.

## Decision

Represent effect lifetime as a catalog-aligned loader axis.

The four concrete loader capabilities are:

```text
LoadCompanions  Actual + Plan + Budget movement + Budget policy + Household
LoadActual      Actual only
LoadContext     Actual + Plan + Budget policy + Household
LoadIssues      Issue source only
```

The retained report catalog aligns to those loaders as:

```text
envelopes          -> LoadCompanions
balances           -> LoadActual
balance-sheet      -> LoadActual
profit-and-loss    -> LoadActual
recent             -> LoadActual
planned            -> LoadContext
cycle-accounts     -> LoadContext
cycle-comparison   -> LoadContext
monthly-accounts   -> LoadActual
daily-flow         -> LoadContext
daily-target       -> LoadContext
issues             -> LoadIssues
```

`catalogIndex◶evidenceLoaders` now selects one lazy effect path. The old `Contains`, `actualKeys`, `contextKeys`, and mutable evidence staging are removed.

Human presentation selection is likewise a lazy value selection. Non-Human surfaces retain the existing default presentation value and do not read Report presentation policy.

## Test and fixture classification

No new persistent fixture is introduced.

`checks/check-report-destination-route-admission.sh` retains its existing canonical fixture and derives temporary reduced copies during the check:

- an Actual-only copy removes Plan, Budget, Household, and Issues sources and must still render Balances byte-for-byte;
- a Context copy removes Budget movement and Issues and must still render Planned Payments;
- an Issues copy removes the accounting source family and must still render Issues.

These are effect-lifetime law guards, not alternate fixture topologies. The reduced directories exist only for the check invocation and are deleted afterward.

The same check also rejects reintroduction of `Contains`, `actualKeys`, or `contextKeys`, and requires catalog-coordinate evidence dispatch.

Existing full destination and current-report checks continue to provide characterization/golden evidence for successful complete Household operation and public report bytes.

## Protected boundaries

Unchanged:

- request and route admission order;
- Report-policy presentation behavior;
- currency Registry admission and diagnostics;
- canonical source identities and Account observation ownership;
- Actual / Household Context / Companion fail-closed diagnostics;
- exact arithmetic, identity, provenance, and source order;
- semantic destination and renderer behavior;
- public report bytes;
- writer authority.

The loaders are application-local effect capabilities. They are not moved into `report_source_adapter.bqn` because that owner should expose source capabilities rather than report-key policy.
