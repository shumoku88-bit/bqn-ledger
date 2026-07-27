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

## Current investigation

Full report/cache generation still constructs the ordinary compatibility `BuildContext` and a second selected-domain context for balances. Selected cycle/composition reuse complete admission, while compatibility `BuildContext` reuses one source-owned complete-or-fallback cycle evidence result across default and explicit period resolution. Context-based report consumers now derive Actual dates and compatibility completion/plan-ID evidence from `ctx.actual_transactions` instead of reloading the Journal; their distinct no-data, identity, cycle-scope, and observation policies remain local. On the public sandbox, sequential context median time fell from about 400 ms to 80 ms before this consumer slice; timings are observations, not gates.

Evidence is recorded in:

- `docs/REPORT_CONTEXT_DUPLICATION_CHARACTERIZATION-2026-07-27.md`
- `tools/characterization/report_context_duplication_probe.bqn`

Do not collapse the routes into one universal context or reuse compatibility posting rows as selected-domain rows without contract evidence. Remaining duplication includes account/raw source reads between contexts, non-Actual preparation, and the second Cube/TBDS view. Current performance no longer justifies a risky universal-context merge. Completion evidence and plan-ID matching were migrated as a separate historical-shape slice after preserving their delta, fallback-identity, and cycle-filter contracts. Exact duplicate Actual-observation logic now has a narrow pure owner for the Daily Flow/Trend and Planned Payments/Cycle Summary pairs; section-specific invalid-date, source-order, absence, and open-ended frontier policies remain local. Planned Payments is the first section explicitly shaped as context adapter → prepared semantic VM → pure renderer, while its compact path remains independent from human/JSON temporal attachment. Remaining plan/non-Actual reads should only be shared when measurements justify a prepared snapshot boundary.

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
