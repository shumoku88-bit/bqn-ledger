# Report composition

Status: production static catalog, semantic request routes, fail-closed current batch, and atomic cache publication.

## Static catalog owner

`src/report/catalog.bqn` is the only destination catalog owner. It contains exactly twelve retained keys in final order and declares label, bounded result shape, and supported human/compact/JSON surfaces.

Catalog listing is source-independent. Unknown legacy keys are rejected rather than translated.

Registered compact owners are:

```text
envelopes
balances
recent
planned
daily-target
```

## One-result composition

`src/report/compose.bqn` exports twelve named functions rather than one universal context:

```text
Balances          Actual Facts, domain, observation
BalanceSheet      Actual Facts, domain, observation
ProfitAndLoss     Actual Facts, domain, period
Recent            Actual Facts, limit / through
Planned           Plan Facts, Actual Facts, resolved cycle, observation
CycleAccounts     Actual Facts, domain, resolved cycle, observation
CycleComparison   Actual Facts, domain, two cycle windows/observations, policy
MonthlyAccounts   Actual Facts, domain, first month, last exclusive month
DailyFlow         Actual Facts, EnvelopeHistory, domain, period, observation
Envelopes         Entitlement, current Envelope policy, EnvelopeHistory,
                  Actual/Plan Facts, Plan retirements, domain/horizon/observation
DailyTarget       observation, target, domain, owner asset/obligation scope
Issues            already-read issue lines, currency registry
```

Each function publishes exactly one bounded semantic result. Error/unavailable results contain no partial report. No composition function accepts source paths, a clock, physical source basenames, or another report's rendered text.

The Envelope composition receives native StockOrigin/Transfer evidence. It does not receive Budget Accounts or an Account-to-Envelope projection. StockOrigin provenance remains in the section result and JSON/compact evidence.

## Request admission and rendering

`src/report/request.bqn` validates one retained key and surface:

```text
human | compact | json
```

A known key on an unsupported surface fails before rendering. `all` is a catalog selection, not a thirteenth semantic result, and aggregate JSON is unsupported.

`src/report/render.bqn` dispatches only a successful one-result composition through the already-admitted surface.

## Application I/O boundary

`src/application/report_source_adapter.bqn` owns canonical read composition over the eight-file Household root:

```text
accounts.journal
actual.journal
plan.journal
entitlement.journal
envelope.toml
household.toml
report.toml
issues.tsv
```

It admits Accounts once, reuses the same Account observation for Actual/Plan/Backing policy, admits stable Envelope history separately from current Envelope policy, and loads Entitlement against the stable identity universe. Every current `envelope.toml` identity must occur in that stable universe.

Physical basenames never enter report request coordinates. `tools/report` accepts only semantic domain/date/count/policy coordinates and resolves canonical source owners internally.

Key-specific source needs remain bounded:

- Actual-only accounting reports need Accounts + Actual;
- Planned needs Plan, Actual, and Cycle resolution;
- Daily Flow needs Actual plus historical Expense routing, not current Envelope membership;
- Envelope & Backing needs Actual/Plan, Entitlement, current Envelope/Backing policy, and stable history;
- Issues needs Issues plus the repository Currency registry.

## Current report batch

`tools/report-all BASE DOMAIN SURFACE [LATEST]` resolves typed current requests from canonical `report.toml` and one canonical Household observation. The generated request rows are in-memory protocol, not a caller-supplied manifest or alternate source authority.

`src/application/current_report_batch_cli.bqn` admits the complete selected request set, buffers every result, and publishes only after the batch succeeds. Human selects all twelve catalog entries; compact selects the five registered compact owners; aggregate JSON remains unsupported.

`tools/report-summary BASE DOMAIN [LATEST]` is the compact current batch. `tools/query` recognizes exact `ledger_[a-z0-9_]+` keys from that summary; it does not translate old keys or parse human headings.

## Source-independent metadata

`src/report/section_metadata.bqn` derives labels, categories, owners, and surfaces directly from the static catalog. `tools/report-section-metadata` reads no Household source or clock.

## Cache publication

`tools/report-cache` stages the twelve human section bodies plus `all.txt`, publishes `.section-keys`, removes stale report bodies, and writes `.cache-timestamp` last. A failed refresh preserves the prior complete generation.

The cache is presentation state, never a source of accounting meaning.

## Cutover boundary

Production uses strict `src/` composition only. There is no source fallback, request-manifest execution input, old-key forwarding, Budget source adapter, dual canonical source, or hidden Account-to-Envelope projection.
