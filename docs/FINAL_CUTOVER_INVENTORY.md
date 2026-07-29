# Final report-engine cutover inventory

Status: P10I tracked repository inventory complete; cutover is **blocked** and production remains unchanged.
Date: 2026-07-28
Authority: `REPORT_PORTFOLIO_CONTRACT.md`, `REPORT_SURFACE_RETIREMENT_MAP.md`, `DESTINATION_COMPOSITION.md`

## Executive result

The destination report side is complete through nine individual routes, human/compact `all`, cache publication, and operational check/inspection. The repository is not yet ready to delete `src_next/` atomically.

Measured tracked blockers:

```text
src_next BQN modules                                  71
BQN files outside src_next with direct src_next import 180
  src_edit files                                      35
  test files                                          141
  check/tool characterization BQN files                 4
named tests/test_src_next_*.bqn                       79
other test files with direct src_next import          63
checks/check-src-next-*.sh                            33
fixture directories named fixtures/src-next-*         35
tracked files under fixtures/src-next-*              153
```

The 180 direct-import files are not all retained runtime. Most tests/checks/fixtures disappear with the old owner, but the 35 editor files are live and must be migrated before physical deletion. Destination runtime under `src/` has no `src_next` import.

The reproducible tracked inventory is:

```bash
tools/characterization/final_cutover_inventory.py
tools/characterization/final_cutover_inventory.py --format tsv
tools/characterization/final_cutover_inventory.py --assert-destination-clean
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

Destination catalog and cache already prove the final key order and stale deletion, but the six-field metadata TSV/JSON adapter is not yet wired. Before cutover:

- derive metadata from `src/report/catalog.bqn`;
- point owner fields to destination section modules;
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

Remaining work:

- introduce final `tools/report-summary` over the compact all manifest;
- change `tools/query` to exact `ledger_*` lookup;
- update only approved consumers;
- delete all old `src_next_*` keys and generation-named summary route atomically;
- do not translate old keys or dual-emit.

External consumers cannot be inferred from Git. Moko must confirm whether untracked scripts call `tools/query`, `tools/report-next-summary`, or parse `src_next_*` keys before this gate can turn green.

## Gate D: editor runtime extraction

Thirty-five `src_edit/*.bqn` files directly import 14 `src_next` modules. Import frequency:

```text
24 loader.bqn
13 config.bqn
12 util.bqn
12 actual_source.bqn
 9 account_key.bqn
 8 journal_profile_stage1.bqn
 8 currency_setup.bqn
 5 date.bqn
 2 journal_currency_proof_carrier_stage2a.bqn
 1 each: journal_posting_ir_stage2a, plan_status,
         travel_exchange_event, friend_travel_source_event, context
```

This is the largest live runtime blocker. Required action is ownership migration, not copying all of `src_next`:

- move generic I/O/text/date/config operations to implementation-neutral owners;
- make editor Journal validation use canonical ledger admission where semantics match;
- retain genuinely editor-specific rewrite/preview capabilities under `src_edit`;
- replace or remove travel helpers according to actual editor callers;
- remove the one editor `context.bqn` dependency instead of moving context;
- update editor checks in the same slices.

No forwarding modules may remain under `src_next`.

## Gate E: tests, checks, fixtures, and characterization

The 79 named src-next tests, 33 named checks, and four direct-import probe/characterization BQN files are deletion inventory, not a migration target. The four are the two `checks/probes/*` old-report probes and two `tools/characterization/*` context/report probes. For each file:

- retain only semantics still owned by ledger/accounting/sections/application;
- move retained assertions to destination tests;
- delete compatibility, old report, Cube/TBDS-only, fallback, and removed-section tests;
- migrate non-src-next destination tests off `src_next/loader.bqn` to an implementation-neutral test/application reader;
- delete old characterization probes after their replacement evidence is recorded;
- delete obsolete `fixtures/src-next-*` directories unless a retained editor/source case still uses one, in which case rename and narrow it.

`tools/check.sh`, coverage, repo index, docs indexes, and workflow inventories must be updated in the same atomic deletion so no removed check remains invoked.

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

1. destination six-field metadata and UI-independent listing;
2. destination compact summary and exact-key query proof;
3. editor dependency extraction from `src_next`;
4. retained non-src-next test helper migration;
5. tracked old test/check/fixture/docs deletion rehearsal;
6. external script answer and separately authorized private readiness;
7. one reviewed atomic production/cutover diff.
