# Destination composition and cutover preparation

Status: P10B static catalog, request admission, purpose-specific one-result composition, and rendering dispatch complete; source I/O adapter and CLI remain in progress.

## Static catalog owner

`src/report/catalog.bqn` is the only destination catalog owner. It contains exactly nine retained keys in final order and declares label, bounded result shape, and supported human/compact/JSON surfaces.

Catalog listing is source-independent. `catalog.Table` and `catalog_text.FormatTsv` perform no source reads, clock access, context construction, or report calculation. The deterministic public listing is `fixtures/ledger-facts-phase1-proof/report_catalog.destination.tsv`.

## Request admission

`src/report/request.bqn` validates only final keys and final surfaces:

```text
human | compact | json
```

Unknown legacy keys fail with `report_key_unknown`; they are not aliases. A known report requested through an unsupported surface fails with `report_surface_unsupported`; it does not return an empty renderer.

`all` is a composition selector, not a tenth catalog entry:

- `all + human` selects all nine entries in catalog order;
- `all + compact` selects only registered compact owners in catalog order;
- `all + json` is unsupported because there is no aggregate JSON schema.

Registered compact owners are:

```text
envelopes
balances
recent
planned
daily-target
```

## One-result composition

`src/report/compose.bqn` exports nine named functions rather than one universal request context:

```text
Balances          Actual Facts, domain, observation
Recent            Actual Facts, limit
Planned           Plan Facts, Actual Facts, resolved cycle, observation
CycleAccounts     Actual Facts, domain, resolved cycle, observation
CycleComparison   Actual Facts, domain, two explicit cycle windows/observations, policy
MonthlyAccounts   Actual Facts, domain, first month, last exclusive month
Envelopes         Budget/Actual/Plan Facts, domain, horizon, observation, funding indices
DailyTarget       observation, target, domain, owner asset scope, obligation scope
Issues            already-read issue lines, currency registry
```

Each function composes existing accounting and section owners and publishes exactly one bounded result. Error/unavailable results contain no partial report; unavailable reason is preserved. No function accepts paths, clock, CLI arguments, unrelated report coordinates, or another report's result.

`src/report/render.bqn` dispatches only a successful one-result composition through the surface already admitted by `request.bqn`. Unsupported surfaces fail before a formatter is called. The dispatcher imports all static section owners but does not build them.

Public composition tests invoke every named composer and compare its rendering with the existing destination golden, proving that composition adds no second semantic owner.

`all` iteration will repeatedly invoke this same one-result boundary and concatenate supported renderings; it will not widen an individual result or construct an all-report record.

## Next I/O and CLI boundary

The next slice may read sources only after request key/surface admission, then prepare the selected composer's exact arguments. It must capture any interactive clock value once outside core and pass explicit coordinates. Public CLI proof remains parallel to production until cutover.

## Cutover boundary

Current production remains `tools/report -> src_next/report.bqn`. No destination alias, dual key, forwarding wrapper, or partial route switch is introduced in P10A.

Before atomic cutover:

1. public one-request composition and deterministic CLI behavior must pass;
2. operational check/debug ownership must be separated;
3. external compact/query/cache consumers must be confirmed with moko;
4. private Issues/source readiness requires separate explicit authorization;
5. old routes, keys, cache entries, metadata, callers, tests, and compatibility runtime are removed in one change.
