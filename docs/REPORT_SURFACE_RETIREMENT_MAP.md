# Current report surface retirement map

Status: Portfolio Contract P1 repository-consumer inventory
Date: 2026-07-28
Authority: `REPORT_PORTFOLIO_DECISION.md` and `REPORT_PORTFOLIO_CONTRACT.md`
Scope: tracked repository consumers and public fixtures; external/private consumers are not assumed absent

## Purpose

This map prevents “removed report” from meaning only “hide one menu row”. At cutover, each old owner is either migrated to a retained report or deleted together with route, metadata, cache, compact/query keys, CLI options, checks, fixtures, labels, and documentation.

Current production remains unchanged while destination reports are implemented. Existing checks continue to characterize current behavior until their owning removal gate is reached.

## Shared consumer families

| family | current owner/examples | cutover action |
|---|---|---|
| static section catalog/order | `src_next/report_sections.bqn`, metadata expected TSV, list-section checks | replace with the nine-key destination catalog |
| human/full dispatch | `src_next/report.bqn`, `tools/report`, report checks | route retained keys only; full output follows retained order |
| section cache/Command Hub | `--write-section-cache`, `.section-keys`, cache refresh/browse checks | regenerate manifest from retained catalog; delete retired `KEY.txt` files atomically |
| compact summary | `src_next/summary.bqn`, `tools/report-next-summary` | replace with `tools/report-summary` and registered retained compact owners only |
| compact query | `tools/query`, scripts parsing `src_next_*` | migrate required values to documented `ledger_*` owners or delete the consumer; no translation fallback |
| JSON dispatch | current snapshot/balances/envelopes/planned JSON checks | retain only balances/envelopes/planned destination JSON; delete snapshot JSON |
| UI metadata/menu | `tools/report-section-metadata`, Command Hub cache menu | consume retained metadata manifest; no hard-coded old labels/order |
| labels | `config/report_labels.tsv` | keep/rename retained labels; delete old-only label keys after caller search |
| latency/characterization | report latency probes, context-duplication probes | update to representative retained reports or archive/delete after cutover |
| focused current-runtime tests | `tests/test_src_next_*`, `checks/check-src-next-*` | replace with destination contract tests where semantics are retained; delete compatibility-only tests with old owner |
| editor issue/plan commands | `src_edit/issue_*`, `src_edit/plan_*` | not report consumers; retain and share canonical admission/identity semantics |

The repository search found heavy check/test pressure but no authority to infer untracked external `tools/query` consumers. Before compact-key deletion, perform a final tracked search and ask moko about any external scripts; do not inspect private data to answer that question.

## Per-section map

### `snapshot` → remove/decompose

Retained meaning moves to:

- latest balances → `balances`;
- funding/backing → `envelopes`;
- daily capacity → `daily-target`.

Atomic removal:

- remove `snapshot` route, metadata/cache key, labels, owner, human/JSON dispatcher;
- delete snapshot compact totals that have no retained named question;
- migrate required liquid/funding values to Envelope or Daily Target evidence, not a new snapshot compatibility record;
- update `check-src-next-report.sh`, JSON clock checks, selected-section poisoning checks, audit smoke calls, and snapshot-focused tests;
- remove snapshot JSON schema rather than aliasing it to balances.

### `issues` → rebuild as `issues`

Retain human route and source-order/open selection semantics after strict issue admission. No compact/JSON surface is selected.

- update metadata owner and cache body;
- replace current report tests with destination List tests;
- preserve editor add/list/close commands independently;
- prevent editor tools from parsing human report text.

### `ytd` → merge into `monthly-accounts`

- remove `ytd` route/cache/metadata/labels and `src_next_ytd_*` compact keys;
- delete unsupported-JSON and unavailable-cycle compatibility checks with the old owner;
- migrate any genuinely used year-to-date question to an explicit month-range Monthly Accounts request;
- do not add YTD cards until a retained consumer requires them.

### `balances` → rebuild as `balances`

Retain selected-domain human/compact/JSON and zero-posting Account behavior.

- preserve `--currency CODE` for balances;
- migrate `src_next_balance` to `ledger_balance` atomically;
- update `tools/query`, balances checks, ILS/USD vertical checks, Command Hub direct/cache checks, JSON checks, labels, metadata, and owner path;
- remove implicit/default-domain compatibility fixtures after strict readiness, not by adding fallback to destination.

### `cycle` → split

- Account opening/movement/closing → `cycle-accounts`;
- horizon and remaining-day evidence → `daily-target` and report metadata;
- open Plans → `planned`/`envelopes`;
- remove Cycle Summary route/cache/metadata/labels and broad `src_next_cycle_*` block.

Each old compact field must be assigned to a retained owner or deleted. In particular, income/expense/net summary fields do not survive merely because `tools/query` can read them.

### `trial-balance` → `cycle-accounts` plus developer proof

- destination Account-period capability and proof tests remain reusable;
- remove old production key/metadata/cache/compact block;
- implement `cycle-accounts` with the added `movement` column and explicit observation;
- keep a full-period Trial Balance only as a plainly named developer inspection preset if it has a real caller;
- do not alias `trial-balance` to `cycle-accounts`.

### `envelopes` → rebuild as `envelopes`

Retain human/compact/JSON surfaces, but replace the old ViewModel with the P1 Envelope & Backing terms.

- migrate `src_next_envelope_*` consumers to documented `ledger_envelope_*` fields derived from one destination result;
- update envelope computation/backing/execution-plan checks and JSON fixtures;
- retain funding, signed envelope total, positive backing requirement, surplus, ledger unassigned, reconciliation delta, Plan reserve, status, and contributor evidence as distinct coordinates;
- delete old policy fallback, raw Budget parsing, `ForTest` surfaces, and old labels with the owner;
- no report imports the old envelope renderer/ViewModel.

### `planned` → retain as `planned`

The destination section proof is complete.

- migrate production human/JSON to `src/sections/planned_payments.bqn` at cutover;
- migrate compact `src_next_planned_payment` to `ledger_planned_payment` with all query/check callers;
- delete `src_next/planned_payments.bqn`, `src_next/plan_rows.bqn` compatibility paths, five-field identity tests, and `ForTest` exports when no other retained capability calls them;
- editor Plan commands retain durable `plan_id` workflows independently.

### `recent` → rebuild as `recent`

- retain human/compact and newest-first Transaction List;
- migrate `src_next_recent_journal` to `ledger_recent_journal`;
- update recent checks and strict public split-transaction evidence;
- delete assumptions that one transaction has one debit/to Account;
- no JSON surface selected.

### `check` → operational `tools/ledger-check`

- remove report route/cache/metadata/labels and readiness compact block;
- move retained strict admission/readiness diagnostics to a non-report operational command with nonzero error status;
- overlap diagnostics either become Plan/Envelope validation evidence or are removed;
- distinguish repository development `tools/check.sh` from future source-facing `tools/ledger-check`;
- delete human report formatting and compatibility counts that do not guide a repair.

### `outlook` → replace with `daily-target` and `envelopes`

- remove route/cache/metadata/labels and `src_next_outlook_*` compact keys;
- replace `--outlook-as-of` with destination `--as-of`; no alias;
- move conservative daily capacity to `daily-target` under explicit asset/obligation policy;
- move Envelope reserve/backing rows to `envelopes`;
- do not carry current future-income arithmetic into P1 safe capacity;
- update selected-section, observation-source, remaining-plan, Actual snapshot, Stage 4 field, and Outlook focused tests to retained owners or delete them.

### `daily-trend` → remove/replace

- remove route/cache/metadata/labels, `src_next_daily_trend*` compact keys, ranked-drop List, and row-replay compatibility tests;
- monthly Account movement moves to `monthly-accounts`;
- current-cycle Account state moves to `cycle-accounts`;
- safe per-day question moves to `daily-target`;
- do not preserve current-source replay as a pseudo-historical knowledge model.

### `daily-flow` → remove production route

- remove route/cache/metadata/labels and current section checks at cutover;
- retain sparse Group/Pivot/Matrix capabilities while they have retained consumers/proofs;
- keep the destination Daily Flow proof temporarily as architecture evidence;
- after Monthly Accounts is implemented, reassess whether date/category flow has another retained consumer; delete proof-only modules if not.

### `actual-comparison` → replace with `cycle-comparison`

- remove route/cache/metadata/labels and `src_next_actual_comparison_*` compact fields;
- replace inferred previous-anchor behavior with two explicit windows and selected `aligned_elapsed|complete_cycles` policy;
- migrate useful public comparison fixtures to Account × current/baseline/difference Matrix tests;
- remove lane/count/ratio/status behavior unless separately re-approved.

### `debug` → operational `tools/ledger-inspect`

- remove report route/cache/metadata/labels and inline report builder;
- retain useful Fact/provenance/numeric inspection under a plainly named non-authoritative command;
- delete `partial/src_next` wording and generation-named entrypoints;
- inspection output is diagnostic capability, not normal report schema.

## Compact key ownership after reset

Selected destination prefixes:

```text
ledger_envelope_*
ledger_balance
ledger_recent_journal
ledger_planned_payment
ledger_daily_target_*
```

There are no compact prefixes for the three Account Matrix reports or Issues in P1. Old `src_next_cycle_*`, `src_next_ytd_*`, `src_next_actual_comparison_*`, and `src_next_daily_trend*` are removed rather than translated wholesale.

Exact envelope/daily-target suffixes are fixed with their implementation result contracts. `tools/query` performs exact-key lookup only and never maps old names.

## Cache and stale-file deletion

At cutover, the new manifest is exactly:

```text
envelopes
balances
recent
planned
cycle-accounts
cycle-comparison
monthly-accounts
daily-target
issues
all
```

Refresh stages all retained bodies and manifest, validates them, atomically publishes, and removes old files not in the manifest, including:

```text
snapshot.txt
ytd.txt
cycle.txt
trial-balance.txt
check.txt
outlook.txt
daily-trend.txt
daily-flow.txt
actual-comparison.txt
debug.txt
```

No stale file may remain selectable after its metadata key disappears.

## Final removal gate

Before deleting any old owner:

1. destination positive/empty/invalid public evidence passes;
2. retained direct/full/cache/compact/JSON consumers use the destination owner;
3. tracked caller search for route/key/module is empty except explicit archive/current-history docs;
4. external script use is confirmed with moko when a machine key or CLI option changes;
5. metadata, labels, fixtures, checks, and stale cache files are resolved in the same cutover;
6. private source readiness remains separately authorized;
7. no forwarding module, alias key, dual catalog, or fallback parser is introduced.
