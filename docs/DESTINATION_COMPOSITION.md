# Destination composition and cutover preparation

Status: P10A static catalog and request admission complete; source composition and routing remain in progress.

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

## Next composition boundary

Composition must build one requested result at a time. It must not construct an all-report record or pass coordinates irrelevant to the selected report. The next slice will define purpose-specific request carriers/adapters for:

- domain and observation;
- Recent limit;
- resolved cycle/current and baseline windows;
- explicit month range;
- Envelope horizon/funding ownership;
- Daily Target observation/target/assets/obligations/reservation evidence;
- strict Issues source.

`all` iteration repeatedly invokes the same one-result boundary and concatenates supported renderings; it does not widen an individual result.

## Cutover boundary

Current production remains `tools/report -> src_next/report.bqn`. No destination alias, dual key, forwarding wrapper, or partial route switch is introduced in P10A.

Before atomic cutover:

1. public one-request composition and deterministic CLI behavior must pass;
2. operational check/debug ownership must be separated;
3. external compact/query/cache consumers must be confirmed with moko;
4. private Issues/source readiness requires separate explicit authorization;
5. old routes, keys, cache entries, metadata, callers, tests, and compatibility runtime are removed in one change.
