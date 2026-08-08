# Architecture

## Production flow

```text
explicit source files + report request manifest
  -> optional daily `current` profile (latest admitted Actual date; no wall clock)
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
- `src/sections/` — the twelve retained report results and human/compact/JSON renderers.
- `src/report/` — final catalog/order/surfaces, request validation, result dispatch, metadata, and text/JSON primitives.
- `src_edit/` and `src/editor/` — write-side commands and pure rewrite semantics using the same strict ledger owners.

Canonical Account identity, accounting type, and optional default Commodity are admitted directly from `accounts.journal` by `src/ledger/account_journal_admission.bqn`; `src/application/account_source_adapter.bqn` is the read-only file boundary. Read-only Account selection uses this canonical registry. Household-specific Account policy does not enter Account Journal admission and remains on its legacy path until the `household.toml` policy boundary replaces it. Writer-side Account mutation remains separately qualified and is not implied by read-side admission.

No report section reads files or the clock. No accounting capability imports a section or composition owner. Native multi-posting transactions remain first-class and are never flattened into two-account compatibility rows.

## Implementation style

Named modules, imports, public namespaces, and effect boundaries express accounting ownership. They should remain explicit even when the implementation inside a pure BQN owner is compact.

Inside a bounded array kernel, dense classical APL-style composition is a preferred architectural form when it makes the full transformation visible at once. Trains, modifiers, rank and cell operations, grouping, structural transforms, and partially tacit expressions may replace conventional staging names. A direct array expression must not be expanded into loops, mutable append, row objects, or a procedural pipeline solely for familiarity.

Comments above a dense kernel declare its semantic contract: axis legend, input and output shape, canonical order, contributor alignment, fill and empty behavior, exactness, and protected accounting invariants. Tests preserve observable values, ordering, provenance, diagnostics, and edge shapes. Comments should not paraphrase each glyph or require the implementation to remain verbose.

Compactness does not permit boundary collapse. Strict admission, exact arithmetic failure, diagnostics, identity, provenance, publication, I/O, and write authority remain named where their separation is semantically important. Within those boundaries, readability means that the array relationship can be seen, not that every mechanical intermediate has a name.

## Possible libri-di-casa convergence

Integration is optional: if BQN remains sufficient for trustworthy accounting, writing, reporting, and daily use, this system may remain independent indefinitely. Only a demonstrated requirement that standalone BQN cannot satisfy as clearly should select convergence. If selected, a future integration may make `libri-di-casa`/Haskell the authoritative confirmation, accounting-validation, identity, provenance, and persistence owner while this BQN engine consumes versioned confirmed evidence and owns derived array calculations and neutral report results.

This is a replaceability constraint, not a committed merger or an active alternate source. Native Journal remains the sole production Actual input until a separately admitted adapter and cutover are proven. Current development must preserve one authoritative writer, distinguish semantic source role from physical encoding, retain exact Transaction/Posting identity and provenance, and keep external consumers from having to parse human report text. Plan, Budget, Issues, and Daily Target policy are not presumed to map to historically named books.

The full boundary and future integration gate are in [`LIBRI_DI_CASA_INTEGRATION_BOUNDARY.md`](LIBRI_DI_CASA_INTEGRATION_BOUNDARY.md).

## Retained portfolio

Catalog order is:

1. Envelope & Backing
2. Account Balances
3. Balance Sheet
4. Profit and Loss
5. Recent Journal
6. Planned Payments
7. Current-cycle Accounts
8. Cycle Comparison
9. Monthly Accounts
10. Daily Flow
11. Daily Target
12. Issues

`all` is a catalog selection, not an all-report semantic record. Human and compact manifests contain existing individual route arguments in catalog order. Every row is admitted before source reads; output is buffered and published only after all selected requests succeed. Direct engine and historical requests use those concrete coordinates unchanged.

The daily Command Hub adds one application policy before that boundary: `current_report_profile.bqn` admits the human template, chooses the maximum admitted Actual transaction date as one observation, resolves current and previous Cycles, and emits a complete concrete manifest. It derives only volatile current coordinates such as observation, current-cycle horizon, P/L end-exclusive, aligned baseline observation, and Monthly Accounts end-exclusive month. It reads no wall clock; nonvolatile choices such as Daily Target target and Monthly Accounts first month remain explicit template policy.

## Cache and UI

`tools/report-cache` stages twelve section bodies plus `all.txt`, publishes `.section-keys`, deletes stale report bodies, and writes `.cache-timestamp` last. `tools/command-hub-cache-refresh` adds exclusive background refresh and status markers. Preview reads only cache/status files and never starts the engine. A failed refresh preserves the prior complete generation; preview labels it as last-known-good and exposes the bounded underlying diagnostic instead of hiding every report.

`tools/report-section-metadata` derives labels, categories, owners, and surfaces directly from the static catalog without household reads. Command Hub does not duplicate report keys.

## Operational boundary

`tools/ledger-check` validates strict source readiness. `tools/ledger-inspect` exposes canonical Fact/provenance evidence. Neither is a report key or compact schema owner.

Git is rollback. Retired runtime aliases, old-key translation, historical parser fallback, and forwarding modules are intentionally absent.
