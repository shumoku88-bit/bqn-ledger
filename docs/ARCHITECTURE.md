# Architecture

## Production flow

```text
explicit source files + report request manifest
  -> src/application (read-only adapters and CLI composition)
  -> src/ledger (strict admission and canonical Facts)
  -> src/accounting (narrow exact capabilities)
  -> src/sections (one semantic result and approved renderers)
  -> src/report (static catalog, request admission, render dispatch)
  -> tools/report / report-summary / query / Command Hub cache
```

Actual is admitted only from the configured Native Journal. Plan and Budget are strict exact companion facts; Issues remain non-accounting facts. Currency, Account ownership, cycle coordinates, observations, and source basenames are explicit. Invalid evidence fails closed without partial publication.

## Ownership

- `src/application/` — source I/O adapters, explicit manifest config, selected-request composition, readiness and inspection CLIs.
- `src/ledger/` — Account, Journal, Plan, Budget, Config, Cycle, Issues, currency, exact-decimal admission, Transaction/Posting Facts, and provenance.
- `src/accounting/` — period balances, grouping/pivot, cycle resolution/comparison, Plan completion, Envelope backing, Daily Target, and recent transactions.
- `src/sections/` — the ten retained report results and human/compact/JSON renderers.
- `src/report/` — final catalog/order/surfaces, request validation, result dispatch, metadata, and text/JSON primitives.
- `src_edit/` and `src/editor/` — write-side commands and pure rewrite semantics using the same strict ledger owners.

No report section reads files or the clock. No accounting capability imports a section or composition owner. Native multi-posting transactions remain first-class and are never flattened into two-account compatibility rows.

## Possible libri-di-casa convergence

Integration is optional: if BQN remains sufficient for trustworthy accounting, writing, reporting, and daily use, this system may remain independent indefinitely. Only a demonstrated requirement that standalone BQN cannot satisfy as clearly should select convergence. If selected, a future integration may make `libri-di-casa`/Haskell the authoritative confirmation, accounting-validation, identity, provenance, and persistence owner while this BQN engine consumes versioned confirmed evidence and owns derived array calculations and neutral report results.

This is a replaceability constraint, not a committed merger or an active alternate source. Native Journal remains the sole production Actual input until a separately admitted adapter and cutover are proven. Current development must preserve one authoritative writer, distinguish semantic source role from physical encoding, retain exact Transaction/Posting identity and provenance, and keep external consumers from having to parse human report text. Plan, Budget, Issues, and Daily Target policy are not presumed to map to historically named books.

The full boundary and future integration gate are in [`LIBRI_DI_CASA_INTEGRATION_BOUNDARY.md`](LIBRI_DI_CASA_INTEGRATION_BOUNDARY.md).

## Retained portfolio

Catalog order is:

1. Envelope & Backing
2. Account Balances
3. Recent Journal
4. Planned Payments
5. Current-cycle Accounts
6. Cycle Comparison
7. Monthly Accounts
8. Daily Flow
9. Daily Target
10. Issues

`all` is a catalog selection, not an all-report semantic record. Human and compact manifests contain existing individual route arguments in catalog order. Every row is admitted before source reads; output is buffered and published only after all selected requests succeed.

## Cache and UI

`tools/report-cache` stages ten section bodies plus `all.txt`, publishes `.section-keys`, deletes stale report bodies, and writes `.cache-timestamp` last. `tools/command-hub-cache-refresh` adds exclusive background refresh and status markers. Preview reads only cache files and never starts the engine.

`tools/report-section-metadata` derives labels, categories, owners, and surfaces directly from the static catalog without household reads. Command Hub does not duplicate report keys.

## Operational boundary

`tools/ledger-check` validates strict source readiness. `tools/ledger-inspect` exposes canonical Fact/provenance evidence. Neither is a report key or compact schema owner.

Git is rollback. Retired runtime aliases, old-key translation, historical parser fallback, and forwarding modules are intentionally absent.
