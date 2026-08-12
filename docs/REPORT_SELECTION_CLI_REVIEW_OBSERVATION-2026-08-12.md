# Report Selection CLI review observation — 2026-08-12

## Scope

Review `src/application/report_selection_cli.bqn` as the request-set selection leaf used by cache/all-report orchestration.

## Observation

This CLI resembles `report_request_cli.bqn` because both delegate retained key/surface admission to the pure Report request owner. Their publication responsibilities are different:

- Request CLI validates one KEY/SURFACE process boundary and publishes `OK`;
- Selection CLI publishes the admitted `section_keys` axis for a request-set such as `all human`.

`tools/report-cache` consumes that key axis as an independent catalog-order expectation. It compares the current profile request rows against the selected Human key order before staging and atomically publishing the cache, then uses the same key axis to define the cache file set.

The separate process protocol therefore has a live consumer and a clear reason to exist. Merging the two CLIs would introduce a mode/configuration abstraction without reducing semantic ownership.

## Decision

Retain production `report_selection_cli.bqn` unchanged.

The existing implementation already has the desired shape:

```text
KEY + SURFACE argv
  -> exact argv arity
  -> pure Report request admission
  -> diagnostics or selected section-key axis
```

It owns no mutable traversal, source discovery, catalog copy, cache behavior, or writer behavior.

Strengthen `checks/check-report-cache.sh` only enough to protect that leaf ownership: Selection CLI must continue to depend on the pure Report request owner and must not gain source-adapter/source-I/O ownership.

## Test and fixture classification

No new fixture is introduced.

`checks/check-report-cache.sh` already exercises the real Selection CLI result against a canonical current Report cache build. It proves selected key order, exact cache file inventory, concatenated `all` parity, stale-file retirement, lock safety, Report-policy fail-closed publication, and generation-token admission.

`checks/check-report-section-metadata.sh` independently compares selected retained keys with metadata/catalog publication.

The pure `src/report/request.bqn` remains the semantic selection law owner. Another focused CLI fixture would duplicate those existing layers.

## Protected boundaries

Unchanged:

- retained Report request/catalog ownership;
- request-set selection order;
- source independence of selection;
- current-profile/cache order validation;
- cache publication semantics;
- diagnostics and exit behavior;
- writer authority.
