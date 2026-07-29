# Phase 0 report engine characterization

Status: Phase 0 exit evidence
Baseline implementation: `e274fe0` plus the public proof fixture/check added in this slice
Purpose: migration comparison evidence, never CI performance thresholds

## Static size and topology

Reproducible commands:

```bash
find src_next -type f -name '*.bqn' | wc -l
find src_next -type f -name '*.bqn' -print0 | xargs -0 wc -l
python3 tools/src-next-import-graph --summary
python3 tools/characterization/src_next_export_callers.py --summary
```

Observed baseline:

| metric | value |
|---|---:|
| BQN modules | 75 |
| physical BQN lines | 13,027 |
| root modules | 71 |
| nested modules | 4 |
| direct internal imports | 286 |
| import cycles | 0 |
| scan errors | 0 |
| recognized modules with final export record | 70 |
| exports | 335 |
| runtime/editor/tool-called exports | 205 |
| test/check-only exports | 63 |
| `ForTest` seams | 14 |
| zero-repository-caller exports | 53 |

The detailed caller evidence is `docs/SRC_NEXT_EXPORT_CALLER_INVENTORY.md`. Module/line counts describe deletion pressure, not a destination size target.

## Source-read ownership

The current composition is not read-once:

- `context.bqn` and `selected_domain_context.bqn` construct separate evidence routes;
- `actual_source.bqn` owns current Actual resolution/admission plus historical behavior;
- config/account/cycle construction reads their source coordinates;
- Cycle, Planned, Envelope, Outlook, Actual Comparison, Readiness, overlap, and trend helpers still perform report-local Plan/Budget/account/cycle reads or source text parsing;
- direct/full selected Balances may construct selected evidence separately from the ordinary context;
- labels are a separate presentation config read;
- report cache writes are composition I/O, not source admission.

A broad static search currently finds source-I/O-shaped calls in 21 `src_next` modules. That number is intentionally not a correctness metric because it includes cache/diagnostic I/O and does not measure repeated runtime reads. C03, C04, C09, and C10 in `docs/RUNTIME_COMPATIBILITY_INVENTORY.md` own the exact deletion requirements.

Destination rule: one strict source snapshot/admission boundary reads each required coordinate for one command. Sections receive admitted facts or narrow capabilities and perform no source reads or amount-text parsing.

## Public timing sample

Command:

```bash
tmp=$(mktemp -d)
bqn tools/characterization/report_latency_probe.bqn \
  fixtures/ledger-facts-phase1-proof "$tmp"
rm -rf "$tmp"
```

One local sample:

| stage | milliseconds |
|---|---:|
| imports | 50.962 |
| ordinary `BuildContext` | 39.062 |
| shared precomputations | 4.865 |
| all section builders/formatters | 12.622 |
| section cache writes | 3.693 |
| total probe | 115.806 |

Fixture scale:

| metric | value |
|---|---:|
| checked projection posting rows | 13 |
| Actual transactions | 3 |
| account keys | 8 |

This is one machine/run and includes process/import/cache effects. It is characterization only. No Phase 1 check may fail because a timing differs. Prior context-duplication observations and caveats remain in `docs/REPORT_CONTEXT_DUPLICATION_CHARACTERIZATION-2026-07-27.md`.

## Observable output baseline

`fixtures/ledger-facts-phase1-proof/` is a strict public synthetic base with explicit currency, role, path, Plan identity, cycle, and empty-compatibility-free companion rows. Its focused check records:

- three Actual transactions and the visible semantics of a three-posting split;
- Trial Balance account closing values and zero-sum totals;
- Recent transaction ordering and multi-destination rendering;
- Daily Flow dynamic category columns;
- selected JPY Balances;
- completed Plan JSON joined by durable identity;
- all 15 section keys and selected first-line markers.

Command:

```bash
bash checks/check-ledger-facts-phase1-proof-fixture.sh
```

During Phase 1 the same fixture must compare current production output with canonical transaction/posting facts. It is not permission to import `src_next` code into the destination.

## Phase 0 exit assessment

Complete:

- all 15 report constructions classified;
- output surfaces and parity levels approved;
- strict-source requirements approved;
- compatibility candidates classified with deletion gates;
- all recognized exports/callers inventoried;
- public source readiness measured;
- private audit/write authorization boundaries defined without inspecting private data;
- strict public synthetic proof fixture and check added;
- static topology, size, source-read pressure, and public timing recorded.

No destination fallback remains undecided. Phase 1 may begin with a small canonical complete-admission fact-schema proof. This authorization does not permit private inspection/migration, section copying, a universal context, or a generic textual query DSL.
