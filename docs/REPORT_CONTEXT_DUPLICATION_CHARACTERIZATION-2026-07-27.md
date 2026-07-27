# Report context duplication characterization — 2026-07-27

Status: characterized; cycle, date, and completion-evidence reuse implemented
Owner: report / context boundaries
Canonical: no; runtime modules and current contracts remain authoritative
Exit: archive or shorten after the duplicate source-preparation route is removed

## Question

For a full human report with `DEFAULT_CURRENCY`, where is work duplicated between the ordinary `BuildContext` route and the selected-domain balances route, and what is safe to share without inventing one universal context?

This characterization uses only repository code and public sandbox data. It does not inspect private household data and does not change report semantics.

## Current route

`src_next/report.bqn` currently performs:

```text
ctx_mod.BuildContext(base)
  -> ordinary full-report context

BuildBalancesEntry(base, ctx)
  -> balances.BuildSelected(base, "")
  -> selected_domain_context.Build(base, default currency)
  -> second Cube/TBDS period view for balances
```

The selected balances body is now BQN-owned and identical across direct, full, and cache routes. That routing correction intentionally did not remove the two context constructions.

## Static findings

### Shared source material remains partly independent

Both routes still independently obtain:

- `accounts.tsv` and resolved AccountKey metadata;
- configured Actual Journal path and raw bytes;
- `plan.tsv` / `budget_alloc.tsv` snapshots;
- posting rows and a Cube/TBDS period view.

Selected-domain cycle resolution reuses its already-admitted transactions instead of independently reloading Actual date/income evidence, and passes that same admission result into production selected composition. The compatibility `BuildContext` now also loads one source-owned cycle evidence carrier and reuses it for default and explicit period resolution.

The resulting rows are not interchangeable by assumption. `context.BuildContext` is the JPY compatibility route; `selected_domain_context.BuildFromPrepared` is a registry-supported, fail-closed selected-currency route with exact normalization.

### Admission semantics differ

The ordinary route uses:

```text
journal_profile_stage1.ParseWithProfile
  -> account declaration parity
  -> journal_posting_ir_stage2a.BuildForSource
```

The selected route uses:

```text
journal_complete_source_admission.Admit
  -> journal_currency_proof_carrier_stage2a.BuildForSource
  -> selected-domain filtering and normalization
```

Therefore checked posting rows are not yet a proven sharing boundary. Raw source bytes, resolved account metadata, and non-Actual source snapshots are lower-risk candidates.

### Baseline: cycle resolution was the largest repeated source adapter

For `incomeAnchor`, compatibility `cycle.ReadCycle` calls `actual_source.LoadDates` and `actual_source.IncomeDates`. Those helpers reload and admit the Journal through `LoadCycleTransactions`.

At the measured baseline, `selected_domain_context.Build` performed preliminary complete admission, called the source-loading cycle resolver, and then `BuildFromPrepared` performed complete admission again. The dominant duplication was therefore repeated Journal admission while resolving observation/cycle evidence, not merely filesystem `ReadRaw`.

The first seam added `cycle.ReadCycleFromAdmittedTransactions`. Cycle still owns latest-Actual/no-Actual observation selection, income-account interpretation, plan evidence, and period construction, but derives Actual dates and income dates from the complete admitted transactions supplied by the selected adapter.

The compatibility slice adds source-owned `actual_source.LoadCycleEvidence` plus `cycle.ReadCycleFromActualEvidence` / `ReadCycleFromActualEvidenceAt`. The evidence retains whether transactions came from complete admission or the historical parser fallback, so delta-vs-normalized income semantics remain unchanged. `BuildContext` reuses one evidence result across its existing two-step default/explicit period selection instead of asking compatibility `ReadCycle` to reload Actual repeatedly.

### Selected admission reuse

After cycle evidence reuse, production `selected_domain_context.Build` still admitted the same `raw` / `resolved` pair twice: preliminary admission for cycle evidence and public `BuildFromPrepared` admission for semantic composition.

The second slice introduces an internal `BuildFromPreparedCore` carrier. Production `Build` passes its successful preliminary admission to that core. Public `BuildFromPrepared` still performs policy-first admission itself, preserving its test seam, unsupported-policy priority, diagnostics, and no-partial-result contract.

### Period selection must remain explicit

The two routes do not have a guaranteed identical period-selection contract:

- ordinary `BuildContext(base)` derives its compatibility `as_of` through its current two-step cycle logic;
- selected `Build(base, currency)` uses the latest admitted Actual transaction when Actual exists.

The public sandbox currently resolves both to the same cycle, but that observation is not proof that one route may silently borrow the other's period.

## Public sandbox timing

Command:

```sh
bqn tools/characterization/report_context_duplication_probe.bqn data JPY
```

Five separate process runs on the local development machine produced these medians:

| Phase | Median |
|---|---:|
| ordinary `BuildContext` | 186.719 ms |
| selected `Build` adapter total | 213.887 ms |
| sequential two-context total | 399.967 ms |
| explicit selected input preparation | 187.673 ms |
| selected preliminary admission within preparation | 9.928 ms |
| selected cycle resolution within preparation | 164.816 ms |
| selected `BuildFromPrepared` | 25.430 ms |

The values are characterization, not performance thresholds. The useful baseline result was their shape: cycle/evidence resolution dominated selected input preparation, while source file reads alone did not.

After the evidence-reuse slice, five new separate process runs produced:

| Phase | Before median | After median |
|---|---:|---:|
| selected `Build` adapter total | 213.887 ms | 40.300 ms |
| sequential two-context total | 399.967 ms | 202.212 ms |
| explicit selected input preparation | 187.673 ms | 24.884 ms |
| selected cycle resolution within preparation | 164.816 ms | 0.146 ms |
| selected `BuildFromPrepared` | 25.430 ms | 18.253 ms |

The selected adapter decreased by about 81% in this public sandbox observation. A second five-run observation after production admission reuse measured selected `Build` at 29.647 ms and the sequential two-context total at 190.227 ms. This is about 86% below the original selected baseline and another 26% below the first slice.

After compatibility cycle-evidence reuse, five runs measured ordinary `BuildContext` at 49.797 ms, selected `Build` at 29.744 ms, and the sequential total at 79.773 ms. The sequential context cost is about 80% below the original 399.967 ms observation. These remain local measurements, not CI gates.

The probe verifies that direct selected construction and construction from explicitly prepared inputs have the same calculation scale, posting-row count, and Actual-transaction count. The focused cycle test additionally proves that prepared income-anchor evidence resolves without any config, accounts, or Journal file, and that it matches source-loaded resolution on a complete production fixture.

## Implemented decisions and remaining boundary

The bounded seams are implemented without a new universal context:

```text
selected complete admission
  ├─> cycle.ReadCycleFromAdmittedTransactions
  └─> BuildFromPreparedCore

compatibility actual_source.LoadCycleEvidence
  ├─> cycle.ReadCycleFromActualEvidence       (default observation)
  └─> cycle.ReadCycleFromActualEvidenceAt     (resolved explicit observation)
```

`actual_source.IncomeDatesFromCompleteTransactions` and `IncomeDatesFromCycleEvidence` own income-date extraction for complete and compatibility evidence shapes. `cycle.bqn` continues to own cycle definition and period selection. The public `BuildFromPrepared` wrapper remains independently admitting and policy-first; only the production adapter uses the trusted admitted carrier.

Both full-report contexts still exist. Do not merge them or reuse compatibility posting rows as selected-domain rows. Remaining duplication includes account/raw source reads between the two contexts, non-Actual preparation, and the second Cube/TBDS view. At roughly 30 ms selected overhead on the public sandbox, a risky universal-context merge is not justified by current performance evidence.

A subsequent consumer slice removed production `LoadDates` reloads from context-based outlook, daily flow/trend, planned-payment, cycle-summary, actual-snapshot, and envelope paths. `actual_source.DatesFromContext` derives dates from the context-carried transactions; each consumer keeps its existing cycle scope, no-data fallback, and observation semantics. The later compatibility cleanup removed repository-unused source wrappers and test seams; only base-oriented cycle entrypoints retain `LoadDates` / `IncomeDates`, while focused missing-field contexts retain fallback loading through the context helpers.

Completion and plan-ID evidence were handled as a separate slice because they carry parser and identity semantics. Compatibility `BuildContext.actual_transactions` is the same `historical_external_plan` transaction shape previously reloaded by `CompletionEvidence`, so `CompletionEvidenceFromTransactions` can preserve delta-based amount, explicit `plan_id`, five-field fallback identity, and cycle filtering without source I/O. Context-based plan rows, daily trend, envelope coverage, Outlook remaining plan, cycle summary, and overlap diagnostics now use that prepared historical evidence. Selected-domain complete transactions are not treated as this compatibility shape.

The date slice also exposed repeated observation interpretation. Only exact duplicate policies were extracted to `actual_observation.bqn`: the Daily Flow/Trend pair uses its historical `start + day_count` window, while Planned Payments/Cycle Summary uses explicit half-open cycle bounds. Actual Snapshot, Snapshot, Envelope, and Outlook retain their distinct invalid-date, absence, source-order, and open-ended-frontier semantics.

Planned Payments now consumes these prepared date/completion seams through an explicit section-local pipeline: context adapter → prepared semantic VM → pure human/JSON renderer. Its compact output keeps a smaller completion-only prepared VM, so introducing the clean boundary does not silently add temporal/as-of dependencies to the compact contract.

## Evidence

- `tools/characterization/report_context_duplication_probe.bqn`
- `checks/check-report-context-duplication-characterization.sh`
- `tests/test_src_next_cycle_prepared_evidence.bqn`
- `fixtures/cycle-prepared-evidence/`
- `src_next/report.bqn`
- `src_next/context.bqn`
- `src_next/selected_domain_context.bqn`
- `src_next/cycle.bqn`
- `src_next/actual_source.bqn`
