# Final report-engine cutover inventory

Status: P12 exact deletion classification and tracked rehearsal complete. Cutover is **blocked** and production remains unchanged.
Date: 2026-07-28
Authority: `REPORT_PORTFOLIO_CONTRACT.md`, `REPORT_SURFACE_RETIREMENT_MAP.md`, `DESTINATION_COMPOSITION.md`

## Executive result

The destination report side is complete through nine individual routes, human/compact `all`, cache publication, and operational check/inspection. The repository is not yet ready to delete `src_next/` atomically.

Measured tracked blockers:

```text
src_next BQN modules                                  65
BQN files outside src_next with direct src_next import 103
  src_edit files                                       0
  test files                                          99
  check/tool characterization BQN files                 4
named tests/test_src_next_*.bqn                       74
other test files with direct src_next import          26
checks/check-src-next-*.sh                            33
fixture directories named fixtures/src-next-*         34
tracked files under fixtures/src-next-*              146
classified residual runtime references                13
current documentation references                      58
  migrate                                              19
  delete                                               39
```

The live editor gate is green: `src_edit/` and `src/editor/` have zero `src_next` imports. The remaining 103 direct-import files are old tests and four characterization/probe files, all classified for deletion. `tests/test_ledger_facts.bqn` was the sole retained non-src-next test and now uses canonical Account admission only. Destination runtime under `src/` also has no `src_next` import.

The reproducible tracked inventory is:

```bash
tools/characterization/final_cutover_inventory.py
tools/characterization/final_cutover_inventory.py --format tsv
tools/characterization/final_cutover_inventory.py --assert-destination-clean
tools/characterization/final_cutover_rehearsal.py
```

`checks/check-final-cutover-inventory.sh` requires every blocker family to remain visible while asserting zero destination `src_next` imports. The check and tool are removed or converted to a ready-state assertion in the atomic cutover.

## Gate A: production application route

Current owners:

```text
tools/report                 -> src_next/report.bqn
tools/report-next            -> src_next/main.bqn
tools/report-next-summary    -> src_next/summary.bqn
tools/report-section-metadata -> src_next/report_section_metadata.bqn
```

Destination proof owners:

```text
tools/report-destination
tools/report-destination-all
tools/report-destination-cache
src/report/catalog.bqn
src/report/request.bqn
src/report/compose.bqn
src/report/render.bqn
```

Remaining work:

1. define the final `tools/report` option/profile mapping to explicit destination coordinates and source basenames;
2. map canonical/default source configuration only after strict private readiness—no fallback discovery;
3. replace production route, list, direct, full, JSON, compact, and cache in one cutover;
4. delete parallel proof names rather than retaining a forwarding layer.

## Gate B: metadata, labels, Command Hub, and cache

Current metadata/UI chain:

```text
src_next/report_sections.bqn
src_next/report_section_metadata.bqn
tools/report-section-metadata
tools/main-ui.sh
tools/command-hub-cache-refresh
tools/command-hub-preview
checks/check-report-section-metadata.sh
checks/check-command-hub-browse-cache.sh
```

The source-independent six-field destination TSV/JSON adapter is now complete in parallel: it derives exact key/order/label/category/owner/human/structured fields from `src/report/catalog.bqn`, points to destination section owners, and rejects retired keys. Before cutover:

- switch UI listing and refresh to destination metadata/cache;
- update browse/cache invalidation proofs;
- remove old hard-coded help keys and old metadata expected TSV.

`config/report_labels.tsv` has 128 lines and is consumed by the old report stack and UI label invalidation. Destination labels are section/catalog-owned. At cutover, retained configuration must be explicitly migrated or the old label file and check removed; old-only labels must not remain as inert compatibility data.

## Gate C: compact summary and query

Current machine chain:

```text
src_next/summary.bqn
tools/report-next-summary
tools/query
tools/devtools-check.sh
checks/check-src-next-compact-summary.sh
plus old src_next_* focused checks/fixtures
```

Destination compact owners are only:

```text
ledger_envelope_*
ledger_balance
ledger_recent_journal
ledger_planned_payment
ledger_daily_target_*
```

Parallel destination proof is complete:

- final `tools/report-summary` runs the admitted compact all manifest through the same individual route;
- `tools/query-destination` proves exact repeated-value `ledger_*` lookup, exact listing, and unique key enumeration;
- old names are neither translated nor dual-emitted; regex/prefix lookup is absent.

At atomic cutover, replace `tools/query` with the proven implementation, update approved tracked consumers, and delete `tools/report-next-summary`, old `src_next_*` output, checks, and fixtures together. Do not leave `tools/query-destination` as a second final query route.

The external-consumer gate is green: under explicit user direction, executable/script/config/automation locations, launch agents, cron, and running processes were searched for `tools/query`, `report-next-summary`, and `src_next_*`. No untracked runtime consumer was found. Matches were limited to tracked current code, an independent legacy repository, and non-executable historical logs/docs. Shell history and private ledger contents were intentionally not inspected. Alias-free deletion remains approved.

## Gate D: editor runtime extraction — green

```text
src_edit/src_next direct imports   0
src/editor/src_next direct imports 0
```

The first extractions moved bounded text/source/config operations to neutral owners and physically removed the two obsolete helper modules. The Actual slice then moved all 12 editor consumers to explicit config routing plus canonical strict Account/Journal Facts in `src/application/editor_actual.bqn`. Completion evidence now exists only for durable non-empty `plan_id`; fabricated transaction-field identity is not emitted. Public sandbox/demo/golden/plan fixtures gained explicit source and Account currency evidence. Current production report compatibility remains in `src_next/actual_source.bqn` until cutover/private readiness. The Account slice moved eight operational consumers to strict canonical Account tables and removed redundant Stage 2A carrier revalidation after complete Journal admission. The final cluster physically moved the historical editor Journal parser and travel validators to `src/editor`, moved Plan temporal status to `src/accounting`, replaced editor date use with canonical date coordinates plus one application clock adapter, removed redundant old Posting IR comparison from canonical rewrite, and replaced broad `BuildContext` post-write validation with strict configured Journal validation. No forwarding module remains.

No forwarding module remains under `src_next`; editor extraction is no longer a cutover blocker.

## Gate E: tests, checks, fixtures, and characterization — classified

The 74 named src-next tests, 26 other compatibility tests, 33 named checks, and four direct-import probe/characterization BQN files are exact deletion inventory. `tests/test_ledger_facts.bqn` is retained and has no old import. The public strict editor fixture was renamed to `fixtures/editor-golden`; the remaining 34 `fixtures/src-next-*` families are deletion inventory.

The inventory additionally classifies 13 residual executable references as one migration and 12 deletions. Current documentation references are exactly 19 migrations and 39 deletions. Any unrecognized reference fails `check-final-cutover-inventory.sh`; no action may use `or`/`classify`. Historical `docs/archive` references are non-runtime and excluded.

Repository-root discovery in retained editor checks no longer uses the old report file as a sentinel. Redundant per-module old-path assertions were removed in favor of the central editor boundary, Source I/O ownership now checks only its final owners, devtools query coverage uses the exact destination summary/query, and `tools/coverage` inventories final module/test families. This preparation reduced residual runtime references from 35 to 13 without switching production.

`tools/check.sh`, safe-write routing, repo index, docs indexes, and workflow inventories must be updated in the same atomic deletion so no removed check remains invoked.

`tools/characterization/final_cutover_rehearsal.py` applies the disposition to a tracked-path simulation without touching the worktree. The current rehearsal removes 402 tracked paths, leaves zero old BQN imports and zero old named path families, preserves final proof fixtures/checks/tools, and verifies all three replacement targets have destination proof owners. Its state is `ready_for_atomic_diff`, not permission to inspect private data or switch production.

## Gate F: private source readiness

No private source was read during this inventory. Cutover requires separate authorization for readonly audit and migration of at least:

- strict eight-column Issues with durable `issue_id`;
- Daily Target Account/Plan/reservation scope;
- explicit Envelope funding Account ownership;
- exact report observations/targets/cycle comparison coordinates or their approved explicit config owner;
- canonical source basename/config readiness.

The sequence remains audit → preview → approval → apply. There is no five-column Issues fallback or inferred ownership path.

## Atomic cutover deletion/replacement set

One final cutover change must include all of these families:

1. `tools/report` and destination application naming;
2. `src_next/` physical deletion;
3. old direct entrypoints `report-next` and `report-next-summary`;
4. static metadata owner, expected metadata, labels, UI menu/help;
5. Command Hub refresh/cache manifest and stale old cache bodies;
6. compact summary/query keys and callers;
7. report `check`/`debug` removal in favor of operational commands;
8. old tests/checks/fixtures/probes and `tools/check.sh` invocations;
9. stale docs/current-design descriptions and repo indexes;
10. parallel proof wrappers that are replaced by final names.

Aliases, dual keys, dual catalogs, fallback parsers, and forwarding wrappers are forbidden.

## Ordered preparation slices

Before requesting cutover approval:

1. prepare final route/UI/cache replacement diff without switching production;
2. separately authorized private readiness;
3. one reviewed atomic production/cutover diff.
