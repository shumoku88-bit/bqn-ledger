# Journal report coverage inventory

Status: audit snapshot
Owner: report / journal source migration
Canonical: no; current routes: `../../../TODO.md`, `../../REPORT_CONTRACTS.md`, and `../../JOURNAL_CANONICAL_TSV_NATIVE_PREFIX_CONVERTER_PLAN.md`
Exit: retain as current-main evidence until a later Journal report-coverage audit supersedes it or a separately selected finite slice changes production routing
Date: 2026-07-22

## Scope

Finite question:

> On current remote `main`, do the repository and production-report checks pass without regression, and for each production report/report section what are the actual input route, numeric owner, existing Journal evidence, and still-unproved production-Journal surface?

This is a public-fixture, read-only inventory. It does not decide or implement converter resumption, production routing, cutover, or private verification. Current behavior is distinguished as follows:

- **A — existing production regression:** current TSV-routed checks.
- **B — Journal structural evidence:** parser, Stage 2A/2B, Posting IR, Cube, and TBDS synthetic evidence.
- **C — Journal report rehearsal:** Journal-derived Posting IR supplied to selected existing report functions in tests.
- **D — production Journal report routing:** production entrypoint reads native Journal as source truth.
- **E — private daily bookkeeping correctness:** private Journal facts appear correctly in production reports.

A, B, and the limited C evidence passed. D and E are **not proven** and must not be inferred from them.

## Repository state

| Item | Observed value |
|---|---|
| Starting branch | `feat/journal-external-plan-reference-profile-prerequisite` |
| Starting local HEAD | `e7706212bd64d02d6b61b2d8315d1f18de2367b2` |
| Initial local `main` | `44ac4652cd2cd0709c661518a3a35811dc7497a4` |
| Verified `origin/main` and remote `main` | `64d808ebb8954de3f4a3cfeb29373542e1d9c24b` |
| Expected remote SHA | `64d808ebb8954de3f4a3cfeb29373542e1d9c24b` |
| PR #323 evidence | `64d808e feat: add Journal external plan reference profile (#323)` at `origin/main` |
| Audit branch | `docs/journal-report-coverage-inventory` |
| Audit branch base | `64d808ebb8954de3f4a3cfeb29373542e1d9c24b` |

The starting working tree was clean. After `git switch main` and `git pull --ff-only origin main`, `HEAD`, local `main`, and `origin/main` all resolved to the verified SHA and the tree remained clean. The audit branch did not exist locally or remotely before creation.

## Starting gate result

**PASS.** Remote `main` exactly matched the instructed SHA, PR #323 was present, all three post-pull main references agreed, and no pre-existing change was touched. Evidence: Git command results listed under [Commands executed](#commands-executed).

## Regression check result

| Field | Result |
|---|---|
| Command | `rtk bash ./tools/check.sh` |
| Start (UTC) | `2026-07-22T12:53:38Z` |
| End (UTC) | `2026-07-22T12:56:21Z` |
| Exit status | `0` |
| Last successful section | `[5/5] engine-independent checks`; final `OK` |
| First failed section | none |
| Failed test/check | none |
| stderr non-sensitive summary | no failure; all five phases completed |
| Classification | repository success; no environment unavailability |
| Post-audit full check | `rtk bash ./tools/check.sh`, `2026-07-22T12:59:58Z`–`2026-07-22T13:02:56Z`, exit `0`, final `[5/5]` / `OK` |

This proves A for the public fixtures/checks registered by `tools/check.sh`: unit tests, golden checks, section checks, MCP checks, and engine-independent checks all passed. The pre-file and post-file runs agree. It is not production-data validation.

## Production routing finding

Production actual input remains TSV:

```text
tools/report
  -> src_next/report.bqn Main
  -> context.BuildContext
  -> context.LoadPostingSourceSnapshot
  -> <base>/journal.tsv + plan.tsv + budget_alloc.tsv
  -> checked 16-field Posting IR
  -> Cube + TBDS
  -> section builders
```

Evidence:

- `tools/report` is the default production report wrapper and executes `src_next/report.bqn`.
- `src_next/report.bqn` `Main` calls `ctx_mod.BuildContext base` and maps all 15 canonical human sections.
- `src_next/context.bqn` `LoadPostingSourceSnapshot` explicitly loads `journal.tsv`, `plan.tsv`, and `budget_alloc.tsv`; `BuildContext` uses that snapshot.
- `src_next/journal_read_only_source_carrier.bqn` states it is test-only, performs no I/O, and is not connected to production routing.
- `src_next/journal_shadow_context.bqn` is a standalone explicit-path shadow builder; it does not replace `BuildContext`.
- `TODO.md` “Journal source migration”, `NEXT_SESSION.md` “Explicit gates”, and `docs/README.md` state that source truth/report routing remain TSV.

Therefore D is **no for every production surface inventoried below**. The explicit shadow module is evidence tooling, not partial production routing.

## Report coverage matrix

Legend:

- **TSV regression** names executable checks/tests over public TSV fixtures.
- **Journal evidence** is `direct C`, `structural B`, or `none`.
- **PJ route** is production Journal routing.
- Shared production entrypoints are `tools/report` → `src_next/report.bqn` for human sections and `tools/report-next-summary` → `src_next/summary.bqn` for the compact machine surface.

Twenty-two surfaces are inventoried: 15 canonical human sections plus 7 machine/internal report surfaces emitted or consumed by the production summary/report path.

| Report / section | Production entrypoint | Actual / plan / budget source owner | Numeric owner | Source-evidence dependency | Existing TSV regression evidence | Existing Journal evidence | PJ route | Proven / Not proven | Evidence paths |
|---|---|---|---|---|---|---|---|---|---|
| Snapshot (`snapshot`) | human section + JSON; `snapshot.Build` | actual: TBDS; plan: TBDS cycle fields; budget: none directly | TBDS closing and `snapshot.Build` totals | cycle/as-of; readiness counts | report, snapshot, JSON, compact checks | structural B: Journal shadow produces equal TBDS; no direct `snapshot.Build` rehearsal | no | Proven: TSV snapshot contracts. Not proven: direct Journal Snapshot output or production Journal input. | `src_next/snapshot.bqn`; `checks/check-src-next-snapshot.sh`; `checks/check-src-next-report.sh`; `tests/test_journal_file_backed_shadow_context.bqn` |
| Issues (`issues`) | human section; `issues.FormatHuman ctx` | actual/plan/budget: n/a; `issues.tsv` via context | no ledger arithmetic | issue rows | full report/builder/registry tests | none; independent of Journal actuals | no | Proven: section registration/current TSV context. Not proven: production report assembled from Journal context. | `src_next/report.bqn`; `src_next/issues.bqn`; `tests/test_src_next_report_builder_order.bqn` |
| YTD Summary (`ytd`) | human + compact; `ytd_summary.Build` | actual: checked Posting IR filtered to `source_file=journal.tsv`; plan/budget: n/a | `ytd_summary.Build` over semantic posting rows | source-file discriminator, date, account role | `check-src-next-ytd-summary.sh`, compact/report checks | none; current filter excludes `profile.journal` rows | no | Proven: TSV YTD. Not proven: any Journal-derived YTD; current consumer needs characterization/migration. | `src_next/ytd_summary.bqn`; `checks/check-src-next-ytd-summary.sh` |
| Balances (`balances`) | human/JSON/selected currency; `balances.Build` | actual: TBDS closing; plan/budget: n/a | `tbds.NonzeroActualBalances`, balances totals | resolved account role/type/currency | balances, currency-M3, report JSON, compact | **direct C**: simple/split Journal contexts, formatters, and file-backed TSV parity | no | Proven: synthetic Journal-derived actual balances and formatters. Not proven: production routing, all currencies, private facts. | `src_next/balances.bqn`; `checks/check-src-next-balances.sh`; `checks/check-currency-m3-balances.sh`; `tests/test_journal_read_path_trial_balance_rehearsal.bqn`; `tests/test_journal_split_purchase_report_information_boundary.bqn`; `tests/test_journal_file_backed_shadow_context.bqn` |
| Cycle Summary (`cycle`) | human + compact; `cycle_summary.Build` | actual: TBDS movement; plan money: plan Posting IR joined by `source_row`; completion/frontier: raw plan/journal TSV | TBDS actual/plan totals plus checked remaining-plan helper | plan ID/completion, source row, latest actual date | cycle, remaining-plan characterization, compact/report | structural B only for TBDS actual movement; no Cycle Summary Journal rehearsal | no | Proven: TSV cycle and fail-closed plan behavior. Not proven: Journal frontier/completion semantics and full section output. | `src_next/cycle_summary.bqn`; `checks/check-src-next-cycle-summary.sh`; `checks/check-src-next-cycle-remaining-plan-characterization.sh` |
| Trial Balance (`trial-balance`) | human + compact; `trial_balance.Build` | selected layer from TBDS | TBDS opening/debit/credit/closing | account key/layer/period only | unit tests, compact and full report surfaces | **direct C**: simple, split-purchase, and file-backed TSV parity | no | Proven: synthetic Journal actual-layer TBDS reaches exact Trial Balance. Not proven: production Journal route/private parity. | `src_next/trial_balance.bqn`; `tests/test_src_next_trial_balance.bqn`; `tests/test_journal_read_path_trial_balance_rehearsal.bqn`; `tests/test_journal_split_purchase_report_information_boundary.bqn`; `tests/test_journal_file_backed_shadow_context.bqn` |
| Envelopes (`envelopes`) | human/JSON/compact; `envelope_computation.Build` | actual spend: Cube valid rows; budget: budget layer and raw `budget_alloc.tsv`; plan coverage/completion: raw plan/journal TSV | `BuildEnvelopes`, budget-layer TBDS/backing/coverage calculations | envelope metadata, plan ID/completion, memo/source rows | envelope computation, execution coverage, production guard, characterization, report JSON | structural B: persisted Journal budget companion reaches separate actual/budget Cube+TBDS; no envelope report rehearsal | no | Proven: Journal can preserve synthetic budget companion coordinates. Not proven: `envelope_computation.Build` parity, raw completion/frontier dependencies, production Journal input. | `src_next/envelope_computation.bqn`; `checks/check-src-next-envelope-computation.sh`; `checks/check-src-next-execution-plan-coverage.sh`; `tests/test_journal_budget_companion_projection_characterization.bqn`; `tests/test_journal_resolved_envelope_assignment_persistence.bqn` |
| Planned Payments (`planned`) | human/JSON/compact; `planned_payments` + `plan_rows` | plan: raw `plan.tsv`; actual: raw `journal.tsv` for completion/actual amount; budget: n/a | `plan_rows.Build/ActualValue`, temporal status | memo, plan ID, completion rows, source values | planned checks (including completion), report JSON, compact | structural B: parser/profile retains `plan-id`; no Planned Payments rehearsal | no | Proven: TSV planned/open/completed contracts. Not proven: Journal completion/actual-value consumer. | `src_next/planned_payments.bqn`; `src_next/plan_rows.bqn`; `checks/check-src-next-planned-payments.sh`; `tests/test_journal_external_plan_reference_profile_prerequisite.bqn` |
| Recent Journal (`recent`) | human + compact; `recent_journal.BuildRecentRows` | actual: Posting IR filtered to `source_file=journal.tsv` | source-row dedup and debit amount | `source_id` is displayed as memo; from/to reconstruction | recent checks, compact/report | none; Journal source-file/description identity differs and current filter excludes it | no | Proven: TSV recent rows. Not proven: Journal descriptions/grouping/recent ordering; requires explicit source-evidence decision. | `src_next/recent_journal.bqn`; `checks/check-src-next-recent-journal.sh`; `tests/test_journal_split_purchase_report_information_boundary.bqn` (shows description is lost after aggregation, not Recent compatibility) |
| Readiness Check (`check`) | human + compact; `readiness_check.Build/FormatHuman` | Cube skipped/valid rows plus direct TSV row counts and plan-overlap reads | diagnostic counts, not report money | source-file names, skipped messages, direct plan/journal rows | readiness, lint, compact/report | structural B rejection evidence exists; no Readiness report rehearsal | no | Proven: TSV diagnostics. Not proven: Journal-specific readiness vocabulary/counts and source-file assumptions. | `src_next/readiness_check.bqn`; `checks/check-src-next-readiness.sh`; `tests/test_journal_posting_ir_comparable_rejection_stage2c.bqn`; `tests/test_journal_resolved_account_registry_mismatch_rejection.bqn` |
| Outlook (`outlook`) | human + compact; `outlook.BuildAt` / `Build` | actual: `actual_snapshot` over Posting IR/TBDS but TSV source discriminator; frontier: direct journal TSV; plan: plan Posting IR + raw source evidence; envelopes: envelope VM | actual snapshot TBDS, `outlook_remaining_plan`, Outlook arithmetic | observation O, frontier L, anchor, plan ID/source row, envelope groups | observation-source, actual-snapshot, remaining-plan, clock, compact/report | structural B only for underlying Cube/TBDS; no Outlook Journal rehearsal | no | Proven: TSV checked actual/plan boundaries. Not proven: Journal actual admission because current filters/frontier name TSV explicitly; full Outlook parity. | `src_next/outlook.bqn`; `src_next/actual_snapshot.bqn`; `src_next/outlook_remaining_plan.bqn`; `checks/check-src-next-outlook-observation-source.sh`; `checks/check-src-next-actual-snapshot.sh`; `checks/check-src-next-outlook-remaining-plan.sh` |
| Daily Trend (`daily-trend`) | human + compact; `daily_trend.BuildAt` | actual/future plan: Cube; fixed reserve: plan Posting IR joined to TSV evidence; frontier/completion: direct TSV | Cube replay + `daily_trend_plan` checked reserve | row date D, latest actual TSV date, plan source row/ID/completion | daily-trend numeric-owner plus temporal unit tests, compact/report | structural B: Journal actual Cube coordinates; no Daily Trend rehearsal | no | Proven: TSV current-source replay. Not proven: Journal frontier, row membership, completion, or section output. | `src_next/daily_trend.bqn`; `src_next/daily_trend_plan.bqn`; `checks/check-src-next-daily-trend-plan-numeric-owner.sh`; `tests/test_journal_native_three_posting_semantic_parity.bqn` |
| Daily Flow (`daily-flow`) | human section; `daily_flow.Build` | actual/plan: Cube; completion/frontier/envelopes: TSV-derived helpers | Cube daily deltas + policy composition | latest actual date, overlap IDs, envelope state | report registry/builder/full-report smoke | structural B for Cube only; no Daily Flow rehearsal | no | Proven: registered TSV section. Not proven: any direct Journal Daily Flow output or TSV-evidence replacement. | `src_next/daily_flow.bqn`; `src_next/report_sections.bqn`; `tests/test_src_next_report_builder_order.bqn` |
| Actual Comparison (`actual-comparison`) | human + compact; `actual_comparison.BuildAt` | actual: Posting IR filtered to `source_file=journal.tsv`, local TBDS; plan: income anchors from plan Posting IR | local TBDS movements and deduplicated source-event counts | source row identity, anchor dates/accounts, observation O | four focused check modes, unit, compact/report | structural B only; current source discriminator excludes Journal rows | no | Proven: TSV numeric-owner and fail-closed windows. Not proven: Journal-derived comparison/counts/anchors. | `src_next/actual_comparison.bqn`; `checks/check-src-next-actual-comparison.sh`; `tests/test_src_next_actual_comparison.bqn` |
| Debug (`debug`) | human section; local builder in `report.bqn` | Cube verification over TSV-built context | `cube.VerifyNumeric` | resolved account keys | full report, builder/registry tests | structural B: Journal Cube parity; no debug-section rehearsal | no | Proven: TSV debug surface and Journal Cube structure separately. Not proven: assembled Journal debug report. | `src_next/report.bqn`; `src_next/cube.bqn`; `checks/check-src-next-report.sh`; `tests/test_journal_native_three_posting_semantic_parity.bqn` |
| Compact Summary | `tools/report-next-summary` → `summary.bqn` | shared TSV `BuildContext`; aggregates many rows above | delegated section owners + Cube/TBDS | all delegated source evidence | minimal/compact/stage4/currency checks on multiple fixtures | none end-to-end; individual B/C evidence does not prove summary | no | Proven: TSV machine surface. Not proven: any Journal-routed compact summary or cross-section parity. | `src_next/summary.bqn`; `checks/check-src-next-compact-summary.sh`; `checks/check-src-next-stage4-fields.sh` |
| Minimal Report Summary / Cube | compact/full diagnostic; `cube.FormatMinimalReportSummary` | checked Posting IR from all three TSV sources | `cube.Materialize` aggregates Day × Account × Layer | posting status/source/layer/account | 15 golden fixtures, minimal-summary checks, Cube units | structural B: native 3-posting and split purchase exact Cube evidence | no | Proven: synthetic Journal numeric Cube coordinates/topology admission. Not proven: production loader or all source semantics. | `src_next/cube.bqn`; `checks/check-src-next-golden.sh`; `checks/check-src-next-minimal-summary.sh`; `tests/test_journal_native_three_posting_semantic_parity.bqn`; `tests/test_journal_split_purchase_transaction_characterization.bqn` |
| TBDS machine surface | compact summary; `tbds.Format ctx.tbds` | Posting IR + Cube period view | `tbds.Build` opening/movement/closing | account/layer/period only | TBDS units, compact, snapshot/cycle consumers | structural B/direct accounting path: simple, split, shadow parity | no | Proven: Journal-derived actual and budget TBDS in synthetic contexts. Not proven: production routing/full consumer coverage. | `src_next/tbds.bqn`; `tests/test_src_next_tbds.bqn`; `tests/test_journal_file_backed_shadow_context.bqn`; `tests/test_journal_budget_companion_projection_characterization.bqn` |
| Expense Breakdown | compact summary and embedded Cycle formatting; `expense_breakdown.Build` | actual: TBDS movement | `tbds.ActualExpenseBreakdown` | account role/key; no transaction memo | focused check/unit, compact | structural B only: split Journal TBDS has exact expense-account totals; no direct builder assertion | no | Proven: TSV expense breakdown. Not proven: direct Journal builder/output parity. | `src_next/expense_breakdown.bqn`; `checks/check-src-next-expense-breakdown.sh`; `tests/test_journal_split_purchase_report_information_boundary.bqn` |
| Actual Snapshot (Outlook internal) | `outlook.BuildAt` calls `actual_snapshot.BuildAt` | actual Posting IR filtered to `source_file=journal.tsv`; local O-bounded TBDS | TBDS closing through O | source-row rejection diagnostics and observation O | focused actual-snapshot check/unit | structural B only; shadow TBDS parity does not exercise source discriminator | no | Proven: TSV O-bounded fail-closed snapshot. Not proven: Journal rows are admitted by this consumer. | `src_next/actual_snapshot.bqn`; `checks/check-src-next-actual-snapshot.sh`; `tests/test_src_next_actual_snapshot_numeric_owner.bqn` |
| Household Metadata | compact summary; `household_metadata.Build` | accounts metadata plus context | diagnostic counts | budget/group/spend-class metadata | focused check + compact | none | no | Proven: TSV/account-registry diagnostics. Not proven: assembled Journal context interaction. | `src_next/household_metadata.bqn`; `checks/check-src-next-household-metadata.sh` |
| Plan Journal Overlap | compact summary and readiness helper | raw `plan.tsv` + raw `journal.tsv` | identity comparison/counts, not ledger arithmetic | plan ID and 5-field fallback source rows | focused check + compact | structural B: Journal parser plan links; no overlap-consumer rehearsal | no | Proven: TSV overlap behavior. Not proven: native Journal source evidence or multi-posting identity mapping. | `src_next/plan_journal_overlap.bqn`; `checks/check-src-next-plan-journal-overlap.sh`; `tests/test_journal_external_plan_reference_profile_prerequisite.bqn` |

`checks/check-src-next-report.sh` combines multiple section/JSON contracts and is not itself one report. Conversely, `checks/check-src-next-compact-summary.sh` verifies one machine surface composed from many section owners. The matrix keeps those relationships explicit.

## Existing Journal evidence

The full suite passed these registered public-synthetic layers:

1. **Parser / profile (B):** `src_next/journal_profile_stage1.bqn` is test-only. `Parse` delegates explicitly to `strict_self_contained`; `ParseWithProfile` supports only `strict_self_contained` and `historical_external_plan`. `tests/test_journal_external_plan_reference_profile_prerequisite.bqn` proves the historical profile's zero-internal-plan-match exception and unchanged strict behavior for other cases.
2. **Stage 2A Posting IR (B):** `src_next/journal_posting_ir_stage2a.bqn` emits the established 16 named fields without production I/O. `tests/test_journal_posting_ir_adapter_stage2a.bqn` proves limited actual/plan success parity; account-registry mismatch is all-or-nothing in `tests/test_journal_resolved_account_registry_mismatch_rejection.bqn`.
3. **Stage 2B provenance (B):** `tests/test_journal_posting_identity_provenance_stage2b.bqn` proves a separate aligned provenance carrier without changing Posting IR.
4. **Comparable rejection (B):** Stage 2C covers invalid date, invalid exact-integer amount, and unknown account structurally; it does not prove diagnostic equality or broad production normalization.
5. **Cube/TBDS (B):** native three-posting and split-purchase fixtures prove exact account/layer coordinates while retaining Journal topology before aggregation. Budget companion tests prove actual/budget layer separation and historical persisted assignment behavior.
6. **Report rehearsal (C):** direct evidence is limited to Trial Balance and Balances (including compact/human Balances formatters). `tests/test_journal_file_backed_shadow_context.bqn` additionally proves an explicitly supplied public Journal file can build a shadow context whose actual TBDS, Trial Balance, and Balances match the public TSV fixture.
7. **Source-information boundary:** `tests/test_journal_split_purchase_report_information_boundary.bqn` proves descriptions, event IDs, grouping, and posting order remain source-side facts and are intentionally not reconstructible from aggregate Trial Balance/Balances outputs.

## Unproven Journal report surfaces

Major unproved areas are:

- **All production routing (D):** `tools/report`, `src_next/report.bqn`, `src_next/summary.bqn`, and `context.BuildContext` still choose TSV.
- **All private correctness (E):** no private source or report was read.
- **String-discriminated consumers:** YTD, Recent Journal, Actual Comparison, and Actual Snapshot explicitly select `source_file = journal.tsv`; existing Journal Stage 2A rows use `profile.journal`.
- **Raw source-evidence consumers:** Cycle Summary, Envelopes, Planned Payments, Outlook, Daily Trend, Daily Flow, Readiness, and Plan Journal Overlap still read `journal.tsv` and/or `plan.tsv` for frontier, memo, plan ID, completion, source-row join, or diagnostics.
- **Report-wide assembly:** no test runs `report.bqn` or `summary.bqn` with a Journal shadow context.
- **Non-rehearsed numeric consumers:** Snapshot, YTD, Cycle Summary, Expense Breakdown, Envelopes, Outlook, Actual Snapshot, Daily Trend, Daily Flow, and Actual Comparison lack direct Journal report-function assertions.
- **Source evidence equivalence:** Journal description, durable event identity, transaction grouping, posting order, physical line provenance, TSV `source_row`, and business `txn_id` are not interchangeable. Existing aggregate parity cannot fill those gaps.
- **Coverage breadth:** current rehearsals are synthetic, JPY-focused, and narrow. They do not establish selected-currency Balances parity, all metadata, all rejection classes, all temporal boundaries, or plan/budget production semantics.

Not established by current repository evidence: that swapping only the production loader would make every report correct. Several consumers have explicit TSV/source-row assumptions and require consumer-by-consumer characterization.

## Failure and unavailable classifications

- Initial full repository check: **success**, no failed or unavailable section.
- Focused reruns: not required because the full run had no failure.
- Environment: `rtk`, BQN, Node/npm, and repository tools were available.
- Production/private validation: **unavailable by scope**, not a repository failure and not attempted.
- D and E: **not proven**, not “failed”; no authorized production-Journal route or private observation was executed.

## Privacy and non-access confirmation

The prohibited path `/Users/user/Projects/moko/ledger-data` and its descendants were not read, listed, hashed, copied, or referenced by any command. No private Journal, TSV snapshot, suffix, amount, description, event ID, plan ID, metadata, or report output was accessed. Only repository code, docs, checks, and public synthetic fixtures were used.

## Candidate next finite slices

No candidate is selected by this audit.

1. **Converter implementation resumption** — gate: explicit owner review of the blocked selected converter plan and its stop conditions; no private conversion in the implementation PR.
2. **Journal production report coverage characterization** — gate: owner selects a finite consumer set and explicitly defines how source-file/source-row/description/plan-completion evidence is represented without changing production routing.
3. **One-report Journal shadow parity slice** — gate: choose exactly one unrehearsed report, public synthetic fixture, numeric and source-evidence parity dimensions, and fail-closed red paths; remain explicit-path/test-only.
4. **Private read-only verification** — gate: separate explicit owner authorization, privacy-safe command/result contract, and confirmation that no source bytes or values enter Git/chat. This audit does not authorize it.
5. **Production cutover readiness** — gate: converter/reconstruction, complete parser/Posting IR validation, report-consumer coverage, prefix parity, suffix preservation, writer/source policy, and explicit owner approval all pass first.

## Conclusion

On remote main `64d808ebb8954de3f4a3cfeb29373542e1d9c24b`, existing repository and production-report checks pass without regression over public TSV fixtures (**A passed**). The repository has substantial public-synthetic Journal structural evidence through parser, unchanged 16-field Posting IR, provenance, rejection, Cube, and TBDS (**B passed within its stated bounds**). It has direct Journal report rehearsal only for Trial Balance and Balances, including a file-backed explicit shadow parity test (**limited C passed**).

Production report routing remains TSV for all 22 inventoried surfaces (**D not proven / no production route**), and private daily-bookkeeping correctness was not examined (**E not proven**). Native Journal remains the owner-selected future durable actual source, but the canonical converter is blocked pending explicit owner review, production cutover remains blocked, and dual daily writes remain prohibited. Evidence: `TODO.md`, `NEXT_SESSION.md`, the converter plan, `context.BuildContext`, and the test-only Journal module headers.

## Commands executed

Commands were run from `/Users/user/Projects/moko/bqn-ledger`. Long-output Git/check/search commands used `rtk` as required.

```text
rtk git branch --show-current
rtk git status --short --branch
rtk git rev-parse HEAD
rtk git fetch origin --prune
rtk git rev-parse main
rtk git rev-parse origin/main
rtk git ls-remote origin refs/heads/main
rtk git log --oneline --decorate -n 8 origin/main
rtk git switch main
rtk git pull --ff-only origin main
rtk git rev-parse HEAD
rtk git rev-parse main
rtk git rev-parse origin/main
rtk git status --short --branch
rtk git branch --list docs/journal-report-coverage-inventory
rtk git ls-remote --heads origin refs/heads/docs/journal-report-coverage-inventory
git show-ref --verify --quiet refs/heads/docs/journal-report-coverage-inventory
git ls-remote --exit-code --heads origin refs/heads/docs/journal-report-coverage-inventory
rtk git switch -c docs/journal-report-coverage-inventory
rtk bash ./tools/check.sh
rtk rg -n "journal.tsv|actual.journal|ParseWithProfile|strict_self_contained|historical_external_plan" ...
rtk rg -n "BuildPeriodView|Posting IR|posting_ir|TBDS|Cube|trial_balance|balances" ...
rtk rg -n "Cycle Summary|YTD|Expense Breakdown|Recent Journal|Planned Payments|Actual Comparison|Outlook|Actual Snapshot|Daily Trend|Compact Summary" ...
rtk rg -n "report routing|production source|source truth|Journal read-path|rehearsal" ...
find tests checks fixtures -type f ...
rg -n ... src_next/<report modules>.bqn
rg -n ... tests/test_journal_*.bqn
tools/report fixtures/src-next-golden --list-sections --no-color
```

Repository files were read with the agent read tool; that does not access the prohibited external path.

## Changed-file verification

The intended and only change is:

```text
docs/archive/audits/JOURNAL_REPORT_COVERAGE_INVENTORY-2026-07-22.md
```

Validation after adding the audit returned success for `git diff --check`, `bash checks/check-docs-lifecycle.sh` (4 passed), `bash checks/check-absolute-links.sh` (1 passed), `bash checks/check-repo-index.sh`, and the second full `rtk bash ./tools/check.sh` (exit 0). The final status/name/stat/check gate is recorded immediately before commit; any additional changed file is a stop condition.
