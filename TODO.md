# Notes and open directions

This is a lightweight notebook for current work. Completed implementation history belongs in `docs/archive/` and Git history.

## Current state

- Native Journal is the sole production Actual source; companion sources remain `plan.tsv`, `budget_alloc.tsv`, `accounts.tsv`, `cycle.tsv`, and `issues.tsv`.
- `src_next/selected_domain_context.bqn` constructs one registry-supported currency through a flat fail-closed sequence: policy, complete Actual admission, currency-proof carriage, non-Actual preparation, exact normalization, and Cube/TBDS period views.
- Canonical Daily Cube, TBDS, and purpose-specific sparse consumers are views over checked posting facts, not competing source truths.
- `src_next/queries/actual_expense_ranking.bqn` is the first direct sparse consumer. A second independent real consumer is still required before extracting broader query vocabulary or replacing production Cube/TBDS accumulation.
- Human balances for ledgers with `DEFAULT_CURRENCY` have one BQN-owned selected-domain body across direct, full, and cache output. BQN owns section descriptors and the cache key manifest; preview does not run report calculation.
- `src_next/projection.bqn` is now a small compatibility shelf for non-Actual Posting IR vocabulary, `ResolveDayFromCycle`, Layer delegates, and arithmetic-proof delegates. Diagnostic presentation and dead date/scalar exports have already been removed.
- `src_next` directory migration is evidence-led. The first query neighborhood is under `src_next/queries/`; high-fan-in hubs remain at root.

## Selected work: reduce report code after prepared-boundary migration

The current implementation plan is [`docs/REPORT_CODE_REDUCTION_PLAN.md`](docs/REPORT_CODE_REDUCTION_PLAN.md). The objective is not to apply the same architecture template to every section. Preserve daily report behavior, introduce only a useful prepared seam, migrate real callers, then remove superseded adapters, source-shape checks, and duplicate preparation.

Point-in-time baseline: `src_next` has 75 BQN modules and 13,056 physical lines (approximately 10,407 nonblank, non-comment lines). This is characterization, not a minification target. Tests and fail-closed diagnostics must not be weakened to reduce the count.

### Completed finite slice: Actual Snapshot

- [x] Added the narrow I/O-free `BuildFromPrepared` calculation boundary.
- [x] Preserved inclusive cumulative cutoff, pre-cycle opening evidence, rejected-row applicability, invalid-date failure, valid-empty zero, and Outlook failure propagation.
- [x] Added a direct prepared-core test and replaced `BuildAt` source-shape grep assertions with behavioral evidence.
- [x] Initially kept broad compatibility adapters, then removed `BuildAt` and the source-loading latest-date API in the Outlook caller-migration slice; the prepared date policy remains explicit.
- [x] Passed focused checks, `tools/check.sh`, coverage, and diff validation.

Completion record:

```text
slice: Actual Snapshot
behavior preserved: cumulative cutoff, rejected/invalid/empty semantics, Outlook propagation
prepared boundary: BuildFromPrepared(postingRows, cubeView, resolved, as_of)
removed code/API/check: removed BuildAt source-shape awk/grep assertions
src_next line delta: +9 (13,056 -> 13,065); exports +1 (3 -> 4)
remaining compatibility caller: resolved later; Outlook and tests now call BuildFromPrepared, while default observation uses Build
checks: focused prepared/numeric tests, actual-snapshot check, full tools/check.sh, coverage
```

The Outlook caller-migration checkpoint repaid 8 of these lines: Actual Snapshot is now 155 lines versus its 154-line baseline, and its export count returned to three without broad `BuildAt` or a source-loading latest-date API.

### Completed finite slice: Daily Flow

- [x] Inventoried the sole production caller, required `ctx` fields, and unused imports.
- [x] Moved Actual date acquisition and compatibility fallback into `Build(ctx)`.
- [x] Added `BuildFromPrepared(cubeView, resolved, cy, actualDates)` and preserved Daily Flow's explicit `as_of` anchor independently from Daily Trend.
- [x] Added no-base/invalid-cycle prepared behavioral evidence and direct adapter parity.
- [x] Removed five unused module imports, the unused label binding, and the dead source-loading `LatestActualDateInCycle` helper.
- [x] Passed focused checks, section rendering, full `tools/check.sh`, and coverage.

Completion record:

```text
slice: Daily Flow
behavior preserved: day-count observation window, explicit as_of row anchor, account partitions, compact/human output
prepared boundary: BuildFromPrepared(cubeView, resolved, cy, actualDates)
removed code/API/check: five unused imports, unused label binding, dead source-loading helper
src_next line delta: +10 (13,065 -> 13,075); exports +1 (3 -> 4)
remaining compatibility caller: report uses Build(ctx); DatesFromContext retains focused base fallback
checks: prepared test, section rendering, context/projection checks, full tools/check.sh, coverage
```

The adapter remains the truthful production boundary. Its compatibility deletion checkpoint is removal of the `DatesFromContext` base fallback after all supported contexts carry Actual transactions; the final track must still repay temporary prepared-boundary growth overall.

### Completed finite slice: Daily Trend

- [x] Preserved the characterized contract that `BuildAt(ctx, header_O)` changes header coordinates, not replay calculation.
- [x] Kept `daily_trend_plan.BuildAt` in the context adapter and passed its checked/fail-closed reserve result into the numeric core.
- [x] Added `BuildFromPrepared(cubeView, resolved, cy, as_of, trend_dates, plan_result)` without broad `ctx` or source access.
- [x] Preserved row-local future-income replay, empty-cycle-start anchoring, reserve completion timing, and error propagation.
- [x] Added adapter parity, no-base, invalid-cycle, and prepared plan-failure evidence.
- [x] Removed the dead source-loading latest-date helper and replaced the helper-connection source grep with behavioral evidence.
- [x] Passed all focused Daily Trend tests, section checks, full `tools/check.sh`, and coverage.

Completion record:

```text
slice: Daily Trend
behavior preserved: header-only BuildAt, row-local replay, empty anchor, checked reserve fail-closed semantics
prepared boundary: BuildFromPrepared(cubeView, resolved, cy, as_of, trend_dates, plan_result)
removed code/API/check: dead source-loading helper; trend_plan.BuildAt connection grep
src_next line delta: +19 (13,075 -> 13,094); exports +1 (4 -> 5)
remaining compatibility caller: report uses BuildAt; summary uses Build; plan adapter retains source/context evidence preparation
checks: prepared test, all focused trend tests, numeric-owner check, full tools/check.sh, coverage
```

`BuildAt` remains because the production human report explicitly supplies a header coordinate, while compact summary uses internal replay observation. The later report/Outlook observation review is the deletion or rename checkpoint; the plan-evidence adapter joins the `actual_source` compatibility checkpoint.

### Completed finite slice: Outlook

- [x] Inventoried `BuildCore`, Actual Snapshot, remaining-plan, frontier, Envelope, next-obligation, and Daily Capacity boundaries.
- [x] Replaced effectful `BuildCore(ctx, ...)` with I/O-free `BuildFromPrepared(input)`; config, plan-line, envelope, snapshot, and remaining-plan preparation stays in the adapter.
- [x] Preserved open-ended frontier, explicit no-Actual unavailable, invalid-date, and snapshot/remaining-plan failure propagation.
- [x] Retained `daily_capacity.bqn` as an independent evidence-first experiment; it is not wired into compatibility Outlook because its arithmetic-domain, asset-scope, obligation, and reservation contracts are materially different.
- [x] Added full VM and renderer parity from a no-base prepared input.
- [x] Migrated Outlook and focused tests to Actual Snapshot's prepared core, removing broad `actual_snapshot.BuildAt`.
- [x] Replaced Outlook/Actual Snapshot source-loading frontier/date APIs with prepared-date policy APIs.
- [x] Replaced the remaining-plan helper-connection grep with prepared behavioral evidence.
- [x] Passed focused Outlook/Snapshot checks, full `tools/check.sh`, and coverage.

Completion record:

```text
slice: Outlook
behavior preserved: explicit/default observation, open-ended frontier, snapshot/plan errors, envelope and obligation output
prepared boundary: BuildFromPrepared(section-specific prepared input)
removed code/API/check: three exported broad/source APIs, one private source wrapper, helper-connection grep
src_next line delta: +11 (13,094 -> 13,105); Outlook +19, Actual Snapshot -8
export delta across both modules: 0; broad APIs replaced by prepared core/policy exports
remaining compatibility caller: Outlook Build/BuildAt adapters; next obligations still interpret plan lines
checks: prepared parity, all focused Outlook/Snapshot checks, full tools/check.sh, coverage
```

The slice contains a real deletion but the overall track remains above baseline by 49 lines. Envelope work must not add a generic framework; it must remove or replace one existing responsibility at a time.

### Completed finite slice: Envelope inventory and compatibility shelf cleanup

- [x] Mapped envelope balances, fixture policy target, unassigned pool, backing diagnostics, execution planned coverage, orchestration, and three renderers.
- [x] Confirmed `CalcEnvelopeBacking` and unassigned calculation are already I/O-free and should not be moved merely because the file is large.
- [x] Removed the uncalled source-loading tuple builder and dead source-loading latest-date helper.
- [x] Reduced the module export surface from 22 fields to the 11 fields with repository callers or focused contract use.
- [x] Removed dead config loading from `BuildEnvelopes`; envelope balance calculation now receives only resolved/cycle/rows/prepared dates.
- [x] Reused `plan_rows.WithValues` for execution planned rows instead of maintaining another local value parser.
- [x] Preserved Envelope's source-order latest-date and invalid-date crash characterization rather than importing another section's policy.
- [x] Passed focused Envelope checks, full `tools/check.sh`, and coverage.

Completion record:

```text
slice: Envelope inventory and compatibility shelf cleanup
behavior preserved: envelope balances, source-order clock, invalid-date characterization, backing and execution diagnostics, all renderers
removed code/API/check: BuildFromTuple, dead latest-date loader, 11 unused exports, dead BuildEnvelopes config read
src_next line delta: -25 (13,105 -> 13,080); module 914 -> 889
export delta: -11 (22 -> 11)
remaining effectful responsibility: BuildWithPreparedActual still owns config/allocation/execution source preparation
checks: focused computation/characterization checks, full tools/check.sh, coverage
```

This is the first net-reduction slice. The overall track is now 24 lines above the original 13,056-line baseline.

### Current finite slice: Execution planned coverage

- [ ] Separate plan source/value preparation from execution-envelope comparison without changing lazy disabled/missing-envelope behavior.
- [ ] Preserve completion identity, duplicate rows, date ordering, and the characterized unrelated-plan inclusion behavior.
- [ ] Remove the remaining local source/value assembly that the prepared input replaces.
- [ ] Keep this readonly diagnostic distinct from envelope balance and backing calculations.
- [ ] Require non-positive `src_next` line delta for the slice; do not add a framework or new module.

Later work remains unselected: other bounded Envelope responsibilities, then `actual_source` compatibility reduction. Do not start them together.

The completed context-reuse characterization remains in:

- `docs/REPORT_CONTEXT_DUPLICATION_CHARACTERIZATION-2026-07-27.md`
- `tools/characterization/report_context_duplication_probe.bqn`

Do not collapse ordinary and selected-domain contexts into one universal context or reuse compatibility posting rows as selected-domain rows without contract evidence. Current performance no longer justifies that risk.

## Other useful directions

- Continue projection cleanup by coherent caller responsibility: mixed `ResolveDayFromCycle` users, Layer ownership, and arithmetic-proof ownership are separate decisions.
- Separate remaining JPY compatibility seams in `account_key.bqn`, arithmetic-proof authorization, and `context.BuildContext` from registry-generic selected-domain behavior.
- Keep improving selected-currency daily use, travel recording, editor ergonomics, and reports from actual experience.
- Reassess the temporary `src_next/main.bqn` compatibility wrapper only through an explicit deprecation decision.
- Move another `src_next` module neighborhood only after import-graph and caller evidence identify a low-blast-radius group.
- Consolidate Command Hub freshness policy only if a read-only cache-state owner reduces responsibility rather than merely moving shell lines.

## Working principles

- Arithmetic domain is an explicit partition/key requirement, not an implicit property of a numeric grouping kernel.
- Transaction `kind` is not posting-level account classification.
- Flat stage composition must preserve first-failure ownership and never expose a partial selected context.
- Code and directory beauty mean truthful ownership, not maximum splitting or nesting.
- Private household data remains under explicit human direction.
