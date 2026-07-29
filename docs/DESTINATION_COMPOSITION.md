# Destination composition and cutover preparation

Status: P10E static catalog, one-result composition/rendering, and all nine key-first individual CLI adapters complete; `all`, cache, operational separation, and cutover remain in progress.

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

## Key-first I/O and parallel CLI

Application-only `source_io.bqn` and `report_source_adapter.bqn` own read-only file access. Core ledger/accounting/sections/report modules do not import them. `tools/report-destination` admits key and surface before its BQN entry reads household evidence and currently wires:

```text
envelopes         Accounts/Actual + explicit Plan/Budget + funding Account keys
balances          accounts.tsv + explicit Journal basename
recent            accounts.tsv + explicit Journal basename
planned           Accounts/Actual + explicit Plan and Cycle basenames
cycle-accounts     Accounts/Actual + explicit Cycle; Plan only for incomeAnchor
cycle-comparison   Accounts/Actual + two explicit Cycle definitions; Plan only for incomeAnchor
monthly-accounts   accounts.tsv + explicit Journal basename
daily-target       Accounts/Actual + explicit Plan + strict ownership/linkage TSV
issues             explicit strict Issue TSV basename
```

All coordinates and basenames are explicit. Safe Journal/TSV basenames reject separators; there is no path fallback. Cycle definitions are strictly admitted before mode-specific resolution. Fixed/calendarMonth requests do not read Plan; incomeAnchor requires it. Comparison admits separate current/baseline definitions and rejects differing modes. Selective-source tests prove Recent works with Accounts/Actual only, fixed Cycle Accounts adds only Cycle, Planned does not require Budget, incomeAnchor fails without Plan, Envelope rejects non-asset funding, Daily Target needs no Budget/Cycle source, Issues works without Accounts/Actual, and unknown/unsupported requests fail even when the base path does not exist.

Envelope funding ownership is admitted from one or more explicit Account keys. Keys must be unique, admitted, same-domain, and `role=asset`; names/prefixes never classify funding.

Daily Target uses the exact seven-column application source:

```text
kind | scope_id | account_key | plan_id | excluded_amount | currency | reservation_ref
```

Asset rows link durable scope identity to an admitted asset Account. Obligation rows link durable scope identity to a canonical Plan `plan_id`; amount/date/currency and completion status come from Plan/Actual evidence rather than the policy row. Positive exclusion requires exact currency and unique reservation reference. The adapter builds assets from observed Account balances and obligations from durable completion Join, preserving contributors. Completed or outside-horizon obligations remain evidenced but are excluded from calculation; overdue open obligations remain included.

The parallel CLI now supports all nine keys individually but still does not replace production. `all` must iterate one-result adapters without creating a universal coordinate record. No Account-name inference or fabricated default fills ownership. Any future interactive clock default must be captured once outside core and converted to explicit coordinates. Public CLI proof remains parallel to production until cutover.

## Cutover boundary

Current production remains `tools/report -> src_next/report.bqn`. No destination alias, dual key, forwarding wrapper, or partial route switch is introduced in P10A.

Before atomic cutover:

1. public one-request composition and deterministic CLI behavior must pass;
2. operational check/debug ownership must be separated;
3. external compact/query/cache consumers must be confirmed with moko;
4. private Issues/source readiness requires separate explicit authorization;
5. old routes, keys, cache entries, metadata, callers, tests, and compatibility runtime are removed in one change.
