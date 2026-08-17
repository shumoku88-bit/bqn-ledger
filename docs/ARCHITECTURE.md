# Architecture

## Production read flow

```text
canonical Household root
  -> src/application (native source adapters, typed policy, CLI composition)
  -> src/ledger (strict admission and canonical Facts)
  -> src/accounting (narrow exact capabilities)
  -> src/sections (one semantic result and approved renderers)
  -> src/report (static catalog, request admission, render dispatch)
  -> tools/report / report-summary / query / Command Hub cache
```

The production Household root has exactly eight physical sources:

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

Source basenames are not report or operational request coordinates. The application receives one Household root and resolves named canonical owners internally. Invalid evidence fails closed without partial publication.

The repository-owned `config/currencies.tsv` is application configuration, not part of the Household root.

## Ownership

- `src/application/` — canonical source I/O adapters, typed policy loading, current-request composition, readiness and inspection CLIs.
- `src/ledger/` — Account, Journal, Plan, Entitlement, Envelope policy/history, Issues, currency, exact-decimal admission, Transaction/Posting Facts, and provenance.
- `src/accounting/` — period balances, grouping/pivot, cycle resolution/comparison, Plan completion, Envelope backing, Daily Target, and recent transactions.
- `src/sections/` — the twelve retained report results and human/compact/JSON renderers.
- `src/report/` — final catalog/order/surfaces, request validation, result dispatch, metadata, and text/JSON primitives.
- `src_edit/` and `src/editor/` — write-side commands and pure rewrite semantics. Writer qualification is a separate boundary from canonical read-side recovery.

Canonical ownership is:

- Account identity, accounting type, and optional default Commodity: `accounts.journal`;
- Actual Transaction/Posting evidence and relations: `actual.journal`;
- Plan Transaction/Posting evidence, schedule, recurrence, and lifecycle relations: `plan.journal`;
- explicit Commodity StockOrigin and source-ordered native Endpoint transfers: `entitlement.journal`;
- current Envelope membership/presentation and Backing policy: `envelope.toml`;
- stable Envelope identities, historical Expense/Fulfillment routing, Cycle, money, and Daily Target policy: `household.toml`;
- report query defaults and presentation policy: `report.toml`;
- non-accounting Household notebook: `issues.tsv`.

`unallocated` is an Entitlement boundary endpoint, not an Account or stored balance. Entitlement admission depends on the stable Envelope identity universe, not the Account registry. Current Envelope membership never reconstructs historical routing.

No report section reads files or the clock. No accounting capability imports a section or composition owner. Native multi-posting transactions remain first-class and are never flattened into two-account compatibility rows.

Writer authority is not inferred from read capability. A mutating operation is canonical only after its own preview, complete-source admission, stale rejection, backup/atomic publication, post-admission, and authority proof. Until that qualification is complete, write-side code must not be treated as evidence for an alternate production source topology.

## Implementation style

Named modules, imports, public namespaces, and effect boundaries express accounting ownership. They should remain explicit even when the implementation inside a pure BQN owner is compact.

Inside a bounded array kernel, dense classical APL-style composition is a preferred architectural form when it makes the full transformation visible at once. Trains, modifiers, rank and cell operations, grouping, structural transforms, and partially tacit expressions may replace conventional staging names. A direct array expression must not be expanded into loops, mutable append, row objects, or a procedural pipeline solely for familiarity.

Comments above a dense kernel declare its semantic contract: axis legend, input and output shape, canonical order, contributor alignment, fill and empty behavior, exactness, and protected accounting invariants. Tests preserve observable values, ordering, provenance, diagnostics, and edge shapes. Comments should not paraphrase each glyph or require the implementation to remain verbose.

Compactness does not permit boundary collapse. Strict admission, exact arithmetic failure, diagnostics, identity, provenance, publication, I/O, and write authority remain named where their separation is semantically important. Within those boundaries, readability means that the array relationship can be seen, not that every mechanical intermediate has a name.

## Possible libri-di-casa convergence

Integration is optional: if BQN remains sufficient for trustworthy accounting, writing, reporting, and daily use, this system may remain independent indefinitely. Only a demonstrated requirement that standalone BQN cannot satisfy as clearly should select convergence. If selected, a future integration may make `libri-di-casa`/Haskell the authoritative confirmation, accounting-validation, identity, provenance, and persistence owner while this BQN engine consumes versioned confirmed evidence and owns derived array calculations and neutral report results.

This is a replaceability constraint, not a committed merger or an active alternate source. Current development must preserve one authoritative writer, distinguish semantic source role from physical encoding, retain exact Transaction/Posting identity and provenance, and keep external consumers from having to parse human report text.

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

`all` is a catalog selection, not an all-report semantic record. Current report requests are built from the canonical Household root plus typed `report.toml` policy. Physical source basenames never enter the request shape.

Historical requests remain explicit through semantic coordinates such as domain, dates, observations, and comparison policy. Current-domain resolution reads canonical Actual Facts; current Cycle/Daily Target coordinates derive from canonical Household/Plan evidence. Clock access is confined to the application boundary, while policy resolution and accounting remain deterministic and clock-free.

## Cache and UI

`tools/report-cache` stages twelve section bodies plus `all.txt`, publishes `.section-keys`, deletes stale report bodies, and writes `.cache-timestamp` last. `tools/command-hub-cache-refresh` adds exclusive background refresh and status markers. Preview reads only cache/status files and never starts the engine. A failed refresh preserves the prior complete generation; preview labels it as last-known-good and exposes the bounded underlying diagnostic instead of hiding every report.

`tools/report-section-metadata` derives labels, categories, owners, and surfaces directly from the static catalog without Household reads. `tools/bl` is the complete daily Command Hub: it groups Record, Plans, Budget, Accounts, Issues, Reports, and Operations, while routing to existing editor/report/operational owners. It does not duplicate report keys, parse owner output for accounting meaning, or publish source changes itself.

Terminal presentation policy comes from canonical `report.toml`; local UI preferences such as theme and selector remain outside Household policy.

The UI boundary is tool-neutral. Report metadata, cached section bodies, editor candidate protocols, and public command results are the stable inputs to presentation adapters. `fzf`, `gum`, and plain numbered interaction are current optional implementations, not owners of report identity, accounting policy, edit semantics, or publication. A future terminal UI may replace them without changing the accounting kernel or canonical writers. Shared selection and input behavior may be consolidated when the review queue reaches `tools/`; until then, core refactors must avoid introducing new selector-specific contracts.

## Operational boundary

`tools/ledger-check BASE` strictly admits the complete eight-file canonical Household root. `tools/ledger-inspect BASE` exposes canonical Actual Fact/provenance evidence from the same root. Neither command accepts a caller-selected Household source basename, and neither is a report key or compact schema owner. `tools/bl check` routes to `tools/ledger-check`; repository development validation remains the separate `tools/check.sh` suite.

Git is rollback. Retired runtime aliases, old-key translation, historical parser fallback, and source-basename forwarding are intentionally absent from the canonical read side.
