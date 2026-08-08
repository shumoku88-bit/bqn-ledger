# Canonical Household Source Recovery Roadmap

Status: proposed recovery plan

Baseline: `bqn-ledger` main `e35203c856ef27fed52dfe955825472104823198`

## 1. Goal

Restore the complete retained `bqn-ledger` application against the same canonical Household root used by `h-kernel`, then remove the legacy source topology and every production dependency on it.

The final state is not a compatibility sandwich. `bqn-ledger` must read the canonical Journal/TOML/TSV sources directly, project them into BQN-native Facts and policy coordinates, preserve its array-native accounting/report kernels, and write only through explicitly qualified canonical operations.

The target canonical Household root is:

```text
accounts.journal
actual.journal
plan.journal
budget.journal
budget.toml
household.toml
report.toml
issues.tsv
```

The recovery is complete only when:

1. all retained reports and operational surfaces work from that source set;
2. all retained editor capabilities have a canonical implementation or an explicit final retirement decision;
3. no production reader, writer, UI, report route, check, default, or documentation requires legacy Household files;
4. the private canonical data repository no longer needs the legacy files retained only for migration evidence;
5. one writer-authority rule remains explicit and dual writing is never introduced during migration;
6. repository documentation describes only the final canonical topology, except clearly archived historical records.

## 2. Current mismatch

`bqn-ledger` currently has a mature accounting/report core, but its application and editor boundaries still assume the earlier source topology.

Current production assumptions include:

- Account admission from `accounts.tsv`;
- Actual Journal admission paired with separately admitted TSV Accounts;
- Plan admission from `plan.tsv`;
- Budget movement admission from `budget_alloc.tsv`;
- Cycle coordinates from `cycle.tsv`;
- Daily Target scope from `daily_target_scope.tsv` plus Plan TSV;
- household/account policy retained in TSV/config metadata;
- report selection and source coordinates from report manifest TSV files;
- source/default discovery through `config.tsv`, `config/system_defaults.tsv`, environment variables, and explicit manifest source basenames.

The canonical Household target instead assigns ownership as follows:

| Meaning | Canonical owner |
| --- | --- |
| Account identity, type, optional default Commodity | `accounts.journal` |
| Actual transactions and Actual relations | `actual.journal` |
| Plan, schedule, recurrence, lifecycle relations | `plan.journal` |
| ordered Budget movement facts and provenance | `budget.journal` |
| general Budget policy | `budget.toml` |
| Household policy, Account classifications, cycle and Daily Target policy | `household.toml` |
| report query defaults and presentation policy | `report.toml` |
| non-accounting Household notebook | `issues.tsv` |

Legacy files are migration evidence, not an alternate canonical source.

## 3. Non-negotiable migration rules

### 3.1 One canonical root

Both engines may consume the same Household root. Do not create a BQN-specific mirror, generated TSV shadow tree, copied data directory, or synchronization job.

### 3.2 Native admission, not back-conversion

Do not restore `bqn-ledger` by converting `accounts.journal`, `plan.journal`, or `budget.journal` back into the legacy TSV layouts. New BQN adapters must project canonical source meaning directly into existing or intentionally revised BQN Facts.

### 3.3 Preserve the BQN core

Source migration must not become a rewrite of `src/accounting`, `src/sections`, or the array-native review queue. Existing exact arithmetic, canonical Fact alignment, report result shapes, provenance, diagnostics, ordering, and native multi-posting support remain protected unless a separately scoped correctness change is required.

### 3.4 No dual writer

Reader parity does not grant writer authority. During recovery, `h-kernel` remains the canonical writer wherever current policy says so. A BQN write capability may be implemented and tested before it is operationally authorized, but it must not silently become a second active writer.

Final writer coexistence requires an explicit authority decision after safety parity is proven. At any moment, one canonical operation must have one authoritative write path.

### 3.5 Delete superseded paths in the same phase

Once a canonical replacement is proven and cut over, remove the corresponding production legacy adapter, default, writer path, check assumptions, and documentation. Do not preserve permanent fallback branches such as "try Journal, then TSV".

## 4. Protected feature inventory

Recovery must cover the application, not only the accounting library.

### 4.1 Retained report portfolio

All twelve retained report keys must work from the canonical root:

1. `envelopes`
2. `balances`
3. `balance-sheet`
4. `profit-and-loss`
5. `recent`
6. `planned`
7. `cycle-accounts`
8. `cycle-comparison`
9. `monthly-accounts`
10. `daily-flow`
11. `daily-target`
12. `issues`

`all`, human/compact surfaces, section metadata, exact query access, current-profile behavior, and historical explicit requests remain part of the retained capability set.

### 4.2 Operational/read-only surfaces

The final canonical root must support:

- `tools/main-ui.sh` and Command Hub report selection;
- report cache generation, refresh, preview, and last-known-good behavior;
- `tools/report`;
- `tools/report-summary`;
- `tools/query`;
- `tools/report-section-metadata`;
- `tools/ledger-check`;
- `tools/ledger-inspect`;
- source/provenance diagnostic surfaces used by checks and development tools;
- retained export/conversion tools that are still part of the supported application, including hledger export if it remains supported at cutover.

### 4.3 Editor capability inventory

Every current editor command must be classified as `restore`, `replace`, or `retire` before final cleanup. The default is `restore` when the capability still has meaning under the canonical contract.

Current capabilities to account for include:

- Account: `add`, `list`;
- Actual Journal: `add`, `multi-add`, `list`, `reverse`;
- native Journal block append;
- Journal identity inventory and canonical-surface/cleanup operations that remain semantically relevant;
- Plan: `add`, `list`, `related`, `finish`, `budget-sync`, `edit`;
- Budget movement: `add`;
- Issue: `add`, `list`, `close`;
- travel friend source-event entry;
- travel exchange entry;
- `tools/add-ui.sh` interaction paths that expose these operations.

A command is not considered restored merely because its shell entry point still exists. It must read and mutate the canonical owner and pass complete-source post-admission.

## 5. Roadmap phases

Each implementation PR should be a coherent finite slice. Correctness changes, source migration, writer changes, UI changes, and cleanup should not be mixed unless the slice cannot be proven otherwise.

### Phase 0: freeze the target and establish executable baseline

Purpose: make later cutover measurable.

Work:

- record the eight canonical basenames in one BQN application-level owner;
- inventory every production reference to legacy basenames and classify it by reader, writer, report, UI, check, fixture, documentation, or migration-only evidence;
- inventory the complete `tools/` executable surface and classify supported application commands versus development-only utilities;
- characterize the current known `tools/check.sh` baseline failure around `check-current-report-profile.sh` and restore a trustworthy full-suite baseline before source cutover claims depend on it;
- add synthetic canonical Household fixtures containing all eight target files without private values;
- add a source-topology check that prevents new production references to legacy basenames after their retirement phase begins.

Exit gate:

- complete inventory committed;
- synthetic canonical root exists;
- full-suite baseline is understood and actionable;
- no implementation has changed canonical writer authority.

### Phase 1: canonical Account boundary

Purpose: replace `accounts.tsv` as the production Account owner.

Work:

- implement `accounts.journal` admission in BQN;
- support Account identity, Account type, and optional default Commodity according to the canonical contract;
- project the result into the Account coordinates required by existing BQN Facts and accounting kernels;
- move Household-only Account classification lookups to the later `household.toml` policy boundary instead of copying them into Account Journal admission;
- update account listing/read-only editor selection to use the new Account registry;
- add cross-engine synthetic parity for Account identity/type/Commodity and rejection cases.

Do not yet delete `accounts.tsv` from private data. Downstream Plan/Budget/Actual readers still require migration.

Exit gate:

- every new BQN canonical reader can obtain its Account registry from `accounts.journal`;
- no new production code consumes `accounts.tsv`;
- legacy Account TSV remains only where explicitly listed by the migration inventory.

### Phase 2: canonical Actual reader and Actual-only report restoration

Purpose: make BQN read the same `actual.journal` as `h-kernel` without TSV Account assistance.

Work:

- resolve canonical `include accounts.journal` semantics;
- admit canonical transaction headers, metadata, posting syntax, explicit commodities, exact amounts, and supported amount elision;
- preserve native multi-posting transactions, identity, Plan completion linkage, reversal linkage, provenance, source coordinates, and exact arithmetic;
- remove the requirement that the complete Actual source declares BQN-specific commodity/account data already owned by the canonical include graph;
- project directly into existing canonical BQN Actual Facts;
- restore `ledger-check`, `ledger-inspect`, and Actual-only report paths against the canonical root.

Reports expected to become canonical at this phase where they do not depend on unmigrated Plan/Budget/policy sources:

- `balances`;
- `balance-sheet`;
- `profit-and-loss`;
- `recent`;
- `monthly-accounts`;
- `daily-flow`.

Exit gate:

- synthetic cross-engine parity for accepted/rejected Actual transactions;
- private canonical read-only smoke passes without reading `accounts.tsv`;
- the six Actual-only reports pass focused and full report evidence from canonical sources;
- BQN remains read-only for canonical Actual unless a later writer phase explicitly authorizes writes.

### Phase 3: canonical Plan Journal

Purpose: remove `plan.tsv` from production Plan semantics.

Work:

- implement canonical `plan.journal` admission over the shared Account include graph;
- admit Plan identity, schedule/recurrence metadata, lifecycle relations, Daily Target selection metadata, and other currently retained Plan semantics;
- preserve exact amounts and posting structure without flattening canonical transactions into legacy from/to rows;
- replace Plan Facts consumers so `planned`, Plan temporal status, completion joins, and cycle income-anchor logic consume canonical Plan facts;
- port Plan read-only editor operations: `list`, `related`, selector logic;
- characterize every current Plan TSV metadata field and prove it is either represented canonically or intentionally retired.

Exit gate:

- `planned` works from `plan.journal`;
- Plan-dependent cycle paths can run without `plan.tsv`;
- no production reader requires `plan.tsv`;
- private parity evidence proves no retained Plan meaning is lost.

### Phase 4: canonical Budget Journal and Budget policy

Purpose: replace `budget_alloc.tsv` and move policy to its named owners.

Work:

- implement `budget.journal` movement admission;
- preserve source order, date, memo, from/to semantic movement, exact Amount, Account resolution, and provenance in BQN-native representation;
- implement the subset of `budget.toml` needed by retained BQN accounting and report behavior;
- stop reading Budget/account policy from legacy Account/config metadata when `budget.toml` is the canonical owner;
- restore Envelope/Backing calculations on canonical Budget evidence.

Exit gate:

- `envelopes` works without `budget_alloc.tsv`;
- Budget movement parity is proven synthetically and on private read-only smoke;
- no production reader requires `budget_alloc.tsv`.

### Phase 5: canonical Household policy, Cycle, and Daily Target

Purpose: replace `cycle.tsv`, `daily_target_scope.tsv`, and Household-only metadata retained in old TSV/config sources.

Work:

- implement the required `household.toml` admission as a named application/policy owner;
- admit Account classification axes required by existing reports: Asset class, Budget structural kind, Envelope role, Household Budget group, Expense spend class, and any other retained policy proven by the inventory;
- admit canonical cycle policy and derive current/baseline cycle coordinates from canonical Actual/Plan evidence where specified;
- rebuild Daily Target scope from `household.toml` asset selection plus `plan.journal` Plan-selection/reservation evidence;
- preserve source-independent selection identities and exact reservation evidence;
- restore `cycle-accounts`, `cycle-comparison`, and `daily-target` from canonical sources.

Exit gate:

- all cycle reports pass without `cycle.tsv`;
- Daily Target passes without `daily_target_scope.tsv`;
- no retained Account-policy behavior requires `accounts.tsv` metadata;
- private parity evidence accounts for every retained policy axis.

### Phase 6: native `report.toml` and report routing simplification

Purpose: remove report manifest TSV files as application configuration.

Work:

- implement BQN admission for the retained `report.toml` schema;
- keep report query/presentation policy in `report.toml` and keep source basenames out of report policy;
- construct report requests from canonical root paths plus typed report policy instead of manifest rows carrying physical source names;
- preserve historical explicit report capability by making historical query coordinates explicit without reviving arbitrary legacy source-basename configuration;
- preserve `all`, human/compact rendering, section metadata, exact query keys, current profile, and deterministic clock-free behavior;
- update cache and Command Hub paths to use the canonical report configuration.

Exit gate:

- all twelve reports run from canonical root plus `report.toml`;
- `REPORT_MANIFEST_CONFIG` is unnecessary for normal operation;
- no production report path reads `report_manifests.tsv`, `report_all_human.tsv`, or `report_all_compact.tsv` as request configuration.

### Phase 7: complete read-side application recovery

Purpose: prove the entire non-mutating application before writer cutover.

Required evidence:

- all twelve report keys individually;
- `all` report composition;
- human and compact surfaces;
- section metadata and exact `query` access;
- current-profile date/cycle resolution;
- report cache generation, failed-refresh preservation, preview, and Command Hub behavior;
- `main-ui.sh` rich and minimal modes;
- `ledger-check` on the eight canonical sources;
- `ledger-inspect` canonical Fact/provenance evidence;
- empty, multi-currency, multi-posting, invalid-source, missing-source, include, identity, exact-decimal, and policy rejection characterization;
- private canonical root read-only smoke with no private content copied to this repository or CI logs.

Exit gate:

- `bqn-ledger` is a complete canonical read-only application;
- legacy source files are no longer required to read or report the household.

### Phase 8: canonical writer qualification

Purpose: restore original editor capability without creating competing writer authority.

Qualify one semantic owner at a time.

#### 8A Account writer

- `account add` writes `accounts.journal` declarations;
- candidate preview, complete-source admission, stale rejection, backup, atomic publication, and post-admission are required;
- Household classification edits, if supported, modify `household.toml` through a separate typed operation rather than smuggling policy into Account declarations.

#### 8B Actual writer

Restore the meaningful retained operations against canonical `actual.journal`:

- `journal add`;
- `journal multi-add`;
- native block append;
- `journal list`;
- `journal reverse`;
- identity inventory;
- cleanup/canonical-surface operations only if they still have a canonical purpose after source migration.

Do not authorize these writes merely because implementation tests pass. Canonical Actual writer authority changes only through an explicit policy decision after parity with the current authoritative writer is demonstrated.

#### 8C Plan writer

Restore against `plan.journal`:

- `plan add`;
- `plan edit`;
- `plan finish`;
- `plan related`;
- recurrence/advance behavior;
- `plan budget-sync` only if the operation remains meaningful under the separated Plan/Budget owners.

Plan completion must append canonical Actual evidence and update Plan lifecycle semantics without dual writing or generated shadow TSV rows.

#### 8D Budget writer

- `budget add` writes canonical `budget.journal` movement evidence;
- Budget policy changes, if exposed, target `budget.toml` through separate typed operations.

#### 8E Issue writer

- retain the shared eight-column `issues.tsv` format;
- reconcile status/date admission differences so BQN never emits a row rejected by the canonical h-kernel reader;
- restore `issue add`, `list`, and `close` with canonical validation.

#### 8F Specialized editor paths

- port travel friend and exchange operations to canonical owners if they remain supported application features;
- remove them only through an explicit retirement decision documenting the replacement workflow.

Writer qualification gate for every mutating operation:

1. preview is derived from typed intent;
2. complete current source is admitted before mutation;
3. stale source is rejected;
4. backup/recovery behavior is tested;
5. publication is atomic;
6. complete resulting source is re-admitted;
7. failure never publishes partial bytes;
8. writer authority is explicit;
9. no other engine is simultaneously treated as authoritative for the same operation.

### Phase 9: legacy runtime deletion inside `bqn-ledger`

Purpose: remove the migration scaffolding instead of carrying it forever.

Delete or rewrite:

- TSV Account admission used only for production Household loading;
- TSV Plan/companion production admission after canonical Plan cutover;
- `budget_alloc.tsv` production admission after Budget Journal cutover;
- `cycle.tsv` and Daily Target scope production loaders;
- `config.tsv` application-source selection once canonical root topology is fixed;
- report manifest config/admission and manifest source routing after `report.toml` cutover;
- `config/system_defaults.tsv` keys that name retired Household files;
- editor code that writes retired TSV sources;
- shell environment/default plumbing used only to locate retired files;
- compatibility aliases and fallback branches;
- obsolete migration-only checks once their final canonical replacements cover the same contract;
- obsolete fixtures that exist only to exercise a deleted production format, unless deliberately moved to a clearly historical archive with no runtime dependency.

Required repository grep gate:

Legacy basenames must not occur in active production code, active checks, current usage docs, or default configuration after their corresponding retirement phase. Historical archive documents may retain them when clearly marked as history.

### Phase 10: private canonical data legacy-file retirement

Purpose: remove the old physical files only after both engines no longer need them.

Candidate legacy files currently retained for migration evidence include:

```text
accounts.tsv
plan.tsv
budget_alloc.tsv
cycle.tsv
daily_target_scope.tsv
config.tsv
report_manifests.tsv
report_all_human.tsv
report_all_compact.tsv
```

Do not delete a file because a replacement file merely exists.

Per-file deletion gate:

1. canonical owner and schema are documented;
2. `h-kernel` reads the canonical owner;
3. `bqn-ledger` reads the canonical owner;
4. every retained BQN report using that meaning passes canonical evidence;
5. every retained writer using that meaning targets the canonical owner or has an explicit retirement decision;
6. cross-engine synthetic parity covers retained semantics;
7. private canonical smoke passes after temporarily hiding the legacy file;
8. repository-wide searches show no active runtime dependency;
9. migration-only metadata has been accounted for field by field;
10. rollback is available through Git history/backup without keeping a live duplicate source.

Delete legacy files from the private data repository in small, source-owner-specific PRs. Do not delete all legacy files in one opaque final batch.

Suggested retirement order:

1. `accounts.tsv` after Account plus Household policy parity;
2. `plan.tsv` after Plan reader/writer and lifecycle parity;
3. `budget_alloc.tsv` after Budget reader/writer parity;
4. `cycle.tsv` after canonical cycle derivation parity;
5. `daily_target_scope.tsv` after Household + Plan Daily Target parity;
6. `config.tsv` after every retained setting has a canonical owner or explicit retirement;
7. legacy report manifest files after `report.toml`, direct historical requests, cache, UI, and query behavior are fully canonical.

The exact order may change when a dependency proves tighter, but every deletion remains individually gated.

### Phase 11: documentation and repository finalization

Purpose: leave one understandable system, not a trail of contradictory current documents.

Update at minimum:

- `README.md` setup and examples;
- `docs/ARCHITECTURE.md` production flow and ownership;
- `docs/AI_CODEMAP.md` source/application ownership;
- editor usage docs;
- Data directory/setup docs;
- Journal and Plan lifecycle docs;
- Cycle and Daily Target docs;
- report configuration/current-profile docs;
- fixture/demo docs;
- environment examples;
- `tools/doctor` expectations;
- contributor/AI guidance that names old production sources;
- checks that enforce current documentation examples.

Archive or delete documents whose only purpose was an already-completed migration. A current reader should encounter the eight-file canonical topology first and should not need to understand the legacy TSV era to operate or modify the program.

Final documentation gate:

- one canonical source diagram;
- one setup path;
- one writer-authority explanation;
- no current document instructs users to create, configure, or edit retired legacy files.

## 6. Legacy source retirement matrix

| Legacy source | Canonical replacement | Main blocked capabilities before retirement |
| --- | --- | --- |
| `accounts.tsv` | `accounts.journal` + `household.toml` policy axes | all Account validation, Actual/Plan/Budget admission, editor Account selection |
| `plan.tsv` | `plan.journal` | planned, Plan lifecycle, cycle income-anchor behavior, Daily Target Plan selection, Plan editor |
| `budget_alloc.tsv` | `budget.journal` | Envelope/Backing, Budget editor |
| `cycle.tsv` | `household.toml` cycle policy + canonical Actual/Plan evidence | cycle-accounts, cycle-comparison, current profile |
| `daily_target_scope.tsv` | `household.toml` asset selection + `plan.journal` selection/reservation evidence | daily-target |
| `config.tsv` | fixed canonical root topology + `budget.toml`/`household.toml` named policies | source discovery and residual legacy policy |
| report manifest TSVs | `report.toml` + canonical request builder | all/current report routing, cache/UI template behavior |

## 7. PR slicing policy

Prefer a sequence of narrow PRs. A likely series is:

1. inventory + canonical root fixture/gates;
2. Account Journal admission;
3. Actual Journal canonical admission;
4. Actual-only reports cutover;
5. Plan Journal admission;
6. Planned/cycle Plan consumers cutover;
7. Budget Journal admission;
8. `budget.toml` policy admission;
9. `household.toml` Account/cycle policy admission;
10. Daily Target native scope;
11. `report.toml` admission;
12. report route/current-profile/cache/UI cutover;
13. complete read-side parity gate;
14. Account writer qualification;
15. Actual writer qualification;
16. Plan writer qualification;
17. Budget writer qualification;
18. Issue writer parity;
19. specialized editor qualification/retirement;
20. bqn-ledger legacy runtime deletion;
21. private data legacy-file retirement, split by source owner;
22. final documentation/fixture/check cleanup.

The sequence is a dependency map, not a requirement to force exactly twenty-two PRs. Combine adjacent slices only when the proof becomes clearer, not to reduce PR count.

## 8. Evidence policy

Every cutover phase should provide the smallest sufficient evidence set:

- focused pure BQN tests for admission/projection;
- exact diagnostic characterization for malformed sources;
- synthetic cross-engine parity where both BQN and h-kernel express the same semantic owner;
- report/result parity for affected retained capabilities;
- complete `tools/check.sh` before Ready unless an independently reproduced baseline failure is explicitly tracked;
- coverage/readiness checks already required by the repository;
- final diff review for accidental writer/source/default changes;
- private data smoke only where needed, without copying private values into this repository, PR text, Issues, or CI logs.

Parity means semantic parity, not byte-for-byte reproduction of the legacy physical format.

## 9. Definition of done

The recovery project is done when all of the following are true:

- the eight-file canonical Household root is the only production Household source topology;
- `bqn-ledger` starts from one root and resolves canonical owners without legacy source-name manifests;
- all twelve reports work and remain queryable/renderable through retained surfaces;
- current profile, historical explicit reporting, cache, Command Hub, minimal/rich UI, check, and inspect work;
- every retained editor capability is canonical and qualified, or explicitly retired with a replacement workflow;
- writer authority is explicit and no dual writer exists;
- no production code converts canonical sources back to legacy TSV for internal use;
- all retired source readers/writers/defaults/fallbacks are deleted;
- legacy Household files are removed from the private canonical data repository after individual deletion gates;
- current docs and examples describe only the final topology;
- archived history is clearly separated from current instructions;
- BQN accounting kernels remain BQN-native rather than becoming wrappers around h-kernel.

The desired coexistence is therefore simple:

```text
                 canonical Household root
                           |
              +------------+------------+
              |                         |
          h-kernel                  bqn-ledger
       typed Haskell view          array-native Facts
              |                         |
       Haskell operations          BQN calculations,
                                  reports, and qualified
                                  canonical operations
```

One source contract, two native interpretations, no shadow source tree.
